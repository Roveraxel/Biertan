using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Animations;
using UnityEngine.Playables;
using Biertan.Enemies;
using Biertan.Levels;
using Biertan.Player;

namespace Biertan.Visual3D
{
    /// <summary>
    /// Animated 3D bodies for the 2D actors, in Quaternius's stylized low-poly look (CC0): people are built
    /// from the Modular Fantasy outfits with a head and hair from the Universal Base Characters, all on one
    /// humanoid rig, so every clip of the Universal Animation Library plays on every one of them. The undead
    /// are KayKit skeletons (CC0, same clips through humanoid retargeting); wolves and the wolf-creatures use
    /// the Quaternius wolf with its own clips. Each body follows its 2D actor, turns toward where it moves or
    /// strikes, and picks a clip from the actor's state. When the actor is destroyed the body plays its death
    /// out, then sinks away. Missing files mean no body: the sprite board stays.
    /// </summary>
    public class CharacterBody : MonoBehaviour
    {
        public enum Move { Idle, Walk, Run, Attack, Attack2, Roll, Hit, Roar, Death }

        /// <summary>Off: the hand-drawn 2D figures stand in the 3D world instead (the chosen direction).</summary>
        public static bool Enabled = false;

        class Spec
        {
            public string outfit, head, hair, beard, skeleton;   // what to assemble
            public bool wolf;
            public float height = 1.8f;
            public string set = "villager";
            public Color tint = Color.white, skin = Color.white;
            public float glow;                                   // emissive strength (spirits)
        }

        const string Root = "Models3D/";

        static Spec SpecFor(Transform t)
        {
            if (t.GetComponent<PlayerController>() != null)
                return new Spec { outfit = "Male_Ranger", head = "Male", height = 1.85f, set = "sword" };
            var e = t.GetComponent<EnemyBase>();
            if (e != null)
                switch (e.kind)
                {
                    case "wolf": return new Spec { wolf = true, height = 0.95f, set = "wolf" };
                    case "pricolici": return new Spec { wolf = true, height = 1.45f, set = "wolf", tint = new Color(0.45f, 0.38f, 0.34f) };
                    case "varcolac": return new Spec { wolf = true, height = 2.6f, set = "wolf", tint = new Color(0.22f, 0.2f, 0.24f) };
                    case "strigoi": return new Spec { outfit = "Male_Ranger", head = "Male", hair = "Hair_Long", height = 1.85f, set = "claw", tint = new Color(0.35f, 0.3f, 0.36f), skin = new Color(0.85f, 0.88f, 0.95f) };
                    case "vlad": return new Spec { outfit = "Male_Ranger", head = "Male", hair = "Hair_Long", beard = "Hair_Beard", height = 2.15f, set = "claw", tint = new Color(0.5f, 0.12f, 0.14f), skin = new Color(0.9f, 0.9f, 0.97f) };
                    case "moroi": return new Spec { skeleton = "Skeleton_Minion", height = 1.7f, set = "zombie" };
                    case "shade": return new Spec { skeleton = "Skeleton_Rogue", height = 1.75f, set = "spirit", tint = new Color(0.35f, 0.35f, 0.5f) };
                    case "muma": return new Spec { outfit = "Female_Peasant", head = "Female", hair = "Hair_Long", height = 2.4f, set = "zombie", tint = new Color(0.32f, 0.42f, 0.3f), skin = new Color(0.62f, 0.7f, 0.55f) };
                    case "scarecrow": return new Spec { outfit = "Male_Peasant", head = "Male", hair = "Hair_Buzzed", height = 2.0f, set = "zombie", tint = new Color(0.85f, 0.72f, 0.45f), skin = new Color(0.8f, 0.65f, 0.4f) };
                    case "iele": return new Spec { outfit = "Female_Peasant", head = "Female", hair = "Hair_Long", height = 1.75f, set = "spirit", tint = new Color(1.25f, 1.25f, 1.35f), skin = new Color(1.1f, 1.1f, 1.2f), glow = 0.35f };
                }
            var pr = t.GetComponent<Prop>();
            if (pr != null && pr.kind == "npc") return Villager(pr.id);
            return null;
        }

        static Spec Villager(string id)
        {
            bool woman = id is "magda" or "veta" or "sofia" or "katharina" or "rozalia";
            int h = Mathf.Abs(id.GetHashCode());
            var s = new Spec { outfit = woman ? "Female_Peasant" : "Male_Peasant", head = woman ? "Female" : "Male", height = woman ? 1.68f : 1.8f, set = "villager" };
            s.hair = woman ? (h % 2 == 0 ? "Hair_Buns" : "Hair_Long") : (h % 3 == 0 ? "Hair_Buzzed" : "Hair_SimpleParted");
            if (!woman && h % 2 == 1) s.beard = "Hair_Beard";
            s.tint = id switch
            {
                "veta" or "pastor" or "sexton" => new Color(0.35f, 0.33f, 0.36f), // mourning black, clergy
                "hermit" => new Color(0.75f, 0.68f, 0.55f),
                "konrad" or "vasile" => new Color(0.7f, 0.62f, 0.55f),
                _ => Color.white,
            };
            return s;
        }

        // which clip plays each move, per set (Universal Animation Library names; the wolf has its own)
        static readonly Dictionary<string, string[]> Sets = new()
        {   //               Idle                Walk                    Run              Attack              Attack2              Roll    Hit              Roar                    Death
            ["sword"] =    new[] { "Sword_Idle", "Walk_Loop", "Jog_Fwd_Loop", "Sword_Regular_A", "Sword_Regular_B", "Roll", "Hit_Chest", "Sword_Block", "Death01" },
            ["claw"] =     new[] { "Idle_Loop", "Walk_Formal_Loop", "Sprint_Loop", "Melee_Hook", "Spell_Simple_Shoot", "Roll", "Hit_Head", "Spell_Simple_Enter", "Death01" },
            ["zombie"] =   new[] { "Zombie_Idle_Loop", "Zombie_Walk_Fwd_Loop", "Jog_Fwd_Loop", "Zombie_Scratch", "Melee_Hook", "Jog_Fwd_Loop", "Hit_Chest", "Zombie_Scratch", "Death01" },
            ["spirit"] =   new[] { "Spell_Simple_Idle_Loop", "Walk_Formal_Loop", "Sprint_Loop", "Spell_Simple_Shoot", "Spell_Simple_Shoot", "Roll", "Hit_Head", "Spell_Simple_Enter", "Death01" },
            ["villager"] = new[] { "Idle_Loop", "Walk_Loop", "Jog_Fwd_Loop", "Idle_Talking_Loop", "Idle_Talking_Loop", "Walk_Loop", "Hit_Chest", "Idle_Talking_Loop", "Death01" },
            ["wolf"] =     new[] { "Idle", "Walk", "Gallop", "Attack", "Attack", "Gallop", "Idle_HitReact_Left", "Idle_2_HeadLow", "Death" },
        };
        // the clips' own travel speed in metres per second, so feet don't skate
        const float WalkSpeed = 1.4f, RunSpeed = 3.6f;

        static Dictionary<string, AnimationClip> ual, wolfClips;
        static readonly Dictionary<string, GameObject> cache = new();
        static readonly Dictionary<(Material, Color, float), Material> tinted = new();

        public Transform src;
        Spec spec;
        PlayableGraph graph;
        AnimationMixerPlayable mixer;
        readonly AnimationClipPlayable[] slots = new AnimationClipPlayable[9];
        readonly float[] weight = new float[9];
        Move cur = Move.Idle;
        float curT, yaw, hurtWas, dyingT = -1f, sink;
        Vector3 lastPos;
        Vector2 smoothVel;
        bool hasLast;

        public static CharacterBody Create(Transform actor, Transform parent)
        {
            var spec = SpecFor(actor);
            if (spec == null) return null;
            string path = spec.wolf ? "Animals/Wolf" : spec.skeleton != null ? "Skeletons/" + spec.skeleton : "Chars/Outfits/" + spec.outfit;
            var prefab = Load(path);
            if (prefab == null) return null;
            var go = Instantiate(prefab, parent, false);
            go.name = "Body3D " + actor.name;
            var body = go.AddComponent<CharacterBody>();
            body.src = actor; body.spec = spec;
            body.Setup();
            return body;
        }

        static GameObject Load(string p)
        {
            if (!cache.TryGetValue(p, out var g)) { g = Resources.Load<GameObject>(Root + p); cache[p] = g; }
            return g;
        }

        static void LoadClips()
        {
            if (ual != null) return;
            ual = new Dictionary<string, AnimationClip>();
            foreach (var f in new[] { "Anims/UAL1_Standard", "Anims/UAL2_Standard" })
                foreach (var c in Resources.LoadAll<AnimationClip>(Root + f))
                {
                    if (c.name.StartsWith("__")) continue;
                    string n = c.name.Contains("|") ? c.name.Substring(c.name.LastIndexOf('|') + 1) : c.name;
                    if (!ual.ContainsKey(n)) ual[n] = c;
                }
            wolfClips = new Dictionary<string, AnimationClip>();
            foreach (var c in Resources.LoadAll<AnimationClip>(Root + "Animals/Wolf"))
            {
                if (c.name.StartsWith("__")) continue;
                string n = c.name.Contains("|") ? c.name.Substring(c.name.LastIndexOf('|') + 1) : c.name;
                wolfClips[n] = c;
            }
        }

        AnimationClip Clip(string name)
        {
            var d = spec.wolf ? wolfClips : ual;
            return d != null && d.TryGetValue(name, out var c) ? c : null;
        }

        /// <summary>Puts a skinned part from another file (a head, hair, a beard) onto this body's skeleton,
        /// matching bones by name: every Quaternius character shares the same 65-bone rig.</summary>
        void Attach(SkinnedMeshRenderer from, Mesh mesh, Material[] mats)
        {
            var bones = new Dictionary<string, Transform>();
            foreach (var t in GetComponentsInChildren<Transform>()) bones.TryAdd(t.name, t);
            var map = new Transform[from.bones.Length];
            for (int i = 0; i < map.Length; i++)
                map[i] = from.bones[i] != null && bones.TryGetValue(from.bones[i].name, out var b) ? b : null;
            var go = new GameObject(mesh.name);
            go.transform.SetParent(transform, false);
            var r = go.AddComponent<SkinnedMeshRenderer>();
            r.sharedMesh = mesh; r.bones = map; r.sharedMaterials = mats;
            r.rootBone = bones.TryGetValue(from.rootBone ? from.rootBone.name : "root", out var rb) ? rb : transform;
        }

        void AddHead()
        {
            var basePrefab = Load("Chars/Base/Superhero_" + spec.head + "_FullBody");
            if (basePrefab == null) return;
            foreach (var r in basePrefab.GetComponentsInChildren<SkinnedMeshRenderer>(true))
            {
                string n = r.name.ToLowerInvariant();
                if (n.StartsWith("superhero"))
                {
                    var head = Resources.Load<Mesh>(Root + "Chars/Heads/Head_" + spec.head);
                    if (head != null) Attach(r, head, new[] { Tint(r.sharedMaterial, spec.skin, 0f) });
                }
                else if (n.Contains("eyes")) Attach(r, r.sharedMesh, r.sharedMaterials);
                else if (n.Contains("eyebrows")) Attach(r, r.sharedMesh, r.sharedMaterials);
            }
            foreach (var h in new[] { spec.hair, spec.beard })
            {
                if (h == null) continue;
                var hp = Load("Chars/Hair/" + h);
                if (hp == null) continue;
                foreach (var r in hp.GetComponentsInChildren<SkinnedMeshRenderer>(true)) Attach(r, r.sharedMesh, r.sharedMaterials);
            }
        }

        void Setup()
        {
            foreach (var col in GetComponentsInChildren<Collider>()) Destroy(col);
            LoadClips();
            var anim = GetComponent<Animator>();
            if (anim == null) anim = gameObject.AddComponent<Animator>();
            // the female peasant ships without a working avatar; the ranger's fits the same skeleton
            if (spec.outfit == "Female_Peasant" && (anim.avatar == null || !anim.avatar.isValid))
            {
                var fr = Load("Chars/Outfits/Female_Ranger");
                if (fr != null) anim.avatar = fr.GetComponent<Animator>().avatar;
            }
            if (spec.head != null) AddHead();
            var hood = transform.Find("Male_Ranger_Head_Hood");
            if (hood != null && spec.set != "sword") hood.gameObject.SetActive(false); // vampires go bareheaded

            // outfit colours: tint the clothing, keep the skin (the "Regular" body material) as it is
            foreach (var r in GetComponentsInChildren<Renderer>())
            {
                if (r.name.StartsWith("Head_") || r.name.Contains("Eye") || r.name.Contains("Hair")) continue;
                var ms = r.sharedMaterials;
                for (int i = 0; i < ms.Length; i++)
                {
                    if (ms[i] == null) continue;
                    bool skin = ms[i].name.Contains("Regular") || ms[i].name.Contains("Superhero");
                    ms[i] = Tint(ms[i], skin ? spec.skin : spec.tint, spec.glow);
                }
                r.sharedMaterials = ms;
            }
            foreach (var r in GetComponentsInChildren<Renderer>())
            {
                r.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
                if (r is SkinnedMeshRenderer smr) smr.updateWhenOffscreen = true;
            }

            // size: stand at the intended height (measured in the bind pose, before animation)
            var b = new Bounds(transform.position, Vector3.zero);
            bool any = false;
            foreach (var r in GetComponentsInChildren<Renderer>())
            {
                if (r.name.Contains("Weapon")) continue;
                if (!any) { b = r.bounds; any = true; } else b.Encapsulate(r.bounds);
            }
            if (any && b.size.y > 0.01f) transform.localScale = Vector3.one * (spec.height / b.size.y);

            anim.applyRootMotion = false;
            anim.cullingMode = AnimatorCullingMode.AlwaysAnimate;
            graph = PlayableGraph.Create("Body");
            graph.SetTimeUpdateMode(DirectorUpdateMode.GameTime);
            mixer = AnimationMixerPlayable.Create(graph, slots.Length);
            var names = Sets[spec.set];
            for (int i = 0; i < slots.Length; i++)
            {
                var clip = Clip(names[i]) ?? Clip(names[0]);
                if (clip == null) continue;
                slots[i] = AnimationClipPlayable.Create(graph, clip);
                slots[i].SetApplyFootIK(!spec.wolf);
                graph.Connect(slots[i], 0, mixer, i);
            }
            var output = AnimationPlayableOutput.Create(graph, "Anim", anim);
            output.SetSourcePlayable(mixer);
            weight[0] = 1f;
            mixer.SetInputWeight(0, 1f);
            graph.Play();
        }

        static Material Tint(Material m, Color c, float glow)
        {
            if (m == null || (c == Color.white && glow <= 0f)) return m;
            var key = (m, c, glow);
            if (tinted.TryGetValue(key, out var t) && t != null) return t;
            t = new Material(m) { name = m.name + " tinted" };
            if (t.HasProperty("_BaseColor")) t.SetColor("_BaseColor", m.GetColor("_BaseColor") * c);
            else if (t.HasProperty("_Color")) t.color = m.color * c;
            if (glow > 0f && t.HasProperty("_EmissionColor"))
            {
                t.EnableKeyword("_EMISSION");
                t.SetColor("_EmissionColor", new Color(0.55f, 0.65f, 0.9f) * glow);
            }
            tinted[key] = t;
            return t;
        }

        void OnDestroy() { if (graph.IsValid()) graph.Destroy(); }

        static bool IsOneShot(Move m) => m is Move.Attack or Move.Attack2 or Move.Hit or Move.Roar or Move.Death or Move.Roll;

        Move Choose(out Vector2 face, float speed)
        {
            face = Vector2.zero;
            var p = src.GetComponent<PlayerController>();
            if (p != null)
            {
                face = p.facing;
                if (p.hp <= 0f) return Move.Death;
                if (p.dodgeT > 0f) { face = p.dodgeDir; return Move.Roll; }
                if (p.attackT > 0f) return Move.Attack;
                if (p.hurtFlash > hurtWas + 0.01f) return Move.Hit;
                return speed > 2.4f ? Move.Run : speed > 0.3f ? Move.Walk : Move.Idle;
            }
            var e = src.GetComponent<EnemyBase>();
            if (e != null)
            {
                face = e.face;
                if (e.hp <= 0f) return Move.Death;
                string s = e.state;
                var f = e.GetType().GetField("bstate");
                if (f != null) s = (string)f.GetValue(e);
                switch (s)
                {
                    case "roar": case "rear": case "telegraph": case "charge_tel": case "howl":
                        return Move.Roar;
                    case "windup": case "lunge": case "leap": case "swipe": case "sweep": case "tel": case "sweep_tel":
                    case "throw": case "dash_tel":
                        return Move.Attack;
                    case "cast": case "pools": case "rite": case "blink":
                        return Move.Attack2;
                    case "stunned": case "fallen": case "recover":
                        return Move.Hit;
                }
                if (e.flash > hurtWas + 0.01f) return Move.Hit;
                return speed > 2.2f ? Move.Run : speed > 0.3f ? Move.Walk : Move.Idle;
            }
            return speed > 0.3f ? Move.Walk : Move.Idle;
        }

        void Play(Move m)
        {
            if (m == cur && !IsOneShot(m)) return;
            if (m == cur && curT < Length(m) * 0.9f) return; // let a strike finish
            cur = m; curT = 0f;
            int i = (int)m;
            if (slots[i].IsValid()) { slots[i].SetTime(0); slots[i].SetSpeed(1); }
        }

        float Length(Move m)
        {
            var s = slots[(int)m];
            return s.IsValid() ? s.GetAnimationClip().length : 0.5f;
        }

        void LateUpdate()
        {
            if (!graph.IsValid()) return;
            float dt = Time.deltaTime;
            if (src == null)
            {
                // the actor is gone: play out the death, then sink into the ground
                if (dyingT < 0f) { dyingT = 0f; cur = Move.Idle; Play(Move.Death); }
                dyingT += dt; curT += dt;
                if (dyingT > Length(Move.Death) + 1.2f) sink += dt;
                if (sink > 0f) transform.position += Vector3.down * dt * 0.5f;
                Blend(dt);
                if (sink > 2f) Destroy(gameObject);
                return;
            }

            var pos = World3D.To3D(src.position);
            Vector2 vel = hasLast && dt > 0f ? new Vector2(pos.x - lastPos.x, pos.z - lastPos.z) / dt : Vector2.zero;
            if (vel.magnitude > 30f) vel = Vector2.zero; // a teleport, not a step
            smoothVel = Vector2.Lerp(smoothVel, vel, 1f - Mathf.Exp(-dt * 12f));
            lastPos = pos; hasLast = true;
            float speed = smoothVel.magnitude;

            var m = Choose(out var face, speed);
            if (IsOneShot(cur) && cur != Move.Death && curT < Length(cur) * 0.85f && m != Move.Death && m != Move.Roll) m = cur; // finish strikes
            if (cur == Move.Death && m != Move.Death) cur = Move.Idle; // revived (player respawn)
            Play(m);
            curT += dt;
            if (IsOneShot(cur) && cur != Move.Death && curT >= Length(cur)) { cur = Move.Idle; curT = 0f; }

            var p = src.GetComponent<PlayerController>();
            var en = src.GetComponent<EnemyBase>();
            hurtWas = p != null ? p.hurtFlash : en != null ? en.flash : 0f;

            // face where it moves while moving, where it looks or strikes otherwise
            Vector2 dir = (cur is Move.Walk or Move.Run) && speed > 0.3f ? smoothVel : face;
            if (dir.sqrMagnitude > 0.0001f)
                yaw = Mathf.MoveTowardsAngle(yaw, Mathf.Atan2(dir.x, dir.y) * Mathf.Rad2Deg, 720f * dt);
            transform.SetPositionAndRotation(pos, Quaternion.Euler(0f, yaw, 0f));

            // playback speed follows the ground speed so the feet keep pace
            int ci = (int)cur;
            if (slots[ci].IsValid() && cur is Move.Walk or Move.Run)
            {
                float k = transform.localScale.y; // a bigger body takes longer strides
                float clipSpeed = (cur == Move.Walk ? WalkSpeed : RunSpeed) * k;
                slots[ci].SetSpeed(Mathf.Clamp(speed / clipSpeed, 0.5f, 1.8f));
            }
            Blend(dt);
        }

        void Blend(float dt)
        {
            for (int i = 0; i < slots.Length; i++)
            {
                float target = i == (int)cur ? 1f : 0f;
                weight[i] = Mathf.MoveTowards(weight[i], target, dt * 9f);
                if (slots[i].IsValid()) mixer.SetInputWeight(i, weight[i]);
            }
            var s = slots[(int)Move.Death];
            if (cur == Move.Death && s.IsValid() && s.GetTime() >= s.GetAnimationClip().length - 0.02f) s.SetSpeed(0); // hold the last frame
        }
    }
}

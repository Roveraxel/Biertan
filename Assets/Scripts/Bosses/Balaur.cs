using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Biertan.Core;
using Biertan.Levels;

namespace Biertan.Bosses
{
    /// <summary>
    /// The Balaur: a three-headed serpent coiled in the flooded quarry, crowned with the enchanted stag's gems.
    /// It dies when all three necks are cut and seared. Port of balaur.gd. Unity coordinates throughout.
    /// </summary>
    public class Balaur : MonoBehaviour, IBoss
    {
        public event System.Action<Balaur> Died;

        public readonly List<BalaurHead> heads = new();
        public bool intro = true, dead;
        public float t, batT = 9f;
        public DrownedQuarry arena;
        public float maxHp = 510f, hp = 510f;
        public string gazeState = "";
        public float gazeT = 9f, gt, gazeA, gazeDir = 1f, gazeTick;
        public string devourState = "";
        public float devourT = 14f, dtv, laneX = 800f, lunge;
        public static readonly Vector2 Gem = new(0, 70);

        public float Hp => hp;
        public float MaxHp => maxHp;
        public Vector2 Pos => transform.position;
        public Vector2 GemPos => Pos + Gem;
        public bool Gazing => gazeState != "";

        public string HudName() => "THE BALAUR";
        public string HudHint()
        {
            if (gazeState != "") return "The stag's gaze! Hide behind a pillar!";
            if (devourState == "tel") return "It will devour the marked lane! Get out of it!";
            foreach (var h in heads) if (h != null && h.hstate == "stump") return "Sear the stump (E) before the head grows back!";
            return "Cut down a head, then sear its stump.";
        }

        public float Rage()
        {
            int s = 0;
            foreach (var h in heads) if (h != null && h.seared) s++;
            return 1f + 0.3f * s;
        }

        public void BuildHeads()
        {
            Vector2[] offs = { new(-130, -30), new(0, -50), new(130, -30) };
            Vector2[] rests = { new(-240, -250), new(0, -290), new(240, -250) };
            string[] els = { "frost", "fire", "thirst" };
            for (int i = 0; i < 3; i++)
            {
                var go = new GameObject("Head " + els[i]);
                go.transform.SetParent(transform.parent, false);
                go.transform.position = Pos + rests[i];
                var rb = go.AddComponent<Rigidbody2D>();
                rb.bodyType = RigidbodyType2D.Kinematic;
                go.AddComponent<SortingGroup>();
                var h = go.AddComponent<BalaurHead>();
                h.body = this;
                h.anchor = Pos + offs[i];
                h.rest = Pos + rests[i];
                h.element = els[i];
                h.Setup("balaur_head");
                go.AddComponent<HeadStump>().head = h;
                go.AddComponent<BalaurHeadView>().head = h;
                heads.Add(h);
            }
        }

        void FireRing()
        {
            var w = WaterWave.Spawn(transform.parent, Pos + new Vector2(0, -60));
            w.fire = true; w.dmg = 18f; w.speed = 360f;
            AudioManager.I?.Sfx("fire", 0f, 0.6f);
        }

        public void HeadSealed(BalaurHead _)
        {
            FireRing();
            foreach (var h in heads)
                if (!h.seared)
                {
                    AudioManager.I?.Sfx("hiss", 0f, 0.7f);
                    arena?.OnHeadSealed();
                    return;
                }
            dead = true;
            hp = 0f;
            AudioManager.I?.Sfx("boss_roar", 0f, 0.7f);
            FxUtil.Ring(Pos, new Color(0.6f, 1f, 0.5f, 0.9f), 260f, 1f);
            foreach (var h in heads) if (h != null) Destroy(h.gameObject);
            heads.Clear();
            Died?.Invoke(this);
            Destroy(gameObject, GameManager.Instant ? 0f : 2f);
        }

        void FixedUpdate()
        {
            if (dead) return;
            float dt = Time.fixedDeltaTime;
            t += dt;
            if (intro && t > 3f) intro = false;
            hp = 0f;
            foreach (var h in heads) if (h != null && !h.seared) hp += h.hp;
            var pl = GameManager.I?.player;
            if (pl == null || intro) return;
            GazeStep(dt, pl);
            DevourStep(dt, pl);
            if (Rage() > 1f)
            {
                batT -= dt;
                if (batT <= 0f && arena != null) { batT = 10f; arena.CallBats(); }
            }
        }

        /// <summary>The body surges out of the lake to devour whatever stands in its lane.</summary>
        void DevourStep(float dt, Biertan.Player.PlayerController pl)
        {
            Vector2 pp = pl.transform.position;
            switch (devourState)
            {
                case "":
                    if (gazeState != "") return;
                    devourT -= dt * Rage();
                    if (devourT <= 0f)
                    {
                        devourState = "tel"; dtv = 0f;
                        laneX = Mathf.Clamp(pp.x, 250f, 1350f);
                        AudioManager.I?.Sfx("hiss", 4f, 0.5f);
                        HudEvents.Toast("The Balaur rears back to devour!");
                    }
                    break;
                case "tel":
                    dtv += dt;
                    if (dtv > 1.1f) { devourState = "surge"; dtv = 0f; AudioManager.I?.Sfx("boss_roar", 0f, 0.8f); }
                    break;
                case "surge":
                {
                    dtv += dt;
                    lunge = Mathf.Min(1f, dtv / 0.25f);
                    float reach = Pos.y - 80f - 620f * lunge;
                    if (Mathf.Abs(pp.x - laneX) < 85f && pp.y > reach && pl.invT <= 0f && dtv < 0.35f)
                    {
                        pl.Hurt(42f, Vector2.down);
                        HudEvents.Toast("Devoured! It spits you out, scorched.");
                    }
                    if (dtv > 0.8f) { devourState = "back"; dtv = 0f; }
                    break;
                }
                case "back":
                    dtv += dt;
                    lunge = Mathf.Max(0f, 1f - dtv / 0.6f);
                    if (dtv > 0.6f) { devourState = ""; devourT = 14f; lunge = 0f; }
                    break;
            }
        }

        /// <summary>The jewelled crown of the enchanted stag: its gaze kills. Hide behind stone.</summary>
        void GazeStep(float dt, Biertan.Player.PlayerController pl)
        {
            Vector2 pp = pl.transform.position;
            switch (gazeState)
            {
                case "":
                    gazeT -= dt * Rage();
                    if (gazeT <= 0f)
                    {
                        gazeState = "charge"; gt = 0f;
                        AudioManager.I?.Sfx("hiss", 2f, 0.4f);
                        HudEvents.Toast("Gems blaze on the Balaur's crown...");
                    }
                    break;
                case "charge":
                    gt += dt;
                    gazeA = Mathf.Atan2(pp.y - GemPos.y, pp.x - GemPos.x);
                    if (gt > 1.3f)
                    {
                        gazeState = "beam"; gt = 0f;
                        gazeDir = Random.value < 0.5f ? 1f : -1f;
                        gazeA -= gazeDir * 0.35f;
                        AudioManager.I?.Sfx("fire", 0f, 0.5f);
                    }
                    break;
                case "beam":
                    gt += dt;
                    gazeA += gazeDir * 0.5f * dt;
                    gazeTick -= dt;
                    if (gazeTick <= 0f && BeamHits(pp + new Vector2(0, 14)))
                    {
                        gazeTick = 0.2f;
                        pl.Hurt(9f, new Vector2(Mathf.Cos(gazeA), Mathf.Sin(gazeA)));
                    }
                    if (gt > 1.6f) { gazeState = ""; gazeT = 11f; }
                    break;
            }
        }

        public bool BeamHits(Vector2 p)
        {
            var dir = new Vector2(Mathf.Cos(gazeA), Mathf.Sin(gazeA));
            var to = p - GemPos;
            if (Vector2.Dot(to, dir) < 0f) return false;
            if (Mathf.Abs(to.x * dir.y - to.y * dir.x) > 34f) return false;
            if (arena != null)
                foreach (var r in arena.pillars) // Godot rects
                    for (int i = 0; i < 24; i++)
                    {
                        var q = Vector2.Lerp(GemPos, p, i / 24f);
                        if (r.Contains(new Vector2(q.x, -q.y))) return false;
                    }
            return true;
        }
    }
}

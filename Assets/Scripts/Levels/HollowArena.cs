using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Biertan.Bosses;
using Biertan.Core;
using Biertan.Enemies;

namespace Biertan.Levels
{
    /// <summary>Muma Pădurii's Hollow: a ring of old oaks around her hollow tree-house.
    /// Port of hollow_level.gd.</summary>
    public class HollowArena : LevelBase
    {
        static readonly Vector2 CenterG = new(750, 680);
        const float Radius = 520f;
        static readonly Vector2[] SpotsG = { new(450, 440), new(1050, 440), new(450, 920), new(1050, 920), new(750, 380) };

        public Muma boss;
        readonly List<Muma> sisters = new();
        Vector2 Center => P(CenterG);

        public override void Build()
        {
            title = "THE HOLLOW";
            subtitle = "Muma Pădurii";
            size = new Vector2(1500, 1400);
            spawn = P(750, 1130);
            ground = new Color32(0x14, 0x1a, 0x12, 0xff);
            rng = new System.Random(404);

            DrawGround();
            Scatter(new Rect(0, 0, 1500, 1400), 700, new Color[] { new Color32(0x26, 0x32, 0x1e, 0xff), new Color32(0x10, 0x16, 0x10, 0xff), new Color32(0x3a, 0x4a, 0x26, 0xff) });
            AddSprite("Clearing", "circle", Center, Vector2.one * Radius * 2f, new Color32(0x1e, 0x26, 0x18, 0xff), -998);
            AddSprite("ClearingInner", "circle", Center, Vector2.one * (Radius - 40f) * 2f, new Color32(0x24, 0x30, 0x20, 0xff), -997);
            for (int i = 0; i < 30; i++) // bones and red caps in the moss
            {
                float a = i * 2.1f;
                float r = 90f + (i * 37) % 380;
                AddSprite("Speck", "circle", Center + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * r, new Vector2(6, 6),
                    i % 4 == 0 ? (Color)new Color32(0xb3, 0x37, 0x2f, 0xff) : new Color32(0xd8, 0xd2, 0xc0, 0xff), -996);
            }
            AddRingWall(Center, Radius);
            for (int i = 0; i < 40; i++)
            {
                float a = Mathf.PI * 2f * i / 40f;
                AddTree(Center + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * (Radius + 50f + Rand(0, 50)), i % 3 == 0);
            }
            foreach (var s in SpotsG) AddHollowTree(P(s) + new Vector2(0, 40));
            foreach (var a in new[] { 0.25f, 0.75f, 1.25f, 1.75f })
            {
                var go = new GameObject("SaltCrystal");
                go.transform.SetParent(transform, false);
                go.transform.position = Center + new Vector2(Mathf.Cos(Mathf.PI * a), Mathf.Sin(Mathf.PI * a)) * (Radius - 70f);
                go.AddComponent<SaltCrystal>();
            }

            boss = MakeBoss(Center + new Vector2(0, 200), false);
            boss.PhaseChanged += OnPhase;
            boss.Died += _ => OnDead();
            GameManager.I.boss = boss;
            AudioManager.I?.SetMusic("music_muma", -6f);
        }

        public override void OnEnter()
        {
            GameManager.I.player.madness = 0f;
        }

        Muma MakeBoss(Vector2 pos, bool illusion)
        {
            var go = new GameObject(illusion ? "Sister" : "Muma") { layer = LayerMask.NameToLayer("Enemy") };
            go.transform.SetParent(transform, false);
            go.transform.position = pos;
            var rb = go.AddComponent<Rigidbody2D>();
            rb.gravityScale = 0; rb.freezeRotation = true;
            rb.interpolation = RigidbodyInterpolation2D.Interpolate;
            go.AddComponent<CircleCollider2D>();
            go.AddComponent<SortingGroup>();
            var m = go.AddComponent<Muma>();
            m.Setup("muma");
            m.illusion = illusion;
            m.arena = this;

            AddSprite("Shadow", "circle", pos + new Vector2(0, -4), new Vector2(100, 45), new Color(0, 0, 0, 0.4f), -1, go.transform);
            var view = go.AddComponent<MumaView>();
            view.boss = m;
            view.body = AddSprite("Body", "muma_idle", pos, Vector2.one, Color.white, 0, go.transform);
            var lgo = new GameObject("SweepArc");
            lgo.transform.SetParent(go.transform, false);
            var lr = lgo.AddComponent<LineRenderer>();
            lr.useWorldSpace = false; lr.widthMultiplier = 10f; lr.sharedMaterial = Resources.Load<Material>("LineMat");
            lr.sortingOrder = 5; lr.enabled = false;
            view.sweepArc = lr;
            view.stars = new SpriteRenderer[5];
            for (int i = 0; i < 5; i++)
            {
                view.stars[i] = AddSprite("Star", "circle", pos, new Vector2(6, 6), Color.white, 6, go.transform);
                view.stars[i].enabled = false;
            }
            return m;
        }

        void AddHollowTree(Vector2 pos)
        {
            var root = new GameObject("HollowTree");
            root.transform.SetParent(transform, false);
            root.transform.position = pos;
            root.AddComponent<SortingGroup>();
            AddSprite("Shadow", "circle", pos + new Vector2(0, -2), new Vector2(110, 38), new Color(0, 0, 0, 0.4f), -1, root.transform);
            AddSprite("Trunk", "circle", pos + new Vector2(0, 46), new Vector2(64, 104), new Color32(0x3a, 0x2c, 0x1e, 0xff), 0, root.transform);
            AddSprite("Hollow", "circle", pos + new Vector2(0, 30), new Vector2(24, 40), new Color32(0x0c, 0x08, 0x06, 0xff), 1, root.transform);
            AddSprite("Crown", "circle", pos + new Vector2(0, 112), new Vector2(120, 70), new Color32(0x1c, 0x28, 0x16, 0xff), 2, root.transform);
        }

        public override Color Ambient() => new(0.32f, 0.36f, 0.34f);

        public Vector2 HopSpot(Vector2 from)
        {
            var opts = new List<Vector2>();
            foreach (var s in SpotsG)
                if (Vector2.Distance(P(s), from) > 200f) opts.Add(P(s));
            return opts[Random.Range(0, opts.Count)];
        }

        /// <summary>The Forest Mother splits into three sisters; only one is real.</summary>
        public void Split(Muma real)
        {
            DispelIllusions();
            var free = new List<Vector2>();
            foreach (var s in SpotsG) free.Add(P(s));
            for (int i = 0; i < free.Count; i++) { int j = Random.Range(i, free.Count); (free[i], free[j]) = (free[j], free[i]); }
            for (int i = 0; i < 2; i++)
            {
                var m = MakeBoss(free[i], true);
                m.phase = real.phase;
                m.hp = real.hp; m.maxHp = real.maxHp;
                m.bstate = "walk";
                sisters.Add(m);
            }
            AudioManager.I?.Sfx("cackle", 0f, 0.9f);
            HudEvents.Toast("Three sisters stand in the Hollow. Only one is real.");
        }

        public void ShuffleSisters(Muma real)
        {
            sisters.RemoveAll(s => s == null);
            if (real.phase >= 2 && sisters.Count == 0) { Split(real); return; }
            foreach (var s in sisters)
            {
                var to = HopSpot(real.transform.position);
                s.transform.position = to;
                s.GetComponent<Rigidbody2D>().position = to;
                s.alpha = 0f;
            }
        }

        public void DispelIllusions()
        {
            foreach (var s in sisters) if (s != null) Destroy(s.gameObject);
            sisters.Clear();
        }

        public void Weave(Muma b)
        {
            AudioManager.I?.Sfx("whisper", -6f, 1.2f);
            Vector2 p = GameManager.I.player.transform.position;
            int n = 2 + b.phase;
            for (int i = 0; i < n; i++)
            {
                float ang = Random.value * Mathf.PI;
                var dir = new Vector2(Mathf.Cos(ang), Mathf.Sin(ang));
                var off = i > 0 ? Vector2.Perpendicular(dir) * Random.Range(-120f, 120f) : Vector2.zero;
                var go = new GameObject("WeaveThread");
                go.transform.SetParent(transform, false);
                go.AddComponent<LineRenderer>();
                var th = go.AddComponent<WeaveThread>();
                th.a = p + off - dir * 600f;
                th.b = p + off + dir * 600f;
            }
        }

        public void CallCrows(Muma b)
        {
            if (EnemyBase.All.Count > 7) return;
            HudEvents.Toast("Crows pour out of her hollow!");
            for (int i = 0; i < 3; i++)
            {
                float a = i * Mathf.PI * 2f / 3f;
                var e = SpawnEnemy("bat", (Vector2)b.transform.position + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 60f);
                if (e != null) e.state = "chase";
            }
        }

        public void CallWisps(Muma b)
        {
            if (EnemyBase.All.Count > 5) return;
            HudEvents.Toast("She calls the wisps of the taken!");
            for (int i = 0; i < 2; i++)
            {
                float a = Random.value * Mathf.PI * 2f;
                SpawnEnemy("shade", (Vector2)b.transform.position + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 120f);
            }
        }

        public void CastRoots(Muma b) => StartCoroutine(CastRootsCo(b));

        IEnumerator CastRootsCo(Muma b)
        {
            AudioManager.I?.Sfx("cackle", -6f, Random.Range(0.95f, 1.2f));
            int n = 3 + b.phase;
            var pl = GameManager.I.player;
            var prb = pl.GetComponent<Rigidbody2D>();
            for (int i = 0; i < n; i++)
            {
                if (pl == null) yield break;
                Vector2 target = pl.transform.position;
                if (i > 0) target += prb.linearVelocity * 0.3f;
                Root(target, 12f + 2f * b.phase, 0.85f);
                yield return new WaitForSeconds(0.38f);
                if (b == null) yield break;
            }
            if (b.phase >= 3)
                for (int i = 0; i < 6; i++)
                {
                    float a = i * Mathf.PI * 2f / 6f;
                    Root((Vector2)b.transform.position + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 150f, 14f, 1f);
                }
        }

        void Root(Vector2 at, float dmg, float delay)
        {
            var go = new GameObject("RootSpike");
            go.transform.SetParent(transform, false);
            go.transform.position = at;
            var r = go.AddComponent<RootSpike>();
            r.dmg = dmg; r.delay = delay;
        }

        /// <summary>Magda turns up once, unimpressed as ever, and throws the hunter a bandage.</summary>
        public void MagdaBandage()
        {
            var pl = GameManager.I.player;
            var go = new GameObject("Magda");
            go.transform.SetParent(transform, false);
            go.transform.position = (Vector2)pl.transform.position + new Vector2(-420, -120);
            var c = go.AddComponent<Cameo>();
            c.vel = new Vector2(420, 120) / 0.9f;
            c.stopAt = 0.75f;
            c.resumeAfter = 1.8f;
            c.life = 4.4f;
            c.line = "Your feet look swollen, take this.";
            c.action = () =>
            {
                c.vel = new Vector2(-520, -140);
                pl.hasteT = 30f;
                AudioManager.I?.Sfx("blip", 0f, 1.4f);
                FxUtil.Ring(pl.transform.position, new Color(1, 1, 1, 0.8f), 50f);
                HudEvents.Toast("Magda's bandage: you move 25% faster for 30 seconds.");
            };
        }

        void OnPhase(int p)
        {
            if (p == 2)
            {
                HudEvents.Banner("THE THREE SISTERS", "Her bark turns steel and she splits in three. Salt finds the real one (R).");
                Split(boss);
                MagdaBandage();
            }
            else if (p == 3)
            {
                HudEvents.Banner("THE WOOD AWAKENS", "Roots everywhere. Keep moving.");
            }
        }

        void OnDead()
        {
            var gm = GameManager.I;
            gm.boss = null;
            gm.StartCoroutine(gm.OnMumaDead());
        }
    }
}

using UnityEngine;
using UnityEngine.Rendering;
using Biertan.Bosses;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>The Hollow Hills: open meadow and standing stones, where the Iele dance in mushroom rings at
    /// dusk, with the Bear's Garden hidden in the south-east. Ends at the mouth of the Salt Caves.
    /// Port of hills_level.gd.</summary>
    public class HollowHills : LevelBase
    {
        static readonly Vector2[] PathPts =
        {
            new(60, 850), new(500, 760), new(950, 900), new(1450, 780),
            new(1900, 880), new(2400, 760), new(2800, 820), new(3060, 800),
        };
        static readonly (Vector2 c, int n)[] Rings = { (new(900, 480), 3), (new(1700, 1180), 3), (new(2350, 420), 4) };
        public static readonly Vector2 Garden = new(2700, 1420);

        public Bear bear;
        float lurkT = 6f;

        public override void Build()
        {
            var gm = GameManager.I;
            title = "THE HOLLOW HILLS";
            subtitle = "If you hear singing, do not dance.";
            size = new Vector2(3200, 1700);
            spawn = P(120, 850);
            ground = new Color32(0x2a, 0x33, 0x22, 0xff);
            tileTint = new Color(0.95f, 0.95f, 0.85f);
            rng = new System.Random(202);

            DrawGround();
            // rolling hill shading
            for (int i = 0; i < 9; i++)
            {
                var c = new Vector2(200 + i * 360, 300 + (i % 3) * 450);
                AddSprite("Hill", "circle", P(c), Vector2.one * 520f, new Color(0, 0, 0, 0.07f), -998);
            }
            AddPath(PathPts, 120f, new Color32(0x3a, 0x30, 0x20, 0xff), -990);
            AddPath(PathPts, 80f, new Color32(0x4e, 0x42, 0x30, 0xff), -989);
            // the garden: an oval of dark earth with rows of wild lettuce
            AddSprite("Garden", "circle", P(Garden), new Vector2(580, 580 * 0.73f), new Color32(0x33, 0x40, 0x1f, 0xff), -988);
            for (int row = 0; row < 5; row++)
                for (int col = 0; col < 9; col++)
                {
                    var lp = Garden + new Vector2(-200 + col * 50, -110 + row * 50);
                    AddSprite("Lettuce", "circle", P(lp), Vector2.one * 18f, new Color32(0x6a, 0xa0, 0x40, 0xff), -987);
                    AddSprite("Heart", "circle", P(lp + new Vector2(-3, -3)), Vector2.one * 10f, new Color32(0x8a, 0xc8, 0x60, 0xff), -986);
                }
            // mushroom rings
            foreach (var r in Rings)
            {
                AddSprite("RingGrass", "circle", P(r.c), Vector2.one * 300f, new Color32(0x2f, 0x3a, 0x26, 0xff), -985);
                for (int i = 0; i < 28; i++)
                {
                    float a = i * Mathf.PI * 2f / 28f;
                    var mp = r.c + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 120f;
                    AddSprite("Stem", "white", P(mp + new Vector2(0, -3)), new Vector2(3, 6), new Color32(0xd8, 0xd2, 0xc0, 0xff), -984);
                    AddSprite("Cap", "circle", P(mp + new Vector2(0, -7)), Vector2.one * 10f, i % 3 != 0 ? new Color32(0xe8, 0xe0, 0xcc, 0xff) : new Color32(0xb3, 0x37, 0x2f, 0xff), -983);
                }
            }
            // the cave mouth
            AddSprite("CaveMouth", "white", P(3080, 810), new Vector2(240, 180), new Color32(0x0d, 0x0c, 0x0b, 0xff), -982);
            AddSprite("CaveDark", "white", P(3130, 810), new Vector2(140, 140), new Color32(0x05, 0x05, 0x05, 0xff), -981);
            Scatter(new Rect(0, 0, 3200, 1700), 1300, new Color[] { new Color32(0x3a, 0x4a, 0x2c, 0xff), new Color32(0x26, 0x30, 0x1e, 0xff), new Color32(0x4a, 0x5a, 0x34, 0xff), new Color32(0x5a, 0x5a, 0x3a, 0xff) });
            Scatter(new Rect(0, 0, 3200, 1700), 140, new Color[] { new Color32(0x9a, 0x8a, 0x6a, 0xff), new Color32(0x6a, 0x2a, 0x2a, 0xff) });

            // invisible borders
            AddBlock(new Rect(-200, -200, 3600, 200), "hidden", 0);
            AddBlock(new Rect(-200, 1700, 3600, 200), "hidden", 0);
            AddBlock(new Rect(-200, -200, 200, 2100), "hidden", 0);
            AddBlock(new Rect(3200, -200, 200, 2100), "hidden", 0);
            // copses on the slopes
            foreach (var c in new[] { new Vector2(400, 300), new Vector2(500, 1350), new Vector2(1300, 250), new Vector2(1250, 1400), new Vector2(2000, 300), new Vector2(2200, 1350), new Vector2(2800, 300) })
                for (int i = 0; i < 14; i++)
                {
                    var p = c + new Vector2(Rand(-220, 220), Rand(-170, 170));
                    if (DistToPath(p) > 170f && !InRing(p)) AddTree(P(p), Rand(0, 1) < 0.5f);
                }
            // Grădina Ursului: a thicket around the garden with one gap facing north-west
            for (int i = 0; i < 34; i++)
            {
                float ang = Mathf.PI * 2f * i / 34f;
                if (Mathf.Abs(Mathf.DeltaAngle(ang * Mathf.Rad2Deg, 225f)) < 0.22f * Mathf.Rad2Deg) continue;
                AddTree(P(Garden + new Vector2(Mathf.Cos(ang) * 300f, Mathf.Sin(ang) * 220f)), i % 2 == 0);
            }
            if (!gm.SideHas("bear"))
            {
                bear = MakeBear(P(Garden + new Vector2(40, 20)));
                AddTrigger(new Rect(Garden.x - 260, Garden.y - 190, 520, 380), EnterGarden);
            }
            AddProp("sign", "garden_sign", "", new Vector2(2440, 1180), "E   Read the warning");
            // standing stones
            foreach (var s in new[] { new Vector2(700, 1000), new Vector2(760, 1060), new Vector2(1550, 600), new Vector2(2650, 1050), new Vector2(2600, 990) })
                AddBlock(new Rect(s.x, s.y, 26, 18), "stone", 46);
            // cliffs and the cave mouth in the east
            AddBlock(new Rect(3060, 0, 140, 720), "rock", 70);
            AddBlock(new Rect(3060, 900, 140, 800), "rock", 70);
            AddBlock(new Rect(2960, 560, 100, 160), "rock", 60);
            AddBlock(new Rect(2960, 900, 100, 160), "rock", 60);
            AddTorch(new Vector2(3000, 740), 200f, new Color(1f, 0.6f, 0.3f), 0.8f);
            AddTorch(new Vector2(3000, 880), 200f, new Color(1f, 0.6f, 0.3f), 0.8f);
            // props
            AddProp("cross", "cross", "", new Vector2(1450, 700), "E   Pray at the wayside cross");
            AddProp("sack", "sack_h", "", new Vector2(2700, 1020), "E   Take the coin sack");
            AddProp("sign", "cave_sign", "", new Vector2(2900, 700), "E   Read the miners' post");
            // Iele in their rings, wolves on the road
            foreach (var r in Rings)
                for (int i = 0; i < r.n; i++)
                {
                    float a = i * Mathf.PI * 2f / r.n;
                    var e = SpawnEnemy("iele", P(r.c + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 70f));
                    if (e != null) { e.home = P(r.c); e.orbit = a; }
                }
            foreach (var c in new[] { new Vector2(1100, 860), new Vector2(2000, 860), new Vector2(2600, 800) })
                for (int i = 0; i < 3; i++)
                {
                    float a = Rand(0, Mathf.PI * 2f);
                    SpawnEnemy("wolf", P(c + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * Rand(20, 70)));
                }
            SpawnEnemy("pricolici", P(2450, 760));
            AddTrigger(new Rect(0, 730, 50, 240), () => Leave("richis", new Vector2(1540, 600)));
            AddTrigger(new Rect(3110, 720, 90, 180), () => Leave("caves", null));
        }

        Bear MakeBear(Vector2 pos)
        {
            var go = new GameObject("Bear") { layer = LayerMask.NameToLayer("Enemy") };
            go.transform.SetParent(transform, false);
            go.transform.position = pos;
            var rb = go.AddComponent<Rigidbody2D>();
            rb.gravityScale = 0; rb.freezeRotation = true;
            rb.interpolation = RigidbodyInterpolation2D.Interpolate;
            go.AddComponent<CircleCollider2D>();
            go.AddComponent<SortingGroup>();
            var b = go.AddComponent<Bear>();
            b.Setup("bear");
            b.Died += _ => OnBearDead();
            AddSprite("Shadow", "circle", pos + new Vector2(0, -4), new Vector2(108, 48), new Color(0, 0, 0, 0.45f), -1, go.transform);
            var view = go.AddComponent<BearView>();
            view.boss = b;
            view.body = AddSprite("Body", "bear_idle", pos, Vector2.one, Color.white, 0, go.transform);
            var mat = Resources.Load<Material>("LineMat");
            view.swipeArc = Line(go.transform, "SwipeArc", 10f, mat);
            view.chargeLane = Line(go.transform, "ChargeLane", 40f, mat);
            view.rearRing = Line(go.transform, "RearRing", 6f, mat);
            return b;
        }

        static LineRenderer Line(Transform parent, string name, float width, Material mat)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var lr = go.AddComponent<LineRenderer>();
            lr.useWorldSpace = false; lr.widthMultiplier = width; lr.sharedMaterial = mat;
            lr.sortingOrder = -2; lr.enabled = false;
            return lr;
        }

        void EnterGarden()
        {
            var gm = GameManager.I;
            if (bear == null || (object)gm.boss == bear) return;
            gm.boss = bear;
            HudEvents.Banner("GRĂDINA URSULUI", "The Bear's Garden. Nobody has taken its lettuce and lived.");
            AudioManager.I?.SetMusic("music_boss", -8f);
        }

        void OnBearDead()
        {
            var gm = GameManager.I;
            gm.boss = null;
            gm.StartCoroutine(gm.OnBearDead());
        }

        static void Leave(string to, Vector2? at)
        {
            var gm = GameManager.I;
            if (gm.state != GameManager.State.Play || gm.transitioning) return;
            LevelLoader.Goto(to, at);
        }

        float DistToPath(Vector2 p)
        {
            float best = float.MaxValue;
            for (int i = 0; i < PathPts.Length - 1; i++) best = Mathf.Min(best, DistToSegment(p, PathPts[i], PathPts[i + 1]));
            return best;
        }

        static bool InRing(Vector2 p)
        {
            foreach (var r in Rings) if (Vector2.Distance(p, r.c) < 190f) return true;
            return false;
        }

        void Update()
        {
            var gm = GameManager.I;
            if (gm == null || gm.state != GameManager.State.Play || gm.player == null) return;
            lurkT -= Time.deltaTime;
            if (lurkT > 0f) return;
            lurkT = Mathf.Lerp(12f, 5f, gm.dusk) + Random.value * 3f;
            if (Lurker.All.Count >= 2) return;
            float a = Random.value * Mathf.PI * 2f;
            Vector2 u = (Vector2)gm.player.transform.position + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * Random.Range(280f, 420f);
            Vector2 g = P(u);
            if (g.x < 80 || g.y < 80 || g.x > size.x - 80 || g.y > size.y - 80 || DistToPath(g) <= 140f) return;
            var go = new GameObject("Lurker");
            go.transform.SetParent(transform, false);
            go.transform.position = u;
            go.AddComponent<Lurker>();
        }
    }
}

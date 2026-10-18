using System.Collections.Generic;
using UnityEngine;
using Biertan.Core;
using Biertan.Enemies;

namespace Biertan.Levels
{
    /// <summary>The Burnt Vineyards: terraced slopes of dead vines, burned cottages and an abandoned churchyard
    /// where the strigoi lie. Bats come with the dark. Port of vineyard_level.gd.</summary>
    public class BurntVineyards : LevelBase
    {
        static readonly Vector2[] PathPts =
        {
            new(60, 900), new(500, 980), new(900, 820), new(1350, 900),
            new(1800, 760), new(2250, 860), new(2700, 760), new(3140, 780),
        };
        static readonly Rect Yard = new(1500, 1100, 560, 380);
        static readonly Vector2 SideA = new(1750, 790), SideB = new(2140, 1290);
        public readonly List<Vector2> graves = new();
        float batT = 10f;

        public override void Build()
        {
            title = "THE BURNT VINEYARDS";
            subtitle = "The dead of Moșna do not lie still.";
            size = new Vector2(3200, 1700);
            spawn = P(120, 900);
            ground = new Color32(0x2e, 0x2a, 0x20, 0xff);
            tileTint = new Color(0.75f, 0.7f, 0.55f);
            rng = new System.Random(606);

            DrawGround();
            AddPath(PathPts, 130f, new Color32(0x2a, 0x22, 0x18, 0xff), -990);
            AddPath(PathPts, 90f, new Color32(0x43, 0x38, 0x2a, 0xff), -989);
            AddPath(new[] { SideA, SideB }, 70f, new Color32(0x3a, 0x30, 0x24, 0xff), -991);
            AddSprite("Yard", "white", P(Yard.center), Yard.size, new Color32(0x26, 0x28, 0x1e, 0xff), -988);
            for (int i = 0; i < 20; i++) // scorch marks
                AddSprite("Scorch", "circle", P(400 + i * 150, 300 + (i * 97) % 1200), new Vector2(52, 52), new Color(0.05f, 0.04f, 0.03f, 0.35f), -987);
            Scatter(new Rect(0, 0, 3200, 1700), 1000, new Color[] { new Color32(0x3a, 0x34, 0x26, 0xff), new Color32(0x23, 0x1f, 0x17, 0xff), new Color32(0x4a, 0x3e, 0x2a, 0xff), new Color32(0x1a, 0x16, 0x12, 0xff) });

            AddBlock(new Rect(-200, -200, 3600, 200), "hidden", 0);
            AddBlock(new Rect(-200, 1700, 3600, 200), "hidden", 0);
            AddBlock(new Rect(-200, -200, 200, 2100), "hidden", 0);
            AddBlock(new Rect(3200, -200, 200, 2100), "hidden", 0);
            // vine terraces, broken where the road and the churchyard pass
            var yardGrown = new Rect(Yard.x - 80, Yard.y - 80, Yard.width + 160, Yard.height + 160);
            for (float y = 120f; y < 1660f; y += 95f)
                for (float x = 60f; x < 3140f;)
                {
                    var seg = new Rect(x, y, Rand(160, 300), 14);
                    if (DistToPath(seg.center) > 140f && !yardGrown.Contains(seg.center)) AddBlock(seg, "vine", 0);
                    x += seg.width + Rand(60, 120);
                }
            // burned cottages
            foreach (var r in new[] { new Rect(700, 560, 160, 110), new Rect(2400, 1050, 170, 110), new Rect(2600, 420, 150, 100) })
                AddBlock(r, "ruin", 22);
            // the churchyard, open to the east
            AddBlock(new Rect(Yard.x, Yard.y, Yard.width, 20), "stone", 14);
            AddBlock(new Rect(Yard.x, Yard.yMax - 20, Yard.width, 20), "stone", 14);
            AddBlock(new Rect(Yard.x, Yard.y, 20, Yard.height), "stone", 14);
            AddBlock(new Rect(Yard.xMax - 20, Yard.y, 20, 140), "stone", 14);
            AddBlock(new Rect(Yard.xMax - 20, Yard.y + 240, 20, 140), "stone", 14);
            AddBlock(new Rect(1560, 1140, 120, 90), "ruin", 40);
            foreach (float gy in new[] { 1260f, 1340f, 1420f })
                foreach (float gx in new[] { 1720f, 1820f, 1920f })
                {
                    var g = new Vector2(gx, gy);
                    graves.Add(g);
                    AddSprite("Grave", "white", P(g.x, g.y + 2), new Vector2(32, 16), new Color32(0x1a, 0x14, 0x10, 0xff), -986);
                    AddSprite("Cross", "white", P(g.x, g.y - 20), new Vector2(6, 28), new Color32(0x5d, 0x58, 0x4f, 0xff), -985);
                    AddSprite("Cross", "white", P(g.x, g.y - 25.5f), new Vector2(22, 5), new Color32(0x5d, 0x58, 0x4f, 0xff), -985);
                }
            for (int i = 0; i < graves.Count; i += 2)
            {
                var e = SpawnEnemy("strigoi", P(graves[i] + new Vector2(0, 10)));
                if (e != null) { e.state = "dormant"; e.aggro = 230f; }
            }
            // strigoi and wolves on the road
            foreach (var p in new[] { new Vector2(1100, 860), new Vector2(2000, 820), new Vector2(2650, 780) }) SpawnEnemy("strigoi", P(p));
            foreach (var c in new[] { new Vector2(700, 950), new Vector2(2300, 870) })
                for (int i = 0; i < 3; i++)
                {
                    float a = Rand(0, Mathf.PI * 2f);
                    SpawnEnemy("wolf", P(c + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * Rand(20, 60)));
                }
            for (int i = 0; i < 5; i++) SpawnEnemy("bat", P(1400 + i * 40, 500 + (i % 2) * 40));

            AddProp("cross", "cross", "", new Vector2(1350, 830), "E   Pray at the wayside cross");
            AddProp("bones", "bones_v", "", new Vector2(1800, 1220), "E   Search the open grave");
            AddProp("sign", "yard_sign", "", new Vector2(2080, 1290), "E   Read the gate inscription");
            AddProp("sign", "quarry_sign", "", new Vector2(3020, 700), "E   Read the waymark");
            AddTorch(new Vector2(1790, 1190), 260f, new Color(0.7f, 0.8f, 1f), 0.35f);
            AddTrigger(new Rect(0, 780, 50, 240), () => { if (Ready()) LevelLoader.Goto("mosna", new Vector2(1640, 620)); });
            AddTrigger(new Rect(3150, 680, 50, 200), EnterGorge);
        }

        static bool Ready() { var gm = GameManager.I; return gm.state == GameManager.State.Play && !gm.transitioning; }

        static void EnterGorge()
        {
            if (!Ready()) return;
            var gm = GameManager.I;
            if (gm.quest3 >= 2)
            {
                HudEvents.Toast("The quarry is quiet now. The road to Biertan is open.");
                gm.player.GetComponent<Rigidbody2D>().linearVelocity = new Vector2(-300, 0);
            }
            else LevelLoader.Goto("gorge");
        }

        float DistToPath(Vector2 p)
        {
            float best = float.MaxValue;
            for (int i = 0; i < PathPts.Length - 1; i++) best = Mathf.Min(best, DistToSegment(p, PathPts[i], PathPts[i + 1]));
            return Mathf.Min(best, DistToSegment(p, SideA, SideB));
        }

        /// <summary>Past deep dusk, swarms of bats come out of the dark around the hunter.</summary>
        void Update()
        {
            var gm = GameManager.I;
            if (gm == null || gm.player == null || gm.state != GameManager.State.Play || gm.dusk < 0.6f) return;
            batT -= Time.deltaTime;
            if (batT > 0f) return;
            batT = Mathf.Lerp(14f, 7f, gm.dusk);
            if (EnemyBase.All.Count >= 14) return;
            float a = Random.value * Mathf.PI * 2f;
            Vector2 p = (Vector2)gm.player.transform.position + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 520f;
            p = new Vector2(Mathf.Clamp(p.x, 60f, size.x - 60f), Mathf.Clamp(p.y, -size.y + 60f, -60f));
            for (int i = 0; i < 3; i++)
            {
                var e = SpawnEnemy("bat", p + new Vector2(i * 20, 0));
                if (e != null) e.state = "chase";
            }
            HudEvents.Toast("A swarm of bats comes out of the dusk.");
            AudioManager.I?.Sfx("bat", -6f);
        }
    }
}

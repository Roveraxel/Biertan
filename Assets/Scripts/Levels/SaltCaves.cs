using UnityEngine;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>The Salt Caves: old workings under the hills. Very dark; glowing salt crystals give light and
    /// refill the salt pouch. Moroi rise from the floor. Port of caves_level.gd.</summary>
    public class SaltCaves : LevelBase
    {
        static readonly Vector2[] PathPts =
        {
            new(60, 700), new(450, 640), new(800, 820), new(1200, 700),
            new(1550, 520), new(1950, 620), new(2300, 860), new(2650, 720), new(2940, 700),
        };
        static readonly (Vector2 c, float r)[] Chambers =
        {
            (new(820, 860), 230f), (new(1550, 460), 260f), (new(2320, 900), 240f), (new(1250, 1120), 170f),
        };

        public override void Build()
        {
            title = "THE SALT CAVES";
            subtitle = "Lord have mercy on the men below.";
            size = new Vector2(3000, 1400);
            spawn = P(110, 700);
            ground = new Color32(0x26, 0x23, 0x1f, 0xff);
            tile = "";
            rng = new System.Random(303);

            DrawGround();
            AddPath(PathPts, 200f, new Color32(0x3a, 0x36, 0x30, 0xff), -990);
            foreach (var c in Chambers) AddSprite("Chamber", "circle", P(c.c), Vector2.one * (c.r + 30f) * 2f, new Color32(0x33, 0x2f, 0x2a, 0xff), -989);
            // the salt lake
            AddSprite("LakeRim", "circle", P(1550, 380), Vector2.one * 230f, new Color(0.9f, 0.92f, 0.95f, 0.5f), -988);
            AddSprite("Lake", "circle", P(1550, 380), Vector2.one * 240f * 0.92f, new Color32(0x1a, 0x2a, 0x34, 0xff), -987);
            AddSprite("LakeDeep", "circle", P(1550, 380), Vector2.one * 200f, new Color32(0x22, 0x39, 0x4a, 0xff), -986);
            // old rails along the tunnel
            for (int i = 0; i < PathPts.Length - 1; i++)
            {
                Vector2 a = P(PathPts[i]), b = P(PathPts[i + 1]);
                Vector2 n = Vector2.Perpendicular((b - a).normalized) * 12f;
                foreach (var off in new[] { n, -n })
                {
                    var rail = AddSprite("Rail", "white", (a + b) / 2f + off, new Vector2(Vector2.Distance(a, b), 2f), new Color32(0x3e, 0x3a, 0x34, 0xff), -985);
                    rail.transform.rotation = Quaternion.Euler(0, 0, Mathf.Atan2(b.y - a.y, b.x - a.x) * Mathf.Rad2Deg);
                }
            }
            Scatter(new Rect(0, 0, 3000, 1400), 900, new Color[] { new Color32(0x35, 0x31, 0x2b, 0xff), new Color32(0x1c, 0x1a, 0x17, 0xff), new Color32(0x4a, 0x46, 0x40, 0xff), new Color32(0x9a, 0x9a, 0x9e, 0xff) });

            AddBlock(new Rect(-200, -200, 3400, 200), "hidden", 0);
            AddBlock(new Rect(-200, 1400, 3400, 200), "hidden", 0);
            AddBlock(new Rect(-200, -200, 200, 1800), "hidden", 0);
            AddBlock(new Rect(3000, -200, 200, 1800), "hidden", 0);
            // solid rock wherever the tunnels and chambers are not
            for (float y = 0f; y < size.y + 60f; y += 90f)
                for (float x = 0f; x < size.x; x += 100f)
                {
                    var p = new Vector2(x + 50f, y + 45f);
                    if (DistToPath(p) > 130f && !InChamber(p, 40f)) AddBlock(new Rect(x, y, 100, 90), "rock", Rand(50, 80));
                }

            // salt crystals: light and salt
            foreach (var c in new[] { new Vector2(520, 600), new Vector2(900, 980), new Vector2(1440, 360), new Vector2(1700, 560), new Vector2(2200, 980), new Vector2(2450, 820), new Vector2(1250, 1180), new Vector2(2800, 660) })
            {
                var go = new GameObject("SaltCrystal");
                go.transform.SetParent(transform, false);
                go.transform.position = P(c);
                go.AddComponent<SaltCrystal>();
            }
            AddProp("bones", "bones1", "", new Vector2(1330, 1150), "E   Search the dead miner");
            AddProp("sign", "lake_sign", "", new Vector2(1430, 610), "E   Read the scratched words");
            // the dead
            foreach (var p in new[] { new Vector2(760, 820), new Vector2(900, 900), new Vector2(1600, 420), new Vector2(1500, 520), new Vector2(1660, 480), new Vector2(2260, 860), new Vector2(2400, 940), new Vector2(1200, 1100) })
                SpawnEnemy("moroi", P(p));
            foreach (var p in new[] { new Vector2(1950, 620), new Vector2(2650, 720) }) SpawnEnemy("shade", P(p));
            AddTorch(new Vector2(140, 700), 220f, new Color(1f, 0.6f, 0.3f), 0.7f);
            AddTorch(new Vector2(2880, 700), 260f, new Color(0.7f, 1f, 0.6f), 0.6f);
            AddTrigger(new Rect(0, 600, 50, 200), () => Leave("hills", new Vector2(2880, 810)));
            AddTrigger(new Rect(2950, 600, 50, 200), () => Leave("hollow", null));
        }

        public override Color Ambient() => new(0.12f, 0.12f, 0.16f);

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
            // side passage to the grave chamber
            return Mathf.Min(best, DistToSegment(p, new Vector2(1050, 760), new Vector2(1250, 1120)) + 30f);
        }

        static bool InChamber(Vector2 p, float pad)
        {
            foreach (var c in Chambers) if (Vector2.Distance(p, c.c) < c.r + pad) return true;
            return false;
        }
    }
}

using System.Collections.Generic;
using UnityEngine;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>
    /// Sighișoara, the citadel on the hill where the hunter's road begins. Laid out from the real town
    /// (OpenStreetMap, halved for play; see SighisoaraMap): the wall ring and its nine guild towers, the Clock
    /// Tower gate over the lower town, the Tailors' Tower gate, the street grid, the covered Scholars' Stairs up
    /// to the Church on the Hill. The spiriduși's lair is under the Butchers' Tower (Turnul Măcelarilor).
    /// </summary>
    public class Sighisoara : LevelBase
    {
        static readonly Color CobbleCol = new Color32(0x4a, 0x46, 0x40, 0xff);
        const float Gap = 110f;     // gate passage width (Godot units)

        public override void Build()
        {
            title = "SIGHIȘOARA";
            subtitle = "The citadel on the hill · Autumn, Anno MDXXI";
            size = SighisoaraMap.Size;
            ground = new Color32(0x2c, 0x33, 0x26, 0xff);
            tile = "tile_grass_village";
            rng = new System.Random(1521);
            spawn = P(SighisoaraMap.At(150f, -100f));

            DrawGround();
            Scatter(new Rect(0, 0, size.x, size.y), 300, new Color[] { new Color32(0x3a, 0x40, 0x2c, 0xff), new Color32(0x2a, 0x2e, 0x22, 0xff), new Color32(0x46, 0x44, 0x36, 0xff) });

            // the streets, cobbled
            for (int i = 0; i < SighisoaraMap.Roads.Length; i++)
                AddPath(SighisoaraMap.Roads[i], SighisoaraMap.RoadWidth[i], CobbleCol, -990, "Cobbles");

            // the two gate towers are vaulted over a passage; the wall stops at their sides
            var gates = new List<SighisoaraMap.B>();
            foreach (var t in SighisoaraMap.Towers)
                if (t.name is "Turnul cu Ceas" or "Turnul Croitorilor") gates.Add(Fixed(t));

            foreach (var w in SighisoaraMap.Walls)
                foreach (var run in CutAtGates(w, gates))
                    AddCurtain(run, "ring", 45f, 46f);

            foreach (var t0 in SighisoaraMap.Towers)
            {
                var t = Fixed(t0);
                bool gate = t.name is "Turnul cu Ceas" or "Turnul Croitorilor";
                float h = t.style == "clocktower" ? 269f : t.name == "Turnul Croitorilor" ? 150f : 125f;
                AddBlockRotated(t.c, t.size, t.angle, t.style, h, solid: !gate);
                if (gate) AddGateFlanks(t);
            }

            foreach (var b in SighisoaraMap.Houses)
            {
                if (b.style == "church") { AddChurch(b); continue; }
                AddRow(b);
            }

            // the covered Scholars' Stairs (Scara Acoperită), 1642, up to the Church on the Hill
            foreach (var s in SighisoaraMap.Stairs)
            {
                var way = new GameObject("CoveredWay").AddComponent<CoveredWay>();
                way.transform.SetParent(transform, false);
                way.a = P(s[0]); way.b = P(s[s.Length - 1]); way.width = 130f;
            }

            AddGraves();
            AddTrees();

            // lights: the Clock Tower gate, the Tailors' gate, the citadel square
            foreach (var g in gates)
            {
                var u = WallDir(g.c);
                var n = new Vector2(-u.y, u.x);
                AddTorch(g.c + n * (Mathf.Max(g.size.x, g.size.y) * 0.6f), 260f, new Color(1f, 0.62f, 0.3f), 0.8f);
                AddTorch(g.c - n * (Mathf.Max(g.size.x, g.size.y) * 0.6f), 260f, new Color(1f, 0.62f, 0.3f), 0.8f);
            }
            AddBrazier(SighisoaraMap.At(77f, 29f)).baseEnergy = 0.7f;
            AddTorch(SighisoaraMap.At(84f, -10f), 220f, new Color(1f, 0.55f, 0.3f), 0.6f);     // Casa Vlad Dracul
            AddTorch(SighisoaraMap.At(-118f, -92f), 220f, new Color(1f, 0.5f, 0.25f), 0.7f);   // Butchers' Tower

            // map edges
            Vector2 sz = size;
            AddWall(P(sz.x / 2f, -20f), new Vector2(sz.x, 40f));
            AddWall(P(sz.x / 2f, sz.y + 20f), new Vector2(sz.x, 40f));
            AddWall(P(-20f, sz.y / 2f), new Vector2(40f, sz.y));
            AddWall(P(sz.x + 20f, sz.y / 2f), new Vector2(40f, sz.y));

            // the road east out of the lower town (to Viscri, later); Saschiz for now
            Vector2 e0 = SighisoaraMap.At(0f, -40f), e1 = SighisoaraMap.At(0f, -150f);
            AddTrigger(new Rect(sz.x - 60f, e0.y, 60f, e1.y - e0.y), () => { if (Ready()) LevelLoader.Goto("hub"); });
        }

        static bool Ready() { var gm = GameManager.I; return gm.state == GameManager.State.Play && !gm.transitioning; }

        /// <summary>The Clock Tower's OSM outline takes in its annex; the tower itself is narrower.</summary>
        static SighisoaraMap.B Fixed(SighisoaraMap.B t)
        {
            if (t.name == "Turnul cu Ceas") t.size = new Vector2(250f, 300f);
            return t;
        }

        // ---------------------------------------------------------------- walls and gates

        /// <summary>Direction of the wall nearest to a point (Godot space, unit length).</summary>
        static Vector2 WallDir(Vector2 at)
        {
            float best = float.MaxValue; Vector2 dir = Vector2.right;
            foreach (var w in SighisoaraMap.Walls)
                for (int i = 0; i < w.Length - 1; i++)
                {
                    float d = DistToSegment(at, w[i], w[i + 1]);
                    if (d < best && (w[i + 1] - w[i]).sqrMagnitude > 1f) { best = d; dir = (w[i + 1] - w[i]).normalized; }
                }
            return dir;
        }

        static bool InBox(Vector2 p, SighisoaraMap.B b, float margin)
        {
            // Godot space has y down; the box angle is counter-clockwise on a north-up map
            float r = -b.angle * Mathf.Deg2Rad;
            var d = p - b.c;
            float lx = d.x * Mathf.Cos(r) + d.y * Mathf.Sin(r);
            float ly = -d.x * Mathf.Sin(r) + d.y * Mathf.Cos(r);
            return Mathf.Abs(lx) < b.size.x / 2f + margin && Mathf.Abs(ly) < b.size.y / 2f + margin;
        }

        /// <summary>Splits a wall line where it runs through a gate tower, into short pieces for the cutaway.</summary>
        List<List<Vector2>> CutAtGates(Vector2[] w, List<SighisoaraMap.B> gates)
        {
            var runs = new List<List<Vector2>>();
            List<Vector2> run = null;
            for (int i = 0; i < w.Length - 1; i++)
            {
                Vector2 a = w[i], b = w[i + 1];
                int steps = Mathf.Max(1, Mathf.CeilToInt(Vector2.Distance(a, b) / 20f));
                for (int k = 0; k <= steps; k++)
                {
                    if (k == 0 && i > 0) continue;
                    var p = Vector2.Lerp(a, b, k / (float)steps);
                    bool blocked = false;
                    foreach (var g in gates) if (InBox(p, g, 10f)) { blocked = true; break; }
                    if (blocked) { if (run != null && run.Count > 1) runs.Add(run); run = null; continue; }
                    run ??= new List<Vector2>();
                    // keep a corner at the polyline's own vertices and every ~3 m between them
                    if (run.Count == 0 || k == steps || Vector2.Distance(run[^1], p) >= 150f) run.Add(p);
                }
            }
            if (run != null && run.Count > 1) runs.Add(run);
            var unity = new List<List<Vector2>>();
            foreach (var r in runs) { var u = new List<Vector2>(); foreach (var p in r) u.Add(P(p)); unity.Add(u); }
            return unity;
        }

        /// <summary>Solid shoulders either side of a gate passage, so the tower can be walked through.</summary>
        void AddGateFlanks(SighisoaraMap.B t)
        {
            var u = WallDir(t.c);
            float wallAngle = Mathf.Atan2(-u.y, u.x) * Mathf.Rad2Deg; // Godot y down to map angle
            float delta = (t.angle - wallAngle) * Mathf.Deg2Rad;
            float along = Mathf.Abs(t.size.x * Mathf.Cos(delta)) + Mathf.Abs(t.size.y * Mathf.Sin(delta));
            float across = Mathf.Abs(t.size.x * Mathf.Sin(delta)) + Mathf.Abs(t.size.y * Mathf.Cos(delta));
            float half = Mathf.Max(20f, (along - Gap) / 2f);
            foreach (float side in new[] { -1f, 1f })
            {
                var c = t.c + u * side * (Gap / 2f + half / 2f);
                AddBlockRotated(c, new Vector2(half, across), wallAngle, "hidden", 100f);
            }
        }

        void AddCurtain(List<Vector2> unityPts, string style, float thick, float h)
        {
            var go = new GameObject("Curtain " + style);
            go.transform.SetParent(transform, false);
            var cw = go.AddComponent<CurtainWall>();
            cw.pts = unityPts; cw.style = style; cw.thick = thick; cw.h = h;
            cw.Build();
        }

        /// <summary>OSM draws a whole street row as one outline: split it into narrow houses of varied
        /// height, gable after gable, as the citadel's rows really stand.</summary>
        void AddRow(SighisoaraMap.B b)
        {
            bool longX = b.size.x >= b.size.y;
            float len = longX ? b.size.x : b.size.y, depth = longX ? b.size.y : b.size.x;
            depth = Mathf.Min(depth, 480f);
            float r = b.angle * Mathf.Deg2Rad;
            var axis = longX ? new Vector2(Mathf.Cos(r), -Mathf.Sin(r)) : new Vector2(Mathf.Sin(r), Mathf.Cos(r)); // Godot space
            int n = Mathf.Max(1, Mathf.RoundToInt(len / (260f + (float)rng.NextDouble() * 120f)));
            float seg = len / n;
            for (int i = 0; i < n; i++)
            {
                var c = b.c + axis * (-len / 2f + seg * (i + 0.5f));
                float w = seg - 6f;
                float h = 44f + (float)rng.NextDouble() * 18f;
                var size = longX ? new Vector2(w, depth) : new Vector2(depth, w);
                AddBlockRotated(c, size, b.angle, "house", h);
            }
        }

        // ---------------------------------------------------------------- churches, graves, trees

        /// <summary>A church with its bell tower at the west end.</summary>
        void AddChurch(SighisoaraMap.B b)
        {
            bool chapel = b.name.Contains("Capela") || b.area < 250f;
            AddBlockRotated(b.c, b.size, b.angle, "church", chapel ? 52f : 78f);
            if (chapel) return;
            float r = b.angle * Mathf.Deg2Rad;
            bool longX = b.size.x >= b.size.y;
            var axis = longX ? new Vector2(Mathf.Cos(r), -Mathf.Sin(r)) : new Vector2(Mathf.Sin(r), Mathf.Cos(r)); // Godot space
            float len = longX ? b.size.x : b.size.y, wid = longX ? b.size.y : b.size.x;
            var end = axis.x < 0 ? b.c + axis * len / 2f : b.c - axis * len / 2f;   // the western end
            float ts = wid * 0.5f;
            AddBlockRotated(end + (b.c - end).normalized * ts * 0.5f, new Vector2(ts, ts), b.angle, "tower", 200f);
        }

        void AddGraves()
        {
            int n = 0;
            foreach (var cem in SighisoaraMap.Cemeteries)
            {
                var bb = Bounds(cem);
                for (float x = bb.xMin; x < bb.xMax && n < 140; x += 70f)
                    for (float y = bb.yMin; y < bb.yMax && n < 140; y += 90f)
                    {
                        var p = new Vector2(x + (float)rng.NextDouble() * 20f, y + (float)rng.NextDouble() * 20f);
                        if (p.x < 40f || p.y < 40f || p.x > size.x - 40f || p.y > size.y - 40f || !Inside(p, cem)) continue;
                        AddBlock(new Rect(p.x - 9f, p.y - 4f, 18f, 8f), "stone", 14f + (float)rng.NextDouble() * 8f);
                        n++;
                    }
            }
        }

        void AddTrees()
        {
            var citadel = SighisoaraMap.Citadel[0];
            Vector2 lt0 = SighisoaraMap.At(135f, 60f), lt1 = SighisoaraMap.At(260f, -175f);
            int n = 0;
            for (float x = 120f; x < size.x - 120f; x += 340f)
                for (float y = 120f; y < size.y - 120f; y += 340f)
                {
                    if (n >= 260) return;
                    var p = new Vector2(x + (float)(rng.NextDouble() - 0.5) * 240f, y + (float)(rng.NextDouble() - 0.5) * 240f);
                    bool wood = false;
                    foreach (var w in SighisoaraMap.Woods) if (Inside(p, w)) { wood = true; break; }
                    if (!wood && Inside(p, citadel)) continue;
                    if (p.x > lt0.x && p.y > lt0.y && p.y < lt1.y) continue;          // the lower town
                    if (!wood && rng.NextDouble() < 0.35) continue;
                    if (NearRoad(p, 70f) || NearBuilding(p, 90f) || NearWall(p, 120f)) continue;
                    AddTree(P(p), rng.NextDouble() < 0.2);
                    n++;
                }
        }

        static bool NearRoad(Vector2 p, float pad)
        {
            for (int i = 0; i < SighisoaraMap.Roads.Length; i++)
            {
                var r = SighisoaraMap.Roads[i]; float lim = SighisoaraMap.RoadWidth[i] / 2f + pad;
                for (int k = 0; k < r.Length - 1; k++) if (DistToSegment(p, r[k], r[k + 1]) < lim) return true;
            }
            return false;
        }

        static bool NearWall(Vector2 p, float pad)
        {
            foreach (var w in SighisoaraMap.Walls)
                for (int k = 0; k < w.Length - 1; k++) if (DistToSegment(p, w[k], w[k + 1]) < pad) return true;
            return false;
        }

        static bool NearBuilding(Vector2 p, float pad)
        {
            foreach (var b in SighisoaraMap.Houses) if (InBox(p, b, pad)) return true;
            foreach (var b in SighisoaraMap.Towers) if (InBox(p, b, pad)) return true;
            return false;
        }

        static float DistToSegment(Vector2 p, Vector2 a, Vector2 b)
        {
            var ab = b - a; float l = ab.sqrMagnitude;
            if (l < 0.0001f) return Vector2.Distance(p, a);
            float t = Mathf.Clamp01(Vector2.Dot(p - a, ab) / l);
            return Vector2.Distance(p, a + ab * t);
        }

        static bool Inside(Vector2 p, Vector2[] poly)
        {
            bool c = false;
            for (int i = 0, j = poly.Length - 1; i < poly.Length; j = i++)
                if ((poly[i].y > p.y) != (poly[j].y > p.y) && p.x < (poly[j].x - poly[i].x) * (p.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x) c = !c;
            return c;
        }

        static Rect Bounds(Vector2[] poly)
        {
            var r = new Rect(poly[0], Vector2.zero);
            foreach (var p in poly) { r.xMin = Mathf.Min(r.xMin, p.x); r.yMin = Mathf.Min(r.yMin, p.y); r.xMax = Mathf.Max(r.xMax, p.x); r.yMax = Mathf.Max(r.yMax, p.y); }
            return r;
        }
    }
}

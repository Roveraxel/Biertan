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
        public static Vector2 CellarDoor;   // Godot space; the hunter climbs back out here

        public override void Build()
        {
            title = "SIGHIȘOARA";
            subtitle = "The citadel on the hill · Autumn, Anno MDXXI";
            size = SighisoaraMap.Size;
            ground = new Color32(0x2c, 0x33, 0x26, 0xff);
            tile = "tile_grass_village";
            rng = new System.Random(1521);
            spawn = P(Free(SighisoaraMap.At(104f, -42f)));     // just inside the Clock Tower gate

            DrawGround();
            Scatter(new Rect(0, 0, size.x, size.y), 300, new Color[] { new Color32(0x3a, 0x40, 0x2c, 0xff), new Color32(0x2a, 0x2e, 0x22, 0xff), new Color32(0x46, 0x44, 0x36, 0xff) });

            // the streets, cobbled
            for (int i = 0; i < SighisoaraMap.Roads.Length; i++)
                AddPath(SighisoaraMap.Roads[i], SighisoaraMap.RoadWidth[i], CobbleCol, -990, "Cobbles");

            // the two gate towers are vaulted over a passage; the wall stops at their sides
            var gates = new List<SighisoaraMap.B>();
            foreach (var t in SighisoaraMap.Towers)
                if (t.name is "Turnul cu Ceas") gates.Add(Fixed(t));   // the only way in or out of the citadel

            foreach (var w in SighisoaraMap.Walls)
                foreach (var run in CutAtGates(w, gates))
                    AddCurtain(run, "ring", 45f, 46f);

            foreach (var t0 in SighisoaraMap.Towers)
            {
                var t = Fixed(t0);
                bool gate = t.name is "Turnul cu Ceas";
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
            AddClutter();
            AddTutorial();

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

            // outside the Clock Tower gate only a small yard is open, where Vlad's cart waits; the road east leaves from it
            Vector2 ya = SighisoaraMap.At(80f, -92f), yb = SighisoaraMap.At(195f, -92f);
            AddBlock(new Rect(ya.x, ya.y, yb.x - ya.x, 40f), "hidden", 0f);
            Vector2 yc = SighisoaraMap.At(156f, -20f), yd = SighisoaraMap.At(195f, -20f);
            AddBlock(new Rect(yc.x, yc.y - 40f, yd.x - yc.x, 40f), "hidden", 0f);
            Vector2 e0 = SighisoaraMap.At(0f, -22f), e1 = SighisoaraMap.At(0f, -90f);
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
            // a deep block is two rows back to back: a house on the street, another on the yard behind
            int rows = depth > 520f ? 2 : 1;
            float rowDepth = Mathf.Min(depth / rows - (rows > 1 ? 40f : 0f), 480f);
            float r = b.angle * Mathf.Deg2Rad;
            var axis = longX ? new Vector2(Mathf.Cos(r), -Mathf.Sin(r)) : new Vector2(Mathf.Sin(r), Mathf.Cos(r)); // Godot space
            int n = Mathf.Max(1, Mathf.RoundToInt(len / (260f + (float)rng.NextDouble() * 120f)));
            float seg = len / n;
            var across = new Vector2(-axis.y, axis.x);
            for (int row = 0; row < rows; row++)
            {
                var off = rows == 1 ? Vector2.zero : across * (row == 0 ? -1f : 1f) * (depth / 4f);
                for (int i = 0; i < n; i++)
                {
                    var c = b.c + off + axis * (-len / 2f + seg * (i + 0.5f));
                    float w = seg - 6f;
                    float h = 44f + (float)rng.NextDouble() * 18f;
                    var size = longX ? new Vector2(w, rowDepth) : new Vector2(rowDepth, w);
                    // OSM outlines fitted with boxes poke into the street: shrink a house until every street stays open
                    for (int tries = 0; tries < 3 && BlocksStreet(c, size, b.angle); tries++) size *= 0.78f;
                    if (BlocksStreet(c, size, b.angle)) continue;
                    AddBlockRotated(c, size, b.angle, "house", h);
                }
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

        // ---------------------------------------------------------------- the opening job

        /// <summary>The bacon thieves: the butcher on the square, the clues and the cellar at the Butchers' Tower.</summary>
        void AddTutorial()
        {
            SighisoaraTutorial.Spots.Clear();
            Vector2 At(float x, float y) => Free(SighisoaraMap.At(x, y));
            // the lower town: the inn where Azorel waits, the notice board, Vlad's cart for the road east
            AddProp("npc", "azorel", "Azorel", At(96f, -50f), "E   Speak to Azorel", new Color32(0xd8, 0xd0, 0xc0, 0xff));
            var nb = At(112f, -52f);
            AddDecor(nb + new Vector2(0f, -16f), "notice_board", 20f);
            AddProp("task", "notice", "Notice board", nb, "E   Read the notice board");
            AddProp("npc", "vlad", "Vlad Laurențiu · Merchant", At(150f, -62f), "E   Speak with Vlad Laurențiu", new Color32(0x4a, 0x5a, 0x6a, 0xff));
            AddDecor(At(160f, -70f), "haycart", 55f);
            // the citadel square: the guild master's stall, Mihai by the well
            AddProp("npc", "butcher", "Meister Thomas · Guild master", At(86f, 12f), "E   Speak with Meister Thomas", new Color32(0x6a, 0x3a, 0x30, 0xff));
            AddProp("npc", "child", "Mihai", At(72f, 46f), "E   Speak with Mihai", new Color32(0x6a, 0x5a, 0x40, 0xff));
            var pt = At(86f, -8f);
            AddDecor(pt + new Vector2(0f, -12f), "portrait", 0f);
            AddProp("task", "portrait", "Casa Vlad Dracul", pt, "E   Look into Casa Vlad Dracul");
            // the butchers' quarter by the tower
            var wife = At(-100f, -80f);
            AddProp("npc", "butcherwife", "Frau Gertrud", wife, "E   Speak with Frau Gertrud", new Color32(0x5a, 0x4a, 0x5a, 0xff));
            AddProp("task", "hearth", "Hearth", Free(wife + new Vector2(-60f, -40f)), "E   Look at the hearth");
            AddTorch(wife + new Vector2(-60f, -40f), 160f, new Color(1f, 0.55f, 0.25f), 0.6f);
            foreach (var (id, x, y, art) in new[] { ("flour", -97f, -86f, "flour"), ("grating", -107f, -91f, "grating"), ("hook", -91f, -97f, "hook_wall") })
            {
                var cp = At(x, y);
                AddDecor(cp + new Vector2(0f, -8f), art, 0f);
                AddProp("clue", id, "", cp, "E   Examine");
            }
            AddProp("clue", "smoke", "", At(-112f, -114f), "E   Examine");
            var crate = At(-115f, -89f);
            AddDecor(crate + new Vector2(0f, -14f), "crate", 30f);
            AddProp("task", "crate", "Crate", crate, "E   Look at the crate");
            CellarDoor = At(-116f, -99f);
            AddProp("task", "cellar", "Cellar door", CellarDoor, "E   Try the cellar door");
            var gs = At(-113f, -104f);
            AddDecor(gs + new Vector2(0f, -10f), "guild_sign", 0f);
            AddProp("task", "sign", "Guild sign", gs, "E   Look at the guild sign");
        }

        public new Prop AddProp(string kind, string id, string display, Vector2 godotPos, string prompt = "", Color? col = null)
        {
            var pr = base.AddProp(kind, id, display, godotPos, prompt, col);
            SighisoaraTutorial.Spots[id] = P(godotPos);
            return pr;
        }

        /// <summary>A Godot-space spot nudged out of any house or the wall, so people and clues stand in the open.</summary>
        Vector2 Free(Vector2 g)
        {
            if (!NearBuilding(g, 18f) && !NearWall(g, 45f)) return g;
            for (float r = 40f; r <= 600f; r += 40f)
                for (int k = 0; k < 12; k++)
                {
                    float a = k * Mathf.PI / 6f;
                    var p = g + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * r;
                    if (!NearBuilding(p, 18f) && !NearWall(p, 45f)) return p;
                }
            return g;
        }

        // ---------------------------------------------------------------- street clutter

        static readonly (string name, float radius, float weight)[] Clutter =
        {
            ("barrel", 18f, 3f), ("barrels", 30f, 2f), ("crate", 20f, 2f), ("sacks", 24f, 2f), ("firewood", 34f, 3f),
            ("handcart", 40f, 1f), ("haycart", 55f, 0.7f), ("bench", 20f, 1f), ("trough", 30f, 0.8f), ("cauldron", 22f, 0.5f),
            ("wheel", 0f, 1f), ("laundry", 0f, 1f), ("crow", 0f, 1.5f), ("lantern", 8f, 1f),
        };

        public Decor AddDecor(Vector2 godotPos, string sprite, float radius, bool flip = false)
        {
            var go = new GameObject("Decor " + sprite);
            go.transform.SetParent(transform, false);
            go.transform.position = P(godotPos);
            var d = go.AddComponent<Decor>();
            d.sprite = sprite; d.flip = flip; d.scale = Decor.SizeOf(sprite);
            d.radius = radius * d.scale;
            d.Build();
            return d;
        }

        /// <summary>Barrels, firewood, carts and crows against the house fronts, off the cobbles; market stalls and
        /// a well on the citadel square.</summary>
        void AddClutter()
        {
            AddDecor(SighisoaraMap.At(66f, 40f), "well", 45f);
            AddDecor(SighisoaraMap.At(88f, 18f), "stall", 55f);
            AddDecor(SighisoaraMap.At(62f, 22f), "stall", 55f, true);
            AddDecor(SighisoaraMap.At(92f, 40f), "stall", 55f);
            float total = 0f; foreach (var c in Clutter) total += c.weight;
            var spawnG = new Vector2(spawn.x, -spawn.y);
            int n = 0;
            for (int i = 0; i < SighisoaraMap.Roads.Length && n < 420; i++)
            {
                float width = SighisoaraMap.RoadWidth[i];
                if (width < 140f) continue;
                var road = SighisoaraMap.Roads[i];
                float next = 200f + (float)rng.NextDouble() * 400f;
                for (int k = 0; k < road.Length - 1 && n < 420; k++)
                {
                    Vector2 a = road[k], b = road[k + 1];
                    float len = Vector2.Distance(a, b);
                    if (len < 1f) continue;
                    var dir = (b - a) / len; var nrm = new Vector2(-dir.y, dir.x);
                    for (float s = next; s < len; s += 260f + (float)rng.NextDouble() * 320f)
                    {
                        float side = rng.NextDouble() < 0.5 ? -1f : 1f;
                        var p = a + dir * s + nrm * side * (width / 2f + 40f);
                        next = s;
                        if (Vector2.Distance(p, spawnG) < 200f || p.x < 60f || p.y < 60f || p.x > size.x - 60f || p.y > size.y - 60f) continue;
                        if (NearRoad(p, -10f) || NearBuilding(p, 4f) || NearWall(p, 40f)) continue;
                        float pick = (float)rng.NextDouble() * total; var c = Clutter[0];
                        foreach (var cc in Clutter) { pick -= cc.weight; if (pick <= 0f) { c = cc; break; } }
                        AddDecor(p, c.name, c.radius, rng.NextDouble() < 0.5);
                        n++;
                    }
                    next = Mathf.Max(0f, next - len);
                }
            }
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

        static List<(Vector2 p, float half)> streetSamples;

        /// <summary>True when a house box (Godot space) would stand on a street: points every 30 units along each
        /// street, padded by most of the street's half-width, must stay outside it.</summary>
        static bool BlocksStreet(Vector2 c, Vector2 size, float angle)
        {
            if (streetSamples == null)
            {
                streetSamples = new List<(Vector2, float)>();
                for (int i = 0; i < SighisoaraMap.Roads.Length; i++)
                {
                    var r = SighisoaraMap.Roads[i]; float half = SighisoaraMap.RoadWidth[i] / 2f;
                    if (half < 30f) continue;    // footpaths and steps may squeeze between houses
                    for (int k = 0; k < r.Length - 1; k++)
                    {
                        int n = Mathf.Max(1, Mathf.CeilToInt(Vector2.Distance(r[k], r[k + 1]) / 30f));
                        for (int j = 0; j <= n; j++) streetSamples.Add((Vector2.Lerp(r[k], r[k + 1], j / (float)n), half));
                    }
                }
            }
            var box = new SighisoaraMap.B { c = c, size = size, angle = angle };
            float reach = Mathf.Max(size.x, size.y);
            foreach (var (p, half) in streetSamples)
            {
                if (Mathf.Abs(p.x - c.x) > reach || Mathf.Abs(p.y - c.y) > reach) continue;
                if (InBox(p, box, half * 0.85f)) return true;
            }
            return false;
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

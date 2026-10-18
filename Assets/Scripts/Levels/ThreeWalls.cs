using System.Collections.Generic;
using UnityEngine;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>
    /// The climb up Biertan hill. Laid out after the real fortress: three closed rings of walls around the
    /// hilltop church, reached by the covered wooden stairway from the village. The outer gate faces the
    /// stairway (south), the middle gate opens to the east, and the inner gate is the Clock Tower on the north
    /// side, so the hunter circles the hill twice before reaching the church door. Each gate is held shut by a
    /// blood ward; break the ward to raise the portcullis. Replaces walls_level.gd's three straight walls,
    /// which could be walked around at the map's flanks.
    /// </summary>
    public class ThreeWalls : LevelBase
    {
        public readonly List<Gate> gates = new();
        public int wardsLeft = 3;

        static readonly Vector2 C = new(1300, 1150);             // the church on the hilltop (Godot coordinates)
        static readonly float[] RX = { 1050f, 720f, 420f };       // outer, middle, inner ring radii
        static readonly float[] RY = { 900f, 600f, 320f };
        static readonly float[] GateDeg = { 90f, 20f, 270f };     // Godot angles (y down): 90 = south, 270 = north
        static readonly float[] Height = { 34f, 42f, 54f };
        const float GateWidth = 150f;

        static Vector2 OnRing(int i, float deg, float extra = 0f)
        {
            float a = deg * Mathf.Deg2Rad;
            return C + new Vector2((RX[i] + extra) * Mathf.Cos(a), (RY[i] + extra) * Mathf.Sin(a));
        }

        /// <summary>A point in the band between ring i and ring i+1 (or between the inner ring and the church).</summary>
        static Vector2 InBand(int i, float deg, float t = 0.5f)
        {
            float a = deg * Mathf.Deg2Rad;
            float rx = i < 2 ? Mathf.Lerp(RX[i + 1], RX[i], t) : Mathf.Lerp(330f, RX[2], t);
            float ry = i < 2 ? Mathf.Lerp(RY[i + 1], RY[i], t) : Mathf.Lerp(170f, RY[2], t);
            return C + new Vector2(rx * Mathf.Cos(a), ry * Mathf.Sin(a));
        }

        public override void Build()
        {
            title = "THE THREE WALLS";
            subtitle = "Three rings of stone. Three wards of blood.";
            size = new Vector2(2600, 2900);
            spawn = P(1300, 2800);
            ground = new Color32(0x26, 0x2a, 0x20, 0xff);
            rng = new System.Random(707);

            DrawGround();
            // the road: up the covered stairway, east round the outer band, north round the middle band,
            // and round the church to its south door
            // up the open hillside in switchbacks, then the covered stairway to the outer gate
            var road = new List<Vector2> { new(1300, 2900), new(1300, 2820), new(800, 2680), new(650, 2520), new(1000, 2400),
                new(1650, 2330), new(1800, 2240), new(1500, 2170), new(1300, 2150), new(1300, 2050) };
            foreach (float d in new[] { 75f, 55f, 35f, 20f }) road.Add(InBand(0, d));
            road.Add(OnRing(1, 20f));
            foreach (float d in new[] { 0f, -25f, -50f, -75f, -90f }) road.Add(InBand(1, d));
            road.Add(OnRing(2, 270f));
            foreach (float d in new[] { 285f, 320f, 350f, 15f, 45f, 75f, 90f }) road.Add(InBand(2, d)); // east of the church: its tower closes the west side
            AddPath(road.ToArray(), 110f, new Color32(0x3a, 0x34, 0x28, 0xff), -990);
            var stone = new Color32(0x4d, 0x48, 0x40, 0xff);
            foreach (float d in new[] { 150f, 165f, 180f, 195f, 210f }) // graves in the outer band, west
            {
                var g = InBand(0, d);
                AddSprite("Grave", "white", P(g.x, g.y - 13), new Vector2(6, 26), stone, -985);
                AddSprite("Grave", "white", P(g.x, g.y - 18), new Vector2(20, 4), stone, -985);
            }
            Scatter(new Rect(0, 0, 2600, 2900), 1400, new Color[] { new Color32(0x33, 0x3a, 0x28, 0xff), new Color32(0x1a, 0x1e, 0x16, 0xff), new Color32(0x44, 0x46, 0x3a, 0xff) });

            AddBlock(new Rect(-200, -200, 3000, 200), "hidden", 0);
            AddBlock(new Rect(-200, 2900, 3000, 200), "hidden", 0);
            AddBlock(new Rect(-200, -200, 200, 3300), "hidden", 0);
            AddBlock(new Rect(2600, -200, 200, 3300), "hidden", 0);

            // the three rings, each closed but for its gate
            for (int i = 0; i < 3; i++)
            {
                float gw = GateWidth / 2f / ((RX[i] + RY[i]) / 2f) * Mathf.Rad2Deg; // half the gate, in degrees
                var pts = new List<Vector2>();
                for (float d = GateDeg[i] + gw; d <= GateDeg[i] + 360f - gw + 0.01f; d += Mathf.Min(6f, 360f / 64f))
                    pts.Add(P(OnRing(i, d)));
                pts.Add(P(OnRing(i, GateDeg[i] + 360f - gw)));
                AddCurtain(pts, i == 1 ? "arches" : "ring", 34f + i * 4f, Height[i]);

                // the gate: a portcullis across the gap, sealed by a ward outside it
                var gc = OnRing(i, GateDeg[i]);
                float a = GateDeg[i] * Mathf.Deg2Rad;
                var tangent = new Vector2(-RX[i] * Mathf.Sin(a), RY[i] * Mathf.Cos(a)); // Godot space
                float rotDeg = Mathf.Atan2(-tangent.y, tangent.x) * Mathf.Rad2Deg;      // Unity space
                gates.Add(Gate.Make(transform, gc, new Vector2(GateWidth + 10f, 40f), rotDeg));
                AddTorch(OnRing(i, GateDeg[i], 70f), 200f, new Color(1f, 0.25f, 0.2f), 0.7f);
                var w = SpawnEnemy("ward", P(OnRing(i, GateDeg[i], 160f)));
                if (w != null)
                {
                    w.atkCd = 3f;
                    int idx = i;
                    w.Died += _ => OnWard(idx);
                }
                // gate towers flanking each gap
                foreach (float s in new[] { -1f, 1f })
                {
                    var t = OnRing(i, GateDeg[i] + s * (gw + 4f));
                    AddBlock(new Rect(t.x - 40, t.y - 40, 80, 80), "tower", 80 + i * 20);
                }
            }
            // the outer ring's four towers (14th century)
            foreach (float d in new[] { 30f, 150f, 210f, 330f })
            {
                var t = OnRing(0, d);
                AddBlock(new Rect(t.x - 45, t.y - 45, 90, 90), "tower", 90);
            }
            // the inner ring: the tall Clock Tower by the north gate, the Mausoleum Tower (north-east), the Catholic
            // Tower (south-east), and the wooden Bell Tower standing inside the ring to the north-west
            var clock = OnRing(2, 270f, -70f);
            AddBlock(new Rect(clock.x - 150, clock.y - 50, 70, 70), "tower", 170);   // Clock Tower (west of the gate)
            var mausoleum = OnRing(2, 300f);
            AddBlock(new Rect(mausoleum.x - 45, mausoleum.y - 45, 90, 90), "tower", 120);
            var catholic = OnRing(2, 60f);
            AddBlock(new Rect(catholic.x - 45, catholic.y - 45, 90, 90), "tower", 120);
            var bell = InBand(2, 230f, 0.35f);
            AddBlock(new Rect(bell.x - 35, bell.y - 35, 70, 70), "tower", 150);       // Bell Tower

            // the hall church on the hilltop, with its south door
            AddBlock(new Rect(C.x - 300, C.y - 130, 600, 260), "church", 70);
            AddBlock(new Rect(C.x - 380, C.y - 70, 90, 140), "tower", 130);
            AddBrazier(new Vector2(C.x - 110, C.y + 175));
            AddBrazier(new Vector2(C.x + 110, C.y + 175));
            AddTorch(new Vector2(C.x, C.y + 170), 240f, new Color(1f, 0.6f, 0.35f), 0.8f);
            AddTrigger(new Rect(C.x - 60, C.y + 132, 120, 36), () => { if (Ready()) LevelLoader.Goto("church"); });

            // the covered wooden stairway: a roofed last stretch up to the outer gate (open at the sides, so the
            // hillside around it stays free to roam)
            float stairTop = OnRing(0, 90f).y + 30f;
            var way = new GameObject("CoveredWay").AddComponent<CoveredWay>();
            way.transform.SetParent(transform, false);
            way.godotRect = new Rect(1170, stairTop, 260, 2200 - stairTop);
            // the hillside: rocks, a ruined hut, graves of the plague year, a wayside shrine
            foreach (var r in new[] { new Rect(520, 2330, 120, 70), new Rect(1900, 2560, 140, 80), new Rect(950, 2620, 90, 60), new Rect(1700, 2700, 110, 70) })
                AddBlock(r, "rock", 40);
            AddBlock(new Rect(2050, 2300, 160, 100), "ruin", 22);
            foreach (float x in new[] { 1500f, 1560f, 1620f, 1680f })
            {
                AddSprite("Grave", "white", P(x, 2560), new Vector2(6, 26), stone, -985);
                AddSprite("Grave", "white", P(x, 2555), new Vector2(20, 4), stone, -985);
            }
            AddProp("bones", "bones_hill", "", new Vector2(2080, 2450), "E   Search the fallen pilgrim");

            // pines on the hillside outside the walls
            for (int k = 0; k < 90; k++)
            {
                var p = new Vector2(Rand(40, 2560), Rand(40, 2860));
                float dx = (p.x - C.x) / (RX[0] + 70f), dy = (p.y - C.y) / (RY[0] + 70f);
                if (dx * dx + dy * dy < 1f || DistToRoad(p, road) < 110f) continue;
                AddTree(P(p), true);
            }
            AddProp("cross", "cross", "", InBand(0, 180f, 0.3f), "E   Pray at the wayside cross");

            // the garrison: wolves on the stairway's foot, the dead in the outer band, the worst inside
            for (int i = 0; i < 4; i++) SpawnEnemy("wolf", P(700 + i * 30, 2480));
            for (int i = 0; i < 3; i++) SpawnEnemy("wolf", P(1700 + i * 30, 2380));
            foreach (float d in new[] { 70f, 45f, 120f }) SpawnEnemy("strigoi", P(InBand(0, d)));
            foreach (float d in new[] { 160f, 185f, 200f, 225f }) SpawnEnemy("moroi", P(InBand(0, d, 0.4f)));
            var ieleHome = InBand(0, 250f);
            for (int i = 0; i < 3; i++)
            {
                float a = i * Mathf.PI * 2f / 3f;
                var e = SpawnEnemy("iele", P(ieleHome + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 70f));
                if (e != null) e.home = P(ieleHome);
            }
            SpawnEnemy("strigoi", P(InBand(0, 300f)));
            foreach (float d in new[] { -10f, -40f, -70f }) SpawnEnemy("shade", P(InBand(1, d)));
            SpawnEnemy("pricolici", P(InBand(1, -20f)));
            SpawnEnemy("pricolici", P(InBand(1, -60f)));
            SpawnEnemy("strigoi", P(InBand(2, 340f)));
            SpawnEnemy("strigoi", P(InBand(2, 30f)));

            AddTrigger(new Rect(1180, 2860, 240, 40), () => { if (Ready()) LevelLoader.Goto("biertan", new Vector2(900, 260)); });
        }

        static float DistToRoad(Vector2 p, List<Vector2> road)
        {
            float best = float.MaxValue;
            for (int i = 0; i < road.Count - 1; i++) best = Mathf.Min(best, DistToSegment(p, road[i], road[i + 1]));
            return best;
        }

        void AddCurtain(List<Vector2> unityPts, string style, float thick, float h)
        {
            var go = new GameObject("Curtain " + style);
            go.transform.SetParent(transform, false);
            var cw = go.AddComponent<CurtainWall>();
            cw.pts = unityPts; cw.style = style; cw.thick = thick; cw.h = h;
            cw.Build();
        }

        public override Color Ambient() => Lights.Dusk(0.8f);

        static bool Ready() { var gm = GameManager.I; return gm.state == GameManager.State.Play && !gm.transitioning; }

        void OnWard(int i)
        {
            wardsLeft--;
            gates[i].Open();
            AudioManager.I?.Sfx("ward", 0f);
            string[] names = { "OUTER", "MIDDLE", "INNER" };
            HudEvents.Banner($"THE {names[i]} GATE OPENS",
                wardsLeft > 0 ? $"{wardsLeft} ward{(wardsLeft == 1 ? "" : "s")} remain." : "The church door stands before you.");
        }
    }
}

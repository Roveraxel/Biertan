using System.Collections.Generic;
using UnityEngine;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>The climb up Biertan hill through its three ring walls. Each gate is held shut by a blood ward;
    /// break the ward to raise the portcullis. Port of walls_level.gd.</summary>
    public class ThreeWalls : LevelBase
    {
        public readonly List<Gate> gates = new();
        public int wardsLeft = 3;
        static readonly float[] WallY = { 1900f, 1250f, 650f };
        static readonly float[] GateX = { 570f, 1770f, 1200f };
        static readonly Vector2[] Wards = { new(1000, 2080), new(1250, 1450), new(650, 840) };

        public override void Build()
        {
            title = "THE THREE WALLS";
            subtitle = "Three rings of stone. Three wards of blood.";
            size = new Vector2(2400, 2600);
            spawn = P(1200, 2500);
            ground = new Color32(0x26, 0x2a, 0x20, 0xff);
            rng = new System.Random(707);

            DrawGround();
            AddPath(new[] { new Vector2(1200, 2600), new Vector2(1100, 2200), new Vector2(570, 2000), new Vector2(570, 1850), new Vector2(1000, 1650),
                new Vector2(1770, 1400), new Vector2(1770, 1200), new Vector2(1400, 950), new Vector2(1200, 700), new Vector2(1200, 470) }, 110f, new Color32(0x3a, 0x34, 0x28, 0xff), -990);
            var stone = new Color32(0x4d, 0x48, 0x40, 0xff);
            foreach (float y in new[] { 2400f, 1700f, 1050f }) // grave crosses between the walls
                for (int i = 0; i < 6; i++)
                {
                    float x = 250 + i * 70;
                    AddSprite("Grave", "white", P(x, y - 13), new Vector2(6, 26), stone, -985);
                    AddSprite("Grave", "white", P(x, y - 18), new Vector2(20, 4), stone, -985);
                }
            Scatter(new Rect(0, 0, 2400, 2600), 1300, new Color[] { new Color32(0x33, 0x3a, 0x28, 0xff), new Color32(0x1a, 0x1e, 0x16, 0xff), new Color32(0x44, 0x46, 0x3a, 0xff) });

            AddBlock(new Rect(-200, -200, 2800, 200), "hidden", 0);
            AddBlock(new Rect(-200, 2600, 2800, 200), "hidden", 0);
            AddBlock(new Rect(-200, -200, 200, 3000), "hidden", 0);
            AddBlock(new Rect(2400, -200, 200, 3000), "hidden", 0);
            for (int i = 0; i < 3; i++)
            {
                float y = WallY[i], gx = GateX[i];
                AddBlock(new Rect(120, y, gx - 70 - 120, 44), "wall", 34 + i * 6);
                AddBlock(new Rect(gx + 70, y, 2280 - gx - 70, 44), "wall", 34 + i * 6);
                AddBlock(new Rect(gx - 110, y - 20, 40, 70), "tower", 70 + i * 10);
                AddBlock(new Rect(gx + 70, y - 20, 40, 70), "tower", 70 + i * 10);
                gates.Add(Gate.Make(transform, new Rect(gx - 70, y, 140, 44)));
                AddTorch(new Vector2(gx, y + 70), 200f, new Color(1f, 0.25f, 0.2f), 0.7f);
                var w = SpawnEnemy("ward", P(Wards[i]));
                if (w != null)
                {
                    w.atkCd = 3f;
                    int idx = i;
                    w.Died += _ => OnWard(idx);
                }
            }
            // pines on the steep flanks
            for (float y = 80f; y < 2600f; y += 110f)
                foreach (float x in new[] { 60f, 2340f })
                    AddTree(P(x + Rand(-30, 30), y + Rand(-20, 20)), true);
            // ruined houses between the walls
            foreach (var r in new[] { new Rect(400, 2200, 160, 100), new Rect(1600, 2300, 180, 110), new Rect(500, 1500, 160, 100), new Rect(1800, 1600, 150, 100), new Rect(1600, 900, 160, 100) })
                AddBlock(r, "ruin", 22);
            // the church at the top
            AddBlock(new Rect(900, 200, 600, 260), "church", 60);
            AddBlock(new Rect(780, 240, 110, 160), "tower", 170);
            AddTorch(new Vector2(1200, 520), 240f, new Color(1f, 0.6f, 0.35f), 0.8f);
            AddBrazier(new Vector2(1000, 560));
            AddBrazier(new Vector2(1400, 560));
            AddProp("cross", "cross", "", new Vector2(1500, 1100), "E   Pray at the wayside cross");
            // the garrison
            foreach (var p in new[] { new Vector2(800, 2300), new Vector2(1400, 2200), new Vector2(1700, 2050) }) SpawnEnemy("strigoi", P(p));
            for (int i = 0; i < 4; i++) SpawnEnemy("wolf", P(1100 + i * 40, 2250));
            foreach (var p in new[] { new Vector2(800, 1600), new Vector2(1000, 1700), new Vector2(1500, 1500), new Vector2(1700, 1400) }) SpawnEnemy("moroi", P(p));
            for (int i = 0; i < 3; i++)
            {
                float a = i * Mathf.PI * 2f / 3f;
                var e = SpawnEnemy("iele", P(new Vector2(400, 1450) + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 70f));
                if (e != null) e.home = P(400, 1450);
            }
            SpawnEnemy("strigoi", P(1300, 1350));
            foreach (var p in new[] { new Vector2(900, 900), new Vector2(1500, 800), new Vector2(500, 1000) }) SpawnEnemy("shade", P(p));
            SpawnEnemy("pricolici", P(1100, 1000));
            SpawnEnemy("pricolici", P(1800, 950));
            SpawnEnemy("strigoi", P(900, 750));
            SpawnEnemy("strigoi", P(1500, 720));
            AddTrigger(new Rect(1080, 2550, 240, 50), () => { if (Ready()) LevelLoader.Goto("biertan", new Vector2(900, 260)); });
            AddTrigger(new Rect(1140, 460, 120, 40), () => { if (Ready()) LevelLoader.Goto("church"); });
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

using UnityEngine;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>Richiș: a smaller fortified village around its hall church, famous for the Green Man carvings.
    /// Second safe haven. Port of richis_level.gd.</summary>
    public class Richis : LevelBase
    {
        static readonly Color Cobble = new Color32(0x62, 0x5a, 0x4a, 0xff);

        public override void Build()
        {
            title = "RICHIȘ";
            subtitle = "Safe haven · The church of the Green Men";
            size = new Vector2(1800, 1200);
            spawn = P(260, 600);
            ground = new Color32(0x3a, 0x46, 0x30, 0xff);
            tile = "tile_grass_village";
            rng = new System.Random(21);

            DrawGround();
            var area = new Rect(200, 150, 1400, 900);
            AddTiled("tile_cobble", area, new Color(0.6f, 0.58f, 0.56f), -995);
            AddSprite("GateRoadW", "white", P(100, 600), new Vector2(200, 140), Cobble * 0.85f, -994);
            AddSprite("GateRoadE", "white", P(1700, 600), new Vector2(200, 140), Cobble * 0.85f, -994);
            foreach (var r in new[] { new Rect(200, 150, 1400, 6), new Rect(200, 1044, 1400, 6), new Rect(200, 150, 6, 900), new Rect(1594, 150, 6, 900) })
                AddSprite("Edge", "white", P(r.center), r.size, new Color(0, 0, 0, 0.18f), -993);
            Scatter(new Rect(0, 0, 1800, 1200), 480, new Color[] { new Color32(0x55, 0x68, 0x3a, 0xff), new Color32(0x2f, 0x3d, 0x22, 0xff), new Color32(0x6a, 0x7a, 0x44, 0xff) });
            Scatter(new Rect(200, 160, 1400, 880), 220, new Color[] { new Color32(0x7d, 0x73, 0x60, 0xff), new Color32(0x5a, 0x51, 0x42, 0xff) });

            // ring wall with west and east gates
            AddBlock(new Rect(160, 110, 1480, 40), "wall", 26);
            AddBlock(new Rect(160, 1050, 1480, 40), "wall", 26);
            AddBlock(new Rect(160, 110, 40, 400), "wall", 26);
            AddBlock(new Rect(160, 690, 40, 400), "wall", 26);
            AddBlock(new Rect(1600, 110, 40, 400), "wall", 26);
            AddBlock(new Rect(1600, 690, 40, 400), "wall", 26);
            foreach (var c in new[] { new Vector2(160, 110), new Vector2(1580, 110), new Vector2(160, 1030), new Vector2(1580, 1030) })
                AddBlock(new Rect(c.x - 10, c.y - 10, 76, 76), "tower", 66);
            foreach (float gx in new[] { 140f, 1580f })
            {
                AddBlock(new Rect(gx, 450, 80, 64), "tower", 60);
                AddBlock(new Rect(gx, 690, 80, 64), "tower", 60);
            }
            // the hall church: long nave and west tower
            AddBlock(new Rect(700, 380, 420, 220), "church", 46);
            AddBlock(new Rect(620, 410, 90, 140), "tower", 104);
            // houses
            AddBlock(new Rect(300, 200, 220, 140), "house", 36);
            AddBlock(new Rect(1240, 210, 230, 140), "house", 36);
            AddBlock(new Rect(320, 820, 200, 120), "house", 34);
            AddBlock(new Rect(1200, 820, 220, 120), "house", 34);
            AddBlock(new Rect(860, 880, 150, 100), "house", 30);
            // well and fruit trees
            AddBlock(new Rect(976, 690, 48, 36), "stone", 16);
            foreach (var p in new[] { new Vector2(560, 260), new Vector2(1100, 260), new Vector2(600, 980), new Vector2(1450, 600), new Vector2(420, 640), new Vector2(1350, 980) })
                AddTree(P(p));

            // villagers and the carving
            AddProp("npc", "pastor", "Pfarrer Lukas · Pastor", new Vector2(900, 690), "E   Speak with the pastor", new Color32(0x1c, 0x1a, 0x20, 0xff));
            AddProp("npc", "vasile", "Vasile · Salt Miner", new Vector2(1380, 420), "E   Speak with Vasile", new Color32(0x8a, 0x8a, 0x86, 0xff));
            AddProp("npc", "katharina", "Katharina · Herbalist", new Vector2(420, 400), "E   Speak with Katharina", new Color32(0x24, 0x32, 0x4e, 0xff));
            AddProp("npc", "rozalia", "Rozalia · Mother", new Vector2(1100, 1000), "E   Speak with Rozalia", new Color32(0xe8, 0xe2, 0xd2, 0xff));
            AddProp("greenman", "greenman", "", new Vector2(1150, 630), "E   Look at the carving");

            // light
            AddBrazier(new Vector2(820, 720)).baseEnergy = 0.7f;
            AddBrazier(new Vector2(1180, 720)).baseEnergy = 0.7f;
            foreach (var t in new[] { new Vector2(230, 505), new Vector2(230, 695), new Vector2(1575, 505), new Vector2(1575, 695) })
                AddTorch(t, 230f, new Color(1f, 0.68f, 0.34f), 0.7f);
            AddTorch(new Vector2(420, 360), 220f, new Color(1f, 0.75f, 0.4f), 0.8f);
            AddTorch(new Vector2(1380, 380), 220f, new Color(0.85f, 0.9f, 1f), 0.6f);
            AddTorch(new Vector2(900, 600), 260f, new Color(1f, 0.8f, 0.5f), 0.5f);

            AddTrigger(new Rect(0, 520, 70, 160), () => { if (Ready()) LevelLoader.Goto("hub", new Vector2(1540, 600)); });
            AddTrigger(new Rect(1730, 520, 70, 160), LeaveEast);
        }

        static bool Ready() { var gm = GameManager.I; return gm.state == GameManager.State.Play && !gm.transitioning; }

        /// <summary>main.gd leave_richis_east(): the pastor first; then the hills, or Moșna once the children are home.</summary>
        static void LeaveEast()
        {
            if (!Ready()) return;
            var gm = GameManager.I;
            if (gm.quest2 == 0)
            {
                HudEvents.Toast("Speak with the pastor before you leave.");
                gm.player.GetComponent<Rigidbody2D>().linearVelocity = new Vector2(-300, 0);
            }
            else if (gm.quest2 >= 3) LevelLoader.Goto("mosna", new Vector2(300, 620));
            else LevelLoader.Goto("hills");
        }
    }
}

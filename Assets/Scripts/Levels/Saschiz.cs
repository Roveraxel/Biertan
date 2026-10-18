using UnityEngine;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>Saschiz: the fortified Saxon village where the journey starts. Safe haven with traders.
    /// Port of hub_level.gd.</summary>
    public class Saschiz : LevelBase
    {
        static readonly Color Cobble = new Color32(0x6a, 0x60, 0x4d, 0xff);

        public override void Build()
        {
            title = "SASCHIZ";
            subtitle = "Safe haven · Autumn, Anno MDXXI";
            size = new Vector2(1800, 1200);
            spawn = P(900, 900);
            ground = new Color32(0x3c, 0x4a, 0x2c, 0xff);
            tile = "tile_grass_village";
            rng = new System.Random(11);

            DrawGround();
            // cobbled square inside the walls, the gate road, and a soft shadow along the wall foot
            AddTiled("tile_cobble", new Rect(184, 144, 1432, 916), new Color(0.62f, 0.6f, 0.58f), -995);
            AddSprite("GateRoad", "white", P(1708, 600), new Vector2(184, 140), Cobble * 0.85f, -994);
            foreach (var r in new[] { new Rect(184, 144, 1432, 6), new Rect(184, 1054, 1432, 6), new Rect(184, 144, 6, 916), new Rect(1610, 144, 6, 916) })
                AddSprite("Edge", "white", P(r.center), r.size, new Color(0, 0, 0, 0.18f), -993);
            Scatter(new Rect(0, 0, 1800, 1200), 520, new Color[] { new Color32(0x55, 0x68, 0x3a, 0xff), new Color32(0x2f, 0x3d, 0x22, 0xff), new Color32(0x6a, 0x7a, 0x44, 0xff) });
            Scatter(new Rect(190, 150, 1420, 900), 260, new Color[] { new Color32(0x7d, 0x73, 0x60, 0xff), new Color32(0x5a, 0x51, 0x42, 0xff) });

            // ring wall with the gate on the east side
            AddBlock(new Rect(140, 100, 1520, 44), "wall", 28);
            AddBlock(new Rect(140, 1060, 1520, 44), "wall", 28);
            AddBlock(new Rect(140, 100, 44, 1004), "wall", 28);
            AddBlock(new Rect(1616, 100, 44, 410), "wall", 28);
            AddBlock(new Rect(1616, 690, 44, 414), "wall", 28);
            foreach (var c in new[] { new Vector2(140, 100), new Vector2(1600, 100), new Vector2(140, 1044), new Vector2(1600, 1044) })
                AddBlock(new Rect(c.x - 10, c.y - 10, 80, 80), "tower", 70);
            // gate towers
            AddBlock(new Rect(1596, 450, 80, 70), "tower", 64);
            AddBlock(new Rect(1596, 690, 80, 70), "tower", 64);
            // the church with its defensive tower
            AddBlock(new Rect(780, 430, 260, 250), "church", 44);
            AddBlock(new Rect(860, 300, 100, 120), "tower", 100);
            // houses
            AddBlock(new Rect(280, 200, 240, 150), "house", 38);
            AddBlock(new Rect(1230, 200, 240, 140), "house", 38);
            AddBlock(new Rect(300, 780, 190, 120), "house", 34);
            AddBlock(new Rect(1150, 800, 180, 120), "house", 34);
            AddBlock(new Rect(1440, 790, 110, 90), "house", 30);
            AddBlock(new Rect(676, 660, 48, 36), "stone", 16);
            // fruit trees
            foreach (var p in new[] { new Vector2(620, 300), new Vector2(540, 560), new Vector2(1100, 330), new Vector2(1330, 620), new Vector2(600, 960), new Vector2(1280, 980), new Vector2(230, 620) })
                AddTree(P(p));

            // villagers
            AddProp("npc", "anna", "Frau Anna Roth · Innkeeper", new Vector2(410, 420), "E   Speak with Anna", new Color32(0x8a, 0x3a, 0x4a, 0xff));
            AddProp("npc", "hans", "Master Hans · Blacksmith", new Vector2(1350, 410), "E   Speak with Hans", new Color32(0x5a, 0x4a, 0x3a, 0xff));
            AddProp("npc", "ileana", "Old Ileana · Herbalist", new Vector2(1540, 610), "E   Speak with Ileana", new Color32(0x5a, 0x6a, 0x4a, 0xff));
            AddProp("npc", "gheorghe", "Gheorghe · Shepherd", new Vector2(1000, 900), "E   Speak with Gheorghe", new Color32(0x7a, 0x6a, 0x4a, 0xff));

            // light
            AddBrazier(new Vector2(760, 730)).baseEnergy = 0.7f;
            AddBrazier(new Vector2(1060, 730)).baseEnergy = 0.7f;
            AddTorch(new Vector2(1590, 505), 240f, new Color(1f, 0.68f, 0.34f), 0.7f);
            AddTorch(new Vector2(1590, 695), 240f, new Color(1f, 0.68f, 0.34f), 0.7f);
            AddTorch(new Vector2(400, 372), 230f, new Color(1f, 0.75f, 0.4f));
            AddTorch(new Vector2(1350, 360), 240f, new Color(1f, 0.45f, 0.2f), 0.8f);
            AddTorch(new Vector2(900, 470), 280f, new Color(1f, 0.8f, 0.5f), 0.45f);

            AddTrigger(new Rect(1720, 520, 80, 160), TryLeave);
        }

        /// <summary>main.gd try_leave_hub(): Anna first; then the forest, or Richiș once the Vârcolac is dealt with.</summary>
        void TryLeave()
        {
            var gm = GameManager.I;
            if (gm.state != GameManager.State.Play || gm.transitioning) return;
            if (gm.quest == 0)
            {
                HudEvents.Toast("Speak with Frau Anna before you leave.");
                gm.player.GetComponent<Rigidbody2D>().linearVelocity = new Vector2(-300, 0);
            }
            else if (gm.quest >= 3) LevelLoader.Goto("richis", new Vector2(300, 600));
            else LevelLoader.Goto("forest");
        }
    }
}

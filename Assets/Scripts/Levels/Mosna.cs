using System.Collections;
using UnityEngine;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>Moșna: a large fortified church with a tall bell tower and a bacon tower. Third safe haven,
    /// last stop before the road to Biertan. Port of mosna_level.gd.</summary>
    public class Mosna : LevelBase
    {
        static readonly Color Cobble = new Color32(0x5e, 0x56, 0x48, 0xff);

        public override void Build()
        {
            title = "MOȘNA";
            subtitle = "Safe haven · The tower that keeps the bacon";
            size = new Vector2(1900, 1250);
            spawn = P(260, 620);
            ground = new Color32(0x38, 0x43, 0x2e, 0xff);
            tile = "tile_grass_village";
            rng = new System.Random(31);

            DrawGround();
            var area = new Rect(200, 150, 1500, 940);
            AddTiled("tile_cobble", area, new Color(0.58f, 0.56f, 0.54f), -995);
            AddSprite("GateRoadW", "white", P(100, 620), new Vector2(200, 140), Cobble * 0.85f, -994);
            AddSprite("GateRoadE", "white", P(1800, 620), new Vector2(200, 140), Cobble * 0.85f, -994);
            AddSprite("Churchyard", "white", P(new Rect(586, 326, 728, 494).center), new Vector2(728, 494), new Color(0.2f, 0.25f, 0.15f, 0.35f), -993);
            foreach (var r in new[] { new Rect(200, 150, 1500, 6), new Rect(200, 1084, 1500, 6), new Rect(200, 150, 6, 940), new Rect(1694, 150, 6, 940) })
                AddSprite("Edge", "white", P(r.center), r.size, new Color(0, 0, 0, 0.18f), -993);
            Scatter(new Rect(0, 0, 1900, 1250), 500, new Color[] { new Color32(0x55, 0x68, 0x3a, 0xff), new Color32(0x2f, 0x3d, 0x22, 0xff), new Color32(0x6a, 0x7a, 0x44, 0xff) });
            Scatter(new Rect(200, 160, 1500, 920), 240, new Color[] { new Color32(0x7d, 0x73, 0x60, 0xff), new Color32(0x5a, 0x51, 0x42, 0xff) });

            // double ring wall
            AddBlock(new Rect(160, 110, 1580, 40), "wall", 30);
            AddBlock(new Rect(160, 1090, 1580, 40), "wall", 30);
            AddBlock(new Rect(160, 110, 40, 420), "wall", 30);
            AddBlock(new Rect(160, 710, 40, 420), "wall", 30);
            AddBlock(new Rect(1700, 110, 40, 420), "wall", 30);
            AddBlock(new Rect(1700, 710, 40, 420), "wall", 30);
            foreach (var c in new[] { new Vector2(160, 110), new Vector2(1680, 110), new Vector2(160, 1070), new Vector2(1680, 1070) })
                AddBlock(new Rect(c.x - 10, c.y - 10, 80, 80), "tower", 74);
            foreach (float gx in new[] { 140f, 1680f })
            {
                AddBlock(new Rect(gx, 470, 80, 64), "tower", 62);
                AddBlock(new Rect(gx, 710, 80, 64), "tower", 62);
            }
            // inner wall around the church yard (gaps north and south)
            AddBlock(new Rect(560, 300, 300, 26), "wall", 20);
            AddBlock(new Rect(1040, 300, 300, 26), "wall", 20);
            AddBlock(new Rect(560, 820, 300, 26), "wall", 20);
            AddBlock(new Rect(1040, 820, 300, 26), "wall", 20);
            AddBlock(new Rect(560, 300, 26, 546), "wall", 20);
            AddBlock(new Rect(1314, 300, 26, 546), "wall", 20);
            // hall church with the tall bell tower, and the bacon tower
            AddBlock(new Rect(760, 420, 380, 230), "church", 50);
            AddBlock(new Rect(700, 470, 80, 120), "tower", 150);
            AddBlock(new Rect(1220, 380, 80, 80), "tower", 96);
            // houses
            AddBlock(new Rect(300, 200, 200, 140), "house", 36);
            AddBlock(new Rect(1420, 200, 220, 140), "house", 36);
            AddBlock(new Rect(300, 880, 220, 130), "house", 34);
            AddBlock(new Rect(1400, 900, 220, 120), "house", 34);
            AddBlock(new Rect(860, 960, 180, 100), "house", 30);
            foreach (var p in new[] { new Vector2(520, 220), new Vector2(1380, 600), new Vector2(460, 640), new Vector2(600, 1000), new Vector2(1250, 1010) })
                AddTree(P(p));

            AddProp("npc", "konrad", "Meister Konrad · Bell-founder", new Vector2(950, 760), "E   Speak with Konrad", new Color32(0x3a, 0x30, 0x28, 0xff));
            AddProp("npc", "hannes", "Hannes · Keeper of the Bacon Tower", new Vector2(1260, 520), "E   Speak with Hannes", new Color32(0x6a, 0x4a, 0x2a, 0xff));
            AddProp("npc", "magda", "Magda · Waiting at the gate", new Vector2(330, 700), "E   Speak with Magda", new Color32(0x3a, 0x2a, 0x3a, 0xff));
            AddProp("npc", "veta", "Veta · Cantor's widow", new Vector2(420, 420), "E   Speak with Veta", new Color32(0x16, 0x14, 0x1a, 0xff));

            AddBrazier(new Vector2(860, 740)).baseEnergy = 0.7f;
            AddBrazier(new Vector2(1040, 740)).baseEnergy = 0.7f;
            foreach (var t in new[] { new Vector2(230, 525), new Vector2(230, 715), new Vector2(1675, 525), new Vector2(1675, 715) })
                AddTorch(t, 230f, new Color(1f, 0.68f, 0.34f), 0.7f);
            AddTorch(new Vector2(950, 720), 240f, new Color(1f, 0.55f, 0.25f), 0.8f);
            AddTorch(new Vector2(420, 380), 220f, new Color(1f, 0.75f, 0.4f), 0.6f);
            AddTorch(new Vector2(1260, 480), 220f, new Color(1f, 0.75f, 0.4f), 0.7f);

            AddTrigger(new Rect(0, 540, 70, 160), () => { if (Ready()) LevelLoader.Goto("richis", new Vector2(1540, 600)); });
            AddTrigger(new Rect(1830, 540, 70, 160), LeaveEast);
        }

        /// <summary>main.gd goto(): Magda has been waiting at the gate since the cock crowed.</summary>
        public override void OnEnter()
        {
            var gm = GameManager.I;
            if (!gm.side.Contains("magda") && gm.state == GameManager.State.Play)
            {
                gm.side.Add("magda");
                StartCoroutine(MagdaArrives());
            }
        }

        IEnumerator MagdaArrives()
        {
            if (!GameManager.Instant) yield return new WaitForSeconds(0.6f);
            GameManager.I.StartDialogue("Magda", new[]
            {
                "WHAT TOOK YOU SO LONG?! We have been standing at this gate since the cock crowed!",
                "YOU ARE SO SLOW! The whole village had to wait for you. The ham went cold. Konrad fell asleep twice. TWICE!",
                "Do you think the Balaur waits forever? Move your feet faster next time. HAIDAAA, HAIDA!",
            });
        }

        static bool Ready() { var gm = GameManager.I; return gm.state == GameManager.State.Play && !gm.transitioning; }

        /// <summary>main.gd leave_mosna_east(): Konrad first; then the vineyards, or Biertan once the road is open.</summary>
        static void LeaveEast()
        {
            if (!Ready()) return;
            var gm = GameManager.I;
            if (gm.quest3 == 0)
            {
                HudEvents.Toast("Speak with Meister Konrad before you leave.");
                gm.player.GetComponent<Rigidbody2D>().linearVelocity = new Vector2(-300, 0);
            }
            else if (gm.quest3 >= 3) LevelLoader.Goto("biertan", new Vector2(260, 900));
            else LevelLoader.Goto("vineyard");
        }
    }
}

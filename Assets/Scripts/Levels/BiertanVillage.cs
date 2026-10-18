using UnityEngine;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>Biertan, the lower village. Survivors hold out in the Marriage Prison, the one house the thralls
    /// will not enter. The fortress looms on the hill. Port of biertan_level.gd.</summary>
    public class BiertanVillage : LevelBase
    {
        public override void Build()
        {
            title = "BIERTAN";
            subtitle = "The bells are silent. The hill is his.";
            size = new Vector2(1800, 1300);
            spawn = P(220, 900);
            ground = new Color32(0x2a, 0x30, 0x24, 0xff);
            tileTint = new Color(0.9f, 0.9f, 0.85f);
            rng = new System.Random(41);

            DrawGround();
            var road = new Color32(0x3a, 0x34, 0x28, 0xff);
            AddPath(new[] { new Vector2(0, 900), new Vector2(900, 900), new Vector2(900, 140) }, 110f, road, -990);
            // the ring of salt around the Marriage Prison
            var salt = new GameObject("SaltRing");
            salt.transform.SetParent(transform, false);
            var lr = salt.AddComponent<LineRenderer>();
            lr.sharedMaterial = Resources.Load<Material>("LineMat");
            lr.useWorldSpace = true; lr.loop = true; lr.positionCount = 64; lr.widthMultiplier = 5f;
            lr.startColor = lr.endColor = new Color(0.9f, 0.92f, 0.95f, 0.55f); lr.sortingOrder = -985;
            for (int i = 0; i < 64; i++)
            {
                float a = i / 64f * Mathf.PI * 2f;
                lr.SetPosition(i, P(900 + Mathf.Cos(a) * 260f, 760 + Mathf.Sin(a) * 260f * 0.73f));
            }
            Scatter(new Rect(0, 0, 1800, 1300), 600, new Color[] { new Color32(0x3a, 0x44, 0x30, 0xff), new Color32(0x1e, 0x24, 0x18, 0xff), new Color32(0x4a, 0x52, 0x36, 0xff) });

            AddBlock(new Rect(-200, -200, 2200, 200), "hidden", 0);
            AddBlock(new Rect(-200, 1300, 2200, 200), "hidden", 0);
            AddBlock(new Rect(-200, -200, 200, 1700), "hidden", 0);
            AddBlock(new Rect(1800, -200, 200, 1700), "hidden", 0);
            // the fortress walls on the hill, north
            AddBlock(new Rect(0, 0, 820, 140), "wall", 60);
            AddBlock(new Rect(980, 0, 820, 140), "wall", 60);
            AddBlock(new Rect(780, 40, 60, 100), "tower", 110);
            AddBlock(new Rect(960, 40, 60, 100), "tower", 110);
            // abandoned houses along the street
            foreach (var r in new[] { new Rect(200, 300, 200, 130), new Rect(480, 290, 180, 120), new Rect(1140, 300, 200, 130), new Rect(1420, 290, 200, 120), new Rect(240, 1060, 200, 120), new Rect(1300, 1060, 220, 120) })
                AddBlock(r, "house", 34);
            AddBlock(new Rect(1560, 640, 140, 100), "ruin", 24);
            // the Marriage Prison: one small house behind a ring of salt and carts
            AddBlock(new Rect(820, 640, 160, 110), "house", 32);
            for (int a = 0; a < 14; a++)
            {
                float ang = Mathf.PI * 2f * a / 14f;
                if (Mathf.Abs(ang - Mathf.PI) < 0.35f || Mathf.Abs(ang - Mathf.PI * 1.5f) < 0.35f) continue;
                var p = new Vector2(900 + Mathf.Cos(ang) * 300f, 760 + Mathf.Sin(ang) * 220f);
                AddBlock(new Rect(p.x - 26, p.y - 12, 52, 24), "ruin", 16);
            }
            AddProp("npc", "sexton", "Martin · Sexton of Biertan", new Vector2(820, 830), "E   Speak with the sexton", new Color32(0x2a, 0x2a, 0x30, 0xff));
            AddProp("npc", "andreas", "Andreas", new Vector2(1030, 820), "E   Speak with Andreas", new Color32(0x3a, 0x4a, 0x5a, 0xff));
            AddProp("npc", "sofia", "Sofia", new Vector2(1080, 800), "E   Speak with Sofia", new Color32(0x7a, 0x2a, 0x36, 0xff));
            AddProp("sign", "prison_sign", "", new Vector2(980, 770), "E   Read the door");
            AddBrazier(new Vector2(900, 880)).baseEnergy = 0.8f;
            AddTorch(new Vector2(900, 700), 300f, new Color(1f, 0.7f, 0.4f), 0.8f);
            AddTorch(new Vector2(900, 160), 260f, new Color(1f, 0.2f, 0.15f), 0.6f);
            foreach (var p in new[] { new Vector2(600, 600), new Vector2(1250, 560), new Vector2(400, 820), new Vector2(1450, 900), new Vector2(700, 1150) })
                AddTree(P(p), true);
            AddTrigger(new Rect(0, 820, 50, 200), () => { if (Ready()) LevelLoader.Goto("mosna", new Vector2(1640, 620)); });
            AddTrigger(new Rect(840, 140, 120, 60), EnterWalls);
        }

        public override Color Ambient() => Lights.Dusk(0.7f);

        static bool Ready() { var gm = GameManager.I; return gm.state == GameManager.State.Play && !gm.transitioning; }

        static void EnterWalls()
        {
            if (!Ready()) return;
            var gm = GameManager.I;
            var rb = gm.player.GetComponent<Rigidbody2D>();
            if (gm.quest4 == 0) { HudEvents.Toast("Speak with the sexton before you climb the hill."); rb.linearVelocity = new Vector2(0, -300); }
            else if (gm.quest4 >= 2) { HudEvents.Toast("The hill is quiet. The bells ring for the living now."); rb.linearVelocity = new Vector2(0, -300); }
            else LevelLoader.Goto("walls");
        }
    }
}

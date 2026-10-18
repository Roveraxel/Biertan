using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Biertan.Bosses;
using Biertan.Core;
using Biertan.Enemies;

namespace Biertan.Levels
{
    /// <summary>The flooded quarry where the Balaur lies across the road to Biertan. Port of gorge_level.gd.</summary>
    public class DrownedQuarry : LevelBase
    {
        public Balaur boss;
        public readonly List<Rect> pillars = new(); // Godot rects that block the stag's gaze

        public override void Build()
        {
            title = "THE DROWNED QUARRY";
            subtitle = "The Balaur, crowned with the enchanted stag's gems";
            size = new Vector2(1600, 1200);
            spawn = P(800, 1080);
            ground = new Color32(0x2a, 0x27, 0x23, 0xff);
            tile = "";
            cameraZoom = 0.95f;
            cameraOffset = new Vector2(0, 150);
            rng = new System.Random(505);

            DrawGround();
            AddSprite("Lake", "white", P(800, 240), new Vector2(1600, 480), new Color32(0x0c, 0x1a, 0x20, 0xff), -990);
            for (int i = 0; i < 32; i++) // the shore
            {
                Vector2 a = P(i * 50f, 470f + Mathf.Sin(i * 1.7f) * 14f), b = P((i + 1) * 50f, 470f + Mathf.Sin((i + 1) * 1.7f) * 14f);
                var s = AddSprite("Shore", "white", (a + b) / 2f, new Vector2(Vector2.Distance(a, b) + 2f, 8f), new Color32(0x8a, 0x8a, 0x7a, 0xff), -989);
                s.transform.rotation = Quaternion.Euler(0, 0, Mathf.Atan2(b.y - a.y, b.x - a.x) * Mathf.Rad2Deg);
            }
            for (int i = 0; i < 14; i++) // ripples
                AddSprite("Ripple", "white", P(i * 120f + 60f, 120 + (i % 4) * 80), new Vector2(60, 2), new Color(0.5f, 0.6f, 0.65f, 0.25f), -988);
            AddSprite("Road", "white", P(800, 1160), new Vector2(160, 80), new Color32(0x3a, 0x36, 0x30, 0xff), -988);
            Scatter(new Rect(0, 420, 1600, 880), 600, new Color[] { new Color32(0x3a, 0x36, 0x30, 0xff), new Color32(0x1c, 0x1a, 0x17, 0xff), new Color32(0x4a, 0x46, 0x40, 0xff) });

            AddBlock(new Rect(-200, -200, 2000, 200), "hidden", 0);
            AddBlock(new Rect(-200, 1200, 2000, 200), "hidden", 0);
            AddBlock(new Rect(-200, -200, 200, 1700), "hidden", 0);
            AddBlock(new Rect(1600, -200, 200, 1700), "hidden", 0);
            AddBlock(new Rect(0, 0, 1600, 470), "hidden", 0);
            // quarry walls
            for (float y = 470f; y < 1200f; y += 90f)
            {
                AddBlock(new Rect(0, y, 120, 90), "rock", Rand(60, 90));
                AddBlock(new Rect(1480, y, 120, 90), "rock", Rand(60, 90));
            }
            for (float x = 120f; x < 1480f; x += 100f)
                if (Mathf.Abs(x + 50f - 800f) > 120f) AddBlock(new Rect(x, 1120, 100, 80), "rock", 60);
            foreach (var p in new[] { new Vector2(320, 640), new Vector2(1280, 640), new Vector2(400, 980), new Vector2(1200, 980) })
                AddBrazier(p);
            // standing stones: cover from the stag's gaze
            foreach (var c in new[] { new Vector2(520, 760), new Vector2(1080, 760), new Vector2(800, 900), new Vector2(300, 860), new Vector2(1300, 860) })
            {
                var r = new Rect(c.x - 30, c.y - 22, 60, 44);
                AddBlock(r, "stone", 90);
                pillars.Add(new Rect(r.x, r.y - 60, r.width, r.height + 60));
            }

            var go = new GameObject("Balaur");
            go.transform.SetParent(transform, false);
            go.transform.position = P(800, 380);
            go.AddComponent<SortingGroup>();
            boss = go.AddComponent<Balaur>();
            boss.arena = this;
            go.AddComponent<BalaurView>().boss = boss;
            AddTorch(new Vector2(800, 330), 520f, new Color(0.55f, 0.85f, 0.6f), 0.55f);
            boss.BuildHeads();
            boss.Died += _ => OnDead();
            GameManager.I.boss = boss;
        }

        public override Color Ambient() => new(0.42f, 0.44f, 0.52f);

        public void OnHeadSealed() => HudEvents.Banner("THE BALAUR THRASHES", "Its remaining heads grow wilder.");

        public void CallBats()
        {
            if (EnemyBase.All.Count > 8) return;
            HudEvents.Toast("Bats pour from the quarry walls!");
            AudioManager.I?.Sfx("bat", -4f);
            for (int i = 0; i < 3; i++)
            {
                var e = SpawnEnemy("bat", P(i % 2 == 0 ? 150f : 1450f, Random.Range(600f, 1000f)));
                if (e != null) e.state = "chase";
            }
        }

        void OnDead()
        {
            var gm = GameManager.I;
            gm.boss = null;
            gm.StartCoroutine(gm.OnBalaurDead());
        }
    }
}

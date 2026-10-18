using UnityEngine;
using UnityEngine.Rendering;
using Biertan.Bosses;
using Biertan.Core;
using Biertan.Enemies;

namespace Biertan.Levels
{
    /// <summary>Inside the fortified church of Biertan. Vlad waits at the altar; the rope of the great bell hangs
    /// in the tower doorway. Port of church_level.gd.</summary>
    public class ChurchOfBiertan : LevelBase
    {
        public Vlad boss;
        public float bellCd;
        public Prop bell;
        SpriteRenderer bellGlow;

        public override void Build()
        {
            title = "THE CHURCH OF BIERTAN";
            subtitle = "Strigoi Vlad";
            size = new Vector2(1400, 1500);
            spawn = P(700, 1380);
            ground = new Color32(0x3a, 0x36, 0x30, 0xff);
            tile = "";
            rng = new System.Random(808);

            DrawGround();
            for (int y = 140; y < 1440; y += 60) // flagstones
                for (int x = 80; x < 1320; x += 60)
                    if ((x / 60 + y / 60) % 2 == 0) AddSprite("Flag", "white", P(x + 30, y + 30), new Vector2(60, 60), new Color(0, 0, 0, 0.08f), -995);
            AddSprite("Carpet", "white", P(700, 790), new Vector2(280, 1300), new Color32(0x4a, 0x14, 0x18, 0xff), -990);
            AddSprite("Carpet", "white", P(700, 790), new Vector2(260, 1300), new Color32(0x5a, 0x1a, 0x1e, 0xff), -989);
            AddSprite("AltarStep", "white", P(700, 315), new Vector2(160, 50), new Color32(0x1a, 0x10, 0x12, 0xff), -988);
            AddSprite("AltarStep", "white", P(700, 287), new Vector2(140, 14), new Color32(0x2a, 0x1a, 0x1c, 0xff), -987);
            AddSprite("TowerDoor", "white", P(135, 760), new Vector2(110, 120), new Color32(0x26, 0x22, 0x1e, 0xff), -988);
            Scatter(new Rect(0, 0, 1400, 1500), 300, new Color[] { new Color32(0x46, 0x42, 0x3a, 0xff), new Color32(0x2c, 0x29, 0x24, 0xff) });

            AddBlock(new Rect(0, 0, 1400, 140), "wall", 80);
            AddBlock(new Rect(0, 1440, 1400, 60), "wall", 40);
            AddBlock(new Rect(0, 0, 80, 1500), "wall", 40);
            AddBlock(new Rect(1320, 0, 80, 1500), "wall", 40);
            // pews, with a wide aisle
            for (int y = 560; y < 1300; y += 130)
            {
                AddBlock(new Rect(180, y, 300, 24), "pew", 14);
                AddBlock(new Rect(920, y, 300, 24), "pew", 14);
            }
            AddBlock(new Rect(600, 200, 200, 60), "stone", 30); // altar
            foreach (float x in new[] { 200f, 420f, 980f, 1200f }) AddBlock(new Rect(x - 22, 300, 44, 44), "stone", 80);
            foreach (var p in new[] { new Vector2(560, 230), new Vector2(840, 230), new Vector2(300, 1400), new Vector2(1100, 1400), new Vector2(160, 400), new Vector2(1240, 400) })
                AddTorch(p, 260f, new Color(1f, 0.7f, 0.4f), 0.7f);
            bell = AddProp("bell", "bell", "", new Vector2(140, 760), "E   Ring the great bell");
            bellGlow = AddSprite("BellGlow", "circle", P(140, 700), Vector2.one * 36f, new Color(1f, 0.85f, 0.5f, 0.18f), 3);

            var go = new GameObject("Vlad") { layer = LayerMask.NameToLayer("Enemy") };
            go.transform.SetParent(transform, false);
            go.transform.position = P(700, 480);
            var rb = go.AddComponent<Rigidbody2D>();
            rb.gravityScale = 0; rb.freezeRotation = true; rb.interpolation = RigidbodyInterpolation2D.Interpolate;
            go.AddComponent<CircleCollider2D>();
            go.AddComponent<SortingGroup>();
            boss = go.AddComponent<Vlad>();
            boss.Setup("vlad");
            boss.arena = this;
            go.AddComponent<VladView>().boss = boss;
            boss.PhaseChanged += OnPhase;
            boss.Died += _ => OnDead();
            GameManager.I.boss = boss;
        }

        public override Color Ambient() => new(0.38f, 0.34f, 0.4f);

        void Update()
        {
            bellCd = Mathf.Max(0f, bellCd - Time.deltaTime);
            if (bellGlow != null)
            {
                bellGlow.enabled = bellCd <= 0f;
                bellGlow.transform.localScale = Vector3.one * (36f + 8f * Mathf.Sin(Time.time * 4f));
            }
        }

        public void RingBell()
        {
            if (bellCd > 0f) { HudEvents.Toast("The bell still sways. Wait for it."); return; }
            bellCd = 12f;
            AudioManager.I?.Sfx("bell", 2f);
            FxUtil.Ring(bell.transform.position, new Color(1f, 0.9f, 0.6f, 0.8f), 400f, 1f);
            if (boss == null) return;
            if (boss.phase >= 2) { boss.BellToll(); HudEvents.Toast("The great bell tolls! Vlad is dragged out of the mist!"); }
            else HudEvents.Toast("The great bell tolls. Vlad flinches.");
        }

        public void CallBats(Vlad v)
        {
            if (EnemyBase.All.Count > 7) return;
            HudEvents.Toast("He breaks into bats and calls their kin!");
            for (int i = 0; i < 4; i++)
            {
                float a = i * Mathf.PI / 2f;
                var e = SpawnEnemy("bat", (Vector2)v.transform.position + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 60f);
                if (e != null) e.state = "chase";
            }
        }

        void OnPhase(int p)
        {
            if (p == 2) HudEvents.Banner("THE NIHIL RITE", "Throw salt and stand in it! Then ring the bell to break his mist.");
            else if (p == 3) HudEvents.Banner("THE MASTER HUNGERS", "His presence drinks your blood. Keep away, or wear garlic.");
        }

        void OnDead()
        {
            var gm = GameManager.I;
            gm.boss = null;
            gm.StartCoroutine(gm.OnVladDead());
        }
    }
}

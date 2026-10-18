using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Biertan.Bosses;
using Biertan.Core;
using Biertan.Enemies;

namespace Biertan.Levels
{
    /// <summary>The Moon Clearing, where the Vârcolac waits. Port of arena_level.gd.</summary>
    public class MoonClearing : LevelBase
    {
        static readonly Vector2 CenterG = new(700, 700);
        const float Radius = 500f;

        public Varcolac boss;
        readonly List<Brazier> braziers = new();
        float darkness;
        Vector2 Center => P(CenterG);

        public override void Build()
        {
            title = "THE MOON CLEARING";
            subtitle = "The Vârcolac, eater of the moon";
            size = new Vector2(1400, 1400);
            spawn = P(700, 1130);
            ground = new Color32(0x10, 0x15, 0x10, 0xff);
            tile = "";
            rng = new System.Random(5);

            DrawGround();
            Scatter(new Rect(0, 0, 1400, 1400), 500, new Color[] { new Color32(0x1c, 0x26, 0x1a, 0xff), new Color32(0x0d, 0x13, 0x0d, 0xff) });
            // the trodden clearing: outer stone ring, two rings of moss and eight spokes
            AddSprite("Rim", "circle", Center, Vector2.one * (Radius + 5f) * 2f, new Color32(0x5d, 0x58, 0x4f, 0xff), -998);
            AddSprite("Clearing", "circle", Center, Vector2.one * (Radius - 5f) * 2f, new Color32(0x23, 0x2a, 0x1f, 0xff), -997);
            AddSprite("Inner", "circle", Center, Vector2.one * (Radius - 40f) * 2f, new Color32(0x2b, 0x33, 0x26, 0xff), -996);
            var markColor = new Color32(0x3d, 0x46, 0x36, 0xff);
            foreach (float r in new[] { 380f, 190f })
            {
                AddSprite("Ring", "circle", Center, Vector2.one * (r + 1.5f) * 2f, markColor, -995);
                AddSprite("RingIn", "circle", Center, Vector2.one * (r - 1.5f) * 2f, new Color32(0x2b, 0x33, 0x26, 0xff), -994);
            }
            for (int i = 0; i < 8; i++)
            {
                float a = Mathf.PI * 2f * i / 8f;
                var dir = new Vector2(Mathf.Cos(a), Mathf.Sin(a));
                var spoke = AddSprite("Spoke", "white", Center + dir * 285f, new Vector2(190f, 2f), markColor, -993);
                spoke.transform.rotation = Quaternion.Euler(0, 0, a * Mathf.Rad2Deg);
            }

            AddRingWall(Center, Radius);
            foreach (var a in new[] { new Vector2(-1, -1), new Vector2(1, -1), new Vector2(-1, 1), new Vector2(1, 1) })
            {
                var go = new GameObject("Brazier");
                go.transform.SetParent(transform, false);
                go.transform.position = Center + a * 300f;
                braziers.Add(go.AddComponent<Brazier>());
            }
            for (int i = 0; i < 36; i++)
            {
                float ang = Mathf.PI * 2f * i / 36f;
                AddTree(Center + new Vector2(Mathf.Cos(ang), Mathf.Sin(ang)) * (Radius + 60f + Rand(0, 40)), true);
            }

            boss = MakeBoss(Center + new Vector2(0, 260));
            boss.PhaseChanged += OnPhase;
            boss.Died += _ => OnBossDied();
            GameManager.I.boss = boss;
            AudioManager.I?.SetMusic("music_boss", -6f);
        }

        Varcolac MakeBoss(Vector2 pos)
        {
            var go = new GameObject("Varcolac") { layer = LayerMask.NameToLayer("Enemy") };
            go.transform.SetParent(transform, false);
            go.transform.position = pos;
            var rb = go.AddComponent<Rigidbody2D>();
            rb.gravityScale = 0; rb.freezeRotation = true;
            rb.interpolation = RigidbodyInterpolation2D.Interpolate;
            go.AddComponent<CircleCollider2D>();
            go.AddComponent<SortingGroup>();
            var b = go.AddComponent<Varcolac>();
            b.Setup("varcolac");
            b.arena = this;

            AddSprite("Shadow", "circle", pos + new Vector2(0, -4), new Vector2(112, 50), new Color(0, 0, 0, 0.4f), -1, go.transform);
            var view = go.AddComponent<VarcolacView>();
            view.boss = b;
            view.body = AddSprite("Body", "boss_idle", pos, Vector2.one, Color.white, 0, go.transform);
            var mat = Resources.Load<Material>("LineMat");
            view.telegraph = Line(go.transform, "Telegraph", 8f, mat, -1);
            view.threads = new LineRenderer[3];
            for (int i = 0; i < 3; i++) view.threads[i] = Line(go.transform, "Thread", 1.5f, mat, -2);
            return b;
        }

        static LineRenderer Line(Transform parent, string name, float width, Material mat, int order)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var lr = go.AddComponent<LineRenderer>();
            lr.useWorldSpace = false; lr.widthMultiplier = width; lr.sharedMaterial = mat;
            lr.sortingOrder = order; lr.enabled = false;
            return lr;
        }

        public override Color Ambient() => Color.Lerp(Lights.Dusk(0.7f), new Color(0.16f, 0.05f, 0.06f), darkness);

        void Update()
        {
            float target = boss != null && boss.phase >= 2 ? 1f : 0f;
            darkness = Mathf.MoveTowards(darkness, target, Time.deltaTime * 0.8f);
        }

        void OnPhase(int p)
        {
            if (p == 2)
            {
                HudEvents.Banner("IT CLIMBS THE THREADS TO THE MOON", "The moon bleeds. Light the fires: the vârcolac fears flame and noise.");
                foreach (var b in braziers) { b.decays = true; b.SetLit(false); }
            }
            else if (p == 3)
            {
                HudEvents.Banner("IT DEVOURS THE FIRES", "Let it gorge. When it grows heavy, its threads will snap.");
            }
        }

        void OnBossDied()
        {
            var gm = GameManager.I;
            gm.boss = null;
            gm.StartCoroutine(gm.OnBossDead());
        }

        public void BossHowl(Varcolac b)
        {
            HudEvents.Toast("The vârcolac howls, and the hounds answer!");
            AudioManager.I?.Sfx("boss_howl", 0f, 1f);
            b.howlAnim = 1.2f;
            FxUtil.Ring(b.transform.position, new Color(0.9f, 0.9f, 1f, 0.7f), 260f, 0.8f);
            if (EnemyBase.All.Count < 7)
                for (int i = 0; i < 2; i++)
                {
                    float a = Random.value * Mathf.PI * 2f;
                    SpawnEnemy("wolf", (Vector2)b.transform.position + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 90f);
                }
        }

        public void SwallowLight(Varcolac b)
        {
            var litList = braziers.FindAll(x => x.lit);
            if (litList.Count == 0) return;
            var br = litList[Random.Range(0, litList.Count)];
            br.SetLit(false);
            FxUtil.Ring(br.transform.position, new Color(0.2f, 0.2f, 0.4f, 0.9f), 140f, 0.7f);
            HudEvents.Toast("The vârcolac swallows a flame!");
            AudioManager.I?.Sfx("flee", -2f, 0.7f);
            b.Gorge();
        }
    }
}

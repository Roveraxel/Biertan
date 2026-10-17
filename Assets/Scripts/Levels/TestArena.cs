using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using Biertan.Core;
using Biertan.Player;
using Biertan.Enemies;

namespace Biertan.Levels
{
    /// <summary>
    /// Sandbox for checking the port: spawns the creatures of the Wolf Forest and lets you
    /// summon any kind with the number keys. Also a minimal on-screen HUD until the real HUD is ported.
    ///   1 wolf · 2 pricolici · 3 scarecrow · 4 shade · 5 iele · 6 moroi · 7 strigoi · 8 bat · 9 blood ward · 0 fire skull
    ///   F1 god mode · F2 unlock salt (+5) · F3 +3 tinctures · F4 toggle dusk 0 / 1 · Enter respawn after death
    /// </summary>
    public class TestArena : LevelBase
    {
        public PlayerController player;
        readonly List<string> toasts = new();
        string banner = "", bannerSub = "";
        float bannerT, toastT;

        static readonly string[] Kinds = { "skull", "wolf", "pricolici", "scarecrow", "shade", "iele", "moroi", "strigoi", "bat", "ward" };

        void Start()
        {
            var gm = GameManager.I;
            gm.player = player;
            gm.level = this;
            gm.current = "forest";
            gm.state = GameManager.State.Play;
            gm.dusk = 0.3f;

            LevelLoader.GotoHandler = (_, at) =>
            {
                player.transform.position = at ?? spawn;
                player.GetComponent<Rigidbody2D>().linearVelocity = Vector2.zero;
            };
            player.Died += () => StartCoroutine(gm.OnPlayerDied());
            player.onToast = HudEvents.Toast;
            HudEvents.OnToast += s => { toasts.Add(s); if (toasts.Count > 4) toasts.RemoveAt(0); toastT = 4f; };
            HudEvents.OnBanner += (s, sub) => { banner = s; bannerSub = sub; bannerT = 3.5f; };

            // the forest's opening pack
            SpawnEnemy("wolf", new Vector2(420, 120));
            SpawnEnemy("wolf", new Vector2(460, -60));
            SpawnEnemy("wolf", new Vector2(380, -200));
            SpawnEnemy("pricolici", new Vector2(-480, 260));
            SpawnEnemy("scarecrow", new Vector2(-300, -320));
            HudEvents.Toast("Test arena — number keys spawn creatures. F1 god, F2 salt, F3 tinctures, F4 dusk.");
        }

        public override EnemyBase SpawnEnemy(string kind, Vector2 pos) => PrefabRegistry.SpawnEnemy(kind, pos);

        public override Color Ambient()
        {
            float d = GameManager.I.dusk;
            return Color.Lerp(new Color(0.85f, 0.85f, 0.95f), new Color(0.35f, 0.38f, 0.6f), d);
        }

        void Update()
        {
            var kb = Keyboard.current;
            if (kb == null) return;
            for (int i = 0; i <= 9; i++)
            {
                var key = kb[(Key)((int)Key.Digit0 + i)];
                if (key.wasPressedThisFrame)
                {
                    float a = Random.value * Mathf.PI * 2f;
                    SpawnEnemy(Kinds[i], (Vector2)player.transform.position + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 330f);
                }
            }
            if (kb.f1Key.wasPressedThisFrame) { player.god = !player.god; HudEvents.Toast("God mode " + (player.god ? "on" : "off")); }
            if (kb.f2Key.wasPressedThisFrame) { player.saltUnlocked = true; player.salt += 5; HudEvents.Toast("+5 salt (R to throw)"); }
            if (kb.f3Key.wasPressedThisFrame) { player.potions += 3; HudEvents.Toast("+3 tinctures (Q to drink)"); }
            if (kb.f4Key.wasPressedThisFrame) { var gm = GameManager.I; gm.dusk = gm.dusk > 0.5f ? 0f : 0.99f; gm.midnightDone = false; }
            if (GameManager.I.state == GameManager.State.Dead && (kb.enterKey.wasPressedThisFrame || kb.eKey.wasPressedThisFrame))
                GameManager.I.Respawn();

            bannerT -= Time.deltaTime;
            toastT -= Time.deltaTime;
            if (toastT <= 0f && toasts.Count > 0) { toasts.RemoveAt(0); toastT = 1.5f; }

            // ambient tint stands in for Godot's CanvasModulate
            var cam = Camera.main;
            if (cam != null) cam.backgroundColor = Ambient() * 0.18f;
        }

        void OnGUI()
        {
            var p = player;
            var gm = GameManager.I;
            GUI.color = Color.white;
            var big = new GUIStyle(GUI.skin.label) { fontSize = 18 };
            GUI.Label(new Rect(16, 12, 600, 28), $"HP {Mathf.CeilToInt(p.hp)} / {p.maxHp}    Tinctures {p.potions}    Salt {p.salt}    Coins {p.coins}", big);
            GUI.Label(new Rect(16, 36, 600, 24), $"Dusk {(gm.dusk * 100f):0}%    Enemies {EnemyBase.All.Count}" +
                (p.hasteT > 0 ? $"    SWIFT {Mathf.CeilToInt(p.hasteT)}s" : "") + (p.god ? "    [GOD]" : ""));
            for (int i = 0; i < toasts.Count; i++)
                GUI.Label(new Rect(16, Screen.height - 40 - 22 * (toasts.Count - 1 - i), 900, 22), toasts[i]);
            if (bannerT > 0f)
            {
                var b = new GUIStyle(GUI.skin.label) { fontSize = 34, alignment = TextAnchor.MiddleCenter };
                var s = new GUIStyle(GUI.skin.label) { fontSize = 16, alignment = TextAnchor.MiddleCenter };
                GUI.Label(new Rect(0, Screen.height * 0.28f, Screen.width, 50), banner, b);
                GUI.Label(new Rect(0, Screen.height * 0.28f + 48, Screen.width, 26), bannerSub, s);
            }
            if (gm.state == GameManager.State.Dead)
            {
                var b = new GUIStyle(GUI.skin.label) { fontSize = 40, alignment = TextAnchor.MiddleCenter };
                GUI.Label(new Rect(0, Screen.height * 0.4f, Screen.width, 60), "YOU HAVE FALLEN — press Enter", b);
            }
        }
    }
}

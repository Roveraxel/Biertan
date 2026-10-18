using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using Biertan.Enemies;
using Biertan.Player;

namespace Biertan.Core
{
    /// <summary>
    /// Stand-in HUD until hud.gd is ported: health, tinctures, salt, madness / blood curse, the boss bar
    /// with its hint, the E prompt, banners, toasts, death screen and the village story card.
    /// Scales with screen height so it reads at any Game view size.
    /// </summary>
    public class DebugHud : MonoBehaviour
    {
        readonly List<string> toasts = new();
        string banner = "", bannerSub = "";
        float bannerT, toastT;
        Texture2D px;

        void OnEnable()
        {
            HudEvents.OnToast += OnToast;
            HudEvents.OnBanner += OnBanner;
        }

        void OnDisable()
        {
            HudEvents.OnToast -= OnToast;
            HudEvents.OnBanner -= OnBanner;
        }

        void OnToast(string s) { toasts.Add(s); if (toasts.Count > 4) toasts.RemoveAt(0); toastT = 4f; }
        void OnBanner(string s, string sub) { banner = s; bannerSub = sub; bannerT = 3.5f; }

        void Update()
        {
            bannerT -= Time.deltaTime;
            toastT -= Time.deltaTime;
            if (toastT <= 0f && toasts.Count > 0) { toasts.RemoveAt(0); toastT = 1.5f; }

            var gm = GameManager.I;
            var kb = Keyboard.current;
            if (gm == null || kb == null) return;
            bool next = kb.enterKey.wasPressedThisFrame || kb.eKey.wasPressedThisFrame || kb.spaceKey.wasPressedThisFrame;
            if (gm.state == GameManager.State.Dead && next) gm.Respawn();
            if (gm.state == GameManager.State.Story && next && gm.storyT > 0.6f) gm.CloseStory();
        }

        void Box(Rect r, Color c)
        {
            if (px == null) { px = new Texture2D(1, 1); px.SetPixel(0, 0, Color.white); px.Apply(); }
            var old = GUI.color; GUI.color = c; GUI.DrawTexture(r, px); GUI.color = old;
        }

        GUIStyle Style(float size, TextAnchor a = TextAnchor.UpperLeft, FontStyle f = FontStyle.Normal) =>
            new(GUI.skin.label) { fontSize = Mathf.RoundToInt(size * Screen.height / 720f), alignment = a, fontStyle = f, wordWrap = true };

        void OnGUI()
        {
            var gm = GameManager.I;
            if (gm == null || gm.player == null) return;
            PlayerController p = gm.player;
            float k = Screen.height / 720f, W = Screen.width, H = Screen.height;

            // health
            Box(new Rect(16 * k, 16 * k, 240 * k, 14 * k), new Color(0, 0, 0, 0.6f));
            Box(new Rect(16 * k, 16 * k, 240 * k * Mathf.Clamp01(p.hp / p.maxHp), 14 * k), new Color32(0xc0, 0x39, 0x2b, 0xff));
            GUI.Label(new Rect(16 * k, 32 * k, 600 * k, 24 * k),
                $"{Mathf.CeilToInt(p.hp)}/{p.maxHp}   Tinctures {p.potions}   Salt {p.salt}   Coins {p.coins}" +
                (p.hasteT > 0 ? $"   SWIFT {Mathf.CeilToInt(p.hasteT)}s" : "") + (p.vampT > 0 ? $"   VAMPIRE {Mathf.CeilToInt(p.vampT)}s" : ""), Style(14));
            float y = 54 * k;
            if (gm.current == "hollow")
            {
                Box(new Rect(16 * k, y, 240 * k, 8 * k), new Color(0, 0, 0, 0.6f));
                Box(new Rect(16 * k, y, 240 * k * Mathf.Clamp01(p.madness / (p.maxHp * 2f)), 8 * k), new Color(0.55f, 0.75f, 0.3f));
                GUI.Label(new Rect(262 * k, y - 6 * k, 200 * k, 20 * k), "madness", Style(12));
                y += 16 * k;
            }
            if (gm.current == "church")
            {
                Box(new Rect(16 * k, y, 240 * k, 8 * k), new Color(0, 0, 0, 0.6f));
                Box(new Rect(16 * k, y, 240 * k * Mathf.Clamp01(p.blood / 5f), 8 * k), new Color(0.6f, 0f, 0.1f));
                GUI.Label(new Rect(262 * k, y - 6 * k, 200 * k, 20 * k), "blood curse", Style(12));
            }

            // boss bar
            if (gm.boss != null && gm.boss.MaxHp > 0f && gm.state == GameManager.State.Play)
            {
                float bw = 640 * k, bx = (W - bw) / 2f, by = H - 70 * k;
                GUI.Label(new Rect(bx, by - 26 * k, bw, 24 * k), gm.boss.HudName(), Style(16, TextAnchor.MiddleCenter, FontStyle.Bold));
                Box(new Rect(bx, by, bw, 12 * k), new Color(0, 0, 0, 0.7f));
                Box(new Rect(bx, by, bw * Mathf.Clamp01(gm.boss.Hp / gm.boss.MaxHp), 12 * k), new Color32(0x9b, 0x1c, 0x1c, 0xff));
                string hint = gm.boss.HudHint();
                if (!string.IsNullOrEmpty(hint)) GUI.Label(new Rect(bx, by + 16 * k, bw, 22 * k), hint, Style(13, TextAnchor.MiddleCenter));
            }

            // E prompt
            var near = gm.state == GameManager.State.Play ? Interactable.Nearest(p.transform.position) : null;
            if (near != null) GUI.Label(new Rect(0, H * 0.62f, W, 26 * k), near.PromptText(), Style(15, TextAnchor.MiddleCenter, FontStyle.Bold));

            for (int i = 0; i < toasts.Count; i++)
                GUI.Label(new Rect(16 * k, H - 130 * k - 22 * k * (toasts.Count - 1 - i), 700 * k, 22 * k), toasts[i], Style(13));

            if (bannerT > 0f)
            {
                GUI.Label(new Rect(0, H * 0.22f, W, 50 * k), banner, Style(32, TextAnchor.MiddleCenter, FontStyle.Bold));
                GUI.Label(new Rect(W * 0.15f, H * 0.22f + 48 * k, W * 0.7f, 40 * k), bannerSub, Style(15, TextAnchor.UpperCenter));
            }

            if (gm.state == GameManager.State.Dead)
            {
                Box(new Rect(0, 0, W, H), new Color(0.15f, 0, 0, 0.5f));
                GUI.Label(new Rect(0, H * 0.4f, W, 60 * k), "YOU HAVE FALLEN", Style(40, TextAnchor.MiddleCenter, FontStyle.Bold));
                GUI.Label(new Rect(0, H * 0.4f + 60 * k, W, 30 * k), "Enter to try again", Style(16, TextAnchor.MiddleCenter));
            }

            if (gm.state == GameManager.State.Story && GameManager.Stories.TryGetValue(gm.storyId, out var card))
                DrawStory(card, gm.storyId, k, W, H);
        }

        void DrawStory(GameManager.StoryCard card, string id, float k, float W, float H)
        {
            Box(new Rect(0, 0, W, H), new Color(0.04f, 0.04f, 0.05f, 1f));
            var photo = Resources.Load<Texture2D>("Photos/" + (id == "biertan" ? "biertan_story" : id));
            float pw = W * 0.5f, ph = H * 0.62f;
            if (photo != null) GUI.DrawTexture(new Rect(W * 0.05f, H * 0.12f, pw, ph), photo, ScaleMode.ScaleAndCrop);
            float tx = W * 0.59f, tw = W * 0.36f;
            GUI.Label(new Rect(tx, H * 0.12f, tw, 50 * k), card.title, Style(34, TextAnchor.UpperLeft, FontStyle.Bold));
            GUI.Label(new Rect(tx, H * 0.12f + 60 * k, tw, H * 0.4f), card.lore, Style(15));
            GUI.Label(new Rect(tx, H * 0.6f, tw, H * 0.2f), card.fact, Style(12, TextAnchor.UpperLeft, FontStyle.Italic));
            GUI.Label(new Rect(0, H * 0.9f, W, 30 * k), "Enter to continue", Style(14, TextAnchor.MiddleCenter));
        }
    }
}

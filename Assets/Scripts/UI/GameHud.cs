using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using Biertan.Core;
using Biertan.Player;

namespace Biertan.UI
{
    /// <summary>
    /// Title screen, in-game HUD, dialogue box, death screen, story cards, bestiary and ending. Port of hud.gd,
    /// drawn with IMGUI like the original's immediate-mode _draw(). Title art uses a 1440×810 design space,
    /// story/bestiary a centred 1280×720 one, the HUD plain screen pixels scaled by height/720.
    /// </summary>
    public class GameHud : MonoBehaviour
    {
        static readonly string[] Items = { "Begin the Hunt", "Continue", "Bestiary", "Settings", "Leave the Valley" };
        const string PromoUrl = "https://www.viatransilvanica.com";

        static readonly Color TextC = new Color32(0xe8, 0xe2, 0xd2, 0xff);
        static readonly Color Muted = new Color32(0x9a, 0x94, 0x86, 0xff);
        static readonly Color Amber = new Color32(0xff, 0xb3, 0x47, 0xff);
        static readonly Color Blood = new Color32(0xb3, 0x1b, 0x22, 0xff);

        readonly List<(string text, float t)> toasts = new();
        string banner = "", bannerSub = "";
        float bannerT, t, msgT, playTime, bestScroll;
        string msg = "";
        int menuIdx, bestIdx;
        bool hasSave;
        GameManager.State lastState = (GameManager.State)(-1);

        Texture2D px, circle, gradient, titlePhoto;
        readonly Dictionary<string, Texture2D> photos = new();
        Dictionary<string, string> credits;
        GUIStyle style;

        void OnEnable()
        {
            HudEvents.OnToast += OnToast;
            HudEvents.OnBanner += OnBanner;
            HudEvents.OnContinueEnabled += OnContinue;
        }

        void OnDisable()
        {
            HudEvents.OnToast -= OnToast;
            HudEvents.OnBanner -= OnBanner;
            HudEvents.OnContinueEnabled -= OnContinue;
        }

        void OnToast(string s) { toasts.Add((s, 4.5f)); if (toasts.Count > 5) toasts.RemoveAt(0); }
        void OnBanner(string s, string sub) { banner = s; bannerSub = sub; bannerT = 3.6f; }
        void OnContinue(bool on) => hasSave = on;

        void Start()
        {
            px = new Texture2D(1, 1); px.SetPixel(0, 0, Color.white); px.Apply();
            var cs = Resources.Load<Sprite>("Sprites/circle");
            circle = cs != null ? cs.texture : px;
            // the left-hand shade behind the title text
            gradient = new Texture2D(64, 1) { wrapMode = TextureWrapMode.Clamp };
            for (int i = 0; i < 64; i++) gradient.SetPixel(i, 0, new Color(0.02f, 0.02f, 0.03f, 0.88f * (1f - i / 63f)));
            gradient.Apply();
            titlePhoto = Resources.Load<Texture2D>("Photos/title_biertan");
            var cj = Resources.Load<TextAsset>("Photos/credits");
            credits = cj != null ? ParseCredits(cj.text) : new Dictionary<string, string>();
            hasSave = GameManager.I != null && GameManager.I.HasSave();
            if (hasSave) menuIdx = 1;
        }

        /// <summary>credits.json → "Photo: artist · license · Wikimedia Commons" per photo id.</summary>
        static Dictionary<string, string> ParseCredits(string json)
        {
            var d = new Dictionary<string, string>();
            foreach (var block in json.Split('}'))
            {
                int q = block.IndexOf('"');
                if (q < 0) continue;
                int q2 = block.IndexOf('"', q + 1);
                string id = block.Substring(q + 1, q2 - q - 1);
                d[id] = $"Photo: {Field(block, "artist")} · {Field(block, "license")} · Wikimedia Commons";
            }
            return d;
        }

        static string Field(string block, string key)
        {
            int i = block.IndexOf("\"" + key + "\"");
            if (i < 0) return "?";
            int a = block.IndexOf('"', block.IndexOf(':', i) + 1), b = block.IndexOf('"', a + 1);
            return block.Substring(a + 1, b - a - 1);
        }

        // ------------------------------------------------------------- input and timers

        void Update()
        {
            float dt = Time.deltaTime;
            t += dt;
            MakeLinearCopies();
            msgT = Mathf.Max(0f, msgT - dt);
            bannerT = Mathf.Max(0f, bannerT - dt);
            for (int i = toasts.Count - 1; i >= 0; i--)
            {
                toasts[i] = (toasts[i].text, toasts[i].t - dt);
                if (toasts[i].t <= 0f) toasts.RemoveAt(i);
            }
            var gm = GameManager.I;
            if (gm == null) return;
            if (gm.state != lastState)
            {
                if (gm.state == GameManager.State.Title) { hasSave = gm.HasSave(); toasts.Clear(); bannerT = 0f; }
                lastState = gm.state;
            }
            if (gm.state != GameManager.State.Title && gm.state != GameManager.State.Bestiary) playTime += dt;

            var kb = Keyboard.current;
            if (kb == null) return;
            bool next = kb.enterKey.wasPressedThisFrame || kb.eKey.wasPressedThisFrame || kb.spaceKey.wasPressedThisFrame;
            switch (gm.state)
            {
                case GameManager.State.Title:
                    if (kb.downArrowKey.wasPressedThisFrame || kb.sKey.wasPressedThisFrame) menuIdx = (menuIdx + 1) % Items.Length;
                    if (kb.upArrowKey.wasPressedThisFrame || kb.wKey.wasPressedThisFrame) menuIdx = (menuIdx + Items.Length - 1) % Items.Length;
                    if (next) Activate(menuIdx);
                    break;
                case GameManager.State.Bestiary:
                    int n = BestiaryData.Entries.Length;
                    if (kb.downArrowKey.wasPressedThisFrame || kb.sKey.wasPressedThisFrame) bestIdx = (bestIdx + 1) % n;
                    if (kb.upArrowKey.wasPressedThisFrame || kb.wKey.wasPressedThisFrame) bestIdx = (bestIdx + n - 1) % n;
                    if (kb.escapeKey.wasPressedThisFrame || kb.backspaceKey.wasPressedThisFrame || kb.qKey.wasPressedThisFrame) gm.state = GameManager.State.Title;
                    var ms = Mouse.current;
                    if (ms != null && ms.scroll.ReadValue().y != 0f) bestIdx = Mathf.Clamp(bestIdx + (ms.scroll.ReadValue().y < 0f ? 1 : -1), 0, n - 1);
                    break;
                case GameManager.State.Dead:
                    if (next) gm.Respawn();
                    break;
                case GameManager.State.Dialogue:
                    if (next && Time.frameCount > gm.dlgFrame) gm.AdvanceDialogue();
                    break;
                case GameManager.State.Story:
                    if (gm.storyT > 1.5f && kb.anyKey.wasPressedThisFrame) gm.CloseStory();
                    break;
                case GameManager.State.Ending:
                    if (gm.endingT > 4f && kb.anyKey.wasPressedThisFrame) gm.LeaveEnding();
                    break;
            }
        }

        public void Activate(int i)
        {
            var gm = GameManager.I;
            bool enabled = i switch { 1 => hasSave, 3 => false, _ => true };
            if (!enabled) { msg = $"{Items[i]} is not yet part of this tale."; msgT = 2.5f; return; }
            switch (i)
            {
                case 0: playTime = 0f; gm.StartGame(); break;
                case 1: playTime = 0f; gm.ContinueGame(); break;
                case 2: gm.state = GameManager.State.Bestiary; bestIdx = 0; break;
                case 4:
#if UNITY_EDITOR
                    msg = "Stop Play mode to leave the valley."; msgT = 2.5f;
#else
                    Application.Quit();
#endif
                    break;
            }
        }

        // ------------------------------------------------------------- drawing helpers

        // The project renders in linear colour space, where IMGUI neither decodes sRGB textures nor treats GUI
        // colours as gamma values, so everything came out washed. Colours go through L(); textures are copied
        // once into a linear render texture by Lin().
        static Color L(Color c) => QualitySettings.activeColorSpace == ColorSpace.Linear ? c.linear : c;
        readonly Dictionary<Texture, Texture> linear = new();

        readonly List<Texture2D> pending = new();

        /// <summary>The linear copy of a texture, or null on the first frame it is asked for: the copy is made in
        /// Update, since blitting inside the GUI pass corrupts it.</summary>
        Texture Lin(Texture2D src)
        {
            if (src == null || QualitySettings.activeColorSpace != ColorSpace.Linear) return src;
            if (linear.TryGetValue(src, out var done)) return done;
            if (!pending.Contains(src)) pending.Add(src);
            return null;
        }

        static float[] toLinear;

        void MakeLinearCopies()
        {
            if (pending.Count == 0) return;
            if (toLinear == null)
            {
                toLinear = new float[256];
                for (int i = 0; i < 256; i++) toLinear[i] = Mathf.GammaToLinearSpace(i / 255f);
            }
            var prev = RenderTexture.active;
            foreach (var src in pending)
            {
                // copy the raw texels out through a render texture (the source need not be readable),
                // then decode sRGB on the CPU into a linear texture IMGUI can show as-is
                var rt = RenderTexture.GetTemporary(src.width, src.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
                Graphics.Blit(src, rt);
                RenderTexture.active = rt;
                var raw = new Texture2D(src.width, src.height, TextureFormat.RGBA32, false, true);
                raw.ReadPixels(new Rect(0, 0, src.width, src.height), 0, 0);
                var px32 = raw.GetPixels32();
                Destroy(raw);
                var cols = new Color[px32.Length];
                for (int i = 0; i < px32.Length; i++)
                {
                    var c = px32[i];
                    cols[i] = new Color(toLinear[c.r], toLinear[c.g], toLinear[c.b], c.a / 255f);
                }
                // half floats: dark photo tones would band at 8 bits once linear
                var copy = new Texture2D(src.width, src.height, TextureFormat.RGBAHalf, false, true) { filterMode = FilterMode.Bilinear };
                copy.SetPixels(cols);
                copy.Apply();
                RenderTexture.ReleaseTemporary(rt);
                linear[src] = copy;
            }
            RenderTexture.active = prev;
            pending.Clear();
        }

        GUIStyle S(float size, TextAnchor a, FontStyle f = FontStyle.Normal, bool wrap = false)
        {
            style ??= new GUIStyle(GUI.skin.label) { richText = false };
            style.fontSize = Mathf.Max(6, Mathf.RoundToInt(size));
            style.alignment = a; style.fontStyle = f; style.wordWrap = wrap;
            style.clipping = TextClipping.Overflow;
            return style;
        }

        /// <summary>Text with a dark outline, like hud.gd txt().</summary>
        void Txt(Rect r, string s, float size, Color c, TextAnchor a = TextAnchor.UpperLeft, FontStyle f = FontStyle.Normal, bool wrap = false)
        {
            if (string.IsNullOrEmpty(s) || c.a <= 0f) return;
            var st = S(size, a, f, wrap);
            float o = Mathf.Max(1f, size / 30f);
            st.normal.textColor = new Color(0, 0, 0, c.a * 0.85f);
            foreach (var d in new[] { new Vector2(o, o), new Vector2(-o, o), new Vector2(o, -o), new Vector2(-o, -o) })
                GUI.Label(new Rect(r.x + d.x, r.y + d.y, r.width, r.height), s, st);
            st.normal.textColor = L(c);
            GUI.Label(r, s, st);
        }

        void Box(Rect r, Color c) { var old = GUI.color; GUI.color = L(c); GUI.DrawTexture(r, px); GUI.color = old; }
        void Frame(Rect r, Color c, float w)
        {
            Box(new Rect(r.x, r.y, r.width, w), c); Box(new Rect(r.x, r.yMax - w, r.width, w), c);
            Box(new Rect(r.x, r.y, w, r.height), c); Box(new Rect(r.xMax - w, r.y, w, r.height), c);
        }
        void Disc(Vector2 c, float r, Color col) { var old = GUI.color; GUI.color = L(col); GUI.DrawTexture(new Rect(c.x - r, c.y - r, r * 2f, r * 2f), circle); GUI.color = old; }

        void Bar(Rect r, float frac, Color col, float k)
        {
            float g = 2f * k;
            Box(new Rect(r.x - g, r.y - g, r.width + 2 * g, r.height + 2 * g), new Color(0, 0, 0, 0.75f));
            Box(r, new Color(0.12f, 0.1f, 0.1f, 0.9f));
            Box(new Rect(r.x, r.y, r.width * Mathf.Clamp01(frac), r.height), col);
            Frame(new Rect(r.x - g, r.y - g, r.width + 2 * g, r.height + 2 * g), Amber * 0.55f + new Color(0, 0, 0, 0.45f), 1.5f * k);
        }

        Texture2D Photo(string id)
        {
            if (!photos.TryGetValue(id, out var tex)) photos[id] = tex = Resources.Load<Texture2D>("Photos/" + id);
            return tex;
        }

        // ------------------------------------------------------------- draw

        void OnGUI()
        {
            var gm = GameManager.I;
            if (gm == null) return;
            GUI.depth = -10;
            switch (gm.state)
            {
                case GameManager.State.Title: DrawTitle(); break;
                case GameManager.State.Bestiary: DrawBestiary(); break;
                case GameManager.State.Story: DrawStory(gm); break;
                case GameManager.State.Ending: DrawEnding(gm.endingT); break;
                default: if (gm.player != null) DrawHud(gm, gm.player); break;
            }
        }

        void DrawTitle()
        {
            float W = Screen.width, H = Screen.height, s = W / 1440f;
            float oy = (H - 810f * s) / 2f; // letterbox when the window is taller than 16:9
            Box(new Rect(0, 0, W, H), new Color(0.02f, 0.02f, 0.03f));
            Rect D(float x, float y, float w, float h) => new(x * s, oy + y * s, w * s, h * s);
            var tp = Lin(titlePhoto); if (tp != null) GUI.DrawTexture(D(0, 0, 1440, 810), tp, ScaleMode.ScaleAndCrop);
            // the blood moon over Biertan
            for (int i = 0; i < 8; i++) Disc(new Vector2(1150 * s, oy + 150 * s), (300 - i * 32) * s, new Color(Blood.r, Blood.g, Blood.b, 0.02f));
            Disc(new Vector2(1150 * s, oy + 150 * s), 84 * s, new Color(Blood.r, Blood.g, Blood.b, 0.9f));
            Disc(new Vector2(1124 * s, oy + 128 * s), 16 * s, new Color(0, 0, 0, 0.12f));
            Disc(new Vector2(1172 * s, oy + 178 * s), 12 * s, new Color(0, 0, 0, 0.12f));
            Disc(new Vector2(1180 * s, oy + 120 * s), 7 * s, new Color(0, 0, 0, 0.12f));
            float flp = 0.55f + 0.25f * Mathf.Sin(t * 4f);
            foreach (var r in new[] { new Rect(774, 640, 8, 20), new Rect(828, 640, 8, 20), new Rect(1240, 600, 6, 14), new Rect(1335, 470, 6, 10) })
                Box(D(r.x, r.y, r.width, r.height), new Color(Amber.r, Amber.g, Amber.b, flp));
            // drifting mist
            for (int m = 0; m < 2; m++)
            {
                float my = m == 0 ? 520f : 600f, sp = m == 0 ? 0.16f : 0.12f, ph = m == 0 ? 0f : 1.7f;
                float mx = 720f + Mathf.Sin(t * sp + ph) * 80f;
                var old = GUI.color; GUI.color = L(new Color(0.59f, 0.63f, 0.69f, 0.03f));
                GUI.DrawTexture(D(mx - 820f, my + 120f - 140f, 1640f, 280f), circle);
                GUI.color = old;
            }
            GUI.DrawTexture(D(0, 0, 760, 810), gradient);

            Txt(D(96, 228, 900, 30), "Anno MDXXI · Siebenbürgen", 20 * s, Muted * 0.85f + new Color(0, 0, 0, 0.15f));
            Txt(D(88, 250, 1000, 150), "Biertan", 132 * s, TextC);
            Txt(D(96, 396, 900, 40), "A Hunter’s Ballad of Transylvania", 28 * s, Muted);

            var mouse = Event.current.mousePosition;
            for (int i = 0; i < Items.Length; i++)
            {
                var r = D(88, 462 + i * 56, 520, 52);
                bool enabled = i switch { 1 => hasSave, 3 => false, _ => true };
                if (r.Contains(mouse))
                {
                    if (Event.current.type == EventType.MouseMove || Event.current.type == EventType.Repaint) menuIdx = i;
                    if (Event.current.type == EventType.MouseDown && Event.current.button == 0) { menuIdx = i; Activate(i); Event.current.Use(); }
                }
                bool sel = i == menuIdx;
                var col = sel ? TextC : Muted;
                if (!enabled) col.a = 0.45f;
                float off = sel ? 6f : 0f;
                if (sel)
                {
                    var old = GUI.color; GUI.color = L(Blood);
                    var c = new Vector2(r.x + 16 * s, r.y + r.height / 2f);
                    GUIUtility.RotateAroundPivot(45f, c);
                    GUI.DrawTexture(new Rect(c.x - 5.5f * s, c.y - 5.5f * s, 11 * s, 11 * s), px);
                    GUI.matrix = Matrix4x4.identity;
                    GUI.color = old;
                }
                Txt(new Rect(r.x + (40 + off) * s, r.y + 6 * s, r.width, r.height), Items[i], 32 * s, col);
            }
            Txt(D(96, 770, 900, 26), "Salt for the dead. Silver for what walks.", 18 * s, Muted * 0.7f + new Color(0, 0, 0, 0.3f));
            Txt(D(644, 772, 700, 24), "WASD move · Mouse attack · Space dodge · E interact · Q tincture", 15 * s, Muted * 0.65f + new Color(0, 0, 0, 0.35f), TextAnchor.UpperRight);
            if (msgT > 0f) Txt(D(96, 738, 900, 28), msg, 20 * s, new Color(Amber.r, Amber.g, Amber.b, Mathf.Min(1f, msgT)));
        }

        static string QuestLine(GameManager gm)
        {
            if (gm.current == "sighisoara") return Biertan.Levels.SighisoaraTutorial.Objective();
            string q = gm.quest switch
            {
                0 => "Speak with Frau Anna at the inn.",
                1 => "Quest: Where the Sheep Went. Slay the beast of the Wolf Forest.",
                2 => "Return to Frau Anna with the Silver Thread.",
                _ => "Level 1 complete. Take the east gate to Richiș.",
            };
            if (gm.visitedRichis)
                q = gm.quest2 switch
                {
                    0 => "Speak with the pastor of Richiș.",
                    1 => gm.metVasile ? "Quest: The Singing Children. Find Muma Pădurii's Hollow beyond the Salt Caves." : "Quest: The Singing Children. Cross the Hollow Hills and the Salt Caves.",
                    2 => "Return to the pastor of Richiș.",
                    _ => "Level 2 complete. Take Richiș's east gate to Moșna.",
                };
            if (gm.visitedMosna)
                q = gm.quest3 switch
                {
                    0 => "Speak with Meister Konrad, the bell-founder.",
                    1 => "Quest: The Road to Biertan. Slay the Balaur in the drowned quarry.",
                    2 => "Return to Meister Konrad in Moșna.",
                    _ => "Level 3 complete. Take Moșna's east gate to Biertan.",
                };
            if (gm.visitedBiertan)
                q = gm.quest4 switch
                {
                    0 => "Speak with the sexton at the Marriage Prison.",
                    1 => "Quest: The Bells of Biertan. Break the blood wards and destroy Strigoi Vlad.",
                    _ => "The bells of Biertan ring again.",
                };
            return q;
        }

        void DrawHud(GameManager gm, PlayerController p)
        {
            float k = Screen.height / 720f, W = Screen.width, H = Screen.height;
            Rect R(float x, float y, float w, float h) => new(x * k, y * k, w * k, h * k);
            if (p.hurtFlash > 0f) Box(new Rect(0, 0, W, H), new Color(0.7f, 0.05f, 0.05f, p.hurtFlash * 0.8f));
            if (gm.current == "hollow" && p.madness > p.maxHp)
            {
                float mk = (p.madness - p.maxHp) / p.maxHp;
                Box(new Rect(0, 0, W, H), new Color(0.3f, 0.1f, 0.4f, Mathf.Max(0f, 0.12f * mk + 0.05f * mk * Mathf.Sin(t * 5f))));
            }
            if (p.vampT > 0f) Box(new Rect(0, 0, W, H), new Color(0.4f, 0f, 0.05f, 0.12f));

            Bar(R(24, 24, 250, 18), p.hp / p.maxHp, new Color32(0xb3, 0x37, 0x2f, 0xff), k);
            Txt(R(30, 24, 250, 18), $"HEALTH  {(int)p.hp} / {(int)p.maxHp}", 13 * k, TextC, TextAnchor.MiddleLeft);
            var sub = R(24, 54, 250, 8);
            var subLabel = R(284, 50, 400, 16);
            switch (gm.current)
            {
                case "forest": case "hills": case "vineyard":
                    Bar(sub, gm.dusk, Color.Lerp(new Color32(0x5a, 0x6a, 0xa8, 0xff), new Color32(0xe8, 0xa9, 0x4a, 0xff), 1f - gm.dusk), k);
                    Txt(subLabel, gm.dusk < 0.85f ? "DUSK" : (gm.dusk < 1f ? "NIGHT FALLS" : "MIDNIGHT"), 12 * k, gm.dusk < 0.85f ? TextC : Blood, TextAnchor.MiddleLeft);
                    break;
                case "hollow":
                    float cap = p.maxHp * 2f;
                    Bar(sub, p.madness / cap, new Color32(0x7a, 0x4a, 0xa8, 0xff), k);
                    Txt(subLabel, p.madness < cap * 0.75f ? "MADNESS" : "THE WOOD WHISPERS", 12 * k, new Color32(0xb0, 0x8a, 0xd8, 0xff), TextAnchor.MiddleLeft);
                    break;
                case "church":
                    if (p.vampT > 0f)
                    {
                        Bar(sub, p.vampT / 18f, new Color32(0x8a, 0x0a, 0x14, 0xff), k);
                        Txt(subLabel, "VAMPIRE  (tinctures burn)", 12 * k, Blood, TextAnchor.MiddleLeft);
                    }
                    else
                    {
                        Bar(sub, p.blood / 5f, new Color32(0x8a, 0x0a, 0x14, 0xff), k);
                        Txt(subLabel, "BLOOD CURSE", 12 * k, new Color32(0xd0, 0x70, 0x70, 0xff), TextAnchor.MiddleLeft);
                    }
                    break;
                case "hub": case "richis": case "mosna": case "biertan": case "sighisoara":
                    Txt(R(24, 50, 300, 16), "SAFE HAVEN", 12 * k, Amber, TextAnchor.MiddleLeft);
                    break;
            }
            if (p.hasteT > 0f) Txt(R(284, 24, 200, 18), $"SWIFT {(int)p.hasteT}s", 12 * k, new Color(0.7f, 0.9f, 0.6f), TextAnchor.MiddleLeft);
            string inv = $"Coins {p.coins}      Tinctures {p.potions}  (Q)";
            if (p.saltUnlocked) inv += $"      Salt {p.salt}  (R)";
            Txt(R(24, 74, 800, 20), inv, 14 * k, Amber);
            Txt(R(24, 96, 900, 20), QuestLine(gm), 14 * k, Muted);

            for (int i = 0; i < toasts.Count; i++)
                Txt(new Rect(W - 784 * k, (28 + i * 26) * k, 760 * k, 24 * k), toasts[i].text, 15 * k, new Color(TextC.r, TextC.g, TextC.b, Mathf.Min(1f, toasts[i].t)), TextAnchor.UpperRight);
            if (bannerT > 0f)
            {
                float a = Mathf.Min(1f, bannerT) * Mathf.Min(1f, (3.6f - bannerT) * 3f);
                Txt(new Rect(0, 112 * k, W, 50 * k), banner, 44 * k, new Color(TextC.r, TextC.g, TextC.b, a), TextAnchor.MiddleCenter);
                Txt(new Rect(0, 164 * k, W, 30 * k), bannerSub, 18 * k, new Color(Muted.r, Muted.g, Muted.b, a), TextAnchor.MiddleCenter);
            }

            var bs = gm.boss;
            if (bs != null && !(bs is Object uo && uo == null) && bs.MaxHp > 0f)
            {
                var r = new Rect(W / 2f - 280 * k, 60 * k, 560 * k, 14 * k);
                Bar(r, bs.Hp / bs.MaxHp, new Color32(0xb3, 0x37, 0x2f, 0xff), k);
                Box(new Rect(r.x + r.width * 0.33f - k, r.y, 2 * k, r.height), Color.black);
                Box(new Rect(r.x + r.width * 0.66f - k, r.y, 2 * k, r.height), Color.black);
                Txt(new Rect(0, 34 * k, W, 22 * k), bs.HudName(), 18 * k, TextC, TextAnchor.MiddleCenter);
                string hint = bs.HudHint();
                if (!string.IsNullOrEmpty(hint)) Txt(new Rect(0, 82 * k, W, 22 * k), hint, 14 * k, Amber, TextAnchor.MiddleCenter);
            }

            if (gm.state == GameManager.State.Play)
            {
                var near = Interactable.Nearest(p.transform.position);
                if (near != null) Txt(new Rect(0, H - 92 * k, W, 30 * k), near.PromptText(), 20 * k, Amber, TextAnchor.MiddleCenter);
            }

            if (gm.state == GameManager.State.Dialogue && gm.dlgIdx < gm.dlgLines.Count)
            {
                var r = new Rect(150 * k, H - 210 * k, W - 300 * k, 170 * k);
                Box(r, new Color(0.03f, 0.03f, 0.05f, 0.92f));
                Frame(r, Amber * 0.7f + new Color(0, 0, 0, 0.3f), 2f * k);
                Txt(new Rect(r.x + 24 * k, r.y + 14 * k, r.width - 48 * k, 26 * k), gm.dlgSpeaker, 20 * k, Amber);
                Txt(new Rect(r.x + 24 * k, r.y + 48 * k, r.width - 48 * k, r.height - 70 * k), gm.dlgLines[gm.dlgIdx], 19 * k, TextC, TextAnchor.UpperLeft, FontStyle.Normal, true);
                Txt(new Rect(r.xMax - 224 * k, r.yMax - 28 * k, 200 * k, 20 * k), $"{gm.dlgIdx + 1}/{gm.dlgLines.Count}   E / Enter  >", 14 * k, Muted, TextAnchor.MiddleRight);
            }

            if (gm.state == GameManager.State.Dead)
            {
                Box(new Rect(0, 0, W, H), new Color(0.1f, 0f, 0f, 0.6f));
                Txt(new Rect(0, H / 2f - 50 * k, W, 64 * k), "YOU HAVE FALLEN", 56 * k, Blood, TextAnchor.MiddleCenter);
                Txt(new Rect(0, H / 2f + 20 * k, W, 30 * k), "Press E to rise again in " + gm.HomeName(), 20 * k, Muted, TextAnchor.MiddleCenter);
            }

            if (playTime < 25f && gm.state != GameManager.State.Dead)
                Txt(new Rect(24 * k, H - 40 * k, W, 20 * k), "WASD move · Mouse aim + click attack · Space dodge · E interact · Q tincture", 14 * k,
                    new Color(Muted.r, Muted.g, Muted.b, Mathf.Clamp01(25f - playTime)));
        }

        void DrawStory(GameManager gm)
        {
            float W = Screen.width, H = Screen.height;
            Box(new Rect(0, 0, W, H), new Color(0.02f, 0.02f, 0.03f));
            if (!GameManager.Stories.TryGetValue(gm.storyId ?? "", out var card)) return;
            float s = Mathf.Min(W / 1280f, H / 720f), ox = (W - 1280f * s) / 2f, oy = (H - 720f * s) / 2f;
            Rect D(float x, float y, float w, float h) => new(ox + x * s, oy + y * s, w * s, h * s);
            float e = Mathf.Max(gm.storyT, 0f);
            string id = gm.storyId;
            bool own = id == "biertan";
            var tex = Photo(own ? "biertan_story" : id);
            var frame = D(60, 90, 640, 480);
            Box(D(52, 82, 656, 496), new Color32(0x3a, 0x2e, 0x20, 0xff));
            if (tex != null)
            {
                var old = GUI.color; GUI.color = new Color(1, 1, 1, Mathf.Clamp01(e));
                if ((float)tex.width / tex.height < 1.1f)
                {
                    Box(frame, new Color32(0x14, 0x11, 0x0e, 0xff));
                    var lt = Lin(tex); if (lt != null) GUI.DrawTexture(frame, lt, ScaleMode.ScaleToFit);
                }
                else { var lt = Lin(tex); if (lt != null) GUI.DrawTexture(frame, lt, ScaleMode.ScaleAndCrop); }
                GUI.color = old;
                if (!own && credits.TryGetValue(id, out var credit))
                    Txt(D(60, 584, 640, 20), credit, 12 * s, new Color(Muted.r, Muted.g, Muted.b, 0.6f));
            }
            else Box(frame, new Color32(0x1a, 0x2a, 0x3a, 0xff));
            float a = Mathf.Clamp01(e - 0.5f);
            Txt(D(750, 100, 480, 56), card.title, 44 * s, new Color(TextC.r, TextC.g, TextC.b, a));
            Box(D(752, 166, 248, 2), new Color(Amber.r, Amber.g, Amber.b, a * 0.7f));
            Txt(D(750, 190, 470, 230), card.lore, 19 * s, new Color(TextC.r, TextC.g, TextC.b, Mathf.Clamp01(e - 1f)), TextAnchor.UpperLeft, FontStyle.Normal, true);
            Txt(D(750, 424, 470, 150), card.fact, 15 * s, new Color(Amber.r, Amber.g, Amber.b, Mathf.Clamp01(e - 2f) * 0.85f), TextAnchor.UpperLeft, FontStyle.Normal, true);
            if (e > 1.5f) Txt(D(0, 666, 1280, 24), "Press any key to continue", 15 * s, new Color(Muted.r, Muted.g, Muted.b, 0.5f + 0.5f * Mathf.Sin(t * 3f)), TextAnchor.MiddleCenter);
        }

        void DrawBestiary()
        {
            float W = Screen.width, H = Screen.height;
            Box(new Rect(0, 0, W, H), new Color32(0x0a, 0x0a, 0x10, 0xff));
            float s = Mathf.Min(W / 1280f, H / 720f), ox = (W - 1280f * s) / 2f, oy = (H - 720f * s) / 2f;
            Rect D(float x, float y, float w, float h) => new(ox + x * s, oy + y * s, w * s, h * s);
            var entries = BestiaryData.Entries;
            float target = Mathf.Clamp(bestIdx * 30f - 260f, 0f, Mathf.Max(0f, entries.Length * 30f - 560f));
            bestScroll = Mathf.Lerp(bestScroll, target, 0.2f);
            Txt(D(60, 38, 400, 44), "BESTIARY", 36 * s, TextC);
            Txt(D(60, 82, 400, 20), "of the road to Biertan", 15 * s, Muted * 0.8f + new Color(0, 0, 0, 0.2f));
            var ev = Event.current;
            bool click = ev.type == EventType.MouseDown && ev.button == 0;
            for (int i = 0; i < entries.Length; i++)
            {
                float y = 120 + i * 30 - bestScroll;
                if (y < 100 || y + 28 > 700) continue;
                var r = D(60, y, 330, 28);
                if (click && r.Contains(ev.mousePosition)) { bestIdx = i; ev.Use(); }
                bool sel = i == bestIdx;
                if (sel) Box(r, new Color(Blood.r, Blood.g, Blood.b, 0.35f));
                Txt(D(72, y + 4, 240, 22), entries[i].name, 16 * s, sel ? TextC : Muted);
                Txt(D(290, y + 7, 92, 20), entries[i].kind, 11 * s, new Color(Amber.r, Amber.g, Amber.b, 0.6f), TextAnchor.UpperRight);
            }
            var cur = entries[bestIdx];
            var panel = D(430, 100, 800, 590);
            Box(panel, new Color(0.05f, 0.05f, 0.08f));
            Frame(panel, new Color(Amber.r, Amber.g, Amber.b, 0.3f), 2f * s);
            if (cur.img != "")
            {
                var sp = Resources.Load<Sprite>("Sprites/" + cur.img);
                if (sp != null)
                {
                    var tr = sp.textureRect;
                    float kk = Mathf.Min(220f / tr.width, 200f / tr.height);
                    var tex = sp.texture;
                    var lt = Lin(tex);
                    if (lt != null) GUI.DrawTextureWithTexCoords(D(460, 130, tr.width * kk, tr.height * kk), lt,
                        new Rect(tr.x / tex.width, tr.y / tex.height, tr.width / tex.width, tr.height / tex.height));
                }
            }
            if (cur.kind == "Trail") // a Via Transilvanica milestone
            {
                Box(D(520, 150, 70, 150), new Color32(0x8d, 0x87, 0x7a, 0xff));
                Box(D(520, 290, 70, 12), new Color32(0x5d, 0x58, 0x4f, 0xff));
                Txt(D(520, 186, 70, 34), "VT", 30 * s, new Color32(0x2a, 0x3a, 0x6a, 0xff), TextAnchor.MiddleCenter);
                Box(D(535, 229, 40, 3), new Color32(0xc9, 0xa2, 0x4a, 0xff));
            }
            Txt(D(700, 124, 520, 40), cur.name, 30 * s, TextC);
            Txt(D(700, 172, 520, 24), cur.ro, 17 * s, Amber);
            Txt(D(700, 206, 520, 18), cur.kind.ToUpperInvariant(), 12 * s, Muted * 0.8f + new Color(0, 0, 0, 0.2f));
            Txt(D(460, 350, 740, 240), cur.lore, 17 * s, TextC, TextAnchor.UpperLeft, FontStyle.Normal, true);
            Box(D(460, 600, 740, 1), new Color(Amber.r, Amber.g, Amber.b, 0.25f));
            Txt(D(460, 610, 640, 70), cur.tip, 15 * s, new Color(Amber.r, Amber.g, Amber.b, 0.9f), TextAnchor.UpperLeft, FontStyle.Normal, true);

            // Via Transilvanica promo
            var pr = D(470, 22, 620, 62);
            Box(pr, new Color(0.12f, 0.2f, 0.12f, 0.85f));
            Frame(pr, new Color(0.55f, 0.8f, 0.45f, 0.6f + 0.2f * Mathf.Sin(t * 2f)), 2f * s);
            Txt(D(486, 30, 600, 24), "Hunt the creatures of Biertan yourself?", 17 * s, TextC);
            Txt(D(486, 56, 600, 20), "Plan your hunt on the Via Transilvanica  ·  viatransilvanica.com  >", 14 * s, new Color(0.7f, 0.9f, 0.6f));
            if (click && pr.Contains(ev.mousePosition)) { Application.OpenURL(PromoUrl); ev.Use(); }
            var back = D(1110, 30, 140, 46);
            Box(back, new Color(Blood.r, Blood.g, Blood.b, 0.4f));
            Txt(back, "BACK", 18 * s, TextC, TextAnchor.MiddleCenter);
            if (click && back.Contains(ev.mousePosition)) { GameManager.I.state = GameManager.State.Title; ev.Use(); }
        }

        static readonly (string text, int size, int tone)[] EndingLines =
        {
            ("THE BELLS OF BIERTAN", 52, 0), ("", 18, 1),
            ("At dawn the great bell rang over the valley, and the Iele stopped their dancing.", 20, 1),
            ("In Saschiz, Frau Anna's sheep came home. In Richiș, the children sang in church, and only there.", 20, 1),
            ("In Moșna, the carters took the Biertan road. In the vineyards, the dead lay still.", 20, 1),
            ("And in the Marriage Prison, Andreas and Sofia asked the council for one more week.", 20, 1),
            ("", 18, 1), ("Salt for the dead. Silver for what walks.", 22, 2), ("", 18, 1),
            ("BIERTAN · A Hunter's Ballad of Transylvania", 16, 3),
            ("Made with Unity · Textures: Poly Haven (CC0) · Sounds: Kenney (CC0)", 14, 4),
            ("Music by Kevin MacLeod (incompetech.com), licensed under CC BY 4.0", 14, 4),
        };

        void DrawEnding(float e)
        {
            float k = Screen.height / 720f, W = Screen.width, H = Screen.height;
            Box(new Rect(0, 0, W, H), new Color(0.02f, 0.02f, 0.03f));
            Color[] tones = { TextC, Muted, Amber, Muted * 0.7f, Muted * 0.6f };
            float y = H * 0.22f;
            for (int i = 0; i < EndingLines.Length; i++)
            {
                var l = EndingLines[i];
                var c = tones[l.tone]; c.a = Mathf.Clamp01(e - i * 0.6f);
                Txt(new Rect(0, y, W, (l.size + 14) * k), l.text, l.size * k, c, TextAnchor.MiddleCenter);
                y += (l.size + 18) * k;
            }
            if (e > 4f)
                Txt(new Rect(0, H - 56 * k, W, 30 * k), "Press any key to return", 16 * k, new Color(Muted.r, Muted.g, Muted.b, 0.5f + 0.5f * Mathf.Sin(t * 3f)), TextAnchor.MiddleCenter);
        }
    }
}

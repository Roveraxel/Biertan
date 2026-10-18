using UnityEngine;
using UnityEngine.Rendering;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>
    /// A solid rectangular structure (wall, house, tower, church, ruin, rock, pew) in the game's ¾ view:
    /// a front face of height h with the roof/top lifted above it. Origin is the bottom-centre of the
    /// footprint so depth sorting works. Port of block.gd.
    /// </summary>
    public class Block : MonoBehaviour
    {
        public string style = "wall";
        public Vector2 footprint;   // w, d in Godot pixels
        public float h = 18f;

        static readonly Color Amber = new Color32(0xff, 0xb3, 0x47, 0xff);

        public void Build()
        {
            gameObject.layer = LayerMask.NameToLayer("World");
            var col = gameObject.AddComponent<BoxCollider2D>();
            col.size = footprint;
            col.offset = new Vector2(0, footprint.y / 2f);
            gameObject.isStatic = true;
            if (style == "hidden") return;
            gameObject.AddComponent<SortingGroup>();
            if (style == "vine") { BuildVines(); return; }

            float w = footprint.x, d = footprint.y;
            Color top = Hex("8d877a"), face = Hex("5d584f");
            bool windows = false;
            switch (style)
            {
                case "wall": top = Hex("a8a292"); face = Hex("6b665b"); break;
                case "house": top = Hex("8a3a2a"); face = Hex("d8d2c0"); windows = true; break;
                case "church": top = Hex("6e2f25"); face = Hex("e0d9c4"); windows = true; break;
                case "tower": top = Hex("7a2e22"); face = Hex("cfc8b2"); break;
                case "ruin": top = Hex("5d584f"); face = Hex("3a3731"); break;
                case "rock": top = Hex("4a4540"); face = Hex("2c2926"); break;
                case "pew": top = Hex("5a3a24"); face = Hex("3a2416"); break;
            }
            // front face (0..h) and top (h..h+d), painted where a texture exists for the style
            var (faceTex, faceTint, topTex, topTint) = Painted(style);
            Surface("Face", 0, h / 2f, w, h, faceTex, faceTint, face, 0);
            Surface("Top", 0, h + d / 2f, w, d, topTex, topTint, top, 1);
            Rect("Outline", 0, h + d / 2f, w, d, new Color(0, 0, 0, 0.35f), 2, outline: true);
            Rect("Eave", 0, h, w, 2f, new Color(0, 0, 0, 0.35f), 3);

            if (style == "wall" && w > d)
                for (float x = -w / 2f + 10f; x < w / 2f - 6f; x += 24f)
                    Rect("Merlon", x + 6f, d + h + 2f, 12f, 6f, top * 0.9f, 2);
            if (style is "house" or "church")
                Rect("Ridge", 0, d / 2f + h, w, 3f, top * 0.7f, 2);
            if (style == "tower")
            {
                Surface("Roof", 0, h + d / 2f, w - 20f, d - 20f, "tex_k_roof", Grey(0.6f), top * 0.75f, 2);
                var cross = Amber * 0.8f; cross.a = 1f;
                Rect("CrossV", 0, d + h - 27f, 3f, 26f, cross, 3);
                Rect("CrossH", 0, d + h - 24f, 16f, 3f, cross, 3);
            }
            if (style == "rock")
            {
                var r = new System.Random((int)(transform.position.x * 7f - transform.position.y * 13f));
                bool painted = Resources.Load<Sprite>("Sprites/tex_flag") != null; // the texture has its own cracks
                for (int i = 0; i < (painted ? 0 : 5); i++)
                {
                    float px = (float)(r.NextDouble() * (w - 12) - (w / 2 - 6));
                    float py = h + 4f + (float)(r.NextDouble() * (d - 10));
                    var crack = Rect("Crack", px, py, 14f + (float)r.NextDouble() * 14f, 2f, new Color(0.85f, 0.87f, 0.9f, 0.35f), 3);
                    crack.transform.localRotation = Quaternion.Euler(0, 0, (float)(r.NextDouble() * 50 - 25));
                }
                Rect("Base", 0, 2f, w, 4f, new Color(0, 0, 0, 0.3f), 1);
            }
            if (windows && h > 20f)
            {
                int n = Mathf.Max(1, (int)(w / 60f));
                for (int i = 0; i < n; i++)
                {
                    float wx = -w / 2f + (i + 0.5f) * w / n;
                    var win = Rect("Window", wx, h - 8f - h * 0.225f, 8f, h * 0.45f, Amber, 4);
                    win.sharedMaterial = Resources.Load<Material>("LineMat"); // lit from inside: glows at night
                }
            }
        }

        /// <summary>A terrace of dead vines: a dark strip of earth, posts, a wire, and twisted stems with
        /// the odd shrivelled grape (block.gd _draw_vines).</summary>
        void BuildVines()
        {
            float w = footprint.x, d = footprint.y;
            Rect("Earth", 0, d / 2f, w, d, new Color(0.12f, 0.09f, 0.06f, 0.6f), 0);
            for (float x = -w / 2f + 6f; x < w / 2f; x += 40f)
                Rect("Post", x, d / 2f + 15f, 3f, 30f, Hex("3a2a1c"), 1);
            Rect("Wire", 0, d / 2f + 24f, w, 1f, new Color(0.5f, 0.5f, 0.5f, 0.5f), 2);
            int i = 0;
            for (float x = -w / 2f + 16f; x < w / 2f - 6f; x += 20f, i++)
            {
                var c = i % 3 != 0 ? Hex("2a1e14") : Hex("4a2a1a");
                var a = Rect("Stem", x - 3f, d / 2f + 6f, 2.5f, 13f, c, 3); a.transform.localRotation = Quaternion.Euler(0, 0, 25);
                var b = Rect("Stem", x - 1f, d / 2f + 16f, 2.5f, 12f, c, 3); b.transform.localRotation = Quaternion.Euler(0, 0, -40);
                if (i % 4 == 1)
                {
                    var g = Rect("Grape", x + 3f, d / 2f + 18f, 6f, 6f, Hex("3a1a2a"), 4);
                    g.sprite = Resources.Load<Sprite>("Sprites/circle");
                }
            }
        }

        /// <summary>Painted textures per style: (face texture, face tint, top texture, top tint).</summary>
        static (string, Color, string, Color) Painted(string style) => style switch
        {
            "wall" => ("tex_k_stone", Grey(0.78f), "tex_k_stone", Grey(0.95f)),
            "house" => ("tex_k_timber", Grey(0.92f), "tex_k_roof", Grey(0.85f)),
            "church" => ("tex_k_plaster", Grey(0.9f), "tex_k_roofdark", Grey(0.8f)),
            "tower" => ("tex_k_plaster", Grey(0.85f), "tex_k_roof", Grey(0.8f)),
            "ruin" => ("tex_k_ruin", Grey(0.55f), "tex_k_ruin", Grey(0.75f)),
            "stone" => ("tex_k_stone", Grey(0.7f), "tex_k_stone", Grey(0.9f)),
            "rock" => ("tex_flag", new Color(0.38f, 0.35f, 0.32f), "tex_flag", new Color(0.55f, 0.51f, 0.47f)),
            "pew" => ("tex_planks", Grey(0.6f), "tex_planks", Grey(0.8f)),
            _ => (null, Color.white, null, Color.white),
        };

        static Color Grey(float v) => new(v, v, v, 1f);

        /// <summary>A tiled texture over a face, or the flat colour when the texture isn't in the project
        /// (the Kalponic textures are kept out of the public repository).</summary>
        SpriteRenderer Surface(string n, float x, float y, float w, float hh, string tex, Color tint, Color flat, int order)
        {
            var sp = tex != null ? Resources.Load<Sprite>("Sprites/" + tex) : null;
            if (sp == null) return Rect(n, x, y, w, hh, flat, order);
            var go = new GameObject(n);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = new Vector3(x, y, 0);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = sp;
            sr.drawMode = SpriteDrawMode.Tiled;
            sr.tileMode = SpriteTileMode.Continuous;
            sr.size = new Vector2(w, hh);
            sr.color = tint; sr.sortingOrder = order;
            return sr;
        }

        SpriteRenderer Rect(string n, float x, float y, float w, float hh, Color c, int order, bool outline = false)
        {
            if (outline)
            {
                // four thin strips
                Rect(n, x, y + hh / 2f - 1f, w, 2f, c, order);
                Rect(n, x, y - hh / 2f + 1f, w, 2f, c, order);
                Rect(n, x - w / 2f + 1f, y, 2f, hh, c, order);
                return Rect(n, x + w / 2f - 1f, y, 2f, hh, c, order);
            }
            var go = new GameObject(n);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = new Vector3(x, y, 0);
            go.transform.localScale = new Vector3(w, hh, 1);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/white");
            sr.color = c; sr.sortingOrder = order;
            return sr;
        }

        static Color Hex(string h) { ColorUtility.TryParseHtmlString("#" + h, out var c); return c; }
    }
}

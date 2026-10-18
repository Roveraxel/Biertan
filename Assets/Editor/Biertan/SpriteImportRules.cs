using System.IO;
using UnityEditor;
using UnityEngine;

namespace Biertan.EditorTools
{
    /// <summary>
    /// Imports every PNG under Resources/Sprites as a Sprite with the same on-screen size
    /// and anchor point the Godot build used (its draw_texture_rect rects), so 1 unit = 1 Godot pixel.
    /// </summary>
    public class SpriteImportRules : AssetPostprocessor
    {
        // prefix -> (drawn width, rect x0, rect y0, drawn height), copied from the GDScript draw calls
        static readonly (string prefix, float w, float x0, float y0, float h)[] Rules =
        {
            ("wanderer_", 80, -40, -69, 80),
            ("npc_", 80, -40, -69, 80),
            ("scarecrow_", 80, -40, -69, 80),
            ("strigoi_", 80, -40, -69, 80),
            ("moroi_", 80, -40, -69, 80),
            ("shade_", 72, -36, -62, 72),
            ("iele_", 72, -36, -66, 72),
            ("bat_", 52, -26, -58, 52),
            ("wolf_", 96, -46.5f, -61, 72),
            ("boss_", 288, -144, -192, 216),
            ("bear_", 288, -144, -201, 216),
            ("muma_", 288, -144, -190, 216),
            ("vlad_", 288, -144, -196, 216),
            ("balaur_body", 480, -240, -150, 360),
            ("balaur_head", 148, -40, -42, 80),
            ("skull", 48, -24, -46, 48),
            ("ward", 40, -20, -88, 92),
        };

        void OnPreprocessTexture()
        {
            string p = assetPath.Replace('\\', '/');
            bool sprite = p.Contains("/Resources/Sprites/");
            bool photo = p.Contains("/Resources/Photos/");
            if (!sprite && !photo) return;

            var ti = (TextureImporter)assetImporter;
            ti.textureType = TextureImporterType.Sprite;
            ti.spriteImportMode = SpriteImportMode.Single;
            ti.mipmapEnabled = false;
            ti.alphaIsTransparency = true;
            ti.filterMode = FilterMode.Bilinear;
            ti.textureCompression = TextureImporterCompression.Uncompressed;
            ti.maxTextureSize = 4096;

            var s = new TextureImporterSettings();
            ti.ReadTextureSettings(s);
            s.spriteAlignment = (int)SpriteAlignment.Custom;
            s.spritePivot = new Vector2(0.5f, 0.5f);
            int texW = PngWidth(p);
            // photos: 1 px per unit; utility sprites (white, circle): exactly 1 unit across, scaled in code
            s.spritePixelsPerUnit = photo ? 1f : Mathf.Max(1, texW);

            string fname = Path.GetFileNameWithoutExtension(p);
            if (sprite && fname.StartsWith("tex_"))
            {
                // painted surface textures, tiled across block faces and the ground; PPU sets how many
                // world units one repeat of the texture spans
                s.spriteMeshType = SpriteMeshType.FullRect;
                s.wrapMode = TextureWrapMode.Repeat;
                s.spritePixelsPerUnit = Mathf.Max(1, texW) / TexWorldSize(fname);
                ti.SetTextureSettings(s);
                return;
            }

            if (sprite && fname.StartsWith("tile_"))
            {
                // ground textures tile across a whole level: full-rect mesh, repeat wrap.
                // Godot drew grass at its native size and the cobbles at 0.55x.
                s.spriteMeshType = SpriteMeshType.FullRect;
                s.wrapMode = TextureWrapMode.Repeat;
                s.spritePixelsPerUnit = fname.StartsWith("tile_cobble") ? texW / 35.2f : 1f;
                ti.SetTextureSettings(s);
                return;
            }

            if (sprite)
            {
                string name = fname;
                foreach (var r in Rules)
                {
                    if (!name.StartsWith(r.prefix)) continue;
                    s.spritePivot = new Vector2(-r.x0 / r.w, (r.y0 + r.h) / r.h);
                    if (texW > 0) s.spritePixelsPerUnit = texW / r.w;
                    break;
                }
            }
            ti.SetTextureSettings(s);
        }

        static float TexWorldSize(string name) => name switch
        {
            "tex_grass" => 256f,
            "tex_dirt" => 256f,
            "tex_flag" => 120f,
            "tex_planks" => 96f,
            "tex_k_plaster" => 128f,
            _ => 112f,
        };

        static int PngWidth(string assetPath)
        {
            try
            {
                using var f = File.OpenRead(assetPath);
                var b = new byte[24];
                if (f.Read(b, 0, 24) < 24) return 0;
                return (b[16] << 24) | (b[17] << 16) | (b[18] << 8) | b[19];
            }
            catch { return 0; }
        }
    }
}

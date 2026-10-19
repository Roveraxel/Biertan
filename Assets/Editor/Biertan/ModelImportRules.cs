using System.IO;
using UnityEditor;
using UnityEditor.AssetImporters;
using UnityEngine;

namespace Biertan.EditorTools
{
    /// <summary>Import rules for the 3D characters. Mixamo FBX (characters exported with their idle, and
    /// skinless animation clips exported on Y Bot) come in as Humanoid so every clip retargets onto every
    /// character. Looping clips are flagged by name. The Quaternius animals keep their own Generic rig.</summary>
    public class ModelImportRules : AssetPostprocessor
    {
        static readonly string[] Loops = { "idle", "walk", "run", "fwalk" };

        void OnPreprocessModel()
        {
            if (!assetPath.Contains("Models3D/")) return;
            var mi = (ModelImporter)assetImporter;
            mi.materialImportMode = ModelImporterMaterialImportMode.ImportViaMaterialDescription;
            mi.importCameras = false; mi.importLights = false;
            if (assetPath.Contains("Models3D/Chars/") || assetPath.Contains("Models3D/Anims/") || assetPath.Contains("Models3D/Skeletons/"))
            {
                mi.animationType = ModelImporterAnimationType.Human;
                mi.avatarSetup = ModelImporterAvatarSetup.CreateFromThisModel;
                mi.importAnimation = true;
                mi.resampleCurves = true;
                mi.animationCompression = ModelImporterAnimationCompression.Optimal;
            }
            else
            {
                mi.animationType = ModelImporterAnimationType.Generic;
                mi.importAnimation = true;
            }
        }

        void OnPreprocessAnimation()
        {
            if (!assetPath.Contains("Models3D/")) return;
            var mi = (ModelImporter)assetImporter;
            string file = System.IO.Path.GetFileNameWithoutExtension(assetPath).ToLowerInvariant();
            var clips = mi.defaultClipAnimations;
            foreach (var c in clips)
            {
                string n = (file + " " + c.name).ToLowerInvariant();
                bool loop = assetPath.Contains("/Characters/") || assetPath.Contains("/Animals/");
                foreach (var l in Loops) if (file == l || file.EndsWith("_" + l)) loop = true;
                if (assetPath.Contains("/Anims/") || assetPath.Contains("/Skeletons/"))
                {
                    string cn = c.name.ToLowerInvariant();
                    loop = cn.Contains("loop") || ((cn.Contains("idle") || cn.Contains("walk") || cn.Contains("run") || cn.Contains("jog") || cn.Contains("sprint")) && !cn.Contains("to_") && !cn.Contains("start") && !cn.Contains("stop"));
                }
                if (assetPath.Contains("/Animals/"))
                    loop = !n.Contains("hitreact") && !n.Contains("jump") && (n.Contains("idle") || n.Contains("walk") || n.Contains("run") || n.Contains("gallop") || n.Contains("eating"));
                c.loopTime = loop;
                c.lockRootRotation = true; c.lockRootHeightY = false; c.lockRootPositionXZ = true;
                c.keepOriginalOrientation = true; c.keepOriginalPositionY = true; c.keepOriginalPositionXZ = true;
                c.name = assetPath.Contains("/Mixamo/") ? file : c.name;
            }
            mi.clipAnimations = clips;
        }

        const string MixTex = "Assets/Resources/Models3D/Mixamo/Textures/";

        void OnPreprocessTexture()
        {
            if (assetPath.Contains("Resources/Sprites/Pixel/"))
            {
                // PixelLab frames: crisp pixels, no blur, no compression artefacts
                var pi = (TextureImporter)assetImporter;
                pi.textureType = TextureImporterType.Sprite;
                pi.spriteImportMode = SpriteImportMode.Single;
                pi.filterMode = FilterMode.Point;
                pi.textureCompression = TextureImporterCompression.Uncompressed;
                pi.mipmapEnabled = false;
                pi.alphaIsTransparency = true;
                pi.spritePixelsPerUnit = 64;
                return;
            }
            if (!assetPath.StartsWith(MixTex)) return;
            var ti = (TextureImporter)assetImporter;
            string n = Path.GetFileNameWithoutExtension(assetPath).ToLowerInvariant();
            if (n.Contains("normal")) ti.textureType = TextureImporterType.NormalMap;
            ti.sRGBTexture = !n.Contains("normal") && !n.Contains("specular");
            ti.maxTextureSize = 2048;
            ti.anisoLevel = 4;
        }

        /// <summary>Mixamo characters: URP Lit materials built from the textures extracted next to them
        /// (diffuse, normal, glow); cut-out alpha where the FBX marks the material transparent.</summary>
        void OnPreprocessMaterialDescription(MaterialDescription d, Material m, AnimationClip[] clips)
        {
            if (!assetPath.Contains("Models3D/Mixamo/Characters/")) return;
            string dir = MixTex + Path.GetFileNameWithoutExtension(assetPath) + "/";
            m.shader = Shader.Find("Universal Render Pipeline/Lit");
            Texture2D Find(string prop, string hint)
            {
                if (d.TryGetProperty(prop, out TexturePropertyDescription t) && !string.IsNullOrEmpty(t.relativePath))
                {
                    var tx = AssetDatabase.LoadAssetAtPath<Texture2D>(dir + Path.GetFileName(t.relativePath.Replace('\\', '/')));
                    if (tx != null) return tx;
                }
                if (hint == null || !Directory.Exists(dir)) return null;
                foreach (var f in Directory.GetFiles(dir, "*.png"))
                    if (Path.GetFileName(f).ToLowerInvariant().Contains(hint)) return AssetDatabase.LoadAssetAtPath<Texture2D>(f.Replace('\\', '/'));
                return null;
            }
            var albedo = Find("DiffuseColor", null) ?? Find("Maya|baseColor", "diffuse");
            if (albedo != null) { m.SetTexture("_BaseMap", albedo); m.SetTexture("_MainTex", albedo); }
            m.SetColor("_BaseColor", Color.white);
            var nrm = Find("NormalMap", null) ?? Find("Bump", "normal");
            if (nrm != null) { m.SetTexture("_BumpMap", nrm); m.EnableKeyword("_NORMALMAP"); }
            var glow = Find("EmissiveColor", null) ?? (Find("x", "glow") ?? Find("x", "emission"));
            if (glow != null) { m.SetTexture("_EmissionMap", glow); m.SetColor("_EmissionColor", Color.white * 0.8f); m.EnableKeyword("_EMISSION"); }
            m.SetFloat("_Smoothness", 0.25f);
            m.SetFloat("_Metallic", 0f);
            bool cut = (albedo != null && albedo.name.ToLowerInvariant().Contains("transparent")) || m.name.ToLowerInvariant().Contains("transparent") || m.name.EndsWith("_");
            if (cut) { m.SetFloat("_AlphaClip", 1f); m.SetFloat("_Cutoff", 0.4f); m.EnableKeyword("_ALPHATEST_ON"); m.SetFloat("_Cull", 0f); }
        }
    }
}

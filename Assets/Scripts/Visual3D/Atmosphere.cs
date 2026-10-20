using UnityEngine;
using Biertan.Core;

namespace Biertan.Visual3D
{
    /// <summary>
    /// The air of a place: low mist drifting over the ground, fireflies in the woods and vines, falling leaves
    /// in the forest, dust hanging in caves and the church, and sparks rising from the braziers. Particles live
    /// in world space in a box that follows the hunter, so they stay put as he walks through them.
    /// </summary>
    public class Atmosphere : MonoBehaviour
    {
        static Texture2D soft, leaf;
        static Material softMat, leafMat;
        string level;

        public static void Build(Transform root, string levelId)
        {
            var go = new GameObject("Atmosphere");
            go.transform.SetParent(root, false);
            var a = go.AddComponent<Atmosphere>();
            a.level = levelId;
            Materials();
            bool under = levelId is "caves" or "gorge" or "church";
            bool village = levelId is "hub" or "richis" or "mosna" or "biertan" or "walls";
            bool woods = levelId is "forest" or "hollow" or "hills" or "arena";

            if (!under)
                a.Mist(woods ? 80 : 50, village ? 0.09f : 0.15f);
            if (levelId is "forest" or "vineyard" or "hills" or "hollow")
                a.Fireflies(levelId == "vineyard" ? 26 : 18);
            if (levelId is "forest" or "hollow")
                a.Leaves(10);
            if (under)
                a.Dust(levelId == "church" ? 40 : 60);
        }

        static void Materials()
        {
            if (softMat != null) return;
            var baseMat = Resources.Load<Material>("LineMat");
            soft = new Texture2D(64, 64, TextureFormat.RGBA32, false) { wrapMode = TextureWrapMode.Clamp };
            leaf = new Texture2D(16, 16, TextureFormat.RGBA32, false) { wrapMode = TextureWrapMode.Clamp, filterMode = FilterMode.Point };
            for (int y = 0; y < 64; y++)
                for (int x = 0; x < 64; x++)
                {
                    float d = Vector2.Distance(new Vector2(x, y), new Vector2(31.5f, 31.5f)) / 32f;
                    float v = Mathf.Clamp01(1f - d); v = v * v * (3f - 2f * v);
                    soft.SetPixel(x, y, new Color(1f, 1f, 1f, v));
                }
            for (int y = 0; y < 16; y++)
                for (int x = 0; x < 16; x++)
                {
                    // a little pointed leaf shape
                    float u = (x - 7.5f) / 7.5f, w = (y - 7.5f) / 7.5f;
                    bool inLeaf = Mathf.Abs(u) < (1f - Mathf.Abs(w)) * 0.55f && Mathf.Abs(w) < 0.95f;
                    leaf.SetPixel(x, y, inLeaf ? Color.white : Color.clear);
                }
            soft.Apply(); leaf.Apply();
            softMat = new Material(baseMat) { mainTexture = soft, name = "AtmosSoft" };
            leafMat = new Material(baseMat) { mainTexture = leaf, name = "AtmosLeaf" };
        }

        ParticleSystem System(string name, Material mat, int max)
        {
            var go = new GameObject(name);
            go.transform.SetParent(transform, false);
            var ps = go.AddComponent<ParticleSystem>();
            ps.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
            var main = ps.main;
            main.simulationSpace = ParticleSystemSimulationSpace.World;
            main.maxParticles = max;
            main.playOnAwake = true;
            main.loop = true;
            var r = go.GetComponent<ParticleSystemRenderer>();
            r.sharedMaterial = mat;
            r.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            r.receiveShadows = false;
            return ps;
        }

        void Mist(int count, float alpha)
        {
            var ps = System("Mist", softMat, count);
            var m = ps.main;
            m.startLifetime = new ParticleSystem.MinMaxCurve(9f, 14f);
            m.startSize = new ParticleSystem.MinMaxCurve(4f, 8f);
            m.startSpeed = 0f;
            m.startRotation = new ParticleSystem.MinMaxCurve(0f, Mathf.PI * 2f);
            m.startColor = new Color(0.62f, 0.68f, 0.8f, 1f);
            var e = ps.emission; e.rateOverTime = count / 11f;
            var sh = ps.shape; sh.shapeType = ParticleSystemShapeType.Box; sh.scale = new Vector3(26f, 0.3f, 22f);
            sh.position = new Vector3(0f, 0.35f, 0f);
            var v = ps.velocityOverLifetime; v.enabled = true; v.space = ParticleSystemSimulationSpace.World;
            v.x = new ParticleSystem.MinMaxCurve(0.15f, 0.35f); v.y = new ParticleSystem.MinMaxCurve(0f, 0f); v.z = new ParticleSystem.MinMaxCurve(-0.08f, 0.08f);
            var rot = ps.rotationOverLifetime; rot.enabled = true; rot.z = new ParticleSystem.MinMaxCurve(-0.05f, 0.05f);
            var col = ps.colorOverLifetime; col.enabled = true;
            col.color = Fade(new Color(0.62f, 0.68f, 0.8f), alpha, 0.3f, 0.7f);
            var r = ps.GetComponent<ParticleSystemRenderer>();
            r.renderMode = ParticleSystemRenderMode.HorizontalBillboard; // lies on the ground like a sheet of mist
            r.sortingFudge = 50f;
            ps.Play();
        }

        void Fireflies(int count)
        {
            var ps = System("Fireflies", softMat, count);
            var m = ps.main;
            m.startLifetime = new ParticleSystem.MinMaxCurve(4f, 8f);
            m.startSize = new ParticleSystem.MinMaxCurve(0.1f, 0.17f);
            m.startSpeed = 0f;
            var e = ps.emission; e.rateOverTime = count / 6f;
            var sh = ps.shape; sh.shapeType = ParticleSystemShapeType.Box; sh.scale = new Vector3(22f, 1.6f, 18f);
            sh.position = new Vector3(0f, 1.1f, 0f);
            var n = ps.noise; n.enabled = true; n.strength = 0.6f; n.frequency = 0.35f; n.scrollSpeed = 0.2f;
            var col = ps.colorOverLifetime; col.enabled = true;
            // they glow on and off as they drift
            var g = new Gradient();
            g.SetKeys(new[] { new GradientColorKey(new Color(0.85f, 1f, 0.45f), 0f), new GradientColorKey(new Color(1f, 0.9f, 0.4f), 1f) },
                      new[] { new GradientAlphaKey(0f, 0f), new GradientAlphaKey(1f, 0.15f), new GradientAlphaKey(0.15f, 0.35f),
                              new GradientAlphaKey(1f, 0.55f), new GradientAlphaKey(0.2f, 0.8f), new GradientAlphaKey(0f, 1f) });
            col.color = g;
            // a soft halo around each one
            var halo = ps.trails; halo.enabled = false;
            ps.Play();
        }

        void Leaves(int count)
        {
            var ps = System("Leaves", leafMat, count);
            var m = ps.main;
            m.startLifetime = new ParticleSystem.MinMaxCurve(5f, 8f);
            m.startSize = new ParticleSystem.MinMaxCurve(0.12f, 0.2f);
            m.startSpeed = 0f;
            m.startRotation = new ParticleSystem.MinMaxCurve(0f, Mathf.PI * 2f);
            m.startColor = new ParticleSystem.MinMaxGradient(new Color(0.45f, 0.28f, 0.12f), new Color(0.62f, 0.42f, 0.16f));
            m.gravityModifier = 0.02f;
            var e = ps.emission; e.rateOverTime = count / 6f;
            var sh = ps.shape; sh.shapeType = ParticleSystemShapeType.Box; sh.scale = new Vector3(20f, 0.5f, 16f);
            sh.position = new Vector3(0f, 4.5f, 0f);
            var v = ps.velocityOverLifetime; v.enabled = true; v.space = ParticleSystemSimulationSpace.World;
            v.x = new ParticleSystem.MinMaxCurve(0.2f, 0.6f); v.y = new ParticleSystem.MinMaxCurve(-0.7f, -0.45f); v.z = new ParticleSystem.MinMaxCurve(-0.15f, 0.15f);
            var n = ps.noise; n.enabled = true; n.strength = 0.5f; n.frequency = 0.8f;
            var rot = ps.rotationOverLifetime; rot.enabled = true; rot.z = new ParticleSystem.MinMaxCurve(-3f, 3f);
            var col = ps.colorOverLifetime; col.enabled = true; col.color = Fade(Color.white, 0.9f, 0.08f, 0.85f);
            ps.Play();
        }

        void Dust(int count)
        {
            var ps = System("Dust", softMat, count);
            var m = ps.main;
            m.startLifetime = new ParticleSystem.MinMaxCurve(6f, 10f);
            m.startSize = new ParticleSystem.MinMaxCurve(0.03f, 0.07f);
            m.startSpeed = 0f;
            m.startColor = new Color(0.9f, 0.82f, 0.68f);
            var e = ps.emission; e.rateOverTime = count / 8f;
            var sh = ps.shape; sh.shapeType = ParticleSystemShapeType.Box; sh.scale = new Vector3(18f, 2.5f, 14f);
            sh.position = new Vector3(0f, 1.4f, 0f);
            var n = ps.noise; n.enabled = true; n.strength = 0.12f; n.frequency = 0.25f;
            var col = ps.colorOverLifetime; col.enabled = true; col.color = Fade(new Color(0.9f, 0.82f, 0.68f), 0.45f, 0.25f, 0.75f);
            ps.Play();
        }

        static Gradient Fade(Color c, float alpha, float inAt, float outAt)
        {
            var g = new Gradient();
            g.SetKeys(new[] { new GradientColorKey(c, 0f), new GradientColorKey(c, 1f) },
                      new[] { new GradientAlphaKey(0f, 0f), new GradientAlphaKey(alpha, inAt), new GradientAlphaKey(alpha, outAt), new GradientAlphaKey(0f, 1f) });
            return g;
        }

        void LateUpdate()
        {
            // the emitting box rides along with the hunter; what it already let go stays where it is
            var p = GameManager.I != null ? GameManager.I.player : null;
            if (p != null) transform.position = World3D.To3D(p.transform.position);
        }
    }
}

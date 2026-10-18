using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace Biertan.Core
{
    /// <summary>Port of g.gd make_light() and the level's CanvasModulate: point lights for lanterns, fires
    /// and salt, and one global light that carries each level's ambient colour (dusk, darkness).</summary>
    public static class Lights
    {
        public static Light2D Point(Transform parent, float radius, Color color, float intensity, Vector2 offset = default)
        {
            var go = new GameObject("Light");
            go.transform.SetParent(parent, false);
            go.transform.localPosition = offset;
            var l = go.AddComponent<Light2D>();
            l.lightType = Light2D.LightType.Point;
            l.pointLightOuterRadius = radius;
            l.pointLightInnerRadius = radius * 0.15f;
            l.color = color;
            l.intensity = intensity;
            l.falloffIntensity = 0.6f;
            return l;
        }

        /// <summary>g.gd ambient(): warm daylight at dusk 0, deep blue night at 1.</summary>
        public static Color Dusk(float d) =>
            Color.Lerp(new Color(0.95f, 0.9f, 0.82f), new Color(0.12f, 0.14f, 0.3f), Mathf.Clamp01(d));
    }
}

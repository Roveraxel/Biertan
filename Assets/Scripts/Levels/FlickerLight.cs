using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace Biertan.Levels
{
    /// <summary>A torch-like light that wavers (flicker_light.gd).</summary>
    public class FlickerLight : MonoBehaviour
    {
        public Light2D light;
        public float baseEnergy = 1.1f;
        float t, seed;

        void Start() => seed = Random.value * 10f;

        void Update()
        {
            t += Time.deltaTime;
            if (light != null)
                light.intensity = baseEnergy + 0.12f * Mathf.Sin((t + seed) * 11f) + 0.07f * Mathf.Sin((t + seed) * 23f);
        }
    }
}

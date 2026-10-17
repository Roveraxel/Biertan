using UnityEngine;
using Biertan.Enemies;

namespace Biertan.Core
{
    /// <summary>Expanding ring drawn with a LineRenderer.</summary>
    [RequireComponent(typeof(LineRenderer))]
    public class RingFx : MonoBehaviour
    {
        LineRenderer lr;
        Color color;
        float radius, life, age;
        const int Segments = 40;

        public void Init(Color c, float r, float l)
        {
            lr = GetComponent<LineRenderer>();
            lr.positionCount = Segments;
            lr.loop = true;
            lr.useWorldSpace = false;
            lr.widthMultiplier = 3f;
            color = c; radius = r; life = l;
        }

        void Update()
        {
            age += Time.deltaTime;
            float k = Mathf.Clamp01(age / life);
            float r = radius * (0.4f + 0.6f * k);
            for (int i = 0; i < Segments; i++)
            {
                float a = i / (float)Segments * Mathf.PI * 2f;
                lr.SetPosition(i, new Vector3(Mathf.Cos(a) * r, Mathf.Sin(a) * r * 0.55f, 0));
            }
            var c = color; c.a *= 1f - k;
            lr.startColor = lr.endColor = c;
            if (age >= life) Destroy(gameObject);
        }
    }
}

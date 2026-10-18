using UnityEngine;
using Biertan.Player;

namespace Biertan.Core
{
    /// <summary>An expanding ring the hunter must dodge through: lake water spat by the Balaur's thirsting
    /// head, a ring of fire, or the shockwave of the bear's slam (earth). Port of water_wave.gd.</summary>
    [RequireComponent(typeof(LineRenderer))]
    public class WaterWave : MonoBehaviour
    {
        public float r = 30f, speed = 430f, band = 34f, maxR = 900f, dmg = 16f;
        public bool fire, earth;
        bool hit;
        LineRenderer outer, inner;
        PlayerController player;
        const int Segments = 72;

        void Start()
        {
            player = FindAnyObjectByType<PlayerController>();
            outer = GetComponent<LineRenderer>();
            inner = new GameObject("Crest").AddComponent<LineRenderer>();
            inner.transform.SetParent(transform, false);
            foreach (var lr in new[] { outer, inner })
            {
                lr.useWorldSpace = false; lr.loop = true; lr.positionCount = Segments;
                lr.sharedMaterial = Resources.Load<Material>("LineMat");
                lr.sortingOrder = -880;
            }
            outer.widthMultiplier = band;
            inner.widthMultiplier = 3f;
        }

        void FixedUpdate()
        {
            r += speed * Time.fixedDeltaTime;
            if (r > maxR) { Destroy(gameObject); return; }
            if (player != null && !hit)
            {
                Vector2 dv = player.transform.position - transform.position;
                dv.y /= 0.75f;
                if (Mathf.Abs(dv.magnitude - r) < band * 0.5f && player.invT <= 0f)
                {
                    hit = true;
                    player.Hurt(dmg, ((Vector2)(player.transform.position - transform.position)).normalized);
                }
            }
        }

        void Update()
        {
            if (outer == null) return;
            float a = Mathf.Clamp01(1f - r / maxR);
            Color c1 = earth ? new Color(0.45f, 0.33f, 0.2f, 0.8f * a) : fire ? new Color(1f, 0.4f, 0.1f, 0.75f * a) : new Color(0.45f, 0.65f, 0.8f, 0.7f * a);
            Color c2 = fire ? new Color(1f, 0.85f, 0.4f, 0.7f * a) : new Color(0.9f, 0.95f, 1f, 0.6f * a);
            outer.startColor = outer.endColor = c1;
            inner.startColor = inner.endColor = c2;
            for (int i = 0; i < Segments; i++)
            {
                float q = i * Mathf.PI * 2f / Segments;
                var d = new Vector3(Mathf.Cos(q), Mathf.Sin(q) * 0.75f, 0);
                outer.SetPosition(i, d * r);
                inner.SetPosition(i, d * (r + band * 0.4f));
            }
        }

        public static WaterWave Spawn(Transform parent, Vector2 at)
        {
            var go = new GameObject("Wave");
            go.transform.SetParent(parent, false);
            go.transform.position = at;
            go.AddComponent<LineRenderer>();
            return go.AddComponent<WaterWave>();
        }
    }
}

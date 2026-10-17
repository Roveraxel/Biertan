using UnityEngine;
using Biertan.Player;

namespace Biertan.Levels
{
    /// <summary>A thread woven across the clearing by the Forest Mother. Snares whoever crosses it.
    /// Pale while being spun, then taut and red. Port of thread.gd.</summary>
    [RequireComponent(typeof(LineRenderer))]
    public class WeaveThread : MonoBehaviour
    {
        public Vector2 a, b;
        public float spin = 0.8f, life = 4f;
        float t, tick;
        LineRenderer lr;
        PlayerController player;

        void Start()
        {
            lr = GetComponent<LineRenderer>();
            lr.useWorldSpace = true; lr.positionCount = 2;
            lr.sharedMaterial = Resources.Load<Material>("LineMat");
            lr.sortingOrder = -890;
            player = FindAnyObjectByType<PlayerController>();
        }

        void FixedUpdate()
        {
            float dt = Time.fixedDeltaTime;
            t += dt; tick -= dt;
            if (t > spin + life) { Destroy(gameObject); return; }
            if (t > spin && player != null)
            {
                Vector2 p = player.transform.position;
                Vector2 ab = b - a;
                float k = Mathf.Clamp01(Vector2.Dot(p - a, ab) / ab.sqrMagnitude);
                if (Vector2.Distance(a + ab * k, p) < 16f)
                {
                    player.slowT = Mathf.Max(player.slowT, 0.6f);
                    if (tick <= 0f) { tick = 0.5f; player.Hurt(5f, Vector2.zero); }
                }
            }
        }

        void Update()
        {
            if (lr == null) return;
            lr.SetPosition(0, a);
            if (t < spin)
            {
                lr.SetPosition(1, Vector2.Lerp(a, b, t / spin));
                lr.widthMultiplier = 1.5f;
                lr.startColor = lr.endColor = new Color(0.9f, 0.9f, 0.8f, 0.35f);
                return;
            }
            float fade = Mathf.Clamp01(spin + life - t);
            lr.SetPosition(1, b);
            lr.widthMultiplier = 3f;
            lr.startColor = lr.endColor = new Color(0.6f, 0.1f, 0.1f, 0.85f * fade);
        }
    }
}

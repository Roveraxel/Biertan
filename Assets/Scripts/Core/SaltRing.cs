using System.Collections.Generic;
using UnityEngine;
using Biertan.Enemies;

namespace Biertan.Core
{
    /// <summary>A circle of thrown salt. The unclean dead cannot cross it and burn inside it. Port of salt_ring.gd.</summary>
    public class SaltRing : MonoBehaviour
    {
        public const float Radius = 120f;
        public static readonly List<SaltRing> All = new();

        public float life = 6f;
        public SpriteRenderer disc;   // circle sprite, scaled to the ring
        public LineRenderer edge;
        float t;

        void OnEnable() => All.Add(this);
        void OnDisable() => All.Remove(this);

        void Start()
        {
            if (disc != null) disc.transform.localScale = new Vector3(Radius * 2f, Radius * 2f * 0.55f, 1f);
            if (edge != null)
            {
                const int n = 64;
                edge.positionCount = n; edge.loop = true; edge.useWorldSpace = false; edge.widthMultiplier = 6f;
                for (int i = 0; i < n; i++)
                {
                    float a = i / (float)n * Mathf.PI * 2f;
                    edge.SetPosition(i, new Vector3(Mathf.Cos(a) * Radius, Mathf.Sin(a) * Radius * 0.55f, 0));
                }
            }
            FxUtil.Ring(transform.position, new Color(1, 1, 1, 0.8f), Radius, 0.4f);
        }

        public bool Contains(Vector2 p, float extra = 0f) => Vector2.Distance(p, transform.position) < Radius + extra;

        void FixedUpdate()
        {
            float dt = Time.fixedDeltaTime;
            t += dt;
            life -= dt;
            if (life <= 0f) { Destroy(gameObject); return; }
            foreach (var e in EnemyBase.All.ToArray())
                if (e != null && e.Undead() && Contains(e.transform.position, e.radius))
                    e.SaltHit(transform, dt);

            float a = Mathf.Clamp01(life);
            if (disc != null) disc.color = new Color(0.9f, 0.92f, 1f, 0.08f * a);
            if (edge != null) edge.startColor = edge.endColor = new Color(0.95f, 0.96f, 1f, (0.3f + 0.1f * Mathf.Sin(t * 6f)) * a);
        }
    }
}

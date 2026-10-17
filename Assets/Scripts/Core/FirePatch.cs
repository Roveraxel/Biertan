using UnityEngine;
using Biertan.Player;

namespace Biertan.Core
{
    /// <summary>Burning ground (fire head, fire skulls), rime (frost head), Muma's brew, or the bear's bees.
    /// Port of fire_patch.gd.</summary>
    public class FirePatch : MonoBehaviour
    {
        public const float R = 38f;
        public bool frost, brew, bees;
        public SpriteRenderer disc; // circle sprite
        float life = 2.6f, t, tick;
        PlayerController player;

        void Start()
        {
            if (frost) life = 3.4f;
            if (brew) life = 3f;
            if (bees) life = 4f;
            if (disc != null) disc.transform.localScale = new Vector3(R * 2f, R * 2f * 0.6f, 1f);
            player = FindAnyObjectByType<PlayerController>();
        }

        void FixedUpdate()
        {
            float dt = Time.fixedDeltaTime;
            t += dt; life -= dt; tick -= dt;
            if (life <= 0f) { Destroy(gameObject); return; }

            if (player != null && Vector2.Distance(player.transform.position, transform.position) < R)
            {
                if (bees) { if (tick <= 0f) { tick = 0.4f; player.Hurt(5f, Vector2.zero); } }
                else if (brew) { player.slowT = Mathf.Max(player.slowT, 0.2f); if (tick <= 0f) { tick = 0.5f; player.Hurt(6f, Vector2.zero); } }
                else if (frost) { player.slowT = Mathf.Max(player.slowT, 0.25f); if (tick <= 0f) { tick = 0.6f; player.Hurt(4f, Vector2.zero); } }
                else if (tick <= 0f) { tick = 0.5f; player.Hurt(9f, ((Vector2)(player.transform.position - transform.position)).normalized); }
            }

            float a = Mathf.Clamp01(life);
            if (disc == null) return;
            Color c = bees ? new Color(0.6f, 0.45f, 0.1f, 0.25f)
                    : brew ? new Color(0.25f, 0.45f, 0.1f, 0.6f)
                    : frost ? new Color(0.7f, 0.85f, 1f, 0.55f)
                    : new Color(1f, 0.45f + 0.1f * Mathf.Sin(t * 12f), 0.1f, 0.6f);
            c.a *= a;
            disc.color = c;
        }
    }
}

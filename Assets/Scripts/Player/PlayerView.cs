using UnityEngine;

namespace Biertan.Player
{
    /// <summary>Draws the wanderer: idle/walk/attack frames, i-frame blink, hurt flash, sword arc,
    /// vampire aura and frost root. Port of player.gd _draw().</summary>
    public class PlayerView : MonoBehaviour
    {
        public PlayerController player;
        public SpriteRenderer body;
        public LineRenderer arc;
        public SpriteRenderer aura;    // circle sprite, red, behind the head (vampirism)
        public SpriteRenderer frost;   // white sprite, pale blue box (rooted)

        Sprite idle, walk, attack;
        Rigidbody2D rb;

        void Awake()
        {
            idle = Resources.Load<Sprite>("Sprites/wanderer_idle");
            walk = Resources.Load<Sprite>("Sprites/wanderer_walk");
            attack = Resources.Load<Sprite>("Sprites/wanderer_attack");
            rb = player.GetComponent<Rigidbody2D>();
        }

        void LateUpdate()
        {
            var p = player;
            Sprite s = idle;
            if (p.attackT > 0f) s = attack;
            else if (rb.linearVelocity.magnitude > 40f && ((int)(p.walkT / 1.6f)) % 2 == 1) s = walk;
            body.sprite = s;

            bool blink = p.invT > 0f && ((int)(p.invT * 30f)) % 2 == 0;
            Color c = Color.white;
            if (p.hurtFlash > 0f) c = Color.Lerp(Color.white, new Color(1f, 0.35f, 0.35f), Mathf.Clamp01(p.hurtFlash * 4f));
            c.a = blink ? 0.45f : 1f;
            body.color = c;
            body.flipX = p.attackT > 0f && p.facing.x < 0f;

            // sword arc
            if (arc != null)
            {
                arc.enabled = p.attackT > 0f;
                if (arc.enabled)
                {
                    float k = 1f - p.attackT / 0.18f;
                    float ang = Mathf.Atan2(p.facing.y, p.facing.x);
                    float a1 = ang + 1.2f - 2.4f * k + 0.9f, a0 = ang + 1.2f - 2.4f * k;
                    const int n = 10;
                    arc.positionCount = n;
                    for (int i = 0; i < n; i++)
                    {
                        float a = Mathf.Lerp(a0, a1, i / (n - 1f));
                        arc.SetPosition(i, new Vector3(Mathf.Cos(a) * 62f, 16f + Mathf.Sin(a) * 62f, 0));
                    }
                }
            }

            if (aura != null)
            {
                aura.enabled = p.vampT > 0f;
                if (aura.enabled) aura.color = new Color(0.7f, 0f, 0.1f, 0.25f + 0.1f * Mathf.Sin(p.walkT * 2f));
            }
            if (frost != null) frost.enabled = p.rootT > 0f;
        }
    }
}

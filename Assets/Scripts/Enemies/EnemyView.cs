using System.Collections.Generic;
using UnityEngine;

namespace Biertan.Enemies
{
    /// <summary>Picks each creature's sprite frame, tint, flip and health bar. Port of enemy.gd _draw().</summary>
    public class EnemyView : MonoBehaviour
    {
        public EnemyBase enemy;
        public SpriteRenderer body;
        public SpriteRenderer barBack, barFill; // white sprites
        public SpriteRenderer windupGlow;       // circle sprite

        static readonly Dictionary<string, Sprite> cache = new();
        Rigidbody2D rb;

        static Sprite S(string n)
        {
            if (!cache.TryGetValue(n, out var s)) { s = Resources.Load<Sprite>("Sprites/" + n); cache[n] = s; }
            return s;
        }

        void Awake() => rb = enemy.GetComponent<Rigidbody2D>();

        void LateUpdate()
        {
            var e = enemy;
            float t = e.t;
            Color tint = Color.white;
            float scale = 1f;
            bool flip = false;
            float yOff = 0f, yScale = 1f;
            bool bar = true;
            Sprite s = null;

            switch (e.kind)
            {
                case "scarecrow":
                    s = S(e.state == "dormant" ? "scarecrow_dormant" : "scarecrow_awake");
                    break;
                case "shade":
                    s = S(((int)(t * 3f)) % 2 == 0 ? "shade_a" : "shade_b");
                    tint.a = 0.8f + 0.15f * Mathf.Sin(t * 5f);
                    break;
                case "iele":
                    s = S(((int)(t * 4f)) % 2 == 0 ? "iele_a" : "iele_b");
                    tint.a = 0.78f + 0.18f * Mathf.Sin(t * 4f);
                    yOff = -Mathf.Sin(t * 3f + e.orbit) * 4f;
                    break;
                case "skull":
                    s = S("skull"); bar = false;
                    break;
                case "ward":
                    s = S("ward");
                    float pulse = 0.5f + 0.5f * Mathf.Sin(t * 4f);
                    tint = Color.Lerp(Color.white, new Color(1f, 0.75f, 0.75f), pulse);
                    break;
                case "bat":
                    s = S(((int)(t * 12f)) % 2 == 0 ? "bat_a" : "bat_b"); bar = false;
                    break;
                case "strigoi":
                    s = S(e.state is "leap" or "crouch" ? "strigoi_leap" : "strigoi_stand");
                    if (e.state == "leap") yOff = Mathf.Sin(Mathf.PI * Mathf.Clamp01(t / 0.45f)) * 70f;
                    if (e.state == "rise") { float r = Mathf.Clamp01(t / 0.8f); yScale = r; yOff = -12f * (1f - r); }
                    flip = e.face.x < 0f;
                    break;
                case "moroi":
                    s = S(e.state == "dormant" ? "moroi_dormant" : "moroi_awake");
                    if (e.state == "rise") { float r = Mathf.Clamp01(t / 0.8f); yScale = r; yOff = -10f * (1f - r); }
                    flip = e.face.x < 0f;
                    break;
                case "wolf":
                case "pricolici":
                    if (e.state is "windup" or "lunge") s = S("wolf_lunge");
                    else if (rb.linearVelocity.magnitude > 40f && ((int)(t * 8f)) % 2 == 0) s = S("wolf_run");
                    else s = S("wolf_idle");
                    if (e.kind == "pricolici") { scale = 1.3f; tint = new Color(1f, 0.82f, 0.72f); }
                    flip = e.face.x < 0f;
                    break;
                default:
                    s = S("circle");
                    break;
            }

            body.sprite = s;
            body.color = e.flash > 0f ? new Color(1f, 0.55f, 0.55f, tint.a) : tint;
            body.flipX = flip;
            body.transform.localScale = new Vector3(scale, scale * yScale, 1f);
            body.transform.localPosition = new Vector3(0f, yOff, 0f);

            if (windupGlow != null)
            {
                windupGlow.enabled = e.state == "windup" && e.kind is "wolf" or "pricolici" or "iele";
                if (windupGlow.enabled)
                    windupGlow.color = new Color(1f, 0.2f, 0.1f, 0.22f + 0.18f * Mathf.Sin(t * 30f));
            }

            bool showBar = bar && e.hp < e.maxHp;
            barBack.enabled = barFill.enabled = showBar;
            if (showBar)
            {
                float y = e.radius * 3.2f + 4f;
                const float w = 30f;
                float k = Mathf.Clamp01(e.hp / e.maxHp);
                barBack.transform.localPosition = new Vector3(0, y, 0);
                barBack.transform.localScale = new Vector3(w, 4f, 1f);
                barFill.transform.localPosition = new Vector3(-w / 2f + w * k / 2f, y, 0);
                barFill.transform.localScale = new Vector3(w * k, 4f, 1f);
            }
        }
    }
}

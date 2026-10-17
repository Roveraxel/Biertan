using UnityEngine;

namespace Biertan.Bosses
{
    /// <summary>Draws Muma Pădurii: idle/cast/sweep poses, the sweep telegraph arc, steel-bark grey
    /// tint, the glow while salted, fading as she hides, the flicker that betrays an illusion,
    /// and the stars over her head when stunned.</summary>
    public class MumaView : MonoBehaviour
    {
        public Muma boss;
        public SpriteRenderer body;
        public LineRenderer sweepArc;
        public SpriteRenderer[] stars;

        Sprite idle, cast, sweep;

        void Awake()
        {
            idle = Resources.Load<Sprite>("Sprites/muma_idle");
            cast = Resources.Load<Sprite>("Sprites/muma_cast");
            sweep = Resources.Load<Sprite>("Sprites/muma_sweep");
        }

        void LateUpdate()
        {
            var b = boss;
            float t = b.t;
            body.sprite = b.bstate == "cast" ? cast : (b.bstate is "sweep" or "sweep_tel" ? sweep : idle);
            body.flipX = b.face.x < 0f;
            float sway = b.bstate == "walk" ? Mathf.Sin(t * 1.6f) * 0.03f : 0f;
            body.transform.localRotation = Quaternion.Euler(0, 0, -sway * Mathf.Rad2Deg);

            Color c = Color.white;
            if (b.flash > 0f) c = new Color(1f, 0.6f, 0.6f);
            else if (b.phase >= 2 && !b.Vulnerable()) c = new Color(0.75f, 0.72f, 0.68f);
            else if (b.vulnT > 0f) c = new Color(1f, 0.95f, 0.85f);
            float a = b.alpha;
            if (b.illusion) a *= Mathf.Repeat(t + b.transform.position.x * 0.01f, 3.2f) < 0.15f ? 0.55f : 0.92f;
            else if (!b.Vulnerable()) a *= 0.92f;
            c.a = a;
            body.color = c;

            sweepArc.enabled = b.bstate == "sweep_tel";
            if (sweepArc.enabled)
            {
                float ang = Mathf.Atan2(b.face.y, b.face.x);
                const int n = 24;
                sweepArc.positionCount = n;
                for (int i = 0; i < n; i++)
                {
                    float q = ang + Mathf.Lerp(-65f, 65f, i / (n - 1f)) * Mathf.Deg2Rad;
                    sweepArc.SetPosition(i, new Vector3(Mathf.Cos(q) * 140f, 20f + Mathf.Sin(q) * 140f, 0));
                }
                sweepArc.startColor = sweepArc.endColor = new Color(1f, 0.3f, 0.1f, 0.35f + 0.3f * Mathf.Sin(t * 30f));
            }

            for (int i = 0; i < stars.Length; i++)
            {
                stars[i].enabled = b.bstate == "stunned";
                float q = t * 4f + i * Mathf.PI * 2f / stars.Length;
                stars[i].transform.localPosition = new Vector3(Mathf.Cos(q) * 34f, 170f + Mathf.Sin(q) * 34f * 0.5f, 0);
            }
        }
    }
}

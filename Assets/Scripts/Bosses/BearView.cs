using UnityEngine;

namespace Biertan.Bosses
{
    /// <summary>Draws the bear: idle/stand/charge poses, the swipe arc, the charge lane and the rear-up circle.</summary>
    public class BearView : MonoBehaviour
    {
        public Bear boss;
        public SpriteRenderer body;
        public LineRenderer swipeArc, chargeLane, rearRing;
        Sprite idle, stand, charge;

        void Awake()
        {
            idle = Resources.Load<Sprite>("Sprites/bear_idle");
            stand = Resources.Load<Sprite>("Sprites/bear_stand");
            charge = Resources.Load<Sprite>("Sprites/bear_charge");
        }

        void LateUpdate()
        {
            var b = boss;
            float t = b.t;
            body.sprite = b.bstate is "rear" or "roar" or "throw" or "tel" or "swipe" ? stand
                        : b.bstate is "charge" or "charge_tel" ? charge : idle;
            body.flipX = b.face.x < 0f;
            Color c = b.flash > 0f ? new Color(1f, 0.6f, 0.6f) : Color.white;
            if (b.enraged) c = Color.Lerp(c, new Color(1f, 0.7f, 0.65f), 0.4f);
            if (b.bstate == "sleep") c *= 0.85f;
            c.a = 1f;
            body.color = c;
            float pulse = 0.35f + 0.3f * Mathf.Sin(t * 28f);
            var warn = new Color(1f, 0.15f, 0.1f, pulse);

            swipeArc.enabled = b.bstate == "tel";
            if (swipeArc.enabled)
            {
                float a = Mathf.Atan2(b.face.y, b.face.x);
                const int n = 24;
                swipeArc.positionCount = n;
                for (int i = 0; i < n; i++)
                {
                    float q = a + Mathf.Lerp(-70f, 70f, i / (n - 1f)) * Mathf.Deg2Rad;
                    swipeArc.SetPosition(i, new Vector3(Mathf.Cos(q) * 135f, 30f + Mathf.Sin(q) * 135f, 0));
                }
                swipeArc.startColor = swipeArc.endColor = warn;
            }

            chargeLane.enabled = b.bstate == "charge_tel";
            if (chargeLane.enabled)
            {
                chargeLane.positionCount = 2;
                chargeLane.SetPosition(0, new Vector3(0, 20, 0));
                chargeLane.SetPosition(1, new Vector3(b.chargeDir.x * 520f, 20 + b.chargeDir.y * 520f, 0));
                chargeLane.startColor = chargeLane.endColor = warn;
            }

            rearRing.enabled = b.bstate == "rear";
            if (rearRing.enabled)
            {
                const int n = 48;
                rearRing.positionCount = n; rearRing.loop = true;
                for (int i = 0; i < n; i++)
                {
                    float q = i * Mathf.PI * 2f / n;
                    rearRing.SetPosition(i, new Vector3(Mathf.Cos(q) * 170f, Mathf.Sin(q) * 170f * 0.45f, 0));
                }
                rearRing.startColor = rearRing.endColor = new Color(1f, 0.3f, 0.1f, pulse);
            }
        }
    }
}

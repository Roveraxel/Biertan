using UnityEngine;

namespace Biertan.Bosses
{
    /// <summary>Draws the Vârcolac: idle/charge/howl poses, the red charge telegraph, the spun threads it
    /// climbs (snapped while fallen), half-transparent when steel can't touch it, tilted when fallen.</summary>
    public class VarcolacView : MonoBehaviour
    {
        public Varcolac boss;
        public SpriteRenderer body;
        public LineRenderer telegraph;
        public LineRenderer[] threads;

        Sprite idle, charge, howl;

        void Awake()
        {
            idle = Resources.Load<Sprite>("Sprites/boss_idle");
            charge = Resources.Load<Sprite>("Sprites/boss_charge");
            howl = Resources.Load<Sprite>("Sprites/boss_howl");
        }

        void LateUpdate()
        {
            var b = boss;
            float t = b.t;
            body.sprite = b.bstate is "charge" or "telegraph" ? charge : (b.howlAnim > 0f ? howl : idle);
            body.flipX = b.face.x < 0f;
            body.transform.localRotation = Quaternion.Euler(0, 0, b.bstate == "fallen" ? -20f * (b.face.x < 0f ? -1f : 1f) : 0f);
            Color c = b.flash > 0f ? new Color(1f, 0.6f, 0.6f) : Color.white;
            c.a = b.Vulnerable() ? 1f : 0.55f;
            body.color = c;

            telegraph.enabled = b.bstate == "telegraph";
            if (telegraph.enabled)
            {
                telegraph.positionCount = 2;
                telegraph.SetPosition(0, new Vector3(0, 20, 0));
                telegraph.SetPosition(1, new Vector3(b.chargeDir.x * 700f, 20 + b.chargeDir.y * 700f, 0));
                telegraph.startColor = telegraph.endColor = new Color(1f, 0.15f, 0.1f, 0.3f + 0.3f * Mathf.Sin(t * 25f));
            }

            for (int i = 0; i < threads.Length; i++)
            {
                var th = threads[i];
                th.enabled = b.phase >= 2;
                if (!th.enabled) continue;
                float x0 = -20f + i * 20f;
                th.positionCount = 2;
                th.SetPosition(0, new Vector3(x0, 60, 0));
                if (b.bstate == "fallen")
                {
                    th.SetPosition(1, new Vector3(x0 + 10f * Mathf.Sin(t * 3f + i), 110, 0));
                    th.startColor = th.endColor = new Color(0.9f, 0.87f, 0.8f, 0.5f);
                }
                else
                {
                    th.SetPosition(1, new Vector3(x0 * 3f + 30f * Mathf.Sin(t + i), 900, 0));
                    th.startColor = th.endColor = new Color(0.9f, 0.87f, 0.8f, 0.35f);
                }
            }
        }
    }
}

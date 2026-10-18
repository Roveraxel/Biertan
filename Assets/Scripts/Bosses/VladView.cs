using UnityEngine;

namespace Biertan.Bosses
{
    /// <summary>Draws Strigoi Vlad (vlad.gd _draw): idle/cast/claw poses, the blood glaive and its sweep, the
    /// thrust and sweep telegraphs, the dash lane, the rite's blood orb, the mist he becomes, the stun stars and
    /// the blood-drinking aura of phase 3.</summary>
    public class VladView : MonoBehaviour
    {
        public Vlad boss;
        SpriteRenderer body, shadow, blade, orb;
        LineRenderer shaft, telLine, telArc, aura;
        readonly SpriteRenderer[] stars = new SpriteRenderer[5];
        Sprite idle, cast, claw;
        static Material mat;

        SpriteRenderer Spr(string n, string s, int order, Color c)
        {
            var go = new GameObject(n);
            go.transform.SetParent(transform, false);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/" + s); sr.sortingOrder = order; sr.color = c;
            return sr;
        }

        LineRenderer Line(string n, float w, int order, int count, bool loop = false)
        {
            var go = new GameObject(n);
            go.transform.SetParent(transform, false);
            var lr = go.AddComponent<LineRenderer>();
            lr.useWorldSpace = true; lr.sharedMaterial = mat; lr.widthMultiplier = w;
            lr.sortingOrder = order; lr.positionCount = count; lr.loop = loop;
            return lr;
        }

        void Start()
        {
            if (mat == null) mat = Resources.Load<Material>("LineMat");
            idle = Resources.Load<Sprite>("Sprites/vlad_idle");
            cast = Resources.Load<Sprite>("Sprites/vlad_cast");
            claw = Resources.Load<Sprite>("Sprites/vlad_claw");
            shadow = Spr("Shadow", "circle", -1, new Color(0, 0, 0, 0.45f));
            shadow.transform.localPosition = new Vector3(0, -4, 0); shadow.transform.localScale = new Vector3(68, 30, 1);
            body = Spr("Body", "vlad_idle", 0, Color.white);
            blade = Spr("Blade", "tri", 3, new Color(0.75f, 0.05f, 0.08f));
            orb = Spr("Orb", "circle", 4, Color.clear);
            orb.transform.localPosition = new Vector3(0, 90, 0);
            for (int i = 0; i < 5; i++) stars[i] = Spr("Star", "circle", 5, new Color(1f, 0.9f, 0.6f, 0.9f));
            shaft = Line("Glaive", 5f, 2, 2);
            shaft.startColor = shaft.endColor = new Color32(0x2a, 0x1a, 0x14, 0xff);
            telLine = Line("Thrust", 22f, -2, 2);
            telArc = Line("Sweep", 12f, -2, 29);
            aura = Line("Aura", 4f, -3, 48, true);
        }

        void LateUpdate()
        {
            var b = boss;
            if (b == null) { Destroy(gameObject); return; }
            Vector2 o = b.transform.position;
            float t = b.t;
            float ang = Mathf.Atan2(b.face.y, b.face.x);

            body.sprite = b.bstate is "cast" or "pools" or "rite" ? cast : (b.bstate is "tel" or "sweep" or "dash" or "dash_tel" ? claw : idle);
            body.flipX = b.face.x < 0f;
            body.transform.localPosition = new Vector3(0, b.bstate == "rite" ? 40f * Mathf.Min(1f, b.bt) : 0f, 0);
            Color tint = b.flash > 0f ? new Color(1f, 0.75f, 0.75f) : Color.white;
            if (!b.Vulnerable() && b.flash <= 0f && b.bstate != "rite") tint = new Color(0.8f, 0.6f, 0.7f);
            tint.a = b.bstate == "blink" ? 0f : (b.Vulnerable() || b.bstate == "rite" ? 1f : 0.5f + 0.1f * Mathf.Sin(t * 3f));
            body.color = tint;
            shadow.enabled = b.bstate != "blink";

            // the blood glaive
            bool showBlade = b.bstate != "blink";
            shaft.enabled = blade.enabled = showBlade;
            if (showBlade)
            {
                float ga = ang;
                if (b.bstate == "sweep" && b.combo != 1) ga += (b.combo % 2 == 0 ? 1f : -1f) * (b.bt / 0.2f - 0.5f) * 2.2f;
                Vector2 dir = new(Mathf.Cos(ga), Mathf.Sin(ga));
                Vector2 bas = o + new Vector2(0, 50), tip = bas + dir * Vlad.Reach * 0.85f;
                shaft.SetPosition(0, bas); shaft.SetPosition(1, tip);
                blade.transform.position = tip + dir * 20f;
                blade.transform.rotation = Quaternion.Euler(0, 0, ga * Mathf.Rad2Deg - 90f);
                blade.transform.localScale = new Vector3(18f, 44f, 1f);
            }

            // telegraphs
            float pulse = 0.35f + 0.3f * Mathf.Sin(t * 30f);
            bool thrust = (b.bstate == "tel" && b.combo == 1) || b.bstate == "dash_tel";
            telLine.enabled = thrust;
            if (thrust)
            {
                bool dash = b.bstate == "dash_tel";
                Vector2 dir = dash ? b.dashDir : b.face;
                Vector2 from = o + new Vector2(0, dash ? 20f : 30f);
                telLine.widthMultiplier = dash ? 30f : 22f;
                telLine.startColor = telLine.endColor = new Color(1f, dash ? 0.1f : 0.15f, 0.1f, dash ? 0.3f + 0.3f * Mathf.Sin(t * 25f) : pulse);
                telLine.SetPosition(0, from); telLine.SetPosition(1, from + dir * (dash ? 300f : Vlad.Reach + 90f));
            }
            telArc.enabled = b.bstate == "tel" && b.combo != 1;
            if (telArc.enabled)
            {
                telArc.startColor = telArc.endColor = new Color(1f, 0.15f, 0.1f, pulse);
                for (int i = 0; i < 29; i++)
                {
                    float a = ang - 65f * Mathf.Deg2Rad + i / 28f * 130f * Mathf.Deg2Rad;
                    telArc.SetPosition(i, o + new Vector2(0, 30) + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * Vlad.Reach);
                }
            }

            // the rite's gathering blood
            if (b.bstate == "rite")
            {
                float k = Mathf.Clamp01(b.bt / 1.4f);
                orb.transform.localScale = Vector3.one * (60f + 80f * k);
                orb.color = new Color(0.8f, 0f, 0.05f, 0.25f + 0.3f * k);
            }
            else orb.color = Color.clear;

            for (int i = 0; i < 5; i++)
            {
                stars[i].enabled = b.bstate == "stunned";
                float a = t * 4f + i * Mathf.PI * 2f / 5f;
                stars[i].transform.position = o + new Vector2(Mathf.Cos(a) * 30f, 180f + Mathf.Sin(a) * 30f);
                stars[i].transform.localScale = Vector3.one * 6f;
            }

            bool drinking = b.phase >= 3 && !(b.Player != null && b.Player.garlic);
            aura.enabled = drinking;
            if (drinking)
            {
                aura.startColor = aura.endColor = new Color(0.7f, 0.05f, 0.1f, 0.25f + 0.1f * Mathf.Sin(t * 4f));
                for (int i = 0; i < 48; i++)
                {
                    float a = i / 48f * Mathf.PI * 2f;
                    aura.SetPosition(i, o + new Vector2(Mathf.Cos(a) * 190f, -4f + Mathf.Sin(a) * 190f * 0.45f));
                }
            }
        }
    }
}

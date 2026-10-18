using UnityEngine;

namespace Biertan.Bosses
{
    /// <summary>Draws the Balaur's body, necks, the stag's gem crown, the gaze beam and the devour lane
    /// (balaur.gd _draw). Necks and beams are LineRenderers in world space.</summary>
    public class BalaurView : MonoBehaviour
    {
        public Balaur boss;
        SpriteRenderer body, glow, lane, laneEdge, mouth, eyeL, eyeR;
        readonly SpriteRenderer[] gems = new SpriteRenderer[5];
        LineRenderer[] neckOut, neckIn;
        LineRenderer beamWide, beamCore, aim, lungeOut, lungeIn;
        static Material mat;

        static Sprite S(string n) => Resources.Load<Sprite>("Sprites/" + n);

        SpriteRenderer Spr(string name, string sprite, int order, Color c)
        {
            var go = new GameObject(name);
            go.transform.SetParent(transform, false);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = S(sprite); sr.sortingOrder = order; sr.color = c;
            return sr;
        }

        LineRenderer Line(string name, Color c, float w, int order, int n = 2)
        {
            var go = new GameObject(name);
            go.transform.SetParent(transform, false);
            var lr = go.AddComponent<LineRenderer>();
            lr.useWorldSpace = true; lr.sharedMaterial = mat; lr.widthMultiplier = w;
            lr.startColor = lr.endColor = c; lr.sortingOrder = order; lr.positionCount = n;
            lr.numCapVertices = 4;
            return lr;
        }

        void Start()
        {
            if (mat == null) mat = Resources.Load<Material>("LineMat");
            body = Spr("Body", "balaur_body", 2, Color.white);
            glow = Spr("GemGlow", "circle", 4, Color.clear);
            for (int i = 0; i < 5; i++) gems[i] = Spr("Gem", "circle", 4, Color.clear);
            lane = Spr("Lane", "white", -5, Color.clear);
            laneEdge = Spr("LaneEdge", "white", -6, Color.clear);
            mouth = Spr("Maw", "circle", 1, new Color32(0x2e, 0x4a, 0x30, 0xff));
            eyeL = Spr("Eye", "circle", 2, new Color32(0xff, 0xcc, 0x3a, 0xff));
            eyeR = Spr("Eye", "circle", 2, new Color32(0xff, 0xcc, 0x3a, 0xff));
            neckOut = new LineRenderer[3]; neckIn = new LineRenderer[3];
            for (int i = 0; i < 3; i++)
            {
                neckOut[i] = Line("Neck", new Color32(0x0e, 0x1a, 0x12, 0xff), 34f, 0, 13);
                neckIn[i] = Line("Neck", new Color32(0x2e, 0x4a, 0x30, 0xff), 26f, 1, 13);
            }
            beamWide = Line("Beam", new Color(0.4f, 1f, 0.6f, 0.35f), 60f, 6);
            beamCore = Line("Beam", new Color(0.85f, 1f, 0.9f, 0.9f), 12f, 7);
            aim = Line("Aim", new Color(0.5f, 1f, 0.6f, 0.25f), 3f, 6);
            lungeOut = Line("Lunge", new Color32(0x0e, 0x1a, 0x12, 0xff), 120f, 3);
            lungeIn = Line("Lunge", new Color32(0x2e, 0x4a, 0x30, 0xff), 104f, 4);
        }

        void LateUpdate()
        {
            var b = boss;
            if (b == null) { Destroy(gameObject); return; }
            Vector2 o = b.Pos;
            var c = body.color;
            if (b.dead) c.a = Mathf.Max(0f, c.a - Time.deltaTime / 2f);
            body.color = c;

            // necks: quadratic curve from the coil to each head
            for (int i = 0; i < 3; i++)
            {
                var h = i < b.heads.Count ? b.heads[i] : null;
                neckOut[i].enabled = neckIn[i].enabled = h != null;
                if (h == null) continue;
                Vector2 a = h.anchor, e = h.transform.position;
                if (h.hstate is "stump" or "sealed") e = a + (e - a) * 0.9f;
                Vector2 mid = (a + e) / 2f + new Vector2(Mathf.Sin(b.t * 1.4f + (a.x - o.x)) * 30f, 60f);
                for (int k = 0; k < 13; k++)
                {
                    float q = k / 12f;
                    Vector2 p = Vector2.Lerp(Vector2.Lerp(a, mid, q), Vector2.Lerp(mid, e, q), q);
                    neckOut[i].SetPosition(k, p); neckIn[i].SetPosition(k, p);
                }
            }

            // the stag's jewelled crown
            float g = b.gazeState == "charge" ? 0.4f + 0.6f * b.gt / 1.3f : (b.gazeState == "beam" ? 1f : 0.3f);
            if (b.dead) g = 0f;
            for (int i = 0; i < 5; i++)
            {
                gems[i].transform.position = b.GemPos + new Vector2((i - 2) * 16f, -Mathf.Abs(i - 2) * 6f);
                gems[i].transform.localScale = Vector3.one * 12f;
                gems[i].color = new Color(0.3f, 1f, 0.6f, g);
            }
            glow.transform.position = b.GemPos;
            glow.transform.localScale = Vector3.one * Mathf.Max(0.01f, 32f * g);
            glow.color = new Color(0.5f, 1f, 0.7f, 0.35f * g);

            Vector2 dir = new(Mathf.Cos(b.gazeA), Mathf.Sin(b.gazeA));
            aim.enabled = b.gazeState == "charge";
            beamWide.enabled = beamCore.enabled = b.gazeState == "beam";
            if (aim.enabled) { aim.SetPosition(0, b.GemPos); aim.SetPosition(1, b.GemPos + dir * 1200f); }
            if (beamCore.enabled)
                foreach (var lr in new[] { beamWide, beamCore }) { lr.SetPosition(0, b.GemPos); lr.SetPosition(1, b.GemPos + dir * 1300f); }

            // the devour lane and the lunge
            bool tel = b.devourState == "tel";
            Vector2 laneC = new(b.laneX, o.y - 80f - 310f);
            lane.transform.position = laneC; lane.transform.localScale = new Vector3(170, 620, 1);
            laneEdge.transform.position = laneC; laneEdge.transform.localScale = new Vector3(176, 626, 1);
            lane.color = tel ? new Color(1f, 0.2f, 0.1f, 0.15f + 0.15f * Mathf.Sin(b.t * 20f)) : Color.clear;
            laneEdge.color = tel ? new Color(1f, 0.3f, 0.1f, 0.6f) : Color.clear;
            bool lg = b.lunge > 0f;
            lungeOut.enabled = lungeIn.enabled = mouth.enabled = eyeL.enabled = eyeR.enabled = lg;
            if (lg)
            {
                Vector2 end = new(b.laneX, o.y - 80f - 620f * b.lunge);
                foreach (var lr in new[] { lungeOut, lungeIn }) { lr.SetPosition(0, o + new Vector2(0, -40)); lr.SetPosition(1, end); }
                mouth.transform.position = end; mouth.transform.localScale = Vector3.one * 128f;
                eyeL.transform.position = end + new Vector2(-22, -10); eyeL.transform.localScale = Vector3.one * 16f;
                eyeR.transform.position = end + new Vector2(22, -10); eyeR.transform.localScale = Vector3.one * 16f;
            }
        }
    }

    /// <summary>Draws one head: open/closed jaws turned toward its target, the element tint, the strike
    /// telegraph, the drinking ripple, the stump with its regrowth clock, and a small health bar.</summary>
    public class BalaurHeadView : MonoBehaviour
    {
        public BalaurHead head;
        SpriteRenderer sprite, stumpOut, stumpIn, ripple, barBg, bar, clock;
        LineRenderer tel;
        Sprite closed, open;

        SpriteRenderer Spr(string name, string s, int order, Color c)
        {
            var go = new GameObject(name);
            go.transform.SetParent(transform, false);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/" + s); sr.sortingOrder = order; sr.color = c;
            return sr;
        }

        void Start()
        {
            closed = Resources.Load<Sprite>("Sprites/balaur_head");
            open = Resources.Load<Sprite>("Sprites/balaur_head_open");
            sprite = Spr("Head", "balaur_head", 2, Color.white);
            stumpOut = Spr("Stump", "circle", 1, Color.white); stumpOut.transform.localScale = Vector3.one * 44f;
            stumpIn = Spr("StumpCore", "circle", 2, Color.white); stumpIn.transform.localScale = Vector3.one * 28f;
            clock = Spr("Regrow", "circle", 3, new Color32(0xff, 0xb3, 0x47, 0xcc));
            clock.transform.localPosition = new Vector3(0, 36, 0);
            ripple = Spr("Ripple", "circle", 0, Color.clear);
            barBg = Spr("BarBg", "white", 5, new Color(0, 0, 0, 0.7f));
            barBg.transform.localPosition = new Vector3(0, 46, 0); barBg.transform.localScale = new Vector3(48, 5, 1);
            bar = Spr("Bar", "white", 6, new Color32(0xc0, 0x39, 0x2b, 0xff));
            var go = new GameObject("Telegraph");
            go.transform.SetParent(transform, false);
            tel = go.AddComponent<LineRenderer>();
            tel.useWorldSpace = true; tel.sharedMaterial = Resources.Load<Material>("LineMat");
            tel.widthMultiplier = 30f; tel.positionCount = 2; tel.sortingOrder = -1;
        }

        void LateUpdate()
        {
            var h = head;
            bool stump = h.hstate is "stump" or "sealed";
            sprite.enabled = !stump;
            stumpOut.enabled = stumpIn.enabled = stump;
            clock.enabled = h.hstate == "stump";
            if (stump)
            {
                stumpOut.color = h.seared ? new Color32(0x1a, 0x1a, 0x14, 0xff) : new Color32(0x3a, 0x5a, 0x30, 0xff);
                stumpIn.color = h.seared ? new Color32(0x0e, 0x0e, 0x0a, 0xff) : new Color32(0x6a, 0x1a, 0x1a, 0xff);
                clock.transform.localScale = Vector3.one * 28f * Mathf.Clamp01(h.regrowT / BalaurHead.RegrowTime);
            }
            else
            {
                sprite.sprite = h.hstate is "tel" or "breath" or "drink" or "spit" ? open : closed;
                float ang = Mathf.Atan2(h.face.y, h.face.x) * Mathf.Rad2Deg;
                bool flip = Mathf.Abs(ang) > 90f;
                sprite.transform.localRotation = Quaternion.Euler(0, 0, ang);
                sprite.transform.localScale = new Vector3(1, flip ? -1 : 1, 1);
                sprite.color = h.flash > 0f ? new Color(1f, 0.75f, 0.75f) : h.Tint();
            }
            tel.enabled = h.hstate == "tel";
            if (tel.enabled)
            {
                Color c = h.element == "frost" ? new Color(0.6f, 0.85f, 1f) : new Color(1f, 0.5f, 0.1f);
                c.a = 0.3f + 0.3f * Mathf.Sin(h.t * 30f);
                tel.startColor = tel.endColor = c;
                tel.SetPosition(0, h.transform.position); tel.SetPosition(1, h.strikeTo);
            }
            ripple.enabled = h.hstate == "drink";
            if (ripple.enabled) { ripple.transform.localScale = Vector3.one * (60f + 20f * Mathf.Sin(h.t * 10f)); ripple.color = new Color(0.4f, 0.6f, 0.9f, 0.3f); }
            bool showBar = !stump && h.hp < h.maxHp;
            barBg.enabled = bar.enabled = showBar;
            if (showBar)
            {
                float k = Mathf.Clamp01(h.hp / h.maxHp);
                bar.transform.localScale = new Vector3(48 * k, 5, 1);
                bar.transform.localPosition = new Vector3(-24 + 24 * k, 46, 0);
            }
        }
    }
}

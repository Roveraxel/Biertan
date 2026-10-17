using UnityEngine;
using Biertan.Core;
using Biertan.Player;

namespace Biertan.Levels
{
    /// <summary>Telegraphed eruption of roots under the hunter (Muma Pădurii). Port of root_spike.gd.</summary>
    public class RootSpike : MonoBehaviour
    {
        public const float R = 48f;
        public float delay = 0.85f;
        public float dmg = 14f;

        float t;
        bool done;
        SpriteRenderer disc;
        LineRenderer warn;
        SpriteRenderer[] spikes;

        void Start()
        {
            disc = Make("Disc", "circle", Vector2.zero, new Vector2(R * 2, R * 2 * 0.55f), new Color(0.1f, 0.06f, 0.02f, 0.35f), -900);
            var go = new GameObject("Warn");
            go.transform.SetParent(transform, false);
            warn = go.AddComponent<LineRenderer>();
            warn.useWorldSpace = false; warn.loop = true; warn.widthMultiplier = 3f; warn.positionCount = 32;
            warn.sharedMaterial = Resources.Load<Material>("LineMat"); warn.sortingOrder = -899;
            warn.startColor = warn.endColor = new Color(0.75f, 0.25f, 0.1f, 0.8f);
            spikes = new SpriteRenderer[7];
            for (int i = 0; i < 7; i++)
            {
                float a = i * Mathf.PI * 2f / 7f + 0.3f;
                var b = new Vector2(Mathf.Cos(a), Mathf.Sin(a) * 0.55f) * R * 0.45f;
                spikes[i] = Make("Root", "circle", b, new Vector2(12, 0), new Color(0.29f, 0.2f, 0.12f), 1);
                spikes[i].enabled = false;
            }
            gameObject.AddComponent<UnityEngine.Rendering.SortingGroup>();
        }

        SpriteRenderer Make(string n, string s, Vector2 local, Vector2 scale, Color c, int order)
        {
            var go = new GameObject(n);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = local;
            go.transform.localScale = new Vector3(scale.x, scale.y, 1);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/" + s);
            sr.color = c; sr.sortingOrder = order;
            return sr;
        }

        void FixedUpdate()
        {
            t += Time.fixedDeltaTime;
            if (!done && t >= delay)
            {
                done = true;
                AudioManager.I?.Sfx("root", -4f, Random.Range(0.9f, 1.1f));
                var p = FindAnyObjectByType<PlayerController>();
                if (p != null && Vector2.Distance(p.transform.position, transform.position) < R + 8f)
                    p.Hurt(dmg, ((Vector2)(p.transform.position - transform.position)).normalized);
            }
            if (t > delay + 0.6f) Destroy(gameObject);
        }

        void Update()
        {
            if (warn == null) return;
            if (!done)
            {
                float k = Mathf.Clamp01(t / delay);
                for (int i = 0; i < 32; i++)
                {
                    float a = i / 32f * Mathf.PI * 2f;
                    warn.SetPosition(i, new Vector3(Mathf.Cos(a) * R * k, Mathf.Sin(a) * R * k * 0.55f, 0));
                }
                return;
            }
            warn.enabled = false;
            float fade = Mathf.Clamp01(1f - (t - delay) / 0.6f);
            float grow = Mathf.Min(1f, (t - delay) * 8f);
            disc.color = new Color(0.12f, 0.08f, 0.04f, 0.6f * fade);
            for (int i = 0; i < spikes.Length; i++)
            {
                var s = spikes[i];
                s.enabled = true;
                // a pointed root rising from its base: a tall, thin ellipse lifted by half its height
                float a = i * Mathf.PI * 2f / 7f + 0.3f;
                var b = new Vector2(Mathf.Cos(a), Mathf.Sin(a) * 0.55f) * R * 0.45f;
                float h = 46f * grow;
                s.transform.localScale = new Vector3(12, h, 1);
                s.transform.localPosition = new Vector3(b.x * 1.15f, b.y + h * 0.5f, 0);
                var c = s.color; c.a = fade; s.color = c;
            }
        }
    }
}

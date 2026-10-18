using UnityEngine;
using Biertan.Core;

namespace Biertan.Bosses
{
    /// <summary>A bolt of blood thrown by Vlad. Salt rings dissolve it. Port of blood_bolt.gd.</summary>
    public class BloodBolt : MonoBehaviour
    {
        public Vector2 vel;
        public float life = 3f, dmg = 10f;
        Transform trail;

        public static BloodBolt Spawn(Transform parent, Vector2 at, Vector2 vel, float dmg)
        {
            var go = new GameObject("BloodBolt");
            go.transform.SetParent(parent, false);
            go.transform.position = at;
            var b = go.AddComponent<BloodBolt>();
            b.vel = vel; b.dmg = dmg;
            return b;
        }

        void Start()
        {
            Dot("Glow", new Vector2(0, 14), 14f, new Color(0.75f, 0.05f, 0.08f), 6);
            Dot("Core", new Vector2(0, 14), 7f, new Color(1f, 0.45f, 0.4f), 7);
            trail = Dot("Trail", new Vector2(0, 14), 1f, new Color(0.6f, 0f, 0.05f, 0.5f), 5, "white").transform;
            float a = Mathf.Atan2(vel.y, vel.x) * Mathf.Rad2Deg;
            trail.localRotation = Quaternion.Euler(0, 0, a);
            trail.localScale = new Vector3(22f, 7f, 1f);
            trail.localPosition = new Vector3(0, 14, 0) - (Vector3)(vel.normalized * 11f);
            Lights.Point(transform, 80f, new Color(1f, 0.2f, 0.15f), 0.6f);
        }

        SpriteRenderer Dot(string n, Vector2 local, float size, Color c, int order, string sprite = "circle")
        {
            var go = new GameObject(n);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = local;
            go.transform.localScale = Vector3.one * size;
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/" + sprite); sr.color = c; sr.sortingOrder = order;
            return sr;
        }

        void FixedUpdate()
        {
            float dt = Time.fixedDeltaTime;
            life -= dt;
            transform.position += (Vector3)(vel * dt);
            if (life <= 0f) { Destroy(gameObject); return; }
            Vector2 p = transform.position;
            foreach (var r in SaltRing.All) if (r != null && r.Contains(p)) { Destroy(gameObject); return; }
            var pl = GameManager.I?.player;
            if (pl != null && Vector2.Distance(pl.transform.position, p + new Vector2(0, -14)) < 20f)
            {
                pl.Hurt(dmg, vel.normalized);
                Destroy(gameObject);
            }
        }
    }

    /// <summary>A pool of spilled blood that erupts into bloodflame after a delay. Port of blood_geyser.gd.</summary>
    public class BloodGeyser : MonoBehaviour
    {
        public const float R = 56f;
        public float t, delay = 1.3f, dmg = 18f;
        public bool done;
        SpriteRenderer pool, rim;
        SpriteRenderer[] flames;
        UnityEngine.Rendering.Universal.Light2D lamp;

        public static BloodGeyser Spawn(Transform parent, Vector2 at, float dmg, float delay)
        {
            var go = new GameObject("BloodGeyser");
            go.transform.SetParent(parent, false);
            go.transform.position = at;
            var g = go.AddComponent<BloodGeyser>();
            g.dmg = dmg; g.delay = delay;
            return g;
        }

        SpriteRenderer Spr(string n, string s, int order)
        {
            var go = new GameObject(n);
            go.transform.SetParent(transform, false);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/" + s); sr.sortingOrder = order;
            return sr;
        }

        void Start()
        {
            rim = Spr("Rim", "circle", -900); rim.transform.localScale = new Vector3(R * 2f, R * 1.2f, 1f);
            pool = Spr("Pool", "circle", -899);
            flames = new SpriteRenderer[6];
            for (int i = 0; i < 6; i++) { flames[i] = Spr("Flame", "tri", 5); flames[i].enabled = false; }
            lamp = Lights.Point(transform, R * 2.2f, new Color(1f, 0.15f, 0.1f), 0f);
        }

        void FixedUpdate()
        {
            t += Time.fixedDeltaTime;
            if (!done && t >= delay)
            {
                done = true;
                if (lamp != null) lamp.intensity = 1.2f;
                AudioManager.I?.Sfx("fire", -6f, 1.3f);
                var p = GameManager.I?.player;
                if (p != null && Vector2.Distance(p.transform.position, transform.position) < R + 6f)
                    p.Hurt(dmg, ((Vector2)(p.transform.position - transform.position)).normalized);
            }
            if (t > delay + 0.6f) Destroy(gameObject);
        }

        void LateUpdate()
        {
            if (pool == null) return;
            if (!done)
            {
                float k = t / delay;
                float r = R * Mathf.Min(1f, k * 1.6f);
                pool.transform.localScale = new Vector3(r * 2f, r * 1.2f, 1f);
                pool.color = new Color(0.35f, 0f, 0.03f, 0.55f);
                rim.color = new Color(0.9f, 0.1f, 0.1f, 0.15f + 0.2f * k);
                return;
            }
            if (lamp != null) lamp.intensity = Mathf.Max(0f, lamp.intensity - Time.deltaTime * 2f);
            float a = Mathf.Clamp01(1f - (t - delay) / 0.6f);
            pool.color = new Color(0.35f, 0f, 0.03f, 0.55f * a);
            rim.enabled = false;
            for (int i = 0; i < 6; i++)
            {
                var f = flames[i];
                f.enabled = true;
                float h = (80f + 30f * Mathf.Sin(i * 1.7f + t * 20f)) * a;
                f.transform.localPosition = new Vector3((i - 2.5f) * R * 0.3f, h / 2f, 0);
                f.transform.localScale = new Vector3(18f, Mathf.Max(0.01f, h), 1f);
                f.color = new Color(0.85f, 0.08f, 0.06f, 0.85f * a);
            }
        }
    }
}

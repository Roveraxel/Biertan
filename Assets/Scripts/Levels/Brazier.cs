using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>An iron fire-basket. Light it with E. In the Vârcolac's phase 2 the fires burn down after
    /// 26 s, and the beast can only be wounded near one that's lit. Port of brazier.gd.</summary>
    public class Brazier : Interactable
    {
        public static readonly List<Brazier> All = new();

        public bool lit = true;
        public bool decays;
        float litT, t;
        public float baseEnergy = 1.25f;

        Light2D glow;
        SpriteRenderer flame, core, ember, timer;

        protected override void OnEnable() { base.OnEnable(); All.Add(this); }
        protected override void OnDisable() { base.OnDisable(); All.Remove(this); }

        void Awake()
        {
            gameObject.layer = LayerMask.NameToLayer("World");
            gameObject.AddComponent<UnityEngine.Rendering.SortingGroup>();
            var col = gameObject.AddComponent<CircleCollider2D>();
            col.radius = 13f;
            Part("Shadow", "circle", new Vector2(0, -2), new Vector2(36, 16), new Color(0, 0, 0, 0.35f), -1);
            Part("Post", "white", new Vector2(0, 7), new Vector2(6, 14), new Color32(0x2a, 0x26, 0x22, 0xff), 0);
            Part("Basket", "white", new Vector2(0, 17), new Vector2(24, 10), new Color32(0x3a, 0x35, 0x30, 0xff), 1);
            flame = Part("Flame", "circle", new Vector2(0, 30), new Vector2(18, 26), new Color32(0xe8, 0x74, 0x2a, 0xff), 2);
            core = Part("Core", "circle", new Vector2(0, 27), new Vector2(10, 16), new Color32(0xff, 0xd2, 0x7a, 0xff), 3);
            ember = Part("Ember", "circle", new Vector2(0, 22), new Vector2(10, 10), new Color32(0x1a, 0x17, 0x14, 0xff), 2);
            timer = Part("Timer", "circle", new Vector2(0, 22), new Vector2(40, 40), new Color(1f, 0.8f, 0.4f, 0f), -1);
            glow = Lights.Point(transform, 270f, new Color(1f, 0.66f, 0.32f), baseEnergy, new Vector2(0, 16));
            SetLit(lit);
        }

        SpriteRenderer Part(string n, string sprite, Vector2 local, Vector2 scale, Color c, int order)
        {
            var go = new GameObject(n);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = local;
            go.transform.localScale = new Vector3(scale.x, scale.y, 1);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/" + sprite);
            sr.color = c; sr.sortingOrder = order;
            return sr;
        }

        public void SetLit(bool v)
        {
            lit = v;
            if (v) litT = 26f;
            if (glow != null) glow.enabled = v;
            if (flame != null) { flame.enabled = core.enabled = v; ember.enabled = !v; }
        }

        public override bool CanInteract() => !lit;
        public override string PromptText() => "E   Light the brazier";

        public override void Interact()
        {
            if (lit) return;
            SetLit(true);
            AudioManager.I?.Sfx("ignite", -4f);
            FxUtil.Ring(transform.position, new Color(1f, 0.7f, 0.3f), 90f);
        }

        void Update()
        {
            t += Time.deltaTime;
            if (lit && decays)
            {
                litT -= Time.deltaTime;
                if (litT <= 0f) SetLit(false);
            }
            if (!lit) { timer.color = Color.clear; return; }
            glow.intensity = baseEnergy + 0.12f * Mathf.Sin(t * 13f) + 0.06f * Mathf.Sin(t * 29f);
            float k = Mathf.Sin(t * 14f) * 2f;
            flame.transform.localScale = new Vector3(18, 26 + k, 1);
            core.transform.localScale = new Vector3(10, 16 + k * 0.6f, 1);
            // dimming halo in the last six seconds, like the GDScript countdown arc
            timer.color = decays && litT < 6f ? new Color(1f, 0.8f, 0.4f, 0.25f * (1f - litT / 6f) + 0.1f * Mathf.Sin(t * 20f)) : Color.clear;
        }
    }
}

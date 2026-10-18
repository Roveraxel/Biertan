using UnityEngine;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>A portcullis sealed by a blood ward. Opens when the ward is broken. Port of gate.gd.</summary>
    public class Gate : MonoBehaviour
    {
        public Rect rect;          // Godot rect
        public bool opened;
        public float lift;
        BoxCollider2D box;
        Transform bars;
        SpriteRenderer seal;

        public static Gate Make(Transform parent, Rect godotRect)
        {
            var go = new GameObject("Gate") { layer = LayerMask.NameToLayer("World") };
            go.transform.SetParent(parent, false);
            go.transform.position = LevelBase.P(godotRect.center);
            var g = go.AddComponent<Gate>();
            g.rect = godotRect;
            g.box = go.AddComponent<BoxCollider2D>();
            g.box.size = godotRect.size;
            g.Build();
            return g;
        }

        void Build()
        {
            bars = new GameObject("Portcullis").transform;
            bars.SetParent(transform, false);
            // anchored at the top of the wall; bars rise 60 above it
            bars.localPosition = new Vector3(0, rect.height / 2f, 0);
            var col = new Color(0.18f, 0.16f, 0.15f);
            float w = rect.width;
            for (float x = -w / 2f + 6f; x < w / 2f; x += 14f) Bar(new Vector2(x, 30f), new Vector2(4f, 60f), col);
            for (int i = 0; i < 4; i++) Bar(new Vector2(0, 60f * (i + 0.5f) / 4f), new Vector2(w, 3f), col);
            seal = Bar(new Vector2(0, 30f), new Vector2(18f, 18f), new Color(0.7f, 0.05f, 0.1f, 0.8f), "circle");
        }

        SpriteRenderer Bar(Vector2 local, Vector2 size, Color c, string s = "white")
        {
            var go = new GameObject("Bar");
            go.transform.SetParent(bars, false);
            go.transform.localPosition = local;
            go.transform.localScale = new Vector3(size.x, size.y, 1);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/" + s); sr.color = c; sr.sortingOrder = 2;
            return sr;
        }

        public void Open()
        {
            opened = true;
            box.enabled = false;
            seal.enabled = false;
            AudioManager.I?.Sfx("ignite", -4f, 0.6f);
            if (GameManager.Instant) lift = 1f;
        }

        void Update()
        {
            if (!opened || bars == null) return;
            lift = Mathf.Min(1f, lift + Time.deltaTime * 0.8f);
            // the portcullis winds up into the gatehouse
            bars.localScale = new Vector3(1f, 1f - lift, 1f);
            bars.localPosition = new Vector3(0, rect.height / 2f + 60f * lift, 0);
            if (lift >= 1f) bars.gameObject.SetActive(false);
        }
    }
}

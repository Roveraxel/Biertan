using System;
using UnityEngine;

namespace Biertan.Levels
{
    /// <summary>A villager who runs on, says their piece in a speech bubble, and runs off
    /// (Magda's scenes). Port of cameo.gd.</summary>
    public class Cameo : MonoBehaviour
    {
        public string sprite = "npc_magda";
        public Vector2 vel;
        public string line = "";
        public float life = 4f;
        public float stopAt = -1f;      // seconds until she stops (and acts); -1 = keep running
        public float resumeAfter = 1.6f;
        public Action action;

        float t;
        bool acted;
        SpriteRenderer body;

        void Start()
        {
            gameObject.AddComponent<UnityEngine.Rendering.SortingGroup>();
            var go = new GameObject("Body");
            go.transform.SetParent(transform, false);
            body = go.AddComponent<SpriteRenderer>();
            body.sprite = Resources.Load<Sprite>("Sprites/" + sprite);

            if (string.IsNullOrEmpty(line)) return;
            // speech bubble: parchment box + pointer + dark text
            var bubble = new GameObject("Bubble");
            bubble.transform.SetParent(transform, false);
            bubble.transform.localPosition = new Vector3(0, 102, 0);
            var text = new GameObject("Text").AddComponent<TextMesh>();
            text.transform.SetParent(bubble.transform, false);
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.GetComponent<MeshRenderer>().sharedMaterial = text.font.material;
            text.GetComponent<MeshRenderer>().sortingOrder = 52;
            text.text = line; text.fontSize = 48; text.characterSize = 3.2f;
            text.anchor = TextAnchor.MiddleCenter; text.color = new Color32(0x2a, 0x14, 0x14, 0xff);
            float w = line.Length * 8.6f + 24f;
            Box(bubble.transform, Vector2.zero, new Vector2(w, 32), 50);
            var tip = Box(bubble.transform, new Vector2(0, -18), new Vector2(12, 12), 50);
            tip.transform.localRotation = Quaternion.Euler(0, 0, 45);
        }

        static SpriteRenderer Box(Transform parent, Vector2 pos, Vector2 size, int order)
        {
            var go = new GameObject("Box");
            go.transform.SetParent(parent, false);
            go.transform.localPosition = pos;
            go.transform.localScale = new Vector3(size.x, size.y, 1);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/white");
            sr.color = new Color(0.95f, 0.92f, 0.85f, 0.95f);
            sr.sortingOrder = order;
            return sr;
        }

        void Update()
        {
            t += Time.deltaTime;
            bool standing = stopAt >= 0f && t >= stopAt && t < stopAt + resumeAfter;
            if (standing)
            {
                if (!acted) { acted = true; action?.Invoke(); }
            }
            else transform.position += (Vector3)(vel * Time.deltaTime);
            if (body != null)
            {
                float bob = standing ? 0f : Mathf.Abs(Mathf.Sin(t * 14f)) * 4f;
                body.transform.localPosition = new Vector3(0, bob, 0);
                body.flipX = vel.x < 0f;
            }
            if (t > life) Destroy(gameObject);
        }
    }
}

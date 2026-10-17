using UnityEngine;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>A salt crystal growing from the ground (Salt Caves, the Hollow). Chip it with E for
    /// +2 salt; it regrows after 20 seconds. Port of prop.gd "crystal" + main.gd prop_used().</summary>
    public class SaltCrystal : Interactable
    {
        float regrow;
        SpriteRenderer[] shards;
        float t;

        void Start()
        {
            gameObject.AddComponent<UnityEngine.Rendering.SortingGroup>();
            var col = gameObject.AddComponent<CircleCollider2D>();
            col.radius = 14f;
            gameObject.layer = LayerMask.NameToLayer("World");
            var glow = Make("Glow", new Vector2(0, 14), new Vector2(110, 70), new Color(0.85f, 0.92f, 1f, 0.12f), -2);
            shards = new[]
            {
                Make("Shard", new Vector2(-9, 16), new Vector2(12, 34), new Color(0.88f, 0.92f, 0.98f), 1),
                Make("Shard", new Vector2(0, 22), new Vector2(14, 46), new Color(0.95f, 0.97f, 1f), 2),
                Make("Shard", new Vector2(10, 14), new Vector2(11, 28), new Color(0.8f, 0.86f, 0.95f), 1),
                glow,
            };
            shards[0].transform.localRotation = Quaternion.Euler(0, 0, 18);
            shards[2].transform.localRotation = Quaternion.Euler(0, 0, -20);
        }

        SpriteRenderer Make(string n, Vector2 local, Vector2 scale, Color c, int order)
        {
            var go = new GameObject(n);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = local;
            go.transform.localScale = new Vector3(scale.x, scale.y, 1);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/circle");
            sr.color = c; sr.sortingOrder = order;
            return sr;
        }

        public override bool CanInteract() => regrow <= 0f;
        public override string PromptText() => "E   Chip salt from the crystal";

        public override void Interact()
        {
            var p = GameManager.I.player;
            regrow = 20f;
            p.salt += 2;
            p.saltUnlocked = true;
            AudioManager.I?.Sfx("crystal", -4f, Random.Range(0.9f, 1.1f));
            FxUtil.Ring(transform.position, new Color(0.9f, 0.95f, 1f, 0.8f), 50f);
            HudEvents.Toast("You chip off raw salt.  +2 salt  (R to throw)");
        }

        void Update()
        {
            t += Time.deltaTime;
            regrow = Mathf.Max(0f, regrow - Time.deltaTime);
            if (shards == null) return;
            float k = regrow > 0f ? 0.35f : 1f;
            for (int i = 0; i < 3; i++) shards[i].transform.localScale = new Vector3(shards[i].transform.localScale.x, (i == 1 ? 46 : i == 0 ? 34 : 28) * k, 1);
            shards[3].color = new Color(0.85f, 0.92f, 1f, (regrow > 0f ? 0.03f : 0.12f) + 0.03f * Mathf.Sin(t * 3f));
        }
    }
}

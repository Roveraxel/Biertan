using UnityEngine;
using Biertan.Core;
using Biertan.Player;

namespace Biertan.Levels
{
    /// <summary>
    /// A ham on a chain swinging across the smokehouse: an obstacle to time, not to fight. It sweeps back and forth
    /// over its anchor; walk into it and it knocks the hunter aside and hurts a little. Drawn in 2D as a chain and a
    /// ham, which the 3D view stands upright like the other figures.
    /// </summary>
    public class SwingingHook : MonoBehaviour
    {
        public Vector2 anchor;          // Unity 2D
        public float reach = 150f;      // half the sweep, in 2D units
        public float period = 2.4f;
        public float phase;
        public bool alongX = true;
        public string sprite = "ham_hook";

        PlayerController player;
        float hitCd, t;

        void Start()
        {
            player = FindAnyObjectByType<PlayerController>();
            if (Resources.Load<Sprite>("Sprites/Props/" + sprite) != null)
            {
                // PixelLab art (42 px a unit in 2D): scaled so it hangs about a man's height in the 3D view
                Part("Ham", "Props/" + sprite, Vector2.zero, new Vector2(39f, 39f), Color.white, 1);
                return;
            }
            Part("Chain", "white", new Vector2(0, 46), new Vector2(3, 54), new Color32(0x3a, 0x34, 0x30, 0xff), 0);
            Part("Ham", "circle", new Vector2(0, 16), new Vector2(26, 34), new Color32(0x8a, 0x3a, 0x2a, 0xff), 1);
            Part("Rind", "circle", new Vector2(-4, 20), new Vector2(12, 16), new Color32(0xc8, 0x9a, 0x7a, 0xff), 2);
            Part("Hook", "white", new Vector2(0, 34), new Vector2(8, 4), new Color32(0x2a, 0x26, 0x22, 0xff), 2);
        }

        void Part(string n, string sprite, Vector2 local, Vector2 size, Color c, int order)
        {
            var go = new GameObject(n);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = local;
            go.transform.localScale = new Vector3(size.x, size.y, 1f);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Resources.Load<Sprite>("Sprites/" + sprite);
            sr.color = c; sr.sortingOrder = order;
        }

        void Update()
        {
            t += Time.deltaTime;
            hitCd = Mathf.Max(0f, hitCd - Time.deltaTime);
            float s = Mathf.Sin((t + phase) * Mathf.PI * 2f / period);
            transform.position = anchor + (alongX ? Vector2.right : Vector2.up) * s * reach;
            if (player == null || hitCd > 0f || GameManager.I == null || GameManager.I.state != GameManager.State.Play) return;
            Vector2 to = (Vector2)player.transform.position - (Vector2)transform.position;
            if (to.magnitude < 30f)
            {
                hitCd = 1.2f;
                // knocked sideways, the way the ham is swinging
                float swingDir = Mathf.Sign(Mathf.Cos((t + phase) * Mathf.PI * 2f / period));
                player.Hurt(4f, (alongX ? Vector2.right : Vector2.up) * swingDir);
                AudioManager.I?.SfxAt("blip", transform.position, -6f, 0.5f);
            }
        }
    }
}

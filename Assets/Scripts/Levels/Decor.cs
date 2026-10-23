using UnityEngine;

namespace Biertan.Levels
{
    /// <summary>
    /// A piece of street clutter (barrel, cart, firewood, a crow) drawn as PixelLab pixel art standing upright in
    /// the 3D world like the villagers. Sprite from Resources/Sprites/Props/&lt;sprite&gt;. Solid ones block the
    /// hunter with a small round footprint.
    /// </summary>
    public class Decor : MonoBehaviour
    {
        public string sprite;
        public float radius;       // 0: walk through it
        public bool flip;
        public float scale = 1f;   // PixelLab fills every canvas: a bench comes as tall as a cart

        /// <summary>How big each prop really stands, relative to its drawing.</summary>
        public static float SizeOf(string sprite) => sprite switch
        {
            "bench" => 0.6f, "crate" => 0.75f, "sacks" => 0.7f, "barrel" => 0.72f, "barrels" => 0.95f,
            "firewood" => 0.8f, "handcart" => 1.2f, "haycart" => 1.6f, "well" => 1.4f, "stall" => 1.8f,
            "trough" => 0.9f, "lantern" => 1.45f, "cauldron" => 0.75f, "wheel" => 0.7f, "laundry" => 1.1f,
            _ => 1f,
        };

        public void Build()
        {
            if (radius <= 0f) return;
            gameObject.layer = LayerMask.NameToLayer("World");
            var c = gameObject.AddComponent<CircleCollider2D>();
            c.radius = radius;
            gameObject.isStatic = true;
        }
    }
}

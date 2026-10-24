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
            "hams_beam" => 1.4f, "sausage_rack" => 1.2f, "salt_barrel" => 0.75f, "chopping_block" => 0.7f, "ham_pile" => 0.8f,
            "smoke_pit" => 1.2f, "spiridus_lantern" => 0.45f, "red_cap" => 0.35f, "ladder" => 1.6f, "fish_crate" => 0.75f,
            "potlid" => 0.5f, "shelf" => 1.2f, "hook_empty" => 0.9f,
            "fig_mon" or "fig_tue" or "fig_wed" or "fig_thu" or "fig_fri" or "fig_sat" or "fig_sun" => 0.6f,
            "notice_board" => 1.4f, "guild_sign" => 0.9f, "portrait" => 0.9f, "grating" => 0.8f, "flour" => 0.8f, "hook_wall" => 0.9f,
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

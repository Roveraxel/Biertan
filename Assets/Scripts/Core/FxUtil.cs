using UnityEngine;
using Biertan.Enemies;

namespace Biertan.Core
{
    /// <summary>Port of g.gd's fx_text / fx_ring helpers.</summary>
    public static class FxUtil
    {
        public static readonly Color Amber = new Color32(0xff, 0xb3, 0x47, 0xff);

        public static void Text(Vector2 pos, string text, Color color)
        {
            var go = PrefabRegistry.Spawn(PrefabRegistry.I?.floatingText, pos);
            if (go != null && go.TryGetComponent(out FloatingText ft)) ft.Init(text, color);
        }

        public static void Ring(Vector2 pos, Color color, float radius, float life = 0.4f)
        {
            var go = PrefabRegistry.Spawn(PrefabRegistry.I?.ring, pos);
            if (go != null && go.TryGetComponent(out RingFx r)) r.Init(color, radius, life);
        }
    }
}

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace Biertan.Levels
{
    /// <summary>
    /// A fortification wall that follows a polyline: the curved rings of Biertan. Solid in 2D (one rotated box
    /// collider per segment, overlapping so nothing slips through) and drawn as a band of stone; the 3D view
    /// builds it as a tall wall with a roofed walkway. style: "ring" (plain), "arches" (buttressed), "gallery"
    /// (the wooden sides of the covered stairway).
    /// </summary>
    public class CurtainWall : MonoBehaviour
    {
        public List<Vector2> pts = new();   // Unity 2D coordinates
        public float thick = 34f;
        public float h = 40f;               // face height in 2D units (3D scales it)
        public string style = "ring";

        public void Build()
        {
            var col = style == "gallery" ? new Color32(0x5a, 0x40, 0x2a, 0xff) : new Color32(0xb4, 0xad, 0x9c, 0xff);
            for (int i = 0; i < pts.Count - 1; i++)
            {
                Vector2 a = pts[i], b = pts[i + 1];
                float len = Vector2.Distance(a, b);
                if (len < 1f) continue;
                var go = new GameObject("Seg") { layer = LayerMask.NameToLayer("World") };
                go.transform.SetParent(transform, false);
                go.transform.position = (a + b) / 2f;
                go.transform.rotation = Quaternion.Euler(0, 0, Mathf.Atan2(b.y - a.y, b.x - a.x) * Mathf.Rad2Deg);
                go.isStatic = true;
                var box = go.AddComponent<BoxCollider2D>();
                box.size = new Vector2(len + thick * 0.7f, thick); // overlap the joints: no gaps to squeeze through
                var sr = new GameObject("Stone").AddComponent<SpriteRenderer>();
                sr.transform.SetParent(go.transform, false);
                sr.transform.localScale = new Vector3(len + thick * 0.7f, thick, 1f);
                sr.sprite = Resources.Load<Sprite>("Sprites/white");
                sr.color = col; sr.sortingOrder = 1;
                var top = new GameObject("Walk").AddComponent<SpriteRenderer>();
                top.transform.SetParent(go.transform, false);
                top.transform.localScale = new Vector3(len + thick * 0.7f, thick * 0.35f, 1f);
                top.sprite = sr.sprite;
                top.color = new Color(0, 0, 0, 0.25f); top.sortingOrder = 2;
            }
        }
    }

    /// <summary>Marks a roofed passage (Biertan's covered wooden stairway) for the 3D view: a shingle roof on
    /// posts over the given Godot-space rect. No collision of its own; its sides are gallery walls.</summary>
    public class CoveredWay : MonoBehaviour
    {
        public Rect godotRect;
    }
}

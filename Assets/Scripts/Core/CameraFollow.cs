using UnityEngine;

namespace Biertan.Core
{
    /// <summary>Smoothly follows the player. Orthographic size 360 = the Godot 1280x720 view at zoom 1.
    /// Also sets Y-based sprite sorting so things lower on screen draw in front (top-down depth).</summary>
    [RequireComponent(typeof(Camera))]
    public class CameraFollow : MonoBehaviour
    {
        public Transform target;
        public float smoothing = 6f;
        public Vector2 offset;
        public float zoom = 1f;
        public Rect bounds;
        public bool useBounds;

        Camera cam;

        void Awake()
        {
            cam = GetComponent<Camera>();
            cam.orthographic = true;
            cam.transparencySortMode = TransparencySortMode.CustomAxis;
            cam.transparencySortAxis = new Vector3(0f, 1f, 0f);
        }

        void LateUpdate()
        {
            cam.orthographicSize = 360f / Mathf.Max(0.1f, zoom);
            if (target == null) return;
            Vector3 goal = new(target.position.x + offset.x, target.position.y + offset.y, transform.position.z);
            transform.position = Clamp(Vector3.Lerp(transform.position, goal, 1f - Mathf.Exp(-smoothing * Time.deltaTime)));
        }

        /// <summary>Jump straight to the target (after a level change).</summary>
        public void Snap()
        {
            if (cam == null) cam = GetComponent<Camera>();
            cam.orthographicSize = 360f / Mathf.Max(0.1f, zoom);
            if (target != null) transform.position = Clamp(new Vector3(target.position.x + offset.x, target.position.y + offset.y, transform.position.z));
        }

        Vector3 Clamp(Vector3 p)
        {
            if (!useBounds) return p;
            float hh = cam.orthographicSize, hw = hh * cam.aspect;
            p.x = bounds.width > hw * 2f ? Mathf.Clamp(p.x, bounds.xMin + hw, bounds.xMax - hw) : bounds.center.x;
            p.y = bounds.height > hh * 2f ? Mathf.Clamp(p.y, bounds.yMin + hh, bounds.yMax - hh) : bounds.center.y;
            return p;
        }
    }
}

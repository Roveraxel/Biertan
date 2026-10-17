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
            transform.position = Vector3.Lerp(transform.position, goal, 1f - Mathf.Exp(-smoothing * Time.deltaTime));
        }
    }
}

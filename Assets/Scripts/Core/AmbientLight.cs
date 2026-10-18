using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace Biertan.Core
{
    /// <summary>The scene's global 2D light. Its colour follows the current level's Ambient(),
    /// eased the way main.gd lerped the CanvasModulate.</summary>
    [RequireComponent(typeof(Light2D))]
    public class AmbientLight : MonoBehaviour
    {
        Light2D global;

        void Awake()
        {
            global = GetComponent<Light2D>();
            global.lightType = Light2D.LightType.Global;
            global.intensity = 1f;
        }

        void Update()
        {
            var gm = GameManager.I;
            Color target = gm != null && gm.level != null && gm.state != GameManager.State.Title ? gm.level.Ambient() : Color.white;
            global.color = Color.Lerp(global.color, target, Mathf.Clamp01(Time.deltaTime * 2.5f));
        }
    }
}

using System.Collections;
using UnityEngine;

namespace Biertan.Core
{
    /// <summary>Fades a full-screen UI Image to/from black. Mirrors main.gd's fade_to().</summary>
    public class ScreenFade : MonoBehaviour
    {
        public static ScreenFade I { get; private set; }
        public UnityEngine.UI.Image overlay;

        void Awake() { I = this; }

        public IEnumerator FadeTo(float alpha, float duration)
        {
            if (overlay == null) yield break;
            Color c = overlay.color;
            float start = c.a;
            float elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                c.a = Mathf.Lerp(start, alpha, Mathf.Clamp01(elapsed / duration));
                overlay.color = c;
                yield return null;
            }
            c.a = alpha;
            overlay.color = c;
        }
    }
}

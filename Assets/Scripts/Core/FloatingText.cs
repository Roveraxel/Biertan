using UnityEngine;

namespace Biertan.Core
{
    /// <summary>Rising, fading damage/coin number (g.gd fx_text). Uses the built-in TextMesh so no
    /// font assets need importing.</summary>
    public class FloatingText : MonoBehaviour
    {
        public TextMesh label;
        float life = 0.9f, age;

        public void Init(string text, Color color)
        {
            if (label == null) label = GetComponent<TextMesh>();
            label.text = text;
            label.color = color;
        }

        void Update()
        {
            age += Time.deltaTime;
            transform.position += Vector3.up * 40f * Time.deltaTime;
            if (label != null) { var c = label.color; c.a = 1f - age / life; label.color = c; }
            if (age >= life) Destroy(gameObject);
        }
    }
}

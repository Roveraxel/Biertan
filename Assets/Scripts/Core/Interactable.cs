using System.Collections.Generic;
using UnityEngine;

namespace Biertan.Core
{
    /// <summary>
    /// Anything the hunter can use with E: NPCs, signs, crystals, crosses, ewes, treasure.
    /// Port of prop.gd's interaction contract plus main.gd's hover search (nearest within 80 px).
    /// </summary>
    public abstract class Interactable : MonoBehaviour
    {
        public static readonly List<Interactable> All = new();
        public const float Reach = 80f;

        protected virtual void OnEnable() => All.Add(this);
        protected virtual void OnDisable() => All.Remove(this);

        public virtual bool CanInteract() => true;
        public abstract string PromptText();
        public abstract void Interact();

        /// <summary>The usable interactable closest to <paramref name="pos"/>, or null.</summary>
        public static Interactable Nearest(Vector2 pos)
        {
            Interactable best = null;
            float bd = Reach;
            foreach (var i in All)
            {
                if (i == null || !i.isActiveAndEnabled || !i.CanInteract()) continue;
                float d = Vector2.Distance(pos, i.transform.position);
                if (d < bd) { bd = d; best = i; }
            }
            return best;
        }
    }
}

using System;
using UnityEngine;
using Biertan.Player;

namespace Biertan.Levels
{
    /// <summary>An invisible zone that calls back when the hunter walks in (level.gd add_trigger).</summary>
    [RequireComponent(typeof(BoxCollider2D))]
    public class Trigger : MonoBehaviour
    {
        public Action onEnter;

        void OnTriggerEnter2D(Collider2D other)
        {
            if (other.GetComponent<PlayerController>() != null) onEnter?.Invoke();
        }
    }
}

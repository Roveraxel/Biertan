using System.Collections.Generic;
using UnityEngine;

namespace Biertan.Testing
{
    /// <summary>
    /// Advances the game by hand: calls FixedUpdate / Update / LateUpdate on every live object and steps 2D
    /// physics. Used by automated checks when the Editor isn't ticking Play mode (for example while its
    /// window is in the background). Coroutines and Time.time do not advance; Time.deltaTime keeps the
    /// value of the last real frame.
    /// </summary>
    public static class SimStep
    {
        static readonly HashSet<GameObject> started = new();

        static List<GameObject> Live()
        {
            var list = new List<GameObject>();
            var seen = new HashSet<GameObject>();
            foreach (var mb in Object.FindObjectsByType<MonoBehaviour>())
                if (mb != null && mb.isActiveAndEnabled && seen.Add(mb.gameObject)) list.Add(mb.gameObject);
            return list;
        }

        /// <summary>Forget which objects already ran Start (call once when a fresh scene is loaded).</summary>
        public static void Reset()
        {
            started.Clear();
            foreach (var go in Live()) started.Add(go);
        }

        public static void Run(float seconds, float dt = 0.02f)
        {
            if (started.Count == 0) Reset();
            Physics2D.simulationMode = SimulationMode2D.Script;
            int steps = Mathf.CeilToInt(seconds / dt);
            for (int i = 0; i < steps; i++)
            {
                foreach (var go in Live())
                    if (go != null && started.Add(go)) go.SendMessage("Start", SendMessageOptions.DontRequireReceiver);
                foreach (var go in Live()) if (go != null) go.SendMessage("FixedUpdate", SendMessageOptions.DontRequireReceiver);
                Physics2D.Simulate(dt);
                // anything created during physics (a level loaded by a trigger) starts before its first Update
                foreach (var go in Live())
                    if (go != null && started.Add(go)) go.SendMessage("Start", SendMessageOptions.DontRequireReceiver);
                foreach (var go in Live()) if (go != null) go.SendMessage("Update", SendMessageOptions.DontRequireReceiver);
                foreach (var go in Live()) if (go != null) go.SendMessage("LateUpdate", SendMessageOptions.DontRequireReceiver);
            }
        }
    }
}

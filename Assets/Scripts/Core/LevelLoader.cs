using System.Collections;
using UnityEngine;

namespace Biertan.Core
{
    /// <summary>Loads/unloads level scenes and places the player. Mirrors main.gd's goto().</summary>
    public static class LevelLoader
    {
        // Filled in once Level 1-4 scene-loading is wired up (tasks: Port Level 1-4).
        // For now exposes the call shape GameManager depends on.
        public static System.Action<string, Vector2?> GotoHandler;

        public static void Goto(string levelName, Vector2? at = null)
        {
            GotoHandler?.Invoke(levelName, at);
        }
    }
}

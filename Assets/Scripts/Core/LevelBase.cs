using System.Collections;
using UnityEngine;

namespace Biertan.Core
{
    /// <summary>Base class every level script derives from. Mirrors level.gd.</summary>
    public abstract class LevelBase : MonoBehaviour
    {
        public virtual Color Ambient() => Color.white;
        public abstract void SpawnEnemy(string kind, Vector2 pos);
    }
}

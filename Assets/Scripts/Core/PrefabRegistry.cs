using UnityEngine;
using Biertan.Enemies;

namespace Biertan.Core
{
    /// <summary>
    /// Holds prefab references that gameplay code spawns at runtime
    /// (Godot built these with .new(); Unity needs prefabs). Put one in the bootstrap scene.
    /// </summary>
    public class PrefabRegistry : MonoBehaviour
    {
        public static PrefabRegistry I { get; private set; }

        public EnemyBase enemy;          // generic enemy prefab (Rigidbody2D + CircleCollider2D + EnemyBase + SpriteRenderer)
        public GameObject firePatch;
        public GameObject saltRing;
        public GameObject floatingText;  // TextMeshPro world-space text with FloatingText component
        public GameObject ring;          // expanding ring FX with RingFx component

        void Awake() => I = this;

        public static GameObject Spawn(GameObject prefab, Vector2 pos)
        {
            if (prefab == null) return null;
            return Instantiate(prefab, pos, Quaternion.identity);
        }

        /// <summary>Equivalent of level.gd spawn_enemy(): instantiates, sets up, applies difficulty.</summary>
        public static EnemyBase SpawnEnemy(string kind, Vector2 pos)
        {
            if (I == null || I.enemy == null) return null;
            var e = Instantiate(I.enemy, pos, Quaternion.identity);
            e.Setup(kind);
            if (GameManager.I != null) e.ApplyDifficulty(GameManager.I.Difficulty());
            return e;
        }
    }
}

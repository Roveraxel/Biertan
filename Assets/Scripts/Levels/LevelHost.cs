using UnityEngine;
using UnityEngine.SceneManagement;
using Biertan.Core;
using Biertan.Player;

namespace Biertan.Levels
{
    /// <summary>
    /// Drops one level into a scene and runs it, for testing a single chapter or boss fight.
    /// (The full game flow between levels comes with the level loader port.) Death or leaving
    /// the level reloads the scene, so each attempt starts fresh.
    /// </summary>
    public class LevelHost : MonoBehaviour
    {
        public PlayerController player;
        public string levelId = "arena";
        [Tooltip("Starting stats roughly matching how far into the game this level is.")]
        public bool chapterGear = true;

        void Start()
        {
            var gm = GameManager.I;
            gm.player = player;
            player.onToast = HudEvents.Toast;
            player.Died += () => StartCoroutine(gm.OnPlayerDied());

            var go = new GameObject("Level: " + levelId);
            LevelBase level = levelId switch
            {
                "arena" => go.AddComponent<MoonClearing>(),
                "hollow" => go.AddComponent<HollowArena>(),
                _ => null
            };
            if (level == null) { Debug.LogError("LevelHost: unknown level " + levelId); return; }

            gm.current = levelId;
            gm.level = level;
            gm.state = GameManager.State.Play;
            gm.dusk = 0.45f;
            if (chapterGear) Gear(levelId);

            level.Build();
            player.transform.position = level.spawn;
            var rb = player.GetComponent<Rigidbody2D>();
            rb.position = level.spawn;
            rb.linearVelocity = Vector2.zero;
            var cam = Camera.main;
            if (cam != null) cam.transform.position = new Vector3(level.spawn.x, level.spawn.y, cam.transform.position.z);
            level.OnEnter();
            HudEvents.Banner(level.title, level.subtitle);

            // respawn / return-home both mean "try again" in a single-level test
            LevelLoader.GotoHandler = (_, __) => SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
        }

        void Gear(string id)
        {
            var p = player;
            switch (id)
            {
                case "arena":
                    p.potions = 3;
                    break;
                case "hollow": // after the Vârcolac and the salt caves
                    p.maxHp = p.hp = 110f; p.dmg = 14f; p.potions = 4;
                    p.charmDodge = true; p.saltUnlocked = true; p.salt = 6;
                    break;
            }
        }
    }
}

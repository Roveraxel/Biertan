using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;
using Biertan.Core;
using Biertan.Player;

namespace Biertan.Levels
{
    /// <summary>
    /// Runs the ported levels inside one scene: builds the starting level, and moves between levels when
    /// the game asks (forest → Moon Clearing, …), with a fade. Port of main.gd goto(). A level that isn't
    /// ported yet (Saschiz, Richiș, …) restarts the scene instead, so every test run starts fresh.
    /// </summary>
    public class LevelHost : MonoBehaviour
    {
        public PlayerController player;
        public string levelId = "arena";
        [Tooltip("Starting stats roughly matching how far into the game this level is.")]
        public bool chapterGear = true;

        LevelBase level;

        static LevelBase Create(string id, GameObject go) => id switch
        {
            "forest" => go.AddComponent<WolfForest>(),
            "arena" => go.AddComponent<MoonClearing>(),
            "hollow" => go.AddComponent<HollowArena>(),
            _ => null,
        };

        public static bool IsPorted(string id) => id is "forest" or "arena" or "hollow";

        void Start()
        {
            var gm = GameManager.I;
            gm.player = player;
            player.onToast = HudEvents.Toast;
            player.Died += () => StartCoroutine(gm.OnPlayerDied());
            gm.state = GameManager.State.Play;
            gm.dusk = levelId == "forest" ? 0.3f : 0.45f;
            if (chapterGear) Gear(levelId);

            LevelLoader.GotoHandler = (id, at) =>
            {
                if (IsPorted(id)) StartCoroutine(Switch(id, at));
                else SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
            };
            Enter(levelId, null);
        }

        void Enter(string id, Vector2? at)
        {
            var gm = GameManager.I;
            var go = new GameObject("Level: " + id);
            level = Create(id, go);
            if (level == null) { Debug.LogError("LevelHost: unknown level " + id); return; }
            gm.current = id;
            gm.level = level;
            gm.midnightDone = false;
            level.Build();
            Vector2 p = at ?? level.spawn;
            player.transform.position = p;
            var rb = player.GetComponent<Rigidbody2D>();
            rb.position = p;
            rb.linearVelocity = Vector2.zero;
            var cam = Camera.main;
            if (cam != null) cam.transform.position = new Vector3(p.x, p.y, cam.transform.position.z);
            level.OnEnter();
            HudEvents.Banner(level.title, level.subtitle);
        }

        IEnumerator Switch(string id, Vector2? at)
        {
            var gm = GameManager.I;
            if (gm.transitioning) yield break;
            gm.transitioning = true;
            if (ScreenFade.I != null) yield return ScreenFade.I.FadeTo(1f, 0.4f);
            if (level != null) Destroy(level.gameObject);
            Biertan.Enemies.EnemyBase.All.Clear();
            yield return null; // let the old level go
            Enter(id, at);
            gm.state = GameManager.State.Play;
            if (ScreenFade.I != null) yield return ScreenFade.I.FadeTo(0f, 0.4f);
            gm.transitioning = false;
        }

        void Gear(string id)
        {
            var p = player;
            var gm = GameManager.I;
            switch (id)
            {
                case "forest": // fresh from Saschiz, with Gheorghe's errand accepted
                    gm.quest = 1;
                    gm.eweQuest = 1;
                    p.potions = 2;
                    break;
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

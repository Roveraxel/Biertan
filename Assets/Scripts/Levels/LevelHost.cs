using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;
using Biertan.Core;
using Biertan.Player;

namespace Biertan.Levels
{
    /// <summary>
    /// Runs the ported levels inside one scene and moves between them with a fade. Port of main.gd
    /// goto(): per-level camera, music, dusk and autosave. Positions passed to LevelLoader.Goto are in
    /// Godot coordinates, like everywhere in the level code. A level that isn't ported yet restarts the
    /// scene instead.
    /// </summary>
    public class LevelHost : MonoBehaviour
    {
        public PlayerController player;
        public string levelId = "hub";
        [Tooltip("Starting stats roughly matching how far into the game this level is (off for a real new game).")]
        public bool chapterGear = true;

        LevelBase level;

        static LevelBase Create(string id, GameObject go) => id switch
        {
            "hub" => go.AddComponent<Saschiz>(),
            "forest" => go.AddComponent<WolfForest>(),
            "arena" => go.AddComponent<MoonClearing>(),
            "hollow" => go.AddComponent<HollowArena>(),
            _ => null,
        };

        public static bool IsPorted(string id) => id is "hub" or "forest" or "arena" or "hollow";

        void Start()
        {
            var gm = GameManager.I;
            gm.player = player;
            player.onToast = HudEvents.Toast;
            player.Died += () => StartCoroutine(gm.OnPlayerDied());
            gm.state = GameManager.State.Play;
            gm.dusk = 0.3f;
            if (chapterGear) Gear(levelId);

            LevelLoader.GotoHandler = (id, at) =>
            {
                if (IsPorted(id)) StartCoroutine(Switch(id, at));
                else SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
            };
            Enter(levelId, null);
            if (levelId == "hub" && !chapterGear) HudEvents.Banner("BIERTAN", "The bells have fallen silent. Reach Biertan.");
        }

        void Enter(string id, Vector2? godotAt)
        {
            var gm = GameManager.I;
            var go = new GameObject("Level: " + id);
            level = Create(id, go);
            if (level == null) { Debug.LogError("LevelHost: unknown level " + id); return; }
            gm.current = id;
            gm.level = level;
            gm.midnightDone = false;
            level.Build();

            Vector2 p = godotAt.HasValue ? LevelBase.P(godotAt.Value) : level.spawn;
            player.transform.position = p;
            var rb = player.GetComponent<Rigidbody2D>();
            rb.position = p;
            rb.linearVelocity = Vector2.zero;
            player.madness = 0f; player.blood = 0f; player.vampT = 0f; player.hasteT = 0f;

            var cam = Camera.main;
            if (cam != null)
            {
                cam.transform.position = new Vector3(p.x, p.y, cam.transform.position.z);
                var follow = cam.GetComponent<CameraFollow>();
                if (follow != null)
                {
                    follow.zoom = level.cameraZoom;
                    follow.offset = level.cameraOffset;
                    follow.bounds = new Rect(0, -level.size.y, level.size.x, level.size.y);
                    follow.useBounds = true;
                    follow.Snap();
                }
            }

            // music, ambience and the hour, as main.gd goto()
            var music = id switch
            {
                "hub" or "richis" or "mosna" => "music_hub",
                "forest" or "walls" => "music_forest",
                "arena" => "music_boss",
                "hills" => "music_hills",
                "caves" => "music_cave",
                "hollow" => "music_muma",
                "vineyard" => "music_vineyard",
                "gorge" => "music_balaur",
                "biertan" => "music_biertan",
                "church" => "music_vlad",
                _ => null,
            };
            if (music != null) AudioManager.I?.SetMusic(music, -9f);
            if (id == "richis") gm.visitedRichis = true;
            if (id == "mosna") gm.visitedMosna = true;
            if (id == "biertan") gm.visitedBiertan = true;
            if (id is "hub" or "richis" or "mosna" or "biertan") { gm.dusk = 0.45f; gm.SaveGame(); }
            else if (id == "hills" && gm.dusk < 0.2f) gm.dusk = 0.2f;
            else if (id == "vineyard" && gm.dusk < 0.45f) gm.dusk = 0.45f;
            else if (id == "forest" && gm.dusk < 0.15f) gm.dusk = 0.15f;

            level.OnEnter();
            HudEvents.Banner(level.title, level.subtitle);
        }

        IEnumerator Switch(string id, Vector2? godotAt)
        {
            var gm = GameManager.I;
            if (gm.transitioning) yield break;
            gm.transitioning = true;
            if (ScreenFade.I != null && !GameManager.Instant) yield return ScreenFade.I.FadeTo(1f, 0.35f);
            if (level != null) Destroy(level.gameObject);
            gm.boss = null;
            if (!GameManager.Instant) yield return null; // let the old level go
            Enter(id, godotAt);
            gm.state = GameManager.State.Play;
            if (ScreenFade.I != null && !GameManager.Instant) yield return ScreenFade.I.FadeTo(0f, 0.35f);
            gm.transitioning = false;
        }

        void Gear(string id)
        {
            var p = player;
            var gm = GameManager.I;
            switch (id)
            {
                case "forest": // fresh from Saschiz, with Anna's and Gheorghe's errands accepted
                    gm.quest = 1;
                    gm.eweQuest = 1;
                    p.potions = 2;
                    break;
                case "arena":
                    gm.quest = 1;
                    p.potions = 3;
                    break;
                case "hollow": // after the Vârcolac and the salt caves
                    gm.quest = 3;
                    p.maxHp = p.hp = 110f; p.dmg = 14f; p.potions = 4;
                    p.charmDodge = true; p.saltUnlocked = true; p.salt = 6;
                    break;
            }
        }
    }
}

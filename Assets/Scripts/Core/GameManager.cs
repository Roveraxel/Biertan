using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using Biertan.Player;

namespace Biertan.Core
{
    /// <summary>
    /// Central game controller — C# port of main.gd.
    /// States: Title, Play, Dialogue, Dead, Ending, Story, Bestiary.
    /// </summary>
    public class GameManager : MonoBehaviour
    {
        public static GameManager I { get; private set; }

        public enum State { Title, Play, Dialogue, Dead, Ending, Story, Bestiary }

        [Serializable]
        public class StoryCard
        {
            public string title;
            public string lore;
            public string fact;
        }

        public static readonly Dictionary<string, StoryCard> Stories = new()
        {
            ["saschiz"] = new StoryCard
            {
                title = "SASCHIZ",
                lore = "With the vârcolac dead, the moon kept its place in the sky. By morning the children of Saschiz were running again over the green and golden hills above the village, chasing lambs between the haystacks, and nobody called them home before dark.",
                fact = "Saxon settlers raised Saschiz's fortified church in the 15th century. Its tower echoes the clock tower of Sighișoara, and the village is one of Transylvania's UNESCO-listed villages with fortified churches."
            },
            ["richis"] = new StoryCard
            {
                title = "RICHIȘ",
                lore = "Ioan, Mitzi and Grete came home through the beech woods at dawn with moss in their hair. That summer they played in the wildflower meadows on the slopes, and the Green Men carved in the church seemed, the old women swore, to be smiling.",
                fact = "Richiș's Gothic hall church is famous for the Green Men carved in its choir: stone faces wreathed in oak leaves, left by Saxon masons centuries ago."
            },
            ["mosna"] = new StoryCard
            {
                title = "MOȘNA",
                lore = "Carts rolled down the Biertan road again. In the vineyards above Moșna the children picked the last grapes and slid down the hay meadows, and on Sunday every family cut a slice of ham from the tower.",
                fact = "Moșna's great late-Gothic hall church stands inside a ring of walls and towers. Like many Saxon villages, it kept each family's bacon safe in a fortified tower."
            },
            ["biertan"] = new StoryCard
            {
                title = "BIERTAN",
                lore = "The great bell rang over the valley, and the dead lay down. The children of Biertan climbed all three walls to watch the sun come up over the hills: green and gold and purple with heather, as far as Saschiz.",
                fact = "Biertan was the seat of the Lutheran bishops of Transylvania from 1572 to 1867. Its church, guarded by three rings of walls, keeps a sacristy door with nineteen locks and the famous 'marriage prison'."
            }
        };

        // ---- state ----
        public State state = State.Title;
        public string current = "";          // active level id
        public PlayerController player;
        public LevelBase level;
        public IBoss boss;
        public bool transitioning;
        public float t;

        // ---- quest state ----
        public int quest;        // 0 none, 1 accepted, 2 boss slain, 3 complete  (Varcolac)
        public int smithLevel;
        public bool metIleana;
        public int quest2;       // Muma
        public bool visitedRichis;
        public bool metVasile;
        public bool rozaliaThanked;
        public int quest3;       // Balaur
        public bool visitedMosna;
        public int quest4;       // Vlad
        public bool visitedBiertan;
        public bool sofiaGift;
        public float endingT;
        public string storyId = "";
        public float storyT;
        public int eweQuest;     // 0 not asked, 1 searching, 2 rewarded
        [NonSerialized] public HashSet<string> side = new();
        public bool midnightDone;

        // day/night cycle (0..1), mirrors G.dusk in the Godot build
        public float dusk = 0.3f;

        // ---- dialogue (main.gd start_dialogue / advance_dialogue) ----
        public string dlgSpeaker = "";
        public List<string> dlgLines = new();
        public int dlgIdx;
        Action dlgAfter;
        /// <summary>Brief lockout after a dialogue closes so the same key press doesn't re-open it.</summary>
        public float inputBlock;
        public int dlgFrame;

        public event Action StoryClosed;
        public bool testMode;
        /// <summary>Automated tests: skip fades and pauses so whole sequences run at once.</summary>
        public static bool Instant;
        public string lastStory = "";

        string SavePath => Path.Combine(Application.persistentDataPath, "biertan_save.json");

        void Awake()
        {
            if (I != null && I != this) { Destroy(gameObject); return; }
            I = this;
        }

        void Update()
        {
            float dt = Time.deltaTime;
            t += dt;

            if (state == State.Play)
            {
                if (current == "forest" || current == "hills" || current == "vineyard")
                {
                    dusk = Mathf.Min(1f, dusk + dt / 240f);
                    if (dusk >= 1f && !midnightDone)
                        StartCoroutine(StrikeMidnight());
                }
                else if (current == "hub" || current == "richis" || current == "mosna")
                {
                    dusk = Mathf.MoveTowards(dusk, 0.45f, dt * 0.4f);
                }
            }

            if (player != null)
                player.frozen = state == State.Dialogue || state == State.Dead || state == State.Ending || state == State.Story;

            inputBlock = Mathf.Max(0f, inputBlock - dt);
            if (state == State.Story) storyT += dt;
            if (state == State.Ending) endingT += dt;
        }

        // ---------------------------------------------------------------- helpers

        public bool SideHas(string id) => side.Contains(id);

        public int EwesFound()
        {
            int n = 0;
            foreach (var id in new[] { "ewe1", "ewe2", "ewe3" }) if (side.Contains(id)) n++;
            return n;
        }

        public int TreasuresFound()
        {
            int n = 0;
            foreach (var id in new[] { "tr1", "tr2", "tr3" }) if (side.Contains(id)) n++;
            return n;
        }

        /// <summary>Difficulty scaling per chapter: (hpMult, dmgMult). Mirrors main.gd difficulty().</summary>
        public Vector2 Difficulty()
        {
            switch (current)
            {
                case "forest":
                case "arena":
                    return new Vector2(1.0f, 0.85f);
                case "hills":
                case "caves":
                case "hollow":
                    return new Vector2(1.4f, 1.25f);
                case "vineyard":
                case "gorge":
                    return new Vector2(1.7f, 1.45f);
                case "walls":
                case "church":
                    return new Vector2(2.0f, 1.6f);
                default:
                    return Vector2.one;
            }
        }

        public string Home()
        {
            if (visitedBiertan) return "biertan";
            if (visitedMosna) return "mosna";
            return visitedRichis ? "richis" : "hub";
        }

        public string HomeName() => Home() switch
        {
            "biertan" => "Biertan",
            "mosna" => "Moșna",
            "richis" => "Richiș",
            _ => "Saschiz"
        };

        // ---------------------------------------------------------------- dialogue

        public void StartDialogue(string who, IList<string> lines, Action after = null)
        {
            dlgSpeaker = who;
            dlgLines = new List<string>(lines);
            dlgIdx = 0;
            dlgAfter = after;
            dlgFrame = Time.frameCount;
            state = State.Dialogue;
            AudioManager.I?.Sfx("blip", -6f);
        }

        public void AdvanceDialogue()
        {
            dlgIdx++;
            AudioManager.I?.Sfx("blip", -8f, 0.9f);
            if (dlgIdx < dlgLines.Count) return;
            state = State.Play;
            inputBlock = 0.25f;
            var a = dlgAfter;
            dlgAfter = null;
            a?.Invoke();
        }

        // ---------------------------------------------------------------- midnight

        public IEnumerator StrikeMidnight()
        {
            midnightDone = true;
            string sub = current == "forest"
                ? "The evil hour. Blue flames burn where treasure lies buried."
                : "The evil hour. The dead are at their strongest.";
            HudEvents.Banner("MIDNIGHT · CEASUL RĂU", sub);
            for (int i = 0; i < 12; i++)
            {
                AudioManager.I?.Sfx("bell", -10f, 0.62f);
                if (!Instant) yield return new WaitForSeconds(0.45f);
                if (current == "" || state == State.Title) yield break;
            }
        }

        // ---------------------------------------------------------------- boss death rewards

        public IEnumerator OnPlayerDied()
        {
            state = State.Dead;
            player.frozen = true;
            AudioManager.I?.Sfx("boss_roar", -10f, 1.5f);
            yield break;
        }

        public void Respawn()
        {
            player.hp = player.maxHp;
            player.frozen = false;
            state = State.Play;
            dusk = 0.3f;
            LevelLoader.Goto(Home());
        }

        public IEnumerator OnBossDead() // Varcolac
        {
            HudEvents.Banner("THE VÂRCOLAC FALLS", "The moon slips free of its jaws.");
            if (!Instant) yield return new WaitForSeconds(3f);
            player.charmDodge = true;
            quest = 2;
            HudEvents.Toast("Received: Wolf-Fang Charm  (+10% dodge)");
            HudEvents.Toast("Received: The Silver Thread  (quest item)");
            if (!Instant) yield return new WaitForSeconds(2.5f);
            if (Instant) lastStory = "saschiz"; else yield return ShowStory("saschiz");
            LevelLoader.Goto("hub", new Vector2(900, 880));
        }

        public IEnumerator OnBearDead()
        {
            side.Add("bear");
            HudEvents.Banner("THE BEAR OF THE GARDEN FALLS", "Like Harap-Alb, you walk out of the garden alive.");
            player.maxHp += 25f;
            player.hp = player.maxHp;
            player.dmg += 3f;
            player.coins += 80;
            HudEvents.Toast("Received: Bearskin cloak  (+25 max health)");
            HudEvents.Toast("Received: Bear's claw  (+3 damage)  and 80 coins");
            AudioManager.I?.SetMusic("music_hills", -9f);
            yield break;
        }

        public IEnumerator OnMumaDead()
        {
            HudEvents.Banner("MUMA PĂDURII IS FELLED", "The wood grows quiet. Far off, children wake.");
            if (!Instant) yield return new WaitForSeconds(3f);
            player.oakHeart = true;
            player.maxHp += 15f;
            player.hp = player.maxHp;
            quest2 = 2;
            HudEvents.Toast("Received: Heart of Oak  (+15 max health)");
            HudEvents.Toast("Found in her hollow: the clapper of a great bell");
            if (!Instant) yield return new WaitForSeconds(2.5f);
            if (Instant) lastStory = "richis"; else yield return ShowStory("richis");
            LevelLoader.Goto("richis", new Vector2(900, 760));
        }

        public IEnumerator OnBalaurDead()
        {
            HudEvents.Banner("THE BALAUR IS SLAIN", "Three necks seared. The road to Biertan lies open.");
            if (!Instant) yield return new WaitForSeconds(3f);
            quest3 = 2;
            player.dmg += 4f;
            player.coins += 40;
            HudEvents.Toast("Received: Balaur Scale  (+4 damage)");
            HudEvents.Toast("+40 coins from the serpent's hoard");
            if (!Instant) yield return new WaitForSeconds(2.5f);
            if (Instant) lastStory = "mosna"; else yield return ShowStory("mosna");
            LevelLoader.Goto("mosna", new Vector2(950, 860));
        }

        public IEnumerator OnVladDead()
        {
            quest4 = 2;
            HudEvents.Banner("STRIGOI VLAD IS DESTROYED", "Dust and ash on the altar steps.");
            AudioManager.I?.SetMusic("music_hub", -12f);
            float[] pitches = { 1.0f, 0.89f, 0.75f };
            for (int i = 0; i < 3; i++)
            {
                if (!Instant) yield return new WaitForSeconds(2.2f);
                AudioManager.I?.Sfx("bell", 0f, pitches[i]);
            }
            SaveGame();
            if (!Instant) yield return new WaitForSeconds(2f);
            if (Instant) lastStory = "biertan"; else yield return ShowStory("biertan");
            state = State.Ending;
            endingT = 0f;
            player.frozen = true;
            if (!Instant) yield return ScreenFade.I.FadeTo(0f, 1f);
        }

        // ---------------------------------------------------------------- story cards

        public IEnumerator ShowStory(string id)
        {
            lastStory = id;
            if (Instant) { storyId = id; yield break; }
            if (!Instant) yield return ScreenFade.I.FadeTo(1f, 0.8f);
            storyId = id;
            storyT = 0f;
            state = State.Story;
            AudioManager.I?.Sfx("bell", -6f, 1f);
            if (!Instant) yield return ScreenFade.I.FadeTo(0f, 0.6f);

            if (testMode)
            {
                if (!Instant) yield return new WaitForSeconds(2f);
                storyT = -999f;
                StoryClosed?.Invoke();
            }

            bool closed = false;
            void OnClosed() => closed = true;
            StoryClosed += OnClosed;
            yield return new WaitUntil(() => closed);
            StoryClosed -= OnClosed;

            if (!Instant) yield return ScreenFade.I.FadeTo(1f, 0.4f);
            state = State.Play;
        }

        public void CloseStory() => StoryClosed?.Invoke();

        /// <summary>Leaving the ending: back to Biertan with the bells ringing (the title screen is not ported yet,
        /// so this goes straight where Continue would).</summary>
        public void LeaveEnding()
        {
            endingT = -999f;
            state = State.Play;
            if (player != null) player.frozen = false;
            LevelLoader.Goto("biertan", new Vector2(900, 860));
        }

        public IEnumerator ToTitle()
        {
            if (!Instant) yield return ScreenFade.I.FadeTo(1f, 0.6f);
            if (level != null)
            {
                if (player.transform.parent != null) player.transform.SetParent(null);
                Destroy(level.gameObject);
                level = null;
            }
            boss = null;
            current = "";
            state = State.Title;
            HudEvents.SetContinueEnabled(HasSave());
            AudioManager.I?.SetMusic("music_hub", -9f);
            if (!Instant) yield return ScreenFade.I.FadeTo(0f, 0.6f);
        }

        // ---------------------------------------------------------------- save / load

        [Serializable]
        class SaveData
        {
            public int v = 1;
            public int quest, quest2, smith, quest3, quest4;
            public bool ileana, richis, vasile, rozalia, mosna, garlic, torch, biertan, sofia;
            public int ewe_q;
            public List<string> side = new();
            public float max_hp, dmg;
            public int potions, coins, salt;
            public bool charm_dodge, red_thread, salt_unlocked, wormwood, oak;
        }

        public void SaveGame()
        {
            var p = player;
            var d = new SaveData
            {
                quest = quest, quest2 = quest2, smith = smithLevel, ileana = metIleana,
                richis = visitedRichis, vasile = metVasile, rozalia = rozaliaThanked, quest3 = quest3, mosna = visitedMosna,
                garlic = p.garlic, torch = p.torch, quest4 = quest4, biertan = visitedBiertan, sofia = sofiaGift,
                ewe_q = eweQuest, side = new List<string>(side),
                max_hp = p.maxHp, dmg = p.dmg, potions = p.potions, coins = p.coins,
                charm_dodge = p.charmDodge, red_thread = p.redThread, salt = p.salt,
                salt_unlocked = p.saltUnlocked, wormwood = p.wormwood, oak = p.oakHeart
            };
            try { File.WriteAllText(SavePath, JsonUtility.ToJson(d)); }
            catch (Exception e) { Debug.LogWarning($"Save failed: {e.Message}"); }
        }

        public bool HasSave() => File.Exists(SavePath);

        public void ContinueGame()
        {
            if (transitioning) return;
            if (!HasSave()) { StartGame(); return; }

            SaveData d;
            try { d = JsonUtility.FromJson<SaveData>(File.ReadAllText(SavePath)); }
            catch { StartGame(); return; }
            if (d == null) { StartGame(); return; }

            player.ResetStats();
            quest = d.quest; quest2 = d.quest2; smithLevel = d.smith; metIleana = d.ileana;
            visitedRichis = d.richis; metVasile = d.vasile; rozaliaThanked = d.rozalia;
            quest3 = d.quest3; visitedMosna = d.mosna; quest4 = d.quest4; visitedBiertan = d.biertan;
            sofiaGift = d.sofia; eweQuest = d.ewe_q;
            side = new HashSet<string>(d.side ?? new List<string>());

            var p = player;
            p.maxHp = d.max_hp > 0 ? d.max_hp : 100f;
            p.hp = p.maxHp;
            p.dmg = d.dmg > 0 ? d.dmg : 12f;
            p.potions = d.potions > 0 ? d.potions : 1;
            p.coins = d.coins > 0 ? d.coins : 20;
            p.charmDodge = d.charm_dodge;
            p.redThread = d.red_thread;
            p.salt = d.salt;
            p.saltUnlocked = d.salt_unlocked;
            p.wormwood = d.wormwood;
            p.oakHeart = d.oak;
            p.garlic = d.garlic;
            p.torch = d.torch;

            dusk = 0.45f;
            state = State.Play;
            LevelLoader.Goto(Home());
        }

        public void StartGame()
        {
            player.ResetStats();
            quest = quest2 = quest3 = quest4 = 0;
            eweQuest = 0;
            side.Clear();
            visitedRichis = visitedMosna = visitedBiertan = false;
            dusk = 0.3f;
            state = State.Play;
            LevelLoader.Goto("hub");
        }
    }
}

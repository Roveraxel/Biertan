using System.Collections.Generic;
using UnityEngine;
using Biertan.Core;
using Biertan.Enemies;

namespace Biertan.Levels
{
    /// <summary>The Wolf Forest between Saschiz and the Moon Clearing. Port of forest_level.gd.</summary>
    public class WolfForest : LevelBase
    {
        static readonly Vector2[] PathPts =
        {
            new(80, 900), new(600, 950), new(1000, 820), new(1400, 760),
            new(1800, 900), new(2300, 960), new(2700, 840), new(3300, 880),
        };

        static readonly (Vector2 c, float r)[] Glades =
        {
            (new(1150, 480), 130f), (new(1550, 480), 170f), (new(2000, 700), 120f),
            (new(1300, 1040), 120f), (new(2700, 1080), 120f),
            // hidden corners: lost ewes, the hermit's spring, treasure ground
            (new(560, 260), 110f), (new(2950, 260), 110f), (new(2200, 1560), 110f),
            (new(420, 1520), 150f), (new(1300, 180), 90f), (new(2550, 1380), 90f), (new(3200, 1600), 90f),
        };

        public static readonly Dictionary<string, Vector2> Ewes = new()
        {
            ["ewe1"] = new(560, 260), ["ewe2"] = new(2950, 260), ["ewe3"] = new(2200, 1560),
        };

        public static readonly Dictionary<string, Vector2> Treasures = new()
        {
            ["tr1"] = new(1300, 180), ["tr2"] = new(2550, 1380), ["tr3"] = new(3200, 1600),
        };

        bool voiceStarted, voiceTrapped, voiceRewarded;
        float nightT, lurkT = 5f;

        public override void Build()
        {
            var gm = GameManager.I;
            title = "THE WOLF FOREST";
            subtitle = "Keep to the path. Never answer a voice that knows your name.";
            size = new Vector2(3400, 1800);
            spawn = P(160, 900);
            ground = new Color32(0x1f, 0x2a, 0x1c, 0xff);
            rng = new System.Random(77);

            DrawGround();
            Scatter(new Rect(0, 0, 3400, 1800), 1100, new Color[] { new Color32(0x2c, 0x3a, 0x24, 0xff), new Color32(0x17, 0x21, 0x1a, 0xff), new Color32(0x3a, 0x4a, 0x2c, 0xff) });
            Scatter(new Rect(0, 0, 3400, 1800), 160, new Color[] { new Color32(0x5a, 0x3a, 0x1c, 0xff), new Color32(0x7a, 0x4a, 0x1c, 0xff) });
            foreach (var g in Glades) AddSprite("Glade", "circle", P(g.c), Vector2.one * g.r * 2f, new Color32(0x2a, 0x35, 0x24, 0xff), -985);
            AddPath(PathPts, 150f, new Color32(0x3a, 0x2e, 0x20, 0xff), -984);
            AddPath(PathPts, 100f, new Color32(0x4a, 0x3a, 0x28, 0xff), -983);
            // the hermit's spring
            AddSprite("Pool", "circle", P(470, 1570), new Vector2(68, 68), new Color32(0x2a, 0x4a, 0x5a, 0xff), -982);
            AddSprite("PoolIn", "circle", P(470, 1570), new Vector2(52, 52), new Color32(0x3a, 0x6a, 0x7a, 0xff), -981);

            // invisible map border
            AddWall(new Vector2(1700, 100), new Vector2(3800, 200));
            AddWall(new Vector2(1700, -1900), new Vector2(3800, 200));
            AddWall(new Vector2(-100, -900), new Vector2(200, 2200));
            AddWall(new Vector2(3500, -900), new Vector2(200, 2200));

            // trees everywhere off the path and out of the glades
            for (float y = 40f; y < size.y; y += 90f)
                for (float x = 40f; x < size.x; x += 100f)
                {
                    var p = new Vector2(x + Rand(-35, 35), y + Rand(-35, 35));
                    if (DistToPath(p) > 175f && !InGlade(p)) AddTree(P(p));
                }

            // ruined shepherd's hut, torn fleece and a coin sack
            AddWall(P(1530, 431), new Vector2(100, 22), new Color32(0x5a, 0x55, 0x4c, 0xff));
            AddWall(P(1491, 465), new Vector2(22, 90), new Color32(0x5a, 0x55, 0x4c, 0xff));
            AddProp("fleece", "fleece", "", new Vector2(1630, 500), "E   Examine the fleece");
            AddProp("sack", "sack1", "", new Vector2(1545, 520), "E   Take the coin sack");
            AddProp("sign", "sign", "", new Vector2(3150, 840), "E   Read the carved post");

            // side quests
            if (gm.eweQuest >= 1)
                foreach (var kv in Ewes)
                    if (!gm.SideHas(kv.Key)) AddProp("ewe", kv.Key, "", kv.Value, "E   Tie a cord to the lost ewe");
            AddProp("npc", "hermit", "Pafnutie · Hermit", new Vector2(400, 1490), "E   Speak with the hermit", new Color32(0x4a, 0x3a, 0x28, 0xff));
            AddProp("spring", "spring", "", new Vector2(470, 1560), "E   Drink from the spring");
            foreach (var kv in Treasures)
                if (!gm.SideHas(kv.Key)) AddProp("treasure", kv.Key, "", kv.Value, "E   Dig where the blue flame burns");
            AddTorch(new Vector2(430, 1530), 200f, new Color(0.6f, 0.85f, 1f), 0.5f);
            AddBrazier(new Vector2(3200, 800));
            AddBrazier(new Vector2(3200, 960));

            // creatures
            Pack("wolf", new Vector2(900, 880), 3);
            Pack("wolf", new Vector2(1550, 780), 3);
            Pack("wolf", new Vector2(2250, 960), 3);
            Pack("wolf", new Vector2(2900, 850), 3);
            Pack("pricolici", new Vector2(1800, 900), 1);
            Pack("pricolici", new Vector2(2500, 900), 1);
            Pack("pricolici", new Vector2(2950, 800), 1);
            Pack("scarecrow", new Vector2(1230, 700), 1);
            Pack("scarecrow", new Vector2(2010, 720), 1);
            Pack("scarecrow", new Vector2(1300, 1040), 1);
            Pack("scarecrow", new Vector2(2700, 1080), 1);

            // events and exits
            AddTrigger(new Rect(0, 780, 60, 240), () => Leave("hub", new Vector2(1540, 600)));
            AddTrigger(new Rect(3310, 760, 90, 240), () => Leave("arena", null));
            AddTrigger(new Rect(1040, 700, 80, 260), StartVoice);
            AddTrigger(new Rect(1070, 410, 170, 150), SpringTrap);
            AddTrigger(new Rect(1860, 780, 80, 260), RewardVoice);
            AddTrigger(new Rect(2640, 640, 70, 420), MagdaFlees);
            AudioManager.I?.SetMusic("music_forest", -9f);
        }

        static void Leave(string to, Vector2? at)
        {
            var gm = GameManager.I;
            if (gm.state != GameManager.State.Play || gm.transitioning) return;
            LevelLoader.Goto(to, at); // Godot coordinates
        }

        float DistToPath(Vector2 p)
        {
            float best = float.MaxValue;
            for (int i = 0; i < PathPts.Length - 1; i++) best = Mathf.Min(best, DistToSegment(p, PathPts[i], PathPts[i + 1]));
            return best;
        }

        static bool InGlade(Vector2 p)
        {
            foreach (var g in Glades) if (Vector2.Distance(p, g.c) < g.r) return true;
            return false;
        }

        void Pack(string kind, Vector2 c, int n)
        {
            for (int i = 0; i < n; i++)
            {
                float a = Rand(0, Mathf.PI * 2f), r = Rand(20, 70);
                SpawnEnemy(kind, P(c + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * r));
            }
        }

        void StartVoice()
        {
            if (voiceStarted) return;
            voiceStarted = true;
            HudEvents.Toast("“…Wanderer… come, the fire is warm here…”  A woman's voice, calling from the trees.");
        }

        void SpringTrap()
        {
            if (voiceTrapped || !voiceStarted) return;
            voiceTrapped = true;
            HudEvents.Toast("You answered. Pale shades of the Iele rise from the grass!");
            for (int i = 0; i < 3; i++)
            {
                float a = i * Mathf.PI * 2f / 3f;
                SpawnEnemy("shade", P(new Vector2(1150, 480) + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 90f));
            }
        }

        void RewardVoice()
        {
            if (!voiceStarted || voiceTrapped || voiceRewarded) return;
            voiceRewarded = true;
            GameManager.I.player.coins += 30;
            HudEvents.Toast("You did not answer. The voice falls silent.  +30 coins");
        }

        /// <summary>Magda, of all people, bolting from the last wolf pack before the clearing.</summary>
        public void MagdaFlees()
        {
            var gm = GameManager.I;
            if (gm.SideHas("magda_flee")) return;
            gm.side.Add("magda_flee");
            var go = new GameObject("Magda");
            go.transform.SetParent(transform, false);
            go.transform.position = P(2980, 760);
            var c = go.AddComponent<Cameo>();
            c.vel = new Vector2(-430, -60);
            c.line = "VLAAAAAD!!!";
            c.life = 3.2f;
            AudioManager.I?.Sfx("shriek", -4f, 1.6f);
            HudEvents.Toast("A woman bolts out of the trees, screaming, and is gone.");
        }

        bool SpawnLurker()
        {
            var pl = GameManager.I.player;
            int cap = GameManager.I.dusk > 0.8f ? 4 : 3;
            if (Lurker.All.Count >= cap) return false;
            for (int i = 0; i < 12; i++)
            {
                float a = Random.value * Mathf.PI * 2f;
                Vector2 u = (Vector2)pl.transform.position + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * Random.Range(250f, 420f);
                Vector2 g = P(u); // back to Godot space (P is its own inverse)
                if (g.x < 80 || g.y < 80 || g.x > size.x - 80 || g.y > size.y - 80) continue;
                if (DistToPath(g) < 130f) continue;
                var go = new GameObject("Lurker");
                go.transform.SetParent(transform, false);
                go.transform.position = u;
                go.AddComponent<Lurker>();
                return true;
            }
            return false;
        }

        void Update()
        {
            var gm = GameManager.I;
            if (gm == null || gm.state != GameManager.State.Play || gm.player == null) return;
            float dt = Time.deltaTime;
            lurkT -= dt;
            if (lurkT <= 0f)
            {
                lurkT = Mathf.Lerp(9f, 3.5f, gm.dusk) + Random.value * 3f;
                SpawnLurker();
            }
            if (gm.dusk < 0.85f) return;
            nightT += dt;
            if (nightT > 7f && EnemyBase.All.Count < 10)
            {
                nightT = 0f;
                float a = Random.value * Mathf.PI * 2f;
                Vector2 g = P((Vector2)gm.player.transform.position + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * 620f);
                g = new Vector2(Mathf.Clamp(g.x, 60, size.x - 60), Mathf.Clamp(g.y, 60, size.y - 60));
                SpawnEnemy("wolf", P(g));
                HudEvents.Toast("Night hunters stir in the dark...");
                AudioManager.I?.Sfx("howl", -6f);
            }
        }
    }
}

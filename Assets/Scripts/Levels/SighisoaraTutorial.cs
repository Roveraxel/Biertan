using System.Collections.Generic;
using UnityEngine;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>
    /// Sighișoara's opening job, which teaches the game in three steps: look (five clues around the butchers'
    /// quarter), use things (the butcher's wife, the child, the firewood, a flame, the lever in the guild sign),
    /// and finally fight, in the smoke-cellar under the Butchers' Tower where the spiriduși carry off the bacon.
    /// Progress is kept as flags in GameManager.side, so it saves with the game.
    /// </summary>
    public static class SighisoaraTutorial
    {
        static GameManager GM => GameManager.I;
        static bool Has(string f) => GM.SideHas(f);
        static void Set(string f) => GM.side.Add(f);

        public static readonly string[] Clues = { "dogs", "grating", "flour", "hook", "storks" };
        public static int CluesFound() { int n = 0; foreach (var c in Clues) if (Has("sig_c_" + c)) n++; return n; }

        public static string Objective()
        {
            if (!Has("sig_job")) return "Find work. The notice by the Clock Tower gate names the butchers' guild on the citadel square.";
            if (CluesFound() < Clues.Length) return $"Look around the Butchers' Tower for signs of the thief ({CluesFound()}/{Clues.Length} clues).";
            if (!Has("sig_wife")) return "Tell the butcher's wife, Frau Gertrud, what you found.";
            if (!Has("sig_child")) return "Ask little Mihai what he saw by the tower.";
            if (!Has("sig_open")) return "Get into the smoke-cellar under the Butchers' Tower.";
            return "Go down into the smoke-cellar.";
        }

        public static bool Marker(string id) => id switch
        {
            "butcher" => !Has("sig_job"),
            "butcherwife" => Has("sig_job") && CluesFound() == Clues.Length && !Has("sig_wife"),
            "child" => Has("sig_wife") && !Has("sig_child"),
            _ => false,
        };

        /// <summary>Clues and tasks glint softly while there is still something to learn from them.</summary>
        public static bool Pending(Prop p) => p.kind switch
        {
            "clue" => !Has("sig_c_" + p.id),
            "task" => p.id switch
            {
                "notice" => !Has("sig_job"),
                "firewood" => Has("sig_child") && !Has("sig_firewood"),
                "hearth" => Has("sig_child") && !Has("sig_flame"),
                "sign" => Has("sig_flame") && !Has("sig_lever"),
                "cellar" => Has("sig_child"),
                _ => false,
            },
            _ => false,
        };

        public static bool Talk(string id)
        {
            var gm = GM;
            switch (id)
            {
                case "butcher":
                    if (!Has("sig_job"))
                        gm.StartDialogue("Meister Thomas, butcher", new[]
                        {
                            "A shepherd with a knife on his belt. Good. You came about the notice?",
                            "Someone is robbing the guild's smoke-cellar under the Butchers' Tower. Bacon, sausages, whole hams, gone a little every night.",
                            "The watch found the doors barred and the locks whole. They say it is rats. Rats do not carry off a ham.",
                            "Look around the tower before you go down. Whoever it is leaves a trail; nobody here has eyes for it. Find out how they get in, and you are paid.",
                        }, () => { Set("sig_job"); HudEvents.Toast("New quest: The Bacon Thieves"); });
                    else if (CluesFound() < Clues.Length)
                        gm.StartDialogue("Meister Thomas, butcher", new[] { "The tower is on the west wall, past the Tailors' gate. Look before you dig." });
                    else
                        gm.StartDialogue("Meister Thomas, butcher", new[] { "Footprints of flour? Little ones? Tell Gertrud. She feeds every child on this hill; she will know whose they are." });
                    return true;
                case "butcherwife":
                    if (Has("sig_job") && CluesFound() == Clues.Length && !Has("sig_wife"))
                        gm.StartDialogue("Frau Gertrud", new[]
                        {
                            "Bare feet, smaller than a child's, in my flour? And the dogs barking at a wall?",
                            "Little Mihai has been saying it for a week: 'little men with lanterns, mother Gertrud, by the tower.' I thought he was making up stories to get a sausage.",
                            "He is by the well on the square. Ask him. Gently; he is frightened of the watch.",
                        }, () => Set("sig_wife"));
                    else if (!Has("sig_job"))
                        gm.StartDialogue("Frau Gertrud", new[] { "If it is work you want, speak to my husband at the stall. If it is sausages, those cost money." });
                    else
                        gm.StartDialogue("Frau Gertrud", new[] { "Find out what is going on at that tower before there is no bacon left for Christmas." });
                    return true;
                case "child":
                    if (Has("sig_wife") && !Has("sig_child"))
                        gm.StartDialogue("Mihai", new[]
                        {
                            "I am not lying. Little men, this big, with beards and red caps. Three of them, carrying a ham like a coffin.",
                            "They go in behind the firewood stack at the bottom of the tower. There is a hole there, under the wood.",
                            "It is dark inside. You will need a light; Frau Gertrud keeps her hearth going all day.",
                            "And the cellar door has a secret. The guild sign over it, the one with the ox. Pull its tongue.",
                        }, () => { Set("sig_child"); HudEvents.Toast("Mihai showed you the way: firewood, a flame, the guild sign."); });
                    else if (!Has("sig_wife"))
                        gm.StartDialogue("Mihai", new[] { "...", "(He stares at your knife and says nothing.)" });
                    else
                        gm.StartDialogue("Mihai", new[] { "Are you going down there? Bring me back a red cap." });
                    return true;
            }
            return false;
        }

        public static void Use(Prop p)
        {
            var gm = GM;
            if (p.kind == "clue")
            {
                bool first = !Has("sig_c_" + p.id);
                Set("sig_c_" + p.id);
                gm.StartDialogue(ClueTitle(p.id), ClueText(p.id), () =>
                {
                    if (first) HudEvents.Toast($"Clue {CluesFound()}/{Clues.Length}" + (CluesFound() == Clues.Length ? ". Tell the butcher's wife." : ""));
                });
                return;
            }
            switch (p.id)
            {
                case "notice":
                    gm.StartDialogue("Notice on the gate", new[]
                    {
                        "WANTED: a man not afraid of the dark. Good pay. Ask for Meister Thomas at the butchers' stall on the citadel square.",
                        "Beneath, in another hand: 'and bring your own lantern'.",
                    });
                    break;
                case "firewood":
                    if (!Has("sig_child")) { gm.StartDialogue("Firewood", new[] { "A tall stack of split beech against the tower. Someone has stacked it with care." }); break; }
                    if (!Has("sig_firewood"))
                    {
                        Set("sig_firewood");
                        p.used = true;
                        AudioManager.I?.Sfx("blip", -4f, 0.6f);
                        gm.StartDialogue("Firewood", new[] { "You pull the logs aside one armful at a time. Behind them, low in the wall, a hole no taller than your knee, and on its sill a smear of lard." });
                    }
                    break;
                case "hearth":
                    if (!Has("sig_child")) { gm.StartDialogue("Hearth", new[] { "Gertrud's hearth. Something smoked and salty hangs in the chimney." }); break; }
                    if (!Has("sig_flame"))
                    {
                        Set("sig_flame");
                        gm.player.torch = true;
                        AudioManager.I?.Sfx("blip", -4f, 1.2f);
                        gm.StartDialogue("Hearth", new[] { "You light a stub of tallow candle in Gertrud's hearth and shield it with your hand. It will do." });
                    }
                    break;
                case "sign":
                    if (!Has("sig_flame")) { gm.StartDialogue("Guild sign", new[] { "An ox's head carved in oak over the cellar door, its tongue lolling out. The butchers' guild of Schäßburg." }); break; }
                    if (!Has("sig_lever"))
                    {
                        Set("sig_lever");
                        AudioManager.I?.Sfx("bell", -16f, 0.6f);
                        gm.StartDialogue("Guild sign", new[] { "You pull the ox's tongue. Somewhere inside the wall a counterweight drops, and the cellar door swings in on its own." }, () => Set("sig_open"));
                    }
                    break;
                case "cellar":
                    if (!Has("sig_firewood") || !Has("sig_child")) gm.StartDialogue("Cellar door", new[] { "An iron-bound door under the tower, barred from the inside. The watch says no one has opened it in a month." });
                    else if (!Has("sig_flame")) gm.StartDialogue("Cellar door", new[] { "Through the hole by the firewood you see nothing at all. You will need a light." });
                    else if (!Has("sig_open")) gm.StartDialogue("Cellar door", new[] { "Barred from the inside. Mihai said the guild sign hides the secret." });
                    else if (LevelHost.IsPorted("cellar")) LevelLoader.Goto("cellar");
                    else gm.StartDialogue("Smoke-cellar", new[] { "Stairs go down into smoke and the smell of bacon. Somewhere below, small feet patter and a lantern swings.", "(The smoke-cellar is the next thing to be built.)" });
                    break;
            }
        }

        static string ClueTitle(string id) => id switch
        {
            "dogs" => "The dogs", "grating" => "Cellar grating", "flour" => "Footprints",
            "hook" => "Smoking hook", "storks" => "Storks", _ => id,
        };

        static IList<string> ClueText(string id) => id switch
        {
            "dogs" => new[] { "Two yard dogs stand stiff-legged at the foot of the town wall, growling at the stones. There is nothing there.", "Nothing you can see. But dogs do not bark at stone." },
            "grating" => new[] { "A cellar grating by the tower. The candle in the window above leans toward it, though there is no wind.", "Air is moving down there. Somewhere below, there is another way in." },
            "flour" => new[] { "Flour spilled across the butcher's yard, and in it bare footprints, smaller than a child's, with long toes.", "They lead toward the tower, and come back heavier: the heels sink deep." },
            "hook" => new[] { "An iron smoking-hook, empty. Flies circle where a ham hung this morning.", "The hook is too high for a child, and the ladder is still chained." },
            "storks" => new[] { "Three storks on a roof ridge, all facing the Butchers' Tower, clattering their beaks at it.", "Old women say storks see what people do not." },
            _ => new[] { "..." },
        };
    }
}

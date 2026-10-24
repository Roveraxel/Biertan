using System.Collections.Generic;
using UnityEngine;
using Biertan.Core;

namespace Biertan.Levels
{
    /// <summary>
    /// "The Stolen Bacon", Sighișoara's tutorial (see Biertan: The Full Story). Look: four clues around the
    /// Butchers' Tower. Use things: the butcher and his wife, the child who saw "little men", a crate, a lantern
    /// lit at the hearth, the lever in the guild sign. Fight: the cellar under the tower, where a spiriduș steals
    /// the hunter's hat and the spiriduși faint rather than die. Then the captain's apology, the hat returned, the
    /// food-for-work deal brokered with the guild, and Vlad Laurențiu's cart to Viscri.
    /// Progress is kept as flags in GameManager.side, so it saves with the game.
    /// </summary>
    public static class SighisoaraTutorial
    {
        static GameManager GM => GameManager.I;
        static bool Has(string f) => GM.SideHas(f);
        static void Set(string f) => GM.side.Add(f);

        public static readonly string[] Clues = { "flour", "grating", "hook", "smoke" };

        public static int CluesFound() { int n = 0; foreach (var c in Clues) if (Has("sig_c_" + c)) n++; return n; }

        /// <summary>Where the props of the job stand (Unity 2D), filled in as Sighișoara is built.</summary>
        public static readonly Dictionary<string, Vector2> Spots = new();

        /// <summary>Where the quest pointer aims, and what it calls the place; null when there is nowhere to send him.</summary>
        public static (Vector2 at, string label)? Target()
        {
            var gm = GM;
            if (gm == null) return null;
            if (gm.current == "cellar")
            {
                if (!Has("sig_cellar")) return (LevelBase.P(2560f, 600f), "The bacon thieves");
                return (LevelBase.P(60f, 600f), "Stairs up");
            }
            if (gm.current != "sighisoara") return null;
            (Vector2, string)? To(string id, string label) => Spots.TryGetValue(id, out var v) ? (v, label) : null;
            if (!Has("sig_notice")) return To("notice", "Notice board");
            if (!Has("sig_job")) return To("butcher", "Meister Thomas");
            if (CluesFound() < Clues.Length)
            {
                var pl = (Vector2)gm.player.transform.position;
                (Vector2, string)? best = null; float bd = float.MaxValue;
                foreach (var c in Clues)
                    if (!Has("sig_c_" + c) && Spots.TryGetValue(c, out var v) && Vector2.Distance(pl, v) < bd) { bd = Vector2.Distance(pl, v); best = (v, "Butchers' Tower"); }
                return best;
            }
            if (!Has("sig_wife")) return To("butcherwife", "Frau Gertrud");
            if (!Has("sig_child")) return To("child", "Mihai");
            if (!Has("sig_crate")) return To("crate", "The crate");
            if (!Has("sig_flame")) return To("hearth", "Gertrud's hearth");
            if (!Has("sig_lever")) return To("sign", "Guild sign");
            if (!Has("sig_cellar")) return To("cellar", "Cellar door");
            if (!Has("sig_deal")) return To("butcher", "Meister Thomas");
            return To("vlad", "Vlad's cart");
        }

        public static string Objective()
        {
            if (!Has("sig_notice")) return "Find work.";
            if (!Has("sig_job")) return "Ask about the notice at the butchers' stall on the citadel square.";
            if (CluesFound() < Clues.Length) return $"Look around the Butchers' Tower for signs of the thief ({CluesFound()}/{Clues.Length} clues).";
            if (!Has("sig_wife")) return "Ask the butcher's wife, Frau Gertrud, about it.";
            if (!Has("sig_child")) return "Find little Mihai by the well on the square.";
            if (!Has("sig_open")) return "Get into the cellar under the Butchers' Tower.";
            if (!Has("sig_cellar")) return Has("sig_hat_lost") ? "Get your hat back. Deal with the bacon thieves." : "Go down into the cellar.";
            if (!Has("sig_deal")) return "Broker a deal for the spiriduși with Meister Thomas.";
            return "Find Vlad Laurențiu's cart in the lower town and ride to Viscri.";
        }

        public static bool Marker(string id) => id switch
        {
            "butcher" => (Has("sig_notice") && !Has("sig_job")) || (Has("sig_cellar") && !Has("sig_deal")),
            "butcherwife" => CluesFound() == Clues.Length && !Has("sig_wife"),
            "child" => Has("sig_wife") && !Has("sig_child"),
            "captain" => !Has("sig_cellar"),
            "vlad" => Has("sig_deal"),
            "azorel" => !Has("sig_azorel"),
            _ => false,
        };

        /// <summary>Clues and tasks glint softly while there is still something to learn from them.</summary>
        public static bool Pending(Prop p) => p.kind switch
        {
            "clue" => !Has("sig_c_" + p.id),
            "task" => p.id switch
            {
                "notice" => !Has("sig_notice"),
                "crate" => Has("sig_child") && !Has("sig_crate"),
                "hearth" => Has("sig_crate") && !Has("sig_flame"),
                "sign" => Has("sig_flame") && !Has("sig_lever"),
                "cellar" => Has("sig_child") && !Has("sig_cellar"),
                "portrait" => !Has("sig_portrait"),
                _ => false,
            },
            _ => false,
        };

        public static bool Talk(string id)
        {
            var gm = GM;
            switch (id)
            {
                case "azorel":
                    gm.StartDialogue("Azorel", Has("sig_deal")
                        ? new[] { "Azorel's tail thumps the cobbles. He knows a cart when he smells one." }
                        : new[] { "Stay here, boy. I'll be back for dinner.", "Azorel sighs through his nose, turns twice and lies down across the inn door." },
                        () => Set("sig_azorel"));
                    return true;
                case "butcher":
                    if (!Has("sig_job"))
                        gm.StartDialogue("Meister Thomas, guild master", Has("sig_notice") ? new[]
                        {
                            "You came about the notice? A shepherd with a knife on his belt. Good.",
                            "Bacon keeps vanishing from the guild's storage under the Butchers' Tower. A side here, a sausage there, every night.",
                            "Nobody has seen anything. The watch says rats. Rats do not untie a ham from its hook.",
                            "Look around the tower first. Find out who it is and how they get in, and the guild pays.",
                        } : new[] { "Meat? The stall opens at dawn. If it is work you want, read the notice on the Clock Tower gate first." },
                        () => { if (Has("sig_notice")) { Set("sig_job"); HudEvents.Toast("New quest: The Stolen Bacon"); } });
                    else if (Has("sig_cellar") && !Has("sig_deal"))
                        gm.StartDialogue("Meister Thomas, guild master", new[]
                        {
                            "Spiriduși? Little house spirits, in my storage? And they were only hungry?",
                            "Hm. My grandmother left a bowl by the hearth for them every night, and her sausages never went bad.",
                            "Very well. The guild and the innkeeper will leave food out for them each night. In return they carry our goods between the market cellars and the tower before dawn. Tell your little friends.",
                            "Here is your pay. And listen: the villages around the town are in trouble, worse than missing bacon. They are asking for people with sharp eyes.",
                            "Viscri, then. My girl Lorena just moved there. I'll start with her village.",
                            "Vlad Laurențiu, the merchant, is taking his cart that way. Ask him in the lower town.",
                        }, () => { Set("sig_deal"); gm.player.coins += 25; AudioManager.I?.Sfx("coin", -4f); HudEvents.Toast("+25 coins.  Quest complete: The Stolen Bacon"); });
                    else if (CluesFound() < Clues.Length)
                        gm.StartDialogue("Meister Thomas, guild master", new[] { "The Butchers' Tower is on the west wall. Look before you dig." });
                    else
                        gm.StartDialogue("Meister Thomas, guild master", new[] { "Gertrud feeds every child on this hill. If anyone has heard something, it is her." });
                    return true;
                case "butcherwife":
                    if (CluesFound() == Clues.Length && !Has("sig_wife"))
                        gm.StartDialogue("Frau Gertrud", new[]
                        {
                            "Footprints in my flour? Smaller than a child's? I saw nothing, and neither did anyone else.",
                            "Except little Mihai. He keeps saying 'little men, mother Gertrud, little men by the tower.' I thought he wanted a sausage.",
                            "He is by the well on the square. Be gentle; he is frightened of the watch.",
                        }, () => Set("sig_wife"));
                    else
                        gm.StartDialogue("Frau Gertrud", new[] { Has("sig_job") ? "Find out what is happening at that tower before there is no bacon left for Christmas." : "If it is work you want, the guild master is at the stall on the square." });
                    return true;
                case "child":
                    if (Has("sig_wife") && !Has("sig_child"))
                        gm.StartDialogue("Mihai", new[]
                        {
                            "I am not lying. Little men, this big, with beards and red caps, carrying a ham like a coffin.",
                            "They go in at the bottom of the Butchers' Tower, behind the big crate.",
                            "It is dark inside. Frau Gertrud keeps her hearth going all day; you can light a lantern there.",
                            "And the cellar door has a secret. The guild sign over it, the ox. Pull its tongue.",
                        }, () => { Set("sig_child"); HudEvents.Toast("Mihai showed you the way: the crate, a lantern, the guild sign."); });
                    else
                        gm.StartDialogue("Mihai", Has("sig_wife") ? new[] { "Are you going down there? Bring me back a red cap." } : new[] { "...", "(He stares at your knife and says nothing.)" });
                    return true;
                case "captain":
                    if (!Has("sig_cellar"))
                        gm.StartDialogue("Spiriduș-căpitan", new[]
                        {
                            "(The captain sits up, sees you standing over him, and squeaks. He drags the rest of his band into a row by their beards.)",
                            "All together now!",
                            "SORRY, SORRY, WE WON'T TOUCH IT AGAIN. WE WERE JUST VERY HUNGRY.",
                            "(The smallest one steps out of the row and holds up your hat, brushing the soot off it.) And sorry about the hat.",
                            "You put your hat back on. It smells of bacon now.",
                        }, () => { Set("sig_cellar"); Set("sig_hat_back"); HudEvents.Toast("Hat recovered. Tell Meister Thomas what you found."); });
                    else
                        gm.StartDialogue("Spiriduș-căpitan", new[] { Has("sig_deal") ? "Food every night and honest work! The best deal a spiriduș ever had." : "Will they feed us, big man? Ask them. Please." });
                    return true;
                case "vlad":
                    if (!Has("sig_deal")) { gm.StartDialogue("Vlad Laurențiu, merchant", new[] { "Cloth, salt and needles, friend, all the way to the villages. Not today, though. Today I wait for my wheel to be mended." }); return true; }
                    gm.StartDialogue("Vlad Laurențiu, merchant", new[]
                    {
                        "Viscri? I go past it. Climb up, and bring the big dog; he can guard the salt.",
                        "(You whistle. Azorel is at your side before the whistle ends.)",
                    }, () =>
                    {
                        Set("sig_left");
                        if (LevelHost.IsPorted("viscri")) LevelLoader.Goto("viscri");
                        else { HudEvents.Toast("Viscri is not built yet: the cart takes you to Saschiz for now."); LevelLoader.Goto("hub"); }
                    });
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
                    if (first) HudEvents.Toast($"Clue {CluesFound()}/{Clues.Length}" + (CluesFound() == Clues.Length ? ". Ask the butcher's wife." : ""));
                });
                return;
            }
            switch (p.id)
            {
                case "notice":
                    gm.StartDialogue("Notice board", new[]
                    {
                        "BRAVE PEOPLE WANTED FOR WORK. Good pay. Ask at the butchers' stall on the citadel square.",
                        "Beneath it, in another hand: 'bring your own lantern'.",
                    }, () => Set("sig_notice"));
                    break;
                case "crate":
                    if (!Has("sig_child")) { gm.StartDialogue("Crate", new[] { "A heavy crate of salt pushed hard against the foot of the tower." }); break; }
                    if (!Has("sig_crate"))
                    {
                        Set("sig_crate");
                        p.used = true;
                        AudioManager.I?.Sfx("blip", -4f, 0.6f);
                        gm.StartDialogue("Crate", new[] { "You put your shoulder to it and shove. Behind it, low in the wall, a hole no taller than your knee, with a smear of lard on its sill." });
                    }
                    break;
                case "hearth":
                    if (!Has("sig_crate")) { gm.StartDialogue("Hearth", new[] { "Gertrud's hearth. Something smoked and salty hangs in the chimney." }); break; }
                    if (!Has("sig_flame"))
                    {
                        Set("sig_flame");
                        gm.player.torch = true;
                        AudioManager.I?.Sfx("blip", -4f, 1.2f);
                        gm.StartDialogue("Hearth", new[] { "You light the lantern from Gertrud's hearth. It will do." });
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
                    if (!Has("sig_child")) gm.StartDialogue("Cellar door", new[] { "An iron-bound door under the tower, barred from the inside." });
                    else if (!Has("sig_crate")) gm.StartDialogue("Cellar door", new[] { "Barred from the inside. Mihai said they go in behind the crate." });
                    else if (!Has("sig_flame")) gm.StartDialogue("Cellar door", new[] { "Through the hole behind the crate you see nothing at all. You need a light." });
                    else if (!Has("sig_open")) gm.StartDialogue("Cellar door", new[] { "Still barred. Mihai said the guild sign hides the secret." });
                    else if (Has("sig_cellar")) gm.StartDialogue("Cellar", new[] { "Quiet down there now, apart from the drip of fat and somebody small snoring." });
                    else LevelLoader.Goto("cellar");
                    break;
                case "portrait":
                    Set("sig_portrait");
                    gm.StartDialogue("Casa Vlad Dracul", new[]
                    {
                        "The house where, they say, Vlad Dracul lived when the town was his. A portrait hangs in the dark hall.",
                        "Someone has scratched out the face with a knife, again and again, until the board shows through. The scratches are fresh.",
                    });
                    break;
            }
        }

        static string ClueTitle(string id) => id switch
        {
            "flour" => "Footprints", "grating" => "Cellar grating", "hook" => "Empty hook", "smoke" => "Smoke", _ => id,
        };

        static IList<string> ClueText(string id) => id switch
        {
            "flour" => new[] { "Flour spilled across the butcher's yard, and in it bare footprints, smaller than a child's, with long toes.", "They lead toward the tower, and come back heavier: the heels sink deep." },
            "grating" => new[] { "A cellar grating by the tower. The candle in the window above leans toward it, though there is no wind.", "Air is moving down there. Somewhere below, there is another way in." },
            "hook" => new[] { "An iron smoking-hook, empty. Flies circle where a ham hung this morning.", "The hook is too high for a child, and the ladder is still chained." },
            "smoke" => new[] { "Smoke from the tower's vents sinks down into the yard instead of rising, as if something below is drawing it in.", "Someone has opened a way between the cellar and the street." },
            _ => new[] { "..." },
        };
    }
}

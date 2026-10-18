using Biertan.Levels;
using UnityEngine;

namespace Biertan.Core
{
    /// <summary>
    /// What happens when the hunter uses a prop or talks to someone. Port of main.gd prop_used(), talk()
    /// and marker_for(). Chapters are added as their levels are ported; this holds the Wolf Forest's.
    /// </summary>
    public static class WorldEvents
    {
        static GameManager GM => GameManager.I;

        public static bool MarkerFor(string id)
        {
            var gm = GM;
            if (gm == null) return false;
            return id switch
            {
                "gheorghe" => gm.eweQuest == 0 || (gm.eweQuest == 1 && gm.EwesFound() >= 3),
                "hermit" => !gm.SideHas("hermit"),
                _ => false,
            };
        }

        public static void PropUsed(Prop p)
        {
            var gm = GM;
            var player = gm.player;
            switch (p.kind)
            {
                case "npc":
                    Talk(p.id);
                    break;
                case "sack":
                    p.used = true;
                    player.coins += 15;
                    AudioManager.I?.Sfx("coin", -4f);
                    HudEvents.Toast("A shepherd's coin sack.  +15 coins");
                    break;
                case "fleece":
                    gm.StartDialogue("Torn fleece", new[]
                    {
                        "The wool is shredded. Three nights of throats opened, and not a drop of blood on the grass.",
                        "Wolf prints circle the hut, but they stop where the moonlight ends. Something walks beside them.",
                    });
                    break;
                case "ewe":
                    p.used = true;
                    gm.side.Add(p.id);
                    AudioManager.I?.Sfx("blip", -2f, 1.3f);
                    HudEvents.Toast($"You tie a cord to the ewe. It trots off toward Saschiz.  ({gm.EwesFound()} / 3)");
                    break;
                case "treasure":
                {
                    p.used = true;
                    gm.side.Add(p.id);
                    AudioManager.I?.Sfx("coin", 0f, 0.8f);
                    int found = gm.TreasuresFound();
                    int gold = 35 + 15 * found;
                    player.coins += gold;
                    HudEvents.Toast($"A haiduc's buried pot of coins!  +{gold} coins  ({found} / 3)");
                    if (found >= 3)
                    {
                        player.dmg += 4f;
                        HudEvents.Banner("THE HAIDUC'S SILVER", "At the bottom of the last pot: a silver knife.  +4 damage");
                    }
                    break;
                }
                case "spring":
                    gm.side.Add("spring");
                    player.maxHp += 15f;
                    player.hp = player.maxHp;
                    AudioManager.I?.Sfx("potion", 0f, 0.7f);
                    FxUtil.Ring(player.transform.position, new Color(0.6f, 0.85f, 1f, 0.8f), 60f);
                    HudEvents.Toast("Cold, sweet water. You feel older and stronger.  +15 max health");
                    break;
                case "sign":
                    gm.StartDialogue("Carved post", new[]
                    {
                        "Beyond this post, the Moon Clearing. Old shepherds say a vârcolac lives there, a thing born of the air.",
                        "When women spin at night without a candle, it climbs their threads to bite the moon. If the moon turns red, light the fires and make a din.",
                    });
                    break;
            }
        }

        public static void Talk(string id)
        {
            var gm = GM;
            var player = gm.player;
            switch (id)
            {
                case "hermit":
                    if (!gm.SideHas("hermit"))
                        gm.StartDialogue("Pafnutie, Hermit", new[]
                        {
                            "Forty years I have prayed in this glade, and you are the third soul to find it. Sit.",
                            "The haiducs who robbed the salt road buried their pots in this forest. At midnight, in the evil hour, the treasure burns with a blue flame. Only then can it be found.",
                            "Let the dusk run out. When you hear the twelve strokes, look for blue fire off the path. And drink from my spring before you go; it has kept me alive a long time.",
                        }, () =>
                        {
                            gm.side.Add("hermit");
                            HudEvents.Toast("Side quest: The Haiducs' Treasure  (three pots, found only at midnight)");
                        });
                    else
                        gm.StartDialogue("Pafnutie, Hermit", new[]
                        {
                            gm.TreasuresFound() < 3
                                ? $"{gm.TreasuresFound()} of three pots found. Wait for the twelve strokes; look for blue fire."
                                : "You found them all. Spend it on salt and silver, not on wine.",
                        });
                    break;

                case "gheorghe":
                    if (gm.eweQuest == 0)
                    {
                        gm.StartDialogue("Gheorghe", new[]
                        {
                            "Forty ewes, gone in one night. I heard something howling at the sky.",
                            "Three more bolted into the Wolf Forest, far from the path. One north-west, one north-east, one down in the southern hollows.",
                            "If you find them, tie a cord on them and they will find their way home. I would give you every coin I have.",
                        }, () =>
                        {
                            gm.eweQuest = 1;
                            HudEvents.Toast("Side quest: The Lost Ewes  (find three ewes deep in the Wolf Forest)");
                        });
                        return;
                    }
                    if (gm.eweQuest == 1 && gm.EwesFound() >= 3)
                    {
                        gm.StartDialogue("Gheorghe", new[]
                        {
                            "All three, home and bleating! You walked where no shepherd dares.",
                            "Take this, and my mother's tinctures. And listen: old Pafnutie the hermit lives in the south-west of the forest. Few have found him.",
                        }, () =>
                        {
                            gm.eweQuest = 2;
                            player.coins += 40;
                            player.potions += 2;
                            HudEvents.Toast("Side quest complete.  +40 coins, +2 tinctures");
                        });
                        return;
                    }
                    if (gm.eweQuest == 1)
                    {
                        gm.StartDialogue("Gheorghe", new[] { $"{gm.EwesFound()} of three ewes are home. The others are still out there, off the path." });
                        return;
                    }
                    gm.StartDialogue("Gheorghe", gm.quest >= 2
                        ? new[] { "They say the beast is slain? Then my ewes can rest in peace. Thank you, stranger." }
                        : new[] { "Forty ewes, gone in one night. I heard something howling at the sky.", "The moon was swallowed whole. I swear it on my mother's grave." });
                    break;
            }
        }
    }
}

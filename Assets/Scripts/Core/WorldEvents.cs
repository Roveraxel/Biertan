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
                "anna" => gm.quest == 0 || gm.quest == 2,
                "ileana" => !gm.metIleana,
                "pastor" => gm.quest2 == 0 || gm.quest2 == 2,
                "vasile" => !gm.metVasile && gm.quest2 >= 1,
                "gheorghe" => gm.eweQuest == 0 || (gm.eweQuest == 1 && gm.EwesFound() >= 3),
                "hermit" => !gm.SideHas("hermit"),
                "konrad" => gm.quest3 == 0 || gm.quest3 == 2,
                "sexton" => gm.quest4 == 0,
                _ => SighisoaraTutorial.Marker(id),
            };
        }

        public static void PropUsed(Prop p)
        {
            var gm = GM;
            var player = gm.player;
            if (p.kind is "clue" or "task") { SighisoaraTutorial.Use(p); return; }
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
                case "cross":
                    p.used = true;
                    player.hp = player.maxHp;
                    AudioManager.I?.Sfx("potion", -4f, 0.8f);
                    FxUtil.Ring(player.transform.position, new Color(1f, 0.85f, 0.5f, 0.8f), 60f);
                    gm.StartDialogue("Wayside cross", new[]
                    {
                        "A troiță of carved oak, painted with suns and a little roof against the rain. Someone has left bread at its foot.",
                        "You stand a moment. The wind drops. Your wounds close.",
                    });
                    break;
                case "greenman":
                    gm.StartDialogue("The Green Man", new[]
                    {
                        "A stone face wreathed in oak leaves, carved by Saxon masons three hundred years ago.",
                        "Some say it guards the church from the wood. Some say the wood is watching through it.",
                    });
                    break;
                case "bones":
                    p.used = true;
                    player.coins += 25;
                    player.potions += 1;
                    AudioManager.I?.Sfx("coin", -4f);
                    HudEvents.Toast("A miner's purse and a stoppered flask.  +25 coins, +1 tincture");
                    break;
                case "sign" when p.id == "cave_sign":
                    gm.StartDialogue("Miners' post", new[] { "THE SALT CAVES. Imperial salt workings, closed by order.", "Below, someone has carved: 'Thirty men went down. Thirty came up. Count them again.'" });
                    break;
                case "sign" when p.id == "garden_sign":
                    gm.StartDialogue("Warning post", new[]
                    {
                        "A bear's skull is nailed to the post, and beneath it, scratched deep: GRĂDINA URSULUI.",
                        "Past the thicket to the south-east lies the Bear's Garden. In the tale, Harap-Alb only came out of it alive because Saint Sunday put the bear to sleep. You have no such help.",
                    });
                    break;
                case "bell":
                    if (gm.level is Biertan.Levels.ChurchOfBiertan church) church.RingBell();
                    break;
                case "sign" when p.id == "prison_sign":
                    gm.StartDialogue("The Marriage Prison", new[] { "For three hundred years, couples who wished to part were locked in here together: one bed, one table, one plate, one spoon.", "Most came out still married. Tonight it holds the last living souls of Biertan." });
                    break;
                case "sign" when p.id == "yard_sign":
                    gm.StartDialogue("Churchyard gate", new[] { "'HIER RUHEN DIE TOTEN VON MESCHEN.' Here rest the dead of Moșna.", "Someone has scratched beneath it in Romanian: 'Not all of them.' The earth of every second grave is turned." });
                    break;
                case "sign" when p.id == "quarry_sign":
                    gm.StartDialogue("Waymark", new[] { "BIRTHÄLM, 2 hours. The Biertan road runs past the old quarry.", "Fresh claw marks run down the stone, wider than a cart." });
                    break;
                case "sign" when p.id == "lake_sign":
                    gm.StartDialogue("Scratched into the salt", new[] { "'She sings from the far side of the lake. The children follow the singing. Do not follow the singing.'" });
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
            if (SighisoaraTutorial.Talk(id)) return;
            var gm = GM;
            var player = gm.player;
            switch (id)
            {
                case "anna":
                    if (gm.quest == 0)
                        gm.StartDialogue("Frau Anna Roth", new[]
                        {
                            "Three nights now the sheep come back with their throats open and not a drop of blood spilled.",
                            "The elders say a varcolac walks the Wolf Forest. Bring me proof, and the inn is yours for a month.",
                            "Hans can sharpen your blade. Old Ileana at the gate knows charms. Then take the east gate, and keep to the path.",
                        }, () =>
                        {
                            gm.quest = 1;
                            player.potions += 1;
                            HudEvents.Banner("QUEST: WHERE THE SHEEP WENT", "Slay the beast of the Wolf Forest.");
                            HudEvents.Toast("Anna gives you a garlic tincture.  (Q to drink)");
                        });
                    else if (gm.quest == 1)
                        gm.StartDialogue("Frau Anna Roth", new[] { "Garlic tincture, ten coins. Drink it when you bleed.", "The east gate leads to the forest. Come back with the beast's proof." }, BuyPotion);
                    else if (gm.quest == 2)
                        gm.StartDialogue("Frau Anna Roth", new[]
                        {
                            "The Silver Thread... and the fang of a varcolac. By the saints, you did it.",
                            "From this night you are Guest of the Hearth. The inn is yours, Wanderer.",
                        }, () =>
                        {
                            gm.quest = 3;
                            player.coins += 50;
                            HudEvents.Banner("GUEST OF THE HEARTH", "+50 coins.  Level 2: Richiș awaits.");
                            player.hp = player.maxHp;
                        });
                    else
                        gm.StartDialogue("Frau Anna Roth", new[] { "Richiș lies east through the gate, along the old salt road. The pastor there will want to hear what you carry.", "Garlic tincture, ten coins?" }, BuyPotion);
                    break;

                case "hans":
                    if (gm.smithLevel >= 3)
                        gm.StartDialogue("Master Hans", new[] { "I can do no more for that blade. It is as keen as Saxon steel gets." });
                    else
                        gm.StartDialogue("Master Hans", new[] { "A sharper edge keeps you breathing. Twenty-five coins for a whetting.", "Iron is what the dead fear. Fire is what the beasts fear." }, Sharpen);
                    break;

                case "ileana":
                    if (gm.quest >= 2)
                        gm.StartDialogue("Old Ileana", new[] { "A varcolac does not wander this far west by chance, child.", "Something drives the old beasts toward us. The bells of Biertan have stopped. When bells stop, the dead listen." });
                    else if (!gm.metIleana)
                        gm.StartDialogue("Old Ileana", new[]
                        {
                            "Salt on the threshold, iron in the hand, a red thread at the wrist. The dead keep rules; learn them.",
                            "Hold out your arm. There. May it keep your blood where it belongs.",
                        }, () =>
                        {
                            gm.metIleana = true;
                            player.redThread = true;
                            player.maxHp += 10f;
                            player.hp = player.maxHp;
                            HudEvents.Toast("Red thread charm.  (+10 max health)");
                        });
                    else
                        gm.StartDialogue("Old Ileana", new[] { "A voice that knows your name is never a friend's, child. Do not answer it.", "Light is your armour in the dark. The dusk makes them bold." });
                    break;

                case "pastor":
                    if (gm.quest2 == 0)
                        gm.StartDialogue("Pfarrer Lukas", new[]
                        {
                            "You carry the fang of a varcolac. Then God has sent you, or something older has.",
                            "Seven nights ago our children began to walk out of their beds, singing. Three are gone: little Ioan, Mitzi and Grete.",
                            "The Iele dance in the Hollow Hills and lead the young away. The women say the singing ends at the Salt Caves, and past them lies the Hollow, where Muma Pădurii keeps her house.",
                            "The Forest Mother takes children to keep the wood young. Bring them home. Vasile knows the caves, and salt is what the old dead cannot cross.",
                        }, () =>
                        {
                            gm.quest2 = 1;
                            player.potions += 1;
                            HudEvents.Banner("QUEST: THE SINGING CHILDREN", "Find the children beyond the Salt Caves.");
                            HudEvents.Toast("The pastor gives you a garlic tincture.");
                        });
                    else if (gm.quest2 == 1)
                        gm.StartDialogue("Pfarrer Lukas", new[] { "The east gate leads to the Hollow Hills. Whatever you hear out there, do not dance." });
                    else if (gm.quest2 == 2)
                        gm.StartDialogue("Pfarrer Lukas", new[]
                        {
                            "They walked in at dawn, all three, with moss in their hair and no memory of the night. The bells rang for them.",
                            "And this... a bell clapper, cast in Biertan. Muma Pădurii was keeping it in her hollow.",
                            "Someone silenced the bells of Biertan on purpose, and paid the old powers to keep them quiet. Go on to Moșna. Take the clapper home.",
                        }, () =>
                        {
                            gm.quest2 = 3;
                            player.coins += 60;
                            player.hp = player.maxHp;
                            HudEvents.Banner("LEVEL 2 COMPLETE", "+60 coins.  Moșna awaits.");
                            gm.SaveGame();
                        });
                    else
                        gm.StartDialogue("Pfarrer Lukas", new[] { "Moșna is the next fortress on the road to Biertan. The clapper must go home." });
                    break;

                case "vasile":
                    if (!gm.metVasile)
                        gm.StartDialogue("Vasile", new[]
                        {
                            "Going down into the salt? Then you will want this pouch.",
                            "Throw salt at your feet and it makes a circle the dead cannot cross. Anything unclean inside it burns. Iele hate it too.",
                            "Thirty years I cut salt down there. Miners buried in salt do not rot, and some of them got up again. Moroi, the old women call them.",
                        }, () =>
                        {
                            gm.metVasile = true;
                            player.saltUnlocked = true;
                            player.salt += 4;
                            HudEvents.Toast("Salt pouch.  +4 salt  (R to throw)");
                        });
                    else
                        gm.StartDialogue("Vasile", new[] { "The caves are full of salt-stone. Chip a piece where it glows.", "Or three pinches for ten coins, if you'd rather not bend." }, BuySalt);
                    break;

                case "katharina":
                    if (!player.wormwood)
                        gm.StartDialogue("Katharina", new[] { "Wormwood and garlic, my dear. The Iele cannot bear the smell of pelin.", "Wear a sprig and their song will not hold your legs. Forty coins." }, BuyWormwood);
                    else
                        gm.StartDialogue("Katharina", new[] { "Garlic tincture, ten coins. The road east is long." }, BuyPotion);
                    break;

                case "sexton":
                    if (gm.quest4 == 0)
                        gm.StartDialogue("Martin, Sexton", new[]
                        {
                            "A living face, and a clapper of the great bell in your pack. Then Konrad sent you. God bless that stubborn Saxon.",
                            "He came at the turn of the year. A boyar's son from over the mountains, they said, dead three winters. Vlad. He had the bells stilled first, so the dead would not hear the hour of judgement.",
                            "His thralls hold the three walls. Each gate is sealed by a ward of blood. Break the wards and the gates will rise.",
                            "Here is my key to the church; it opens one of the nineteen locks of the sacristy door, and the side door besides. Hang the clapper, ring the great bell, and he will have to stand in his flesh.",
                        }, () =>
                        {
                            gm.quest4 = 1;
                            player.potions += 2;
                            player.salt += 3;
                            HudEvents.Banner("QUEST: THE BELLS OF BIERTAN", "Climb the three walls. Destroy Strigoi Vlad.");
                            HudEvents.Toast("Received: the sexton's key, two tinctures and salt");
                        });
                    else if (gm.quest4 == 1)
                        gm.StartDialogue("Martin, Sexton", new[] { "Tinctures and salt, ten coins each. Take what you need. Nothing up there will sell you anything." }, BuyPotion);
                    else
                        gm.StartDialogue("Martin, Sexton", new[] { "Listen to them. Three hundred years those bells have rung over this valley, and they ring again because of you.", "Stay as long as you like, Wanderer. Biertan owes you its every hour." });
                    break;

                case "andreas":
                    if (gm.quest4 < 2)
                        gm.StartDialogue("Andreas", new[] { "The council locked us in here to make up, Sofia and me. Two weeks, one spoon. On the third night the dead came down the hill.", "We have not argued since. Funny, that." });
                    else
                        gm.StartDialogue("Andreas", new[] { "When the council lets us out, I think we will stay married. Do not tell the council." });
                    break;

                case "sofia":
                    if (!gm.sofiaGift)
                        gm.StartDialogue("Sofia", new[] { "Take this. My wedding ribbon. My grandmother said a red ribbon keeps the strigoi from the throat.", "Bring it back to me when the bells ring." }, () =>
                        {
                            gm.sofiaGift = true;
                            player.maxHp += 20f;
                            player.hp = player.maxHp;
                            HudEvents.Toast("Wedding ribbon.  (+20 max health)");
                        });
                    else
                        gm.StartDialogue("Sofia", gm.quest4 >= 2 ? new[] { "Keep it. You have earned more than a ribbon." } : new[] { "Come back to us. Both of you: you and the ribbon." });
                    break;

                case "konrad":
                    if (gm.quest3 == 0)
                        gm.StartDialogue("Meister Konrad", new[]
                        {
                            "Let me see that. A bell clapper... my father's mark is on it. He cast it for the great bell of Biertan.",
                            "No cart has come from Biertan in a month. The road runs past the old quarry, and something has coiled itself in the flooded pit. Three heads, the carters say. A balaur.",
                            "Old Saxon law: you do not cut a balaur's head, you cut and burn it. Cut only, and it grows back by evening.",
                            "Take this torch from my furnace. It does not go out. Sear every neck you cut.",
                        }, () =>
                        {
                            gm.quest3 = 1;
                            player.torch = true;
                            player.potions += 1;
                            HudEvents.Banner("QUEST: THE ROAD TO BIERTAN", "Slay the Balaur in the drowned quarry.");
                            HudEvents.Toast("Received: Founder's Torch  (sears stumps)");
                        });
                    else if (gm.quest3 == 1)
                        gm.StartDialogue("Meister Konrad", new[] { "Cut, then burn. Do not forget it.", "If your blade is dull, I can whet it. Twenty-five coins." }, Sharpen);
                    else if (gm.quest3 == 2)
                        gm.StartDialogue("Meister Konrad", new[]
                        {
                            "You hear that? The carters are already hitching their horses.",
                            "Biertan lies two hours down the road. Whatever silenced its bells is waiting for you there.",
                            "I will fit the clapper to a hanger. When you reach the great bell, ring it. The dead of Biertan should hear it.",
                        }, () =>
                        {
                            gm.quest3 = 3;
                            player.coins += 50;
                            player.hp = player.maxHp;
                            AudioManager.I?.Sfx("bell", -2f);
                            HudEvents.Banner("LEVEL 3 COMPLETE", "+50 coins.  The road to Biertan is open.");
                            gm.SaveGame();
                        });
                    else
                        gm.StartDialogue("Meister Konrad", new[] { "Ring the great bell of Biertan, Wanderer. Twenty-five coins for a whetting, if you want it." }, Sharpen);
                    break;

                case "magda":
                    if (gm.quest3 >= 2)
                        gm.StartDialogue("Magda", new[] { "Oh, NOW you killed the serpent. A month late. Biertan is waiting, and you are dawdling. HAIDA!", "...Thank you. Now HAIDA, go!" });
                    else if (gm.quest3 == 0)
                        gm.StartDialogue("Magda", new[] { "Konrad is by the church, by the fire. Go! HAIDA, HAIDA!" });
                    else
                        gm.StartDialogue("Magda", new[] { "Still standing here? HAIDA, the Balaur will not slay itself!" });
                    break;

                case "hannes":
                    gm.StartDialogue("Hannes", new[] { "Every family of Moșna keeps its ham in the tower, and on Sundays we cut a slice. That is how a village survives a siege.", "Smoked ham and plum brandy, ten coins. Heals like a tincture, tastes better." }, BuyPotion);
                    break;

                case "veta":
                    if (!player.garlic)
                        gm.StartDialogue("Veta", new[] { "My husband sang in the church for forty years. They buried him in the yard below the vineyards, and last week he came to the window.", "A strigoi drinks what it bites. Wear garlic and its teeth slide off. Forty coins for the wreath." }, BuyGarlic);
                    else
                        gm.StartDialogue("Veta", new[] { "If you see a cantor with a grey beard among them... lay him down gently." });
                    break;

                case "rozalia":
                    if (gm.quest2 < 2)
                        gm.StartDialogue("Rozalia", new[] { "My Ioan walked out singing. His eyes were open but he did not see me.", "Please. Bring him home." });
                    else if (!gm.rozaliaThanked)
                        gm.StartDialogue("Rozalia", new[] { "He is home. He remembers only a green woman and honey cake.", "Take these. I made them for him, but he has his mother now." }, () =>
                        {
                            gm.rozaliaThanked = true;
                            player.potions += 2;
                            HudEvents.Toast("Rozalia gives you two tinctures.");
                        });
                    else
                        gm.StartDialogue("Rozalia", new[] { "God keep you on the road, Wanderer." });
                    break;

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

        // ---------------------------------------------------------------- shops (main.gd buy_*)

        static bool Pay(int cost, string need)
        {
            var p = GM.player;
            if (p.coins >= cost) { p.coins -= cost; return true; }
            HudEvents.Toast(need);
            return false;
        }

        public static void BuyPotion()
        {
            if (!Pay(10, "You need ten coins.")) return;
            GM.player.potions += 1;
            HudEvents.Toast("Garlic tincture bought.  -10 coins");
        }

        public static void BuySalt()
        {
            if (!Pay(10, "You need ten coins.")) return;
            GM.player.salt += 3;
            HudEvents.Toast("Three pinches of salt.  -10 coins");
        }

        public static void BuyGarlic()
        {
            if (!Pay(40, "You need forty coins.")) return;
            GM.player.garlic = true;
            HudEvents.Toast("Garlic wreath.  Strigoi bite half as hard and cannot drink.");
        }

        public static void BuyWormwood()
        {
            if (!Pay(40, "You need forty coins.")) return;
            GM.player.wormwood = true;
            HudEvents.Toast("Wormwood sprig.  The Iele's song no longer slows you.");
        }

        public static void Sharpen()
        {
            if (!Pay(25, "You need twenty-five coins.")) return;
            GM.smithLevel += 1;
            GM.player.dmg += 4f;
            HudEvents.Toast("Blade whetted.  (+4 damage)");
        }
    }
}

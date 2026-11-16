# Biertan - Playtest & QA Checklist

Playtesting flow for all levels in order, documenting required actions, flags set (`G.side_add`), expected visual/audio feedback, and critical edge cases / softlocks identified in the code.

---

## Act 1: The Road to Biertan

### 1. Stână (Prologue) - `stana.gd`
- **Step 1:** Wait for Azorel to approach and lick the sleeping hunter.
  - *Flags:* `step = 1`
  - *Visible:* Hunter unfreezes; dialogue popup "(Something warm and wet across your face...)".
- **Step 2:** Interact with the gate prop to open the fold (`gate_open = true`).
  - *Visible:* Hurdle gap clears; objective updates to "Drive the cows into the stână".
- **Step 3:** Herd all 4 cows into the pen (`FOLD`).
  - *Visible:* Counter increments `penned() / cows.size()`.
- **Step 4:** Interact with gate prop again to shut the fold.
  - *Flags:* `step = 2`, `wolves_come = true`
  - *Visible:* Gate closes; HUD banner "WOLVES - You pull the knife from your belt"; 3 wolves spawn from the spruce.
- **Step 5:** Defeat all 3 wolves with knife attacks (Click / J) or dodges (SPACE).
  - *Flags:* `step = 3`
  - *Visible:* Azorel leans against hunter's leg; dialogue "Good dog. Tomorrow we go down."
  - *Story Card:* `prologue` and `descent` story cards play.
  - *Transition:* Automatic transition to `sighisoara`.

---

### 2. Sighișoara & The Smoke-Cellar - `sighisoara.gd`, `cellar.gd`, `sig_quest.gd`
- **Step 1:** Arrive at citadel square; inspect the Notice Board (`notice`).
  - *Flags:* `sig_arrive`, `sig_notice`
  - *Visible:* Dialogue displays work notice; objective updates to speak with Meister Thomas.
- **Step 2:** Speak with Meister Thomas at his butcher stall on the square.
  - *Flags:* `sig_job`
  - *Visible:* Toast "New quest: The Stolen Bacon"; Meister Thomas walks down to the Butchers' Tower; 4 clues spawn.
- **Step 3:** Find and inspect 4 clues around the Butchers' Tower:
  - `flour`: flour footprints (`sig_c_flour`)
  - `grating`: cellar grating (`sig_c_grating`)
  - `hook`: empty iron smoking hook (`sig_c_hook`)
  - `smoke`: smoke drawn downward (`sig_c_smoke`)
  - *Visible:* Clue counter increments; toast prompts to speak with Frau Gertrud.
- **Step 4:** Speak with Frau Gertrud (`butcherwife`) by the kitchen.
  - *Flags:* `sig_wife`
  - *Visible:* Gertrud mentions her son Mihai playing near the woodpile.
- **Step 5:** Speak with Mihai (`child`) behind the kitchen.
  - *Flags:* `sig_child`
  - *Visible:* Mihai tells how the little men slip behind the salt crate.
- **Step 6:** Push the heavy salt crate (`crate`) by the tower base.
  - *Flags:* `sig_crate`
  - *Visible:* Crate moves aside; reveals small entrance hole in wall.
- **Step 7:** Light lantern at Gertrud's kitchen hearth (`hearth`).
  - *Flags:* `sig_flame`
  - *Visible:* Player torch turns on; light radius appears around hunter.
- **Step 8:** Pull the ox's tongue lever on the guild sign (`sign`).
  - *Flags:* `sig_lever`, `sig_open`
  - *Visible:* Bell chime SFX; counterweight drops inside wall; cellar door unlocks.
- **Step 9:** Interact with cellar door (`cellar`) to transition to `cellar.gd`.
  - *Transition:* Level loads `cellar.gd`.
- **Step 10:** In the cellar, advance past swinging ham hooks. Trigger hat theft:
  - *Flags:* `sig_hat_lost`
  - *Visible:* Small spiriduș drops from hook, snatches hat, giggles, and runs east.
- **Step 11:** Fight through spiriduși to the captain's den (east end). Defeat `spiridus_cap`.
  - *Flags:* `sig_cellar`, `sig_hat_back`
  - *Visible:* Captain faints; banner "THE CAPTAIN FAINTS"; speak with captain to recover hat; spiriduși apologize.
- **Step 12:** Take west stairs up (`_leave`) to return to Sighișoara square.
- **Step 13:** Speak with Meister Thomas at Butchers' Tower to broker the food-for-work deal.
  - *Flags:* `sig_deal`, `token_tin_button`
  - *Visible:* Thomas agrees to feed the spiriduși; awards token: `token_tin_button`.
- **Step 14:** Speak with Vlad Laurențiu at his cart in the lower town (`vlad`).
  - *Flags:* `sig_left`
  - *Transition:* Vlad's cart departs for `viscri`.

---

### 3. Viscri & The Churchyard Crypt - `viscri.gd`, `crypt.gd`, `vis_quest.gd`
- **Step 1:** Arrive on Vlad's cart. Speak to Lorena at her gate (`lorena`).
  - *Flags:* `vis_arrive`, `vis_job`
  - *Visible:* Toast "New quest: The Silent Dogs"; investigation targets appear.
- **Step 2:** Find 3 clues:
  - Geese pen hissing (`vis_c_geese`)
  - Sleeping yard dog stuffed with raw pork (`vis_c_dog`)
  - Trail of raw meat scraps (`vis_c_scraps`)
- **Step 3:** Speak with 3 witnesses:
  - The butcher (`vis_w_vbutcher`)
  - The goose woman (`vis_w_goosewife`)
  - The church caretaker (`vis_w_caretaker`)
  - *Visible:* Counter shows 3/3 clues, 3/3 witnesses; objective updates: "Watch the old barn after dark."
- **Step 4:** Interact with old barn (`barn`).
  - *Flags:* `vis_key`
  - *Visible:* Cutscene shows sexton walking in daze with sack, dropping key; collect sexton's key.
- **Step 5:** Unlock cellar door in churchyard wall (`cryptdoor`) -> transitions to `crypt.gd`.
- **Step 6:** In `crypt.gd`, engage and defeat the spellbound Sexton boss.
  - *Flags:* `vis_crypt`
  - *Visible:* Banner "THE SEXTON FALLS"; sexton drops bell rope and sits dazed.
- **Step 7:** Untie and speak with stable boy Matei (`matei`).
  - *Flags:* `vis_matei`
  - *Visible:* Matei reveals the sexton wasn't spellbound and led people underground.
- **Step 8:** Inspect chalk arrow on tunnel wall (`chalk`) and torn map scrap (`mapscrap`).
  - *Flags:* `vis_chalk`, `vis_scrap`
  - *Visible:* Toast reveals map scrap pointing to "BIRTHÄLM" (Biertan).
- **Step 9:** Take stairs up back to Viscri.
- **Step 10:** Report back to Lorena at her gate.
  - *Flags:* `vis_done`, `map_unlocked`, `token_cellar_key`
  - *Visible:* Lorena unlocks road map; grants token `token_cellar_key`; road south to Criț opens.

---

### 4. Criț & The Sacred Grove - `crit.gd`, `critforest.gd`, `crit_quest.gd`
- **Step 1:** Arrive in Criț (`cr_arrive`). Speak to Floarea (`floarea`).
  - *Flags:* `cr_job`
  - *Visible:* Toast "New quest: The Friday Curse"; Floarea shows her burned hands.
- **Step 2:** Find 4 clues:
  - Unwashed trousseau linen (`cr_c_laundry`)
  - Tub of harsh lye (`cr_c_lye`)
  - Ribbons on hedges (`cr_c_ribbons`)
  - Overgrown forest path (`cr_c_path`)
- **Step 3:** Speak with 3 village grandmothers:
  - Baba Ana (`cr_b_baba_ana`)
  - Baba Safta (`cr_b_baba_safta`)
  - Baba Veta (`cr_b_baba_veta`)
- **Step 4:** Speak with Floarea or her mother to learn the ritual offering basket requirements (`cr_basket`).
- **Step 5:** Gather the offerings:
  - Pick apples from mother's orchard (`cr_fruit`)
  - Gather poppies from old cemetery (`cr_poppy`)
  - Enter forest path to `critforest.gd`; pick wild roses from bushes (`cr_roses`)
- **Step 6:** Approach Sfânta Vineri's shrine in `critforest.gd` clearing (`shrine`).
  - *Flags:* `cr_shrine`
  - *Visible:* Basket placed on altar; shrine candle lights; clearing wind stills.
- **Step 7:** Return to Criț village. Speak with Floarea's mother (`mother`) to calm her stubbornness (`cr_mother`).
- **Step 8:** Speak with Floarea (`floarea`).
  - *Flags:* `cr_done`, `token_ribbon`
  - *Visible:* Hands heal; awards `token_ribbon`; road east to Saschiz unlocks.

---

### 5. Saschiz & Cetatea Uriașilor - `saschiz.gd`, `uriasi.gd`, `sx_quest.gd`
- **Step 1:** Arrive in Saschiz (`sx_arrive`). Speak to Ilinca on church square (`ilinca`).
  - *Flags:* `sx_job`
  - *Visible:* Toast "New quest: The Missing Children".
- **Step 2:** Inspect 3 clues:
  - Giant tracks beside child prints (`sx_c_tracks`)
  - Dropped clay horse toy (`sx_c_clayhorse`)
  - Boulders stacked like toys (`sx_c_stones`)
- **Step 3:** Inspect neighbours' carts at edge of village (`carts`).
  - *Flags:* `sx_carts`
  - *Visible:* Confirms neighbours are innocent; tracks lead up the fortress hill.
- **Step 4:** Speak with angry mob by clock tower (`mob`); survive/disperse brawl.
  - *Flags:* `sx_brawl`
  - *Visible:* Mob backs down; path to fortress hill unblocks.
- **Step 5:** Climb hill path (`hill`) to enter `uriasi.gd`.
- **Step 6:** Fight Uriașul (Giant boss).
  - *Phase 1:* Knock giant down to 200 HP -> Paul slips out of apron (`child_freed(1)`).
  - *Phase 2:* Giant scoops player into apron; strike him 4 times to break free; reduce to 100 HP -> Ioana freed (`child_freed(2)`).
  - *Phase 3:* Strike rot spot on giant's back; reduce to 0 HP -> Andrei freed (`child_freed(3)`).
  - *Flags:* `sx_giant`
  - *Visible:* Giant sits down peacefully with toys (`sat_down`).
- **Step 7:** Speak to sitting giant (`giant`) and rescued children (`sx_giant_talk`).
- **Step 8:** Take path down (`exit`) back to Saschiz.
- **Step 9:** Speak to Ilinca on church square.
  - *Flags:* `sx_done`, `token_fort_stone`
  - *Visible:* Children reunited; awards `token_fort_stone`; road west to Șapartoc opens.

---

### 6. Șapartoc (The Deserted Village) - `sapartoc.gd`, `sp_quest.gd`
- **Step 1:** Arrive in Șapartoc (`sp_arrive`). Speak to Radu at inn (`radu`).
  - *Flags:* `sp_job`
  - *Visible:* Radu explains ghost Ana in old Catholic church.
- **Step 2:** Visit Catholic church; speak to ghost Ana; return to Radu.
  - *Flags:* `sp_plan`
  - *Visible:* Plan formed to give the 3 abandoned churches new community functions.
- **Step 3:** Speak to Mayor Horia (`horia`) to get letters signed.
  - *Flags:* `sp_letters`
- **Step 4:** Light street lamps (`sp_lamp0`..`sp_lamp4`) and gather timber from old barn (`sp_materials`).
- **Step 5:** Restore all 3 churches:
  - Catholic church: set up soup tables (`sp_canteen`).
  - Saxon fortified church: set up violin music hall (`sp_concert`).
  - Sheep pasture: wake sleeping Hungarian priest Father Bálint (`traveller`), escort to Orthodox church for liturgy (`sp_priest`, `sp_mass`).
- **Step 6:** (Optional) Challenge Bull of Șapartoc in pasture (`bull.gd`); dodge charges into trees.
- **Step 7:** Speak to Radu at the inn.
  - *Flags:* `sp_done`, `token_ana_lantern`
  - *Visible:* Settlers arrive; awards `token_ana_lantern`; road south to Apold opens.

---

### 7. Apold (Sâmedru's Fire) - `apold.gd`, `ap_quest.gd`
- **Step 1:** Arrive in Apold (`ap_arrive`). Speak to Old Dumitru (`dumitru`).
  - *Flags:* `ap_job`
  - *Visible:* Toast "New quest: Sâmedru's Fire"; Dumitru lists ancestral offerings needed.
- **Step 2:** Gather the 3 offerings:
  - Stir wheat for grandmother (`granny`) -> colivă (`ap_coliva`).
  - Help baker's wife (`baker`) -> colaci bread (`ap_colaci`).
  - Retrieve jug of wine from old cellar (`wine_cellar` -> `ap_wine`).
- **Step 3:** Inspect Sâmedru woodpile on the hill (`woodpile` -> `ap_woodpile`).
- **Step 4:** Speak to Dumitru to initiate the night feast.
  - *Flags:* `ap_night`
  - *Visible:* Dusk falls; ancestral tables set near churchyard; hungry dead emerge.
- **Step 5:** Defend the tables across 3 waves; light the Sâmedru bonfire on the hill (`ap_fire`) to slow the dead.
- **Step 6:** Hold until dawn arrives (`ap_dawn`).
- **Step 7:** Speak to Dumitru in the morning.
  - *Flags:* `ap_done`, `token_samedru_candle`
  - *Visible:* Dead return to graves pacified; awards `token_samedru_candle`; road to Criș opens.

---

### 8. Criș & Muma Pădurii - `cris.gd`, `crisforest.gd`, `cs_quest.gd`
- **Step 1:** Arrive in Criș (`cs_arrive`). Speak to forester Gheorghe (`gheorghe`).
  - *Flags:* `cs_job`
  - *Visible:* Toast "New quest: Muma Pădurii and the Feast"; villagers afflicted with ergot delirium.
- **Step 2:** Observe 5 delirious villagers (`oakman`, `henwoman`, `goose1`, `farmer`, `towerkid`).
  - *Flags:* `cs_m_*`
- **Step 3:** Speak to herbalist Denisa (`denisa`).
  - *Flags:* `cs_denisa`
  - *Visible:* Denisa points to Muma Pădurii's wood to the west.
- **Step 4:** Enter Criș forest (`crisforest.gd`).
- **Step 5:** Free 4 trapped forest animals from iron snares:
  - Fox (`cs_fox`)
  - Deer (`cs_deer`)
  - Owl (`cs_owl`)
  - Bear (`cs_bear_down`, then soothe/bandage -> `cs_bear`).
- **Step 6:** Speak to Muma Pădurii beneath her ancient oak tree (`muma`).
  - *Flags:* `cs_muma`, `token_muma_twig`
  - *Visible:* Muma thanks the hunter; awards `token_muma_twig`; identifies rot-marked alpha wolf.
- **Step 7:** Defeat the rot-marked Alpha Wolf.
  - *Flags:* `cs_wolves`
- **Step 8:** Return to Criș village square.
  - *Flags:* `cs_done`
  - *Visible:* Villagers burn tainted rye and prepare community feast.
  - *Story Card:* `recap_cris` plays, cutting directly to black.

---

### 9. Mălâncrav (The Morning After) - `malancrav.gd`, `malcrypt.gd`, `ml_quest.gd`
- **Step 1:** Wake up without trousers in farmer Petru's haystack (`ml_arrive`, `ml_pantsless`). Speak to Petru (`petru`).
  - *Flags:* `ml_job`
- **Step 2:** Speak to 4 witnesses around the village:
  - Sexton (`ml_c_msexton`)
  - Orchard keeper (`ml_c_orchard`)
  - Baker (`ml_c_mbaker`)
  - Children (`ml_c_mchild`)
- **Step 3:** Relive 3 interactive flashback memories:
  - Feast table in Criș (`ml_f_cup`)
  - Talking to Muma Pădurii (`ml_f_twig`)
  - Climbing the tower with trousers as flag (`ml_f_stones`)
- **Step 4:** Climb church tower ladder to retrieve trousers (`tower`).
  - *Flags:* `ml_pants`
  - *Visible:* Hunter puts trousers back on; village stops mocking.
- **Step 5:** Enter churchyard crypt (`malcrypt.gd`).
- **Step 6:** Defeat Crypt Warden boss and rising moroi.
  - *Flags:* `ml_crypt`
  - *Visible:* Banner "THE WARDEN FALLS"; crypt quietens.
- **Step 7:** Speak to Muma Pădurii / her bear at village edge (`muma`).
  - *Flags:* `ml_moroi`, `ml_stake`
  - *Visible:* Fulfills drunken oath; receives oak stake.
- **Step 8:** Speak with sexton (`msexton`).
  - *Flags:* `ml_done`, `token_tower_key`
  - *Visible:* Sexton hands over church tower key (`token_tower_key`); road to Richiș opens.

---

### 10. Richiș & The Iele Ridge - `richisvillage.gd`, `richisforest.gd`, `ieleridge.gd`, `rc_quest.gd`
- **Step 1:** Arrive in Richiș (`rc_arrive`). Speak to Moș Ilie (`ilie`).
  - *Flags:* `rc_job`
  - *Visible:* Toast "New quest: The Brothers and the Iele"; Toader dancing entranced.
- **Step 2:** Observe Toader dancing (`toader` -> `rc_o_toader`) and inspect blocked ridge road (`ridge` -> `rc_o_ridge`).
- **Step 3:** Collect 4 protective herbs:
  - Wormwood from `richisforest.gd` (`rc_wormwood`)
  - Walnut leaves from `richisforest.gd` (`rc_walnut`)
  - Garlic from widow's cellar (`cellar` -> `rc_garlic`)
  - Basil from Denisa (`denisa` -> `rc_basil`)
- **Step 4:** Speak to Denisa to brew the herbal decoction (`rc_brew`).
- **Step 5:** Administer decoction to Toader (`toader` -> `rc_calm`).
- **Step 6:** Speak to Moș Ilie (`ilie`); agree to ascend ridge while he plays the pan flute (`rc_agree`).
- **Step 7:** Ascend to `ieleridge.gd`.
- **Step 8:** Stand in the fae ring; fight the 7 Iele sisters.
  - *Mechanic:* Listen to Ilie's Doina; strike only sisters turned solid by music; avoid illusions.
  - *Flags:* `rc_iele`
- **Step 9:** Return to village; speak with Ilie and Toader.
  - *Flags:* `rc_done`, `token_flower_ring`, `rc_whistle`
  - *Visible:* Toader restored; awards `token_flower_ring`; road to Biertan opens.

---

## Act 2: Biertan Fortified Church

### 11. Biertan: The Baron's Table & The Sacristy Door - `biertanfort.gd`, `sacristy.gd`, `bt_quest.gd`
- **Step 1 (Day):** Arrive in Biertan (`bt_arrive`). The baron comes down the covered stair to greet player and invites him to supper (`bt_invited`).
- **Step 2 (Day):** Inspect 5 clues at the baron's banquet table:
  - `bt_s_salt`: roast meat, no salt cellar
  - `bt_s_garlic`: no garlic in food
  - `bt_s_wine`: cup untouched with drowned fly
  - `bt_s_servant`: grey-faced servants
  - `bt_s_kennel`: empty dog kennels
- **Step 3 (Day):** Sit down to supper with the baron (`bt_supper`).
  - *Story Card:* `supper_biertan` plays; dawn breaks.
- **Step 4 (Day):** Investigate all three concentric rings for proof:
  - Outer wall: speak to bickering couple locked in marriage prison (`bt_i_couple`).
  - Middle wall: inspect freshly dug-over grave plot with worn year 1321 (`bt_i_grave`).
  - Inner wall: break into sexton's house; inspect ledger showing payments from every village (`bt_i_ledger`).
- **Step 5 (Day):** Confront the baron on the terrace and declare aloud what he is: a strigoi mort.
  - *Flags:* `bt_night`
  - *Visible:* Sexton flees; alarm bell rings; night falls immediately; villagers flee down stairs.
- **Step 6 (Night):** Fight up through all three wall rings:
  - Ring 1 (outer): defeat rot wolves -> open gate 1 (`bt_bolt0`).
  - Ring 2 (middle): defeat moroi rising from graves -> open gate 2 (`bt_bolt1`).
  - Ring 3 (inner): defeat thrall servants -> open gate 3 (`bt_bolt2`).
- **Step 7 (Night):** Enter fortified hall church -> loads `sacristy.gd`.
- **Step 8 (Night):** Approach the Sacristy Door of 1515 (`door`).
  - *Requirement:* All 9 road tokens must be in inventory (`token_tin_button`, `token_cellar_key`, `token_ribbon`, `token_fort_stone`, `token_ana_lantern`, `token_samedru_candle`, `token_muma_twig`, `token_tower_key`, `token_flower_ring`).
  - *Action:* Interact with door: each token draws 2 bolts (18 bolts total). The 19th bolt slides back by itself from inside (`bt_open`).
  - *CRITICAL QA SOFTLOCK WARNING:* See Section 15 below.
- **Step 9 (Night):** Boss Fight - The Baron of Biertan / Strigoi Mort (`lord`):
  - Phase 1: Lord with bell-rope lash; summons thralls.
  - Phase 2: Shatters at 60% HP into wolves/mist.
  - Phase 3: Strigoi mort; blade deflects unless church bell is rung to stun him; deliver final blow with Muma's oak stake.
  - *Flags:* `bt_fled`, `bt_done`
  - *Visible:* Baron shatters and flees down the tomb trapdoor into the subterranean passage.
- **Step 10:** Take trapdoor under tomb or road down -> transitions to Act 3: `gorge.gd`.

---

## Act 3: The Chase Back

### 12. The Gorge & The Solomonar - `gorge.gd`
- **Step 1:** Arrive in gorge on Vlad and Magda's cart. Encounter the Solomonar in beggar's rags.
  - *Story Card:* `balaur_rise` plays.
- **Step 2:** Boss Fight - Storm Balaur (`storm_balaur.gd`):
  - Dodge lightning bolts by standing near standing stones (lightning strikes tallest object).
  - Sidestep dive attacks. Strike the balaur when grounded.
  - *Visible:* Balaur beaten down steaming.
- **Step 3:** Speak to the Solomonar; share bread.
  - *Visible:* Solomonar recognizes mistake, lifts storm curse, and promises aid for the wedding; path east to vineyard opens.

### 13. The Vineyard & Marțolea - `vineyard.gd`
- **Step 1:** Enter vineyard press-house where women are sewing the groom's shirt on Tuesday night.
- **Step 2:** Interactive ritual before nightfall: turn every vessel (pots, troughs, lamps, buckets) upside down, place broom across threshold.
- **Step 3:** Night falls. Boss Fight - Marțolea (`martolea.gd`):
  - Marțolea's health, damage, and speed scale with every vessel left upright.
  - Dodge spinning threads (tangle/root effect) and claw swipes.
  - Fight until cockcrow signals dawn; Marțolea flees.
  - *Flags:* `vy_done`
  - *Visible:* Women finish the bridegroom's shirt; player collects shirt; path to Wolf Forest opens.

### 14. Wolf Forest, Moon Clearing & Joimărița - `forest.gd`
- **Step 1:** Navigate through Wolf Forest past wolves and late-blooming snowdrops.
- **Step 2:** Enter Moon Clearing. Boss Fight - The Vârcolac (`varcolac.gd`):
  - Vârcolac devours the moon, plunging arena into total darkness.
  - Light braziers with torch; fight only within the light radius (vârcolac is invulnerable shadow in the dark).
  - Break his ascension threads when he gorges on flames.
  - *Visible:* Threads snap; vârcolac crashes down and flees into the sky.
- **Step 3:** Spring glade opens. Speak to Joimărița:
  - Joimărița inspects the hunter's hands, thanks him, and gives spring flowers.
  - *Flags:* `fo_done`
  - *Visible:* Path to underground tunnel unblocks.

### 15. The Tunnel & Cățelul Pământului - `tunnel.gd`
- **Step 1:** Follow Cățelul Pământului (pale subterranean hound) through underground passage.
- **Step 2:** When the dog stops and barks at buried grave earth, interact to dig up the wick-tied linen bags.
  - *Flags:* `tn_dug`
  - *Visible:* Dog sneezes and continues leading through safe floor.
- **Step 3:** Reach exit ladder leading up into the cellars of Viscri (`tn_done`).

### 16. Viscri Revisit - `viscri.gd`
- **Step 1:** Climb out of Viscri cellar.
- **Step 2:** Inspect Lorena's open gate (`lorenagate` -> `v3_gate`).
  - *Visible:* Dialogue reveals the baron politely abducted Lorena after she bit his finger and tried to feed him garlic; neighbor saw him fleeing toward Sighișoara.
- **Step 3:** Inspect wounded Azorel lying across the doorstep (`azorel` -> `v3_azorel`).
  - *Visible:* Bandage Azorel; Azorel gets up and joins the hunter.
- **Step 4:** Take the road to Sighișoara (`v3road`).

### 17. Sighișoara (Act 3 Finale) - `sighisoara.gd`, `draculhouse.gd`, `fin_quest.gd`
- **Step 1:** Arrive in Sighișoara at dusk (`fin_arrive`).
- **Step 2:** Speak to spiriduș captain under Butchers' Tower; show the bent tin button (`captain`).
  - *Flags:* `fin_spirid`
  - *Visible:* Captain reveals Lorena is locked in Tinsmiths' Tower and the baron is hiding at Casa Vlad Dracul.
- **Step 3:** Enter Casa Vlad Dracul; speak to the baron with bandaged hand (`baron`).
  - *Flags:* `fin_key`
  - *Visible:* Baron complains Lorena is wild; gives tower key (`fin_key`); warns of his midnight transformation.
- **Step 4:** Unlock Tinsmiths' Tower (`tower`).
  - *Flags:* `fin_lorena`
  - *Visible:* Lorena freed from her garlic-strewn barricade.
- **Step 5:** Midnight arrives. Square boss fight - Hold the Strigoi until dawn:
  - Dodge attacks; interact with Clock Tower bell rope (`bell`) to ring the great bell and stun the strigoi.
  - Survive until dawn timer expires (`DAWN_AFTER`).
  - *Flags:* `fin_dawn`
  - *Visible:* Dawn breaks; cock crows; baron regains his senses; Lorena insists on a proper burial-wedding.
- **Step 6:** Prepare the Funeral-Wedding (gather 3 elements):
  - Fir tree: speak to Vlad and Magda by their cart (`bvlad` -> `fin_p_fir`).
  - Feast table: speak to Meister Thomas at Butchers' Tower (`butcher` -> `fin_p_table`).
  - Priest: wake Hungarian priest Father Bálint on bench (`finpriest` -> `fin_p_priest`).
- **Step 7:** Climb the covered Scholars' Stair (`stair`) to the Church on the Hill.

### 18. Church on the Hill (The Wedding & The Sexton) - `hillchurch.gd`
- **Step 1:** Walk up the nave aisle to the altar.
  - *Visible:* Funeral-wedding begins; coffin open, fir tree in bride's place, guests assembled.
- **Step 2:** Cold feet: The baron stops the ceremony, refuses to marry a tree, and proposes to Joimărița.
  - *Visible:* Joimărița checks his nine-fingered hands, agrees; Father Bálint demands wine.
- **Step 3:** Sexton ambushes the ceremony from the crypt door: throws his remaining sack of grave earth over crypt slabs.
- **Step 4:** Final Battle:
  - Wave 1: Dead rise from crypt slabs; ring tower bell rope to stun dead and restore guest courage.
  - Wave 2: Rot wolves invade from church doors; allies assist (spiriduși, Azorel, bear, Lorena).
  - Wave 3: Moroi storm the pews; Sexton enters with spade.
  - Wave 4: Defeat the Sexton boss (`sexton`).
- **Step 5:** Sexton falls (`sexton_end` story card plays).
- **Step 6:** Judgement:
  - Cățelul Pământului barks 3 times from under the floor; dead sink back under slabs.
  - Joimărița inspects Sexton's smooth, unworked hands; burns his fingers with her ember pot; sentences him to spin coarse hemp in the Biertan marriage prison.
- **Step 7:** The Wedding concludes:
  - Hunter plants Muma's oak twig by altar; it leafs out with fresh green foliage.
  - Bridegroom of 1321 and Joimărița depart down the aisle; snowdrops bloom between flagstones; bells ring across Transylvania.
  - *Flags:* `fin_done`
  - *Visible:* Ending screen and credits trigger.

---

## 19. Critical QA Edge Cases & Softlock Risk

> [!CAUTION]
> **POTENTIAL GAME SOFTLOCK AT BIERTAN SACRISTY DOOR (`sacristy.gd:90-95`)**
> 
> In `bt_quest.gd:104`, triggering `bt_night` requires only that the player uncover the 3 proofs in Biertan (`bt_i_couple`, `bt_i_grave`, `bt_i_ledger`). It does NOT check whether the player actually collected all 9 road tokens from earlier villages (`tokens_have() == 9`).
> 
> However:
> 1. Once `bt_night` is triggered, the road down out of Biertan is hard-blocked:
>    `elif night(): G.start_dialogue("The road down", ["Not while he is still up there."])` (`bt_quest.gd:266`).
> 2. Inside the church, `sacristy.gd:90-95` strictly requires all 18 bolts drawn (all 9 tokens):
>    If `_locks() < 18`, the sacristy door refuses to open, listing the missing tokens.
> 
> **Result:** If a playtester skips sidequests or does not collect all 9 tokens before triggering `bt_night`, they cannot open the sacristy door AND cannot backtrack down the hill to previous villages. The player is permanently trapped in Biertan at night.
> 
> **Recommended Fix for Claude:** In `bt_quest.gd:104`, require `tokens_have() == TOKENS.size()` before allowing the hunter to confront the baron and trigger `bt_night`, or allow backtracking during night if tokens are missing.

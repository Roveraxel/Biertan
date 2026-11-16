# Folklore Fact-Check

Review of all dialogue, STORIES, and `scripts/bosses/*.gd` text against traditional Romanian mythological and ethnographic sources: Tudor Pamfile (*Mitologia poporului român*, *Sărbătorile la români*), Mihai Coman (*Mitologie populară românească*), Aurel Cosma Jr. (*Cosmogonia poporului român*), and classical ethnographic records of the Solomonar, Cățelul Pământului, and Transylvanian Saxon/Romanian funerary rites.

---

## 1. Discrepancies and Pop-Culture Elements

scripts/bosses/vampire_boss.gd:16: what the game says: `func hud_name() -> String: return "THE STRIGOI MORT" if mort else "THE VAMPIRE OF BIERTAN"`: what the source says: In Tudor Pamfile (*Mitologia poporului român*) and Mihai Coman (*Mitologie populară românească*), the entity is exclusively known as a *strigoi* (strigoi viu / strigoi mort) or *moroi*. The term "vampire" (*vampir*) is a 19th-century Western literary importation (via Bram Stoker, Sheridan Le Fanu, and Western translations) that was unknown to 16th-century Romanian peasants: suggested fix: Change the boss name to `"THE STRIGOI OF BIERTAN"` or `"LORD STRIGOI"`.

scripts/quests/cs_quest.gd:2: what the game says: `the forester blames the vampire's rot and sends the hunter into Muma Pădurii's wood`: what the source says: Romanian folklore attributes unnatural blight, wasting illness, or cursed soil to a *strigoi mort* spreading grave dirt, never to a "vampire": suggested fix: Change "the vampire's rot" to "the strigoi's rot".

scripts/bosses/vampire_boss.gd:2: what the game says: `at three fifths of his strength he breaks into wolves and bats`: what the source says: In Pamfile's accounts of strigoi, a strigoi mort leaves its grave taking the form of a wolf, a dog, a black cat, a horse, or an incorporeal whirlwind/shadow. Dissolving into a swarm of bats is an iconic Western Dracula/Hollywood film trope with no basis in Romanian peasant folklore: suggested fix: Replace bats with a flock of ravens/crows or a surge of freezing mist/shadows (`"breaks into wolves and shadow"`).

scripts/levels/hillchurch.gd:125-132: what the game says: Joimărița is portrayed as a young, barefoot woman in her mid-twenties with flowers in her hair, functioning as a spring maiden who falls in love with and marries the dead baron: what the source says: In Tudor Pamfile (*Sărbătorile la români*) and Mihai Coman, Joimărița is a grotesque, terrifying, ancient hag with enormous teeth and a blackened pot of live embers (*oală cu jăratic*) who stalks village households on Maundy Thursday to burn the fingers of girls who failed to complete their winter hemp-spinning. She is an agent of strict pastoral punishment, never a romantic maiden or bride: suggested fix: While this adaptation is noted as an intentional creative choice in `STORY.md:96-98`, the dialogue should emphasize her archaic, unsettling severity with the ember pot and her primordial nature ("I am Maundy Thursday") rather than conventional romantic sweetness.

scripts/quests/fin_quest.gd:115: what the game says: `"She tried to stuff garlic in my mouth, a whole head, with the skin on."`: what the source says: In Romanian apotropaic tradition (Pamfile, Coman), garlic (*usturoi*) is used proactively as a protective barrier—rubbed along window ledges, doorways, keyholes, cattle horns, and across the forehead on the eve of St. Andrew (*Noaptea Strigoilor*) or St. George. Forcibly stuffing whole garlic bulbs into an undead creature's mouth is a modern cinematic comedy/horror trope: suggested fix: Reframe Lorena's resistance to authentic folkloric barriers: `"She hung braids of garlic from every rafter, smeared the latch until the bronze turned green, and made the whole tower a fortress against me."`

scripts/bosses/bull.gd:1-10: what the game says: `"The Bull of Șapartoc, a vain Limousin who comes thundering over... 'Do you even plough, little man?', '...ow. My quiff.'"`: what the source says: Limousin cattle are a French beef breed, and the vain quiff-combing bodybuilder persona is pure contemporary comedy rather than Romanian pastoral folklore (which honors the sacred ancient *Bour* or *Sura de Stepă* / Grey Steppe cattle): suggested fix: Retain as comic relief if desired for combat variety, but note that it is modern parody; for authentic Romanian naming, refer to him as a *Taur de Stepă* or *Buhai*.

---

## 2. Authentic Folklore Elements Verified

The following major folkloric systems in the game were evaluated and found to be exceptionally faithful to authentic Romanian sources:

1. **Marțolea (`scripts/bosses/martolea.gd`, `scripts/levels/vineyard.gd`)**:
   - Accurately portrays Marțolea (Marțiseara), the fearsome demonic spirit of Tuesday evening who punishes women who spin, weave, or wash after dark.
   - The ritual mechanic of turning pots, troughs, and lamps upside down so they cannot answer her voice when she calls from the gate directly reflects authentic field recordings in Tudor Pamfile and Mihai Coman.

2. **The Solomonar and Balaur (`scripts/bosses/storm_balaur.gd`, `scripts/levels/gorge.gd`, `scripts/core/game_manager.gd:28-31`)**:
   - Accurately captures the legendary weather-sorcerer schooled for seven years in the Scholomance / lake school (*Șolomanță* under the mountain).
   - Accurately reflects his book of spells, birch/golden reins, summoning of the hail-dragon (*balaurul de grindină*), and his characteristic folk behavior: wandering in beggar's rags asking for bread/milk, cursing with destructive hail those who refuse him, and rewarding those who share their food.

3. **Cățelul Pământului (`scripts/levels/tunnel.gd`)**:
   - Accurately reflects Aurel Cosma Jr. and Tudor Pamfile's accounts of the subterranean earth-hound that lives underground near burial grounds.
   - His warning bark heard through the soil and his inability to cross stolen, wick-tied grave earth directly mirrors Romanian beliefs surrounding boundary-taboos and unhallowed burial earth.

4. **The Funeral-Wedding / Nunta Mortului (`scripts/quests/fin_quest.gd`, `scripts/levels/hillchurch.gd`)**:
   - Accurately reflects the archaic Romanian ritual (*Nunta mortului*) documented by Ion Ghinoiu and Tudor Pamfile, wherein an unmarried youth cannot rest until married, symbolized by an adorned fir tree (*bradul de nuntă*), a bridegroom's shirt (*cămașa de mire*), and funeral songs replacing wedding carols.

5. **The Iele and Vântoase (`scripts/bosses/iele_sister.gd`, `scripts/levels/ieleridge.gd`, `scripts/quests/rc_quest.gd`)**:
   - Accurately incorporates the wrath of the dancing maidens of the air on open mountain ridges, the affliction of anyone who sees them dancing (*luat din Iele*), and the authentic remedies: protective herbs (wormwood / *pelin*, garlic / *usturoi*), doina melodies, and ritual călușari cures.

6. **The Giant / Uriașul (`scripts/bosses/giant.gd`, `scripts/levels/uriasi.gd`)**:
   - The giant scooping the hunter and children into his apron (`giant.gd:80-90`) directly preserves the famous Romanian myth recorded by Aurel Cosma Jr. and Tudor Pamfile, where a giant's child scoops up human plowmen and oxen in her apron as curious tiny playthings.

7. **The Spiriduș (`scripts/quests/sig_quest.gd`, `scripts/levels/sighisoara.gd`)**:
   - Faithfully reflects the Romanian domestic spirit (*spiriduș*), hatched from a tiny egg, that steals food and coin (specifically pork and bacon) for the household if fed sweet bread and milk, turning mischievous when neglected.

8. **Sâmedru and Moșii de Toamnă (`scripts/quests/ap_quest.gd`, `scripts/levels/apold.gd`)**:
   - Faithfully models Sâmedru (St. Demetrius, Oct 26) as the closing of the pastoral season, accompanied by ancestral tables laid with colivă, colaci, candles, and wine to feast and appease the wandering dead.

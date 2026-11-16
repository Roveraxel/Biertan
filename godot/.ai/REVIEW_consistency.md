# Consistency and Anachronism Review

Review of `STORY.md`, `scripts/quests/*.gd`, `scripts/levels/*.gd` dialogue strings, and `scripts/core/game_manager.gd` (STORIES).
Canon: game year 1521; the baron died unmarried in 1321 ("two hundred years"); sacristy door 1515; Biertan; character names and roles match across files.

## 1. Contradictions with Canon & Timeline

STORY.md:8: problem: states the baron of Biertan "died the night before his wedding in 1515", contradicting canon where he died unmarried in 1321 ("two hundred years" before the game year 1521). 1515 is the year of the sacristy door: suggested fix: change "in 1515" to "in 1321".

scripts/quests/fin_quest.gd:2: problem: file header says "wedding of the dead he was refused in 1515", contradicting canon where Biertan refused him the funeral-wedding in 1321 (as confirmed in `scripts/levels/sighisoara.gd:469` and `scripts/levels/sacristy.gd:159`): suggested fix: change "1515" to "1321".

scripts/quests/fin_quest.gd:179: problem: the baron responds to whether he was baptised: "(In 1493, says the baron, from across the square. In Biertan. By Father Johannes. He can give the date.)". The baron died in 1321; he could not have been baptised in 1493 (172 years after his death): suggested fix: change "In 1493" to a year prior to 1321, such as "In 1293" or "In 1301".

scripts/core/game_manager.gd:66: problem: in STORIES["saschiz"], lore text states "With the vârcolac dead, the moon kept its place in the sky." This is a remnant of an earlier story draft. In the actual game (`scripts/quests/sx_quest.gd`, `scripts/levels/uriasi.gd`), Saschiz is about rescuing the three children from the Uriaș (giant); the Vârcolac fight is in Act 3 in the Moon Clearing (`scripts/levels/forest.gd`): suggested fix: rewrite the panel text to describe the giant returning Paul, Ioana, and Andrei to the church square.

scripts/levels/hillchurch.gd:140: problem: timeline mismatch with Biertan bell. The sexton says "Thirty years. Thirty years I kept your door, my lord", but in `scripts/quests/bt_quest.gd:150` and `scripts/quests/bt_quest.gd:260` the bell has not been rung in "forty years": suggested fix: change "Thirty years" in `hillchurch.gd:140` and `hillchurch.gd:173` to "Forty years" (or clarify that the sexton succeeded his predecessor 30 years ago).

## 2. Character Name & Role Mismatches

scripts/quests/fin_quest.gd:173: problem: the drunk Hungarian priest from Șapartoc is named "Father Imre" (and in lines 175, 178), whereas in `scripts/levels/sapartoc.gd:129`, `212`, `213` he was introduced and named "Father Bálint": suggested fix: harmonize his name across both files (use "Father Bálint" in `fin_quest.gd` and `hillchurch.gd`, or update `sapartoc.gd`).

scripts/levels/hillchurch.gd:67: problem: guest list has `["finpriest", "Father Imre", Vector2(40, -90)]`, and line 281 has `G.start_dialogue("Father Imre", ...)`, clashing with "Father Bálint" from `scripts/levels/sapartoc.gd:129`: suggested fix: change "Father Imre" to "Father Bálint" to match `sapartoc.gd`.

## 3. Historical Anachronisms

scripts/quests/ap_quest.gd:109: problem: Old Dumitru says: "Nobody has done it here in years. The young went to Germany, the old forgot." Saxon mass emigration to Germany (Aussiedler) occurred in the 20th century. In 1521, Germany was not a unified nation and Transylvanian Saxons were flourishing under King Louis II: suggested fix: replace with a 16th-century reason for youth absence: "The young went down to the towns, or off to the wars; the old forgot."

scripts/core/game_manager.gd:16: problem: in STORIES["recap_cris"], panel 2 says: "two lads from Mălâncrav had a pipe of something that was not tobacco." Tobacco was unknown in Transylvania in 1521; mentioning tobacco implies contemporary familiarity: suggested fix: change to "had a pipe of sweet-grass" or "dried mountain herbs".

scripts/quests/rc_quest.gd:130: problem: dialogue says "(Denisa, from Criș, puffing her pipe on the step of the house where she's lodging.)" Pipe smoking was not practiced in 1521 Romania: suggested fix: change to "sorting her dried herbs on the step" or "measuring a dark tincture".

scripts/quests/crit_quest.gd:106: problem: miller says "The wheel turns for everybody: Saxon rye, Romanian corn, all one flour by evening." In 1521, maize/corn (porumb) had not arrived from the New World (it reached Transylvania in the late 17th century). Romanian peasants grew wheat (grâu) and millet (mei): suggested fix: change "Romanian corn" to "Romanian wheat" or "Romanian millet".

scripts/levels/crit.gd:129: problem: decor uses `"corn_shock"`, representing shocks of maize: suggested fix: replace or rename decor reference to wheat sheaves or haystacks (`"wheat_shock"` / `"haycart"`).

scripts/levels/sighisoara.gd:71: problem: code comment and landmark feature: "the covered Scholars' Stairs (Scara Acoperită), 1642, up to the Church on the Hill". The covered stairway in Sighișoara was constructed in 1642, 121 years after 1521: suggested fix: retain as accepted folkloric/visual license, but note in lore that it is an open wooden roofed stairway rather than the historical 1642 gymnasium staircase.

## 4. Modern Phrasing & Idioms

scripts/quests/sp_quest.gd:123: problem: Radu the innkeeper says: "We need a priest. Good luck with that." "Good luck with that" is a late-20th-century sarcastic idiom: suggested fix: change to "May the saints grant you patience for that." or "You'd have better luck catching wind in a sieve."

scripts/quests/fin_quest.gd:136: problem: Lorena says: "Stop looking at me like that, I am FINE." "I am FINE" in capital letters is modern sitcom dialogue: suggested fix: change to "Stop staring, my neck is still attached." or "I still have all my teeth, don't I?"

scripts/quests/crit_quest.gd:156: problem: dialogue says "Fine. Fridays we sit. But I'm not sitting idle; I'll pray." "Fine." as a clipped concession sounds contemporary: suggested fix: change to "So be it. Fridays we sit." or "Aha! Fridays we sit, then."

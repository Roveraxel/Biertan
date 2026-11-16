# Backlog Designs

Short, actionable designs for the backlog items specified in Task T14. Grounded in Romanian folklore, the game's aesthetic, and web-safe performance constraints.

---

## 1. Village Recaps (Lorena's Voice)

Story cards (`recap_*`) shown on the road leaving villages that currently lack cards, narrated in Lorena's fond, dry Transylvanian voice:

### Viscri (`recap_viscri`)
- *Location / Trigger:* Road south leaving Viscri for Criț.
- *Lorena's Line:* "In Viscri my hunter found the sexton playing dazed in his own cellar, and let him off with a warning. A very trusting boy, my hunter. I could have told him: nobody with boots that clean is innocent. At least Matei got his supper."

### Criț (`recap_crit`)
- *Location / Trigger:* Road east leaving Criț for Saschiz.
- *Lorena's Line:* "Floarea soaked her trousseau on Friday and got her fingers scorched for her trouble. My hunter climbed the mountain with an apple and a poppy to beg for mercy. Sfânta Vineri took pity on the girl. She looked at him like he was an uninvited goat."

### Saschiz (`recap_saschiz`)
- *Location / Trigger:* Road west leaving Saschiz for Șapartoc.
- *Lorena's Line:* "The giants' hill above Saschiz. The mob wanted blood; my hunter found a lonely giant playing horses with three stolen children in his apron. Two bruised ribs, but he brought them down without drawing steel. The mother gave him a stone."

### Șapartoc (`recap_sapartoc`)
- *Location / Trigger:* Road south leaving Șapartoc for Apold.
- *Lorena's Line:* "A deserted village with three empty churches and one noisy ghost. He put soup in the Catholic nave, fiddles in the Saxon tower, and poured enough plum wine down a sleeping priest to hold a mass. By evening, families were moving in."

### Apold (`recap_apold`)
- *Location / Trigger:* Road west leaving Apold for Criș.
- *Lorena's Line:* "Sâmedru's night in Apold. The dead came home for supper, grumbling about the colivă, and he had to keep them from eating the tables. He stood by the bonfire until dawn, smelling of smoke and old church tallow. Quite proud of himself."

### Mălâncrav (`recap_malancrav`)
- *Location / Trigger:* Road north leaving Mălâncrav for Richiș.
- *Lorena's Line:* "He woke in a haystack without his trousers, swore he had only had three cups of țuică, and had to climb the church tower to get them down from the weathervane. The children cheered. I still haven't heard the truth of it."

### Richiș (`recap_richis`)
- *Location / Trigger:* Mountain path leaving Richiș for Biertan.
- *Lorena's Line:* "Seven Iele dancing on the frost. Moș Ilie played the Doina on his pan flute until his lips bled, while my hunter stood in the circle taking blows meant for a phantom. Toader is back in his mind. The road to Biertan opened."

---

## 2. Shades at Lamps (Volumetric Lantern Silhouette)
- **What is meant:** Atmospheric silhouettes and dust-mote falloff cones around tallow lanterns and hearths, preventing lights from appearing as flat uniform circles.
- **Cheap Web Approach:**
  - Create a single shared transparent 2D quad texture (`res://textures/fx_lantern_cone.png`): a soft radial gradient with subtle angular streaks (simulating wooden lantern struts).
  - Add as a flat child `Sprite3D` or decal directly beneath `lamp_lit` and `hearth` props, pitched flush with the ground (`position.y = 0.014`).
  - Modulate color with a slow sine pulse `0.9 + 0.1 * sin(TIME * 7.0)` in `Atmosphere.gd`.
  - **Node Budget:** 1 static sprite per lamp, 0 dynamic light passes.

---

## 3. Limousin Cow Jokes (Bull of Șapartoc)
Ten short, spoken lines for the vain, bodybuilding bull in `scripts/bosses/bull.gd`:
1. "Look at this dewlap. Chiseled from French limestone."
2. "Do you even pull the plow, little man? That's just cardio."
3. "A Carpathian ox has horns like dry twigs. Mine are polished ivory."
4. "Never skip flank day. Never."
5. "Ten leagues up the pasture and my quiff didn't move an inch."
6. "The brown Swiss cow by the hedge? She's been staring for three hours."
7. "You call that a blade? I've chewed thistles with more bite."
8. "Moo? We don't moo here. We announce our arrival."
9. "Careful around the shoulder crest. That took three summers of clover."
10. "Move along, shepherd. You're standing in my good sun."

---

## 4. Footprints in Snow or Mud
- **What is meant:** Ephemeral tracks left by the hunter, Azorel, and fleeing wolves in damp lanes, mud patches, and churchyard snow.
- **Cheap Web Approach:**
  - Avoid creating and destroying nodes. Pre-allocate a single `MultiMeshInstance3D` pool with 48 flat ground quads using a 4-frame texture atlas (boot, dog paw, cloven hoof, wolf paw).
  - In `Player.gd`, on footstep audio event, set the transform of index `(step_idx % 48)` to the player's ground position and facing angle.
  - A simple custom shader uses instance custom data: float `spawn_time` decrements alpha over 4.5 seconds.
  - **Cost:** Exactly 1 draw call, 1 node for the entire game, zero garbage collection.

---

## 5. Stână Hay Ground Texture
- **Texture Description:**
  - A rich, rustic alpine pasture ground texture replacing the placeholder flat dark color in `stana.gd`.
  - *Visual Elements:* Dry golden-straw hay and trampled mountain fescue grass, interwoven with dark loamy earth patches, scattered sheep wool tufts, and rounded river stones.
  - *Palette:* Warm straw-gold (`#b89858`), weathered thatch (`#8a7042`), and dark damp soil (`#3b2f20`).
  - *Technical Specs:* Seamless $256 \times 256$ pixel-art diffuse texture (`textures/px_stana_hay_diff_1k.png`), roughness 0.95, matte, non-reflective, mapped with nearest-neighbor mipmaps.

---

## 6. Music & Boss Audio Pass (Surorile Osoianu Style)
- **Aesthetic Core:** Archaic Romanian vocal polyphony, open-throat modal harmonies, driving rustic percussion (*dobă*, *toacă*), shepherd flutes (*tilincă*, *fluier*, *bucium*), and drone strings (*cobză*). No orchestral strings, no medieval Celtic lutes.
- **Track & Mood Allocations:**
  - **The High Pastures (`stana`):** Solitary, ancient shepherd flute (*caval*) over mountain wind and distant bronze cowbells.
  - **The Villages (Day):** Plucked cobză, light hand-drumming, and warm women's humming; buoyant acoustic *bătută* on market squares.
  - **Boss: Marțolea (`vineyard`):** Staccato pizzicato, rhythmic spindle clicks, and hushed female chanting counting backwards from seven.
  - **Boss: Storm Balaur (`gorge`):** Blaring horn calls (*trâmbiță*), thunderous frame drums, and fierce archaic weather-chants (*descântec de grindină*).
  - **Boss: Vârcolac (`forest`):** Guttural throat drone, rising dissonant polyphony, and frantic heartbeat percussion in the dark.
  - **Church on the Hill (Wedding & Sexton Fight):** Solemn wedding-dirge polyphony (Surorile Osoianu: *Cântecul Miresei* / *Bradul*) merging with heavy tolling church bells; triumphant communal *hora* at the conclusion.

---

## 7. Privacy-Safe Playtest Analytics
- **What to Measure (2-Hour Playtest Scope):**
  1. *Progression Milestones:* Timestamp upon completing each village quest (`*_done`).
  2. *Combat Friction:* Death counts, retry counts, and damage taken per boss (Balaur, Vârcolac, Sexton).
  3. *Navigation Bottlenecks:* Time elapsed between quest initiation (`*_job`) and finding clues/witnesses.
  4. *Church Fight Metrics:* Guest courage level drop rates and bell rope activation frequency.
  5. *Token Inventory Audit:* Flag check ensuring all 9 tokens are present when `bt_night` triggers.
- **Privacy-Safe Implementation:**
  - Generate a random anonymous session UUID on initial boot (e.g. `crypto.randomUUID()`), stored in `sessionStorage` (cleared when browser closes).
  - Collect zero PII, zero IP addresses, and zero device fingerprints.
  - Store telemetry events in an in-memory array; serialize to JSON.
  - Transmit payload via `navigator.sendBeacon("/api/telemetry", blob)` on level unload or session completion, failing silently without interrupting gameplay.

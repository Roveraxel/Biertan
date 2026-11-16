scripts/actors/actor.gd: Anything that walks the map: the hunter, creatures, bosses, set_body_radius, set_solid, slide, set_figure
scripts/actors/board.gd: flat coloured shapes (squares, discs, triangles), part, set_color, used by decoration/environmental elements
scripts/actors/brazier.gd: An iron fire-basket, setup, set_lit, interact, used in Vârcolac phases and related interactions.
scripts/actors/decor.gd: piece of street clutter (barrel, cart, etc), setup, set_solid, size_of; used in scene decoration across various levels.
scripts/actors/enemy.gd: Base enemy class (wolf, strigoi, cow, etc.), setup(), hud_name(), used by all levels/quests for creature encounters.
scripts/actors/fire_patch.gd: Ground hazard effect (fire, frost, brew, bees), spawn(), used in environmental hazard levels.md
scripts/actors/gate.gd: Portcullis gate actor, make, open, used in level geometry/barriers.
scripts/actors/ground_fx.gd: implements SaltRing ground fx, throw_at(), contains(), used by combat/area effects in various levels.
scripts/actors/pixel_figure.gd: A frame-animated pixel-art character, set_figure, tick, fade_to, used by world simulation (e.g., NPC behavior/events)
scripts/actors/player.gd: The hunter's core stats and behaviors (movement, combat, curse effects); key public functions are `reset_stats`, `mouse_world`, `swing`, `drink`, `throw_salt`, `hurt`; used by all core levels/quests (madness, vampirism, etc.)
scripts/actors/prop.gd: Generic interactable entity (villager, sack, cross, etc.), can_interact(), retire(), interact(), walk(), steer_to(), _process(), used in most levels/quests.
scripts/actors/wood_gate.gd: a wooden farm gate, make, open, use (via Prop), levels that implement farm yards/lanes
scripts/bosses/boulder.gd: A projectile boss object, launch(), _process(), used in boss encounters
scripts/bosses/bull.gd: Bull boss enemy, setup, step, hurt, die, used in level encounters where the hunter engages the bull.
scripts/bosses/crypt_warden.gd: CryptWarden boss logic, setup, step, hurt, die, used in boss encounters (e.g., Mălâncrav)
scripts/bosses/giant.gd: Giant boss (Uriașul), key public functions: setup, step, hud_name, used in main combat loop/boss encounters.
scripts/bosses/iele_sister.gd: IeleSister boss (one of the seven Iele), setup, step, hurt, used in boss encounters.
scripts/bosses/martolea.gd: Martolea boss (Tues evening spirit), setup, step, hurt, used in boss encounters managed by G.
scripts/bosses/storm_balaur.gd: Boss enemy (StormBalaur), key functions are `setup`, `step`, `hurt`, `die`, used in boss encounters (e.g., Solomonar's balaur).
scripts/bosses/vampire_boss.gd: The Vampire of Biertan/Strigoi Mort boss, setup(), step(), hud_hint(), used by core game progression (e.g., Biertan sequence).
scripts/core/audio_manager.gd: manages sound (SFX, ambient, music, voice), sfx, sfx_at, set_music, voice, vocal, used by all levels/quests for environmental and character sounds
scripts/core/events.gd: Handles all player interactions (prop usage, dialogue, buying), key public functions are prop_used, marker_for, pay, and item purchases (buy_potion, etc.), used by various quest/item interactions.
scripts/core/fx.gd: World-space helpers and effects, add_light, text, ring, shake, hit_stop, spark, claw, corpse, used by combat and visual event systems.
scripts/core/game_manager.gd: Manages global game state (State enum, stories, player tracking), public functions include start_dialogue, show_story, save_game, continue_game, used by all major quest lines (Vârcolac, Muma, Balaur, etc.)
scripts/core/level_base.gd: Base level class, build(), on_enter(), structural creation helpers (e.g., add_block, find_path), used by all levels and associated quests.
scripts/core/level_loader.gd: Manages level transitions (goto_level), level existence (exists), and setup (enter), used by all game levels and specific quests (e.g., VisQuest, V3 Azorel tracking).
scripts/core/main.gd: Main game environment setup, _ready, _process, _place_camera, _bind_keys, set_light, uses Player, Loader, Fx, and Hud.
scripts/core/narration.gd: handles story card narration and level arrival lines, key functions are speak() and arrive(), used by all defined story sections (e.g., prologue, act_3) and levels (lvl_gorge, lvl_forest, lvl_uriasi).
scripts/core/quests.gd: Quest management utility class, public functions include talk, use, marker, pending, target, objective, used by the level or its shared village quest scripts.
scripts/core/road.gd: Defines road narratives (CART, NOTES, BAGS), dress(), bags_found(), use(), used in viscri, crisforest, malcrypt, and ieleridge levels.
scripts/core/shop.gd: Shop implementation (market stalls), open(village: String, again: bool), _count(prefix: String), used in all village interactions/road progression.
scripts/core/village.gd: Base village generation logic (layout, roads, houses, trees); load_map, standard, churches_and_houses, compact, add_troita; used by viscri, malancrav, cris, crit, richisvillage, saschiz, sighisoara quests.
scripts/levels/apold.gd: Apold (Trappold) level for Sâmedru's Fire quest, build(), _quest_things(), _start_wave(), _dawn(), _pub_dialogue() used by Sâmedru's Fire.
scripts/levels/biertanfort.gd: Defines the Biertan fortress level (three rings, church), uses BtQuest, key public functions are build() and reconciled().
scripts/levels/cellar.gd: Defines the "THE SMOKE-CELLAR" level, build(), ambient(), _open(), _hat_theft(), _on_captain(), _leave(), used in the opening job quest.
scripts/levels/cris.gd: Village level configuration, build(), feast(), Muma Pădurii and the Feast quest, leads to malancrav
scripts/levels/crisforest.gd: Defines the Cris Forest level, build(), leave(), free_animal(), meet_muma(), and _start_hunt(), used by CsQuest (forest and related quests).
scripts/levels/crit.gd: Criț (Deutsch-Kreuz) village level, build(), raise_the_dead(), The Friday Curse quest
scripts/levels/critforest.gd: forest level definition, build(), _trail_dist(), _wake_pack(), offering(), used by CritQuest
scripts/levels/crypt.gd: Crypt level data, build(), _on_sexton(), used by "viscri" level and VisQuest.
scripts/levels/draculhouse.gd: Draculhouse level definition, ambient(), build(), leave(), used by FinQuest
scripts/levels/forest.gd: Defines the Wolf Forest level (Moon Clearing, Glade), manages environment state (e.g., eclipse, snowdrops), key public functions are target(), objective(), use(), which are used by quests/dialogue systems.
scripts/levels/gorge.gd: gorge level logic, talk, use, used by the Solomonar questline
scripts/levels/ieleridge.gd: Iele Ridge level logic, build, _begin, _start_wave, _start_boss, line, sister_down, uses RcQuest
scripts/levels/malancrav.gd: Mălâncrav morning after/dusk transition, build(), on_enter(), climb_tower(), _dusk(), muma_talk(), used by MlQuest.
scripts/levels/malcrypt.gd: The crypt under the church of Mălâncrav, build, line, _alive, _start_wave, _add, _won, leave (used by MlQuest for the crypt level)
scripts/levels/richisforest.gd: Richiș forest level definition, build(), pick(p: Prop), leave(), used by RcQuest.
scripts/levels/richisvillage.gd: Richiș village scene setup, `build()`, `_quest_things()`, `_process()`, `brothers()`, Quest: The Brothers and the Iele.
scripts/levels/sacristy.gd: Sacristy level (1515), build(), line(), ring_bell(), stake(), leave(), used by BtQuest ("The Locked Door")
scripts/levels/sapartoc.gd: Șapartoc village level, build, _hillside, _quest_things, light_lamp, lamps_out, summon, ana_retires, canteen, concert, priest_to_church, used by The Three Churches quest.
scripts/levels/saschiz.gd: Saschiz village layout and setup, build(), _quest_things(), brawl(), _end_brawl(), SxQuest
scripts/levels/sighisoara.gd: Sighișoara map setup (citadel, towers, houses), build(), _finale(), _tutorial(), _process(), used by SigQuest and FinQuest.
scripts/levels/stana.gd: Prologue level (high pasture above Sibiu), build(), on_enter(), _process(), talk(), use(), target(), objective(), used in prologue sequence
scripts/levels/uriasi.gd: Cetatea Uriașilor level implementation, build, _on_sat, _after_fight, used by 'sx_giant' quest.
scripts/levels/viscri.gd: Viscri village setup, build(), _quest_things(), watch_barn(), The Silent Dogs
scripts/quests/ap_quest.gd: Defines the "Sâmedru's Fire" Apold quest logic, uses functions like target(), objective(), talk(), and is used in the Apold quest line, leading to the 'cris' level.
scripts/quests/bt_quest.gd: Manages "The Baron's Table" quest state, target(), objective(), talk(), _supper(), uses biertanfort, gorge, richisvillage.
scripts/quests/crit_quest.gd: The Friday Curse quest (Criț), has(), mark(), target(), objective(), use(), uses critforest and saschiz levels.
scripts/quests/cs_quest.gd: CsQuest class managing the "Muma Pădurii and the Feast" quest, key public functions are target(), objective(), talk(), and use(), used by the Criș quest line logic.
scripts/quests/fin_quest.gd: Final quest progression in Sighișoara, target(), objective(), talk(), use(), sighisoara, hillchurch, draculhouse
scripts/quests/ml_quest.gd: Mălâncrav quest implementation, target(), objective(), marker(), pending(), arrive(), talk(), use(), used by malancrav, malcrypt, richisvillage
scripts/quests/sig_quest.gd: The Stolen Bacon quest logic, target(), objective(), marker(), pending(), talk(), use(), Sighișoara and cellar levels
scripts/quests/sp_quest.gd: The Three Churches quest (Șapartoc), has, mark, target, objective, talk, use, used by Șapartoc quest.
scripts/quests/vis_quest.gd: "The Silent Dogs" quest logic, `target()`, `objective()`, `use()`, used by Viscri/Sighișoara/Criț quest lines.
scripts/ui/game_hud.gd: HUD rendering canvas, toast(), banner(), fade_to(), loading(), set_black(), open_map(), used by Title, Play, Story, Ending, and Dialogue states
scripts/ui/hud_map.gd: The UI representation of the map, journal, and bestiary, open(travel: bool), open_local(), open_journal(), open_bestiary(), reached(i: int) are key functions, used by all levels (e.g., "biertanfort") and associated quests.
scripts/world/atmosphere.gd: Defines visual atmospheric effects (mist, fireflies, leaves, indoor dust), key public function is `build()`, used by level generation logic (e.g., "forest", "church", "stana").
scripts/world/batch.gd: Batched rendering container (Material -> MeshBuilder), mb, empty, commit; used for world decoration/chunks (Performance Rule 5).
scripts/world/map_data.gd: Stores village layout from JSON (boxes, lines), key functions are at, boxes, lines, scale_all, used by world generation/level loading.
scripts/world/mesh_builder.gd: Procedural mesh helper for world geometry (tri, quad, box, gable, hip, cone, etc.), used by level generation/decoration systems.
scripts/world/model_kit.gd: Utility for standardized building models, exists, shape, place, used during village construction and level generation.
scripts/world/net_random.gd: NetRandom class providing seeded random functions f(), range_f(), i(), used by random generation logic across game elements.
scripts/world/trees.gd: Low-poly tree generation (autumn/spruce) and undergrowth; leaf_color(), limb(), clump(), tufts(), broadleaf(), spruce(), undergrowth(); used by scripts/world/world_builder.gd
scripts/world/world_builder.gd: Builds the 3D world (ground, roads, decals, houses, walls, trees), key functions include build(), _ground(), _roads(), _decals(), _prep_houses(), _block(), _trees(), _wilds(), used by all levels and map loading processes.

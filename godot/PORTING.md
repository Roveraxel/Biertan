# Biertan: Unity → Godot port notes (working file)

Project root (container): /home/claude/bg   ·  Unity sources: /home/claude/unity/Assets/Scripts
Godot 4.7.2 binary: /home/claude/gd/Godot_v4.7.2-stable_linux.x86_64 (web templates installed)
Build + screenshot: /home/claude/shots/build.sh ; node /home/claude/shots/shot.js "?level=<id>&fast&at=x,y" out.png 26000 "shot:10"
(http.server on :8765 serves build/web). Headless smoke: godot --headless -s tests/probe.gd

## Conventions
- Logic space = map pixels, x east, y SOUTH (the old "Godot" coordinates of the level files). No P() flip.
  Unity 2D vectors (x, y_up) → here (x, -y). Rect "FoldU" etc. → use the Godot-space rect directly.
- Fx.S = 0.02 m/px. Actors: `pos` (px), `vel` (px/s). Fx.text(pos, s, color, lift_px) replaces FxUtil.Text(Pos + (0, lift)).
- Unity → here: GameManager.I → G ; HudEvents.Toast/Banner → Hud.toast/banner ; AudioManager.I.Sfx → Audio.sfx ;
  FxUtil.Ring → Fx.ring ; LevelLoader.Goto → Loader.goto_level ; gm.side.Add/SideHas → G.side_add/side_has ;
  StartDialogue(who, lines, after) → G.start_dialogue or `await G.say(who, lines)` in coroutines ;
  WaitForSeconds → await G.wait(s) ; ShowStory → await G.show_story(id) ; EnemyBase → Enemy ; Prop.used/gameObject.SetActive(false) → prop.retire()
- Level API (scripts/core/level_base.gd): add_block(Rect2, style, h), add_block_rotated(c, size, angle, style, h, solid),
  add_tree(p, pine), add_decor(p, sprite, radius, flip), add_prop(kind, id, display, p, prompt, col), add_trigger(rect, cb),
  add_brazier, add_torch, add_path(pts, width, _, _, "Cobbles"|"Path"), add_decal(disc, c, size, col, order, rot),
  add_cobbles(rect), add_wall(centre, size, color?), add_ring_wall, add_curtain(pts, thick, h, style), add_covered_way,
  spawn_enemy(kind, p), scatter(rect, n, colors), rand(a, b) / rng (NetRandom = .NET System.Random: keep call order!).
- Quest hooks on the level (or level.quest object): talk(id)->bool, use(prop), marker(id)->bool, pending(prop)->bool,
  target()->[Vector2, label] or [], objective()->String.
- WorldBuilder builds meshes after build(); geometry code is written in Unity 3D space (z north) and mirrored by MeshBuilder.

## Status
- Done: core (G, Fx, Audio, Loader, Hud), actors (Player, Enemy, Prop, Decor, Brazier, SaltRing, FirePatch, Gate), world builder,
  Village base + map JSON (data/*.json via tools/maps_to_json.py), and the whole road: stana, sighisoara (+cellar),
  viscri (+crypt), crit (+critforest), saschiz (+uriasi, Giant), sapartoc (Bull), apold, cris (+crisforest),
  malancrav (+malcrypt, CryptWarden), richisvillage (+richisforest, ieleridge, IeleSister), biertanfort (+sacristy, VampireBoss).
  Quests in scripts/quests/, bosses in scripts/bosses/.
- Tests (headless): tests/load.gd -- <level>...  (builds levels, prints counts) ; tests/probe.gd (plays the prologue) ;
  tests/chk.gd -- res://path.gd (compile check; test scripts must not name project classes statically) ;
  tests/bot.gd -- <level> <until_flag> [flags] [frames] with --fixed-fps 30: follows the quest pointer and plays the road.
  Passing runs: `bot.gd -- sighisoara token_ana_lantern prologue_done` and
  `bot.gd -- apold bt_done token_cellar_key,token_ribbon,token_fort_stone,token_ana_lantern`.
- Gotchas: never name a method `free` (Object.free). After adding a class_name run `godot --headless --import` once.
  NetRandom wraps to 32 bits like C# (big hashed seeds broke without it). Triggers call their callback deferred.
  On the Mac, unpack the sync tarball with `tar xzf ... --overwrite` (deleting is not permitted there).
- Todo: the walk home to Viscri after bt_done (epilogue), a played check
  of each village by hand, legacy enemy sprites (scarecrow, skull, ward, bat), Mac export templates.
- Old chapters (hub, forest, arena, richis, hills, caves, hollow, mosna, vineyard, gorge, biertan, walls, church): not on the
  new road; port last or drop (ask Alex).

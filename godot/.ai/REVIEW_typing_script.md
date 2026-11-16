# T1 static-typing audit (script, exact line numbers; Claude 2026-11-16)
Categories, most important first. Only A can break compilation (lesson 2); B-E are style gaps. The game currently compiles and exports with all of these, so A is a risk list, not an error list. Nothing here is applied automatically.

## A. `:=` on a Variant-returning call or index (can fail to compile) (11)
- scripts/actors/board.gd:41: `var c := base[i]`
- scripts/actors/prop.gd:314: `var f := _flames[i]`
- scripts/levels/crit.gd:107: `var beside := func(t: float, off: float) -> Vector2: return free_spot(on_road.call(t) + si`
- scripts/levels/crit.gd:117: `var bd := 1e9; var want: Vector2 = on_road.call(0.5)`
- scripts/levels/viscri.gd:137: `var lorena := _free(street.call(0.55, 120.0), 40.0)`
- scripts/levels/viscri.gd:168: `var dog := _free(street.call(0.12, -130.0), 30.0)`
- scripts/ui/game_hud.gd:552: `var dr := Rect2(sc.x - sz.x * k / 2.0 + pan, D.call(0, 652, 0, 0).position.y - sz.y * k + `
- scripts/world/model_kit.gd:40: `var top := tris[0]`
- scripts/world/trees.gd:63: `var ia := _ico_t[i]; var ib := _ico_t[i + 1]; var ic := _ico_t[i + 2]`
- scripts/world/trees.gd:80: `var a := _ico0[ICO_F[i]]; var b := _ico0[ICO_F[i + 1]]; var d := _ico0[ICO_F[i + 2]]`
- scripts/world/trees.gd:141: `var q0 := rim[j]; var q1 := rim[(j + 1) % seg]`

## B. function without return type (3)
- scripts/core/village.gd:308: `cross()`
- scripts/levels/crisforest.gd:237: `alpha_pos()`
- scripts/world/world_builder.gd:516: `_occupied()`

## C. parameter without type (8)
- scripts/actors/actor.gd:41: `set_figure(...names...)`
- scripts/actors/pixel_figure.gd:95: `make(...names...)`
- scripts/core/level_base.gd:302: `add_wall(...color = null...)`
- scripts/core/level_loader.gd:20: `goto_level(...at = null...)`
- scripts/core/level_loader.gd:53: `enter(...at = null...)`
- scripts/levels/stana.gd:101: `_clamp_in(...a...)`
- scripts/world/mats.gd:52: `plain(...emission = null...)`
- scripts/world/world_builder.gd:405: `_windows(...shutter...)`

## D. `var x = value` without type (29)
- scripts/actors/enemy.gd:70: `var goal = null`
- scripts/bosses/iele_sister.gd:8: `var ring = null`
- scripts/core/game_manager.gd:104: `var boss = null`
- scripts/core/game_manager.gd:343: `var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH)) if has_save(`
- scripts/core/level_base.gd:31: `var quest = null`
- scripts/core/main.gd:126: `var q = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('`
- scripts/core/main.gd:129: `var at = null`
- scripts/core/main.gd:131: `var a = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('`
- scripts/core/main.gd:133: `var fl = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get(`
- scripts/core/main.gd:143: `var nr = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get(`
- scripts/core/main.gd:145: `var pr = G.level.prop_by_id(nr)`
- scripts/core/main.gd:147: `var dz = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get(`
- scripts/core/main.gd:155: `var nx = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get(`
- scripts/core/village.gd:325: `var x = cross(r[k], r[k + 1], w[j], w[j + 1])`
- scripts/core/village.gd:406: `var tmp = houses[i]; houses[i] = houses[j]; houses[j] = tmp`
- scripts/core/village.gd:494: `var v = get(pr.name)`
- scripts/levels/crisforest.gd:261: `var a = alpha_pos()`
- scripts/quests/ap_quest.gd:149: `var L = G.level`
- scripts/quests/cs_quest.gd:58: `var ap = G.level.alpha_pos()`
- scripts/quests/cs_quest.gd:169: `var L = G.level`
- scripts/quests/sp_quest.gd:189: `var L = G.level`
- scripts/quests/vis_quest.gd:146: `var az = G.level.prop_by_id("azorel")`
- scripts/quests/vis_quest.gd:177: `var m = G.level.prop_by_id("matei")`
- scripts/quests/vis_quest.gd:213: `var m = G.level.prop_by_id("matei")`
- scripts/ui/game_hud.gd:73: `var cj = JSON.parse_string(FileAccess.get_file_as_string("res://photos/credits.j`
- scripts/ui/game_hud.gd:373: `var bs = G.boss`
- scripts/world/map_data.gd:49: `var v = _raw[key]`
- scripts/world/model_kit.gd:33: `var idx = arr[Mesh.ARRAY_INDEX]`
- scripts/world/world_builder.gd:546: `var in_gap = _occupied((ea.end + e2.end) / 2.0)`

## E. signal parameter without type (4)
- scripts/actors/enemy.gd:6: `signal died(e)`
- scripts/actors/enemy.gd:7: `signal hurted(e)`
- scripts/actors/enemy.gd:8: `signal fled(e)`
- scripts/actors/enemy.gd:9: `signal call_thralls(e)`


# Biertan: Project Context

Romanian-folklore top-down action RPG. Godot 4.7.2, GDScript, Compatibility renderer, web export. About 2 hours of play.
Live build: https://roveraxel.github.io/Biertan/ (branch `gh-pages` of this repo).

## Story (1521, Transylvania)
Act I the stână and Sighișoara (spiriduși, butchers' guild), Act II Criș and Mălâncrav (feast, flashbacks), Act III Biertan (the baron's supper, the trapdoor under his tomb, gorge, vineyards, Wolf Forest, tunnel), Act IV Viscri, Casa Vlad Dracul in Sighișoara, and the final fight at the Church on the Hill.
The hunter is a sabre-wielding drifter with his dog Azorel. Lorena, his partner, is abducted and tells the story in narration. She mocks him fondly ("my foolish hunter").
Canon: the game year is 1521. The baron died unmarried in 1321 ("two hundred years"). The sacristy door is dated 1515.

## Repo layout
- `godot/` the Godot project (the only engine now; the Unity version was removed and lives in git history before this commit).
- `scripts/core` game_manager (G), level_loader, level_base (Level API), village (compact(), trim), narration, audio_manager.
- `scripts/levels` one file per place. `scripts/quests` quest scripts (sig, cris, bt, fin, vis). `scripts/actors` prop, enemy, player, wood_gate. `scripts/bosses` giant, storm_balaur, varcolac, sexton.
- `scripts/ui` hud, story cards. `sprites/Story` folk-illustration story pictures. `sprites/Pixel/<name>/` PixelLab rotations and walk frames.
- Level API: add_block, add_decor, add_prop, add_torch, add_patch, add_trigger, wall_door, cellar_head, road_gate, gap_gate, find_path. Village.compact() shrinks villages (0.8) and trims 15% of the outer houses.

## Tooling and pipelines
- Web export: project copy in `bgweb`, `godot --headless --export-release Web build/web/index.html`. Publish to gh-pages: split `index.pck` into 16 MB parts, gzip the wasm, update `PARTS` and the pck size in `index.html`, push.
- Test hooks in `core/main.gd` URL query: `?level=X&fast&near=<prop id>&flags=a,b&do=story:<card>|<method>`.
- Art: PixelLab MCP (characters, 8 directions, `walking-6-frames` template), Meshy MCP (story pictures via image_to_image, 3D models). Story pictures are keyed to alpha, resized to 960x540, with a feathered mask.
- Narration: Fish Audio. Chosen voice "Romania" (`6d76b9c0a0c54f6a97a1c1748270cee1`), model drama-3 with bracket directions. Lines live in `scripts/core/narration.gd` and play from `res://audio/voice/<key>_<n>.mp3`. A missing file is silently skipped.
- Fish Audio files can only be downloaded once `*.fish.audio` is allowed in the sandbox network settings.

## Done recently
Compact villages; bigger Biertan fortress with terrace and gates (night gates open after beating that ring's guards); wood gates; Casa Vlad Dracul interior; act title cards; story films (feast, flashbacks, supper, balaur); walking animations for Matei, the sexton, Azorel, the earth dog, the vârcolac; balaur ripple animation; Sighișoara postern gate by the Butchers' Tower with the guild sign beside the cellar door.

## Open items
1. Narration audio: record all 28 lines in the Romania voice and wire the mp3s into the build.
2. Final fight as a new level inside the Church on the Hill, Meshy-generated; fix bell placement and fight start; film after the sexton is defeated.
3. Regenerate ground and grass; make village props (haystacks, trees) look natural.
4. Character consistency (size and style) across the cast.
5. Verify in game: act cards, balaur film, new walk cycles, compact villages in every quest, Biertan gates.
6. Backlog: other village recaps, Criț subquests, children singing, Sfânta Vineri explanation, mushroom/Turks, Saschiz market, more music, boss music, lamp shades, analytics, Limousin jokes, stână hay texture, footprints.

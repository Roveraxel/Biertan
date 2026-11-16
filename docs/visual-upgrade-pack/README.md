# Biertan — Environment Visual Upgrade Pack

**Purpose:** Visual references and implementation brief for Claude. This folder is a handoff package only. Do not treat its mockups as production assets, and do not change game code until the current source used for the live Pages build has been located and reviewed.

## User-approved visual direction

- Preserve Biertan's existing Yaga-inspired identity and all existing character/NPC/enemy sprites.
- Improve environmental graphics: ground, grass, fences, buildings, vegetation and small props.
- Keep the current top-down / 3/4 camera, game scale, readability and practical Godot 2D production constraints.
- Use the Stână screenshot as the baseline for the first environment pass.
- The generated fence material/design is approved as a reference. The fence kit must include vertical runs (top-to-bottom in the image), horizontal runs, corners, gates and broken sections. The previous scene edit made the fence run horizontally where the enclosure needs vertical sections too.
- Haystacks must sit on the ground with visible contact shadows and a flattened base; no floating appearance.
- Keep walkable paths clear and preserve collision/navigation logic.

## Reference images

1. **Original Stână gameplay screenshot supplied by the user**
   - Use the screenshot in the conversation as the authoritative layout and sprite reference.
   - Preserve player, Azorel, HUD, quest text, building and prop placement unless the user approves a specific change.

2. **Stână environment edit (Meshy image-to-image)**
   - The user considered this direction better.
   - Meshy task: `01a1e543-183a-7749-a33a-2817b7f5a377`
   - Image: https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e543-183a-7749-a33a-2817b7f5a377_0.png

3. **Fence and haystack refinement**
   - Meshy task: `01a1e545-4b36-74a7-b691-eaa2c0d029dd`
   - Image: https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e545-4b36-74a7-b691-eaa2c0d029dd_0.png
   - Fence design/material approved; orientation/layout needs correction so vertical sections are present where required. Haystack should be grounded.

4. **Modular wattle fence kit reference sheet**
   - Meshy task: `01a1e546-efa0-755a-9881-ea99e5970e7e`
   - Image: https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e546-efa0-755a-9881-ea99e5970e7e_0.png
   - Intended modules: vertical straight run, horizontal straight run, 90-degree corner, short section, gate, broken section.

5. **Earlier forest visual backup**
   - Meshy task: `01a1e53c-b731-70c1-a8fa-90d396b8b4a5`
   - Image: https://api.meshy.ai/misc/cdn-images/d90a0c39-1d00-445e-aac4-0a37ad759527/uploads/image_01a1e53c-b731-70c1-a8fa-90d396b8b4a5_0.png
   - Keep as a backup visual reference only.

## Required workflow for Claude

1. Identify the exact source commit and branch that produced the current GitHub Pages build. The Pages branch is a web export; do not implement gameplay/source edits on `gh-pages`.
2. The connected GitHub source branch previously inspected by ChatGPT (`godot-level1-slice`, commit `7d7d26f54ae87fe7739d28ebbee0f9ca74c31e63)) did not contain a dedicated Stână level. The Pages branch had newer commits, including `1b3c269` ("Saschiz children sing"), but the exported deployment tree is not the source project. Locate the matching source commit/branch before implementation.
3. Inspect all current level scripts and existing art-generation pipeline. Identify reusable environment elements and avoid duplicating systems.
4. Produce a visual asset inventory and a level-by-level environment plan for all actual levels present in the current source.
5. Start with the Stână. Use the supplied gameplay screenshot and Meshy references to define reusable ground, grass, wattle fence, gate, haystack, trough, sheepfold, firewood, rocks and vegetation assets.
6. Create actual production assets in the project's established formats/pipeline. Meshy mockups are references, not ready-to-import tiles or sprites.
7. Preserve all existing character sprites and their visual style. Do not replace player, dog, NPC or enemy art.
8. Ensure fence modules align in both screen axes and at corners; match existing perspective and Y-sort/depth conventions. Ground all posts and props with contact shadows. Haystack base must visibly contact the ground.
9. Check collision shapes, navigation/walkability, occlusion/Y-sort, lighting, readability and desktop/web performance.
10. After the Stână prototype is approved, apply the shared environment style selectively to the other levels. Each region should retain its own palette and materials.

## Scope and constraints

- **This is a reference/brief folder only.** ChatGPT has not modified gameplay code or production assets.
- Do not regenerate every level as a single image. Build reusable modular assets and integrate them into the real scenes.
- Do not alter story, quests, enemy behaviour, character designs, camera, HUD or level layout as part of the environment-art pass unless separately requested.
- Do not replace existing assets wholesale. Keep backups and use a feature branch.
- Keep asset provenance/licensing notes for generated assets and check Meshy's current commercial-use terms before shipping.

## Acceptance criteria

- Stână still reads as the same playable scene and retains its current layout and characters.
- Grass/ground has more natural muted variation and better transitions.
- Wattle fence looks like woven branches, has consistent scale, grounded posts, usable corners/gates, and correct vertical and horizontal runs.
- Haystack visibly rests on the ground with contact shadow.
- New props are modular, reusable, consistent with the current pixel-art style and appropriately scaled.
- No new collision/navigation problems; player and NPCs remain readable.
- Existing headless test passes: `godot --headless --path . -- --autotest`.
- Provide before/after gameplay screenshots and list every changed/added asset.

## Project source of truth

Repository: https://github.com/Roveraxel/Biertan
Current known source branch: `godot-level1-slice`
Deployment branch: `gh-pages`
Project context: `PROJECT_CONTEXT.md`

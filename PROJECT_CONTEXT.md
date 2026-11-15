# Biertan — Shared Project Context

Last updated: 2026-11-15

This file is the shared source of truth for AI-assisted work on Biertan. Keep it current when architecture, design decisions, tools, scope, or production status change. Claude and ChatGPT should read this file before proposing substantial changes.

## Project identity

- **Title:** Biertan
- **Subtitle:** A Hunter's Ballad of Transylvania
- **Genre:** Top-down action RPG / action-adventure with roguelite elements
- **Setting:** Medieval Transylvania, inspired by Romanian folklore and Saxon fortified villages
- **Tone:** Dark, atmospheric folklore with dry, characterful humour. Preserve genuine menace and emotional stakes while allowing NPCs, dialogue, quest writing, item descriptions, and bestiary entries to be funny.
- **Visual direction:** Top-down/isometric-feeling 2D gameplay, pixel-art characters and props, stylised environments with depth and lighting. Keep the visual language coherent across sprites, environments, effects, UI, and promotional art.
- **Commercial intent:** Side project with a planned commercial release. Current build is still in development and is not considered worth a €20 price point.
- **Current pricing hypothesis:** Evaluate a modest indie price after a content/polish review; €9.99 is a working planning assumption, with €7.99–€12.99 as a range to test. Do not present this as a final decision.

## Engine and repository

- **Engine:** Godot 4.3 (migration from Unity is complete).
- **Primary source branch:** `godot-level1-slice`
- **Web deployment branch:** `gh-pages`
- **Public repository:** https://github.com/Roveraxel/Biertan
- **Playable web build:** https://roveraxel.github.io/Biertan/
- The `gh-pages` branch contains exported web build files. Make source changes on the Godot source branch, not in the deployment export.
- Main scene: `scenes/main.tscn`
- Main controller: `scripts/main.gd`
- Shared helpers/state: `scripts/g.gd`
- Player controller: `scripts/player.gd`
- Audio manager: `scripts/audio.gd`

## Current game structure (from source README)

1. Saschiz hub → Wolf Forest → Vârcolac in the Moon Clearing.
2. Richiș hub → Hollow Hills (Iele fairy rings) → Salt Caves (moroi and salt crystals) → Muma Pădurii in the Hollow.
3. Moșna hub → Burnt Vineyards (strigoi churchyard and bats) → three-headed Balaur in the Drowned Quarry.
4. Biertan (survivors in the Marriage Prison) → Three Walls (blood wards seal each gate) → Strigoi Vlad in the church; ring the great bell. Ending and credits.

Optional content documented in the source README:
- Bear of the Garden (Grădina Ursului), from Harap-Alb, hidden in the south-east of Hollow Hills.
- Wolf Forest side quests: Gheorghe's lost ewes, the hermit's spring, and haiduc treasure that only burns blue at midnight.
- Bestiary with folklore context for creatures and characters.

## Gameplay and controls (source README)

- WASD: move
- Mouse: aim; click: attack
- Space: dodge
- E: interact
- Q: garlic tincture
- R: throw salt
- The game saves on reaching a village; Continue loads the save.

Source README also documents a headless end-to-end test:
`godot --headless --path . -- --autotest`
Expected successful output includes `TEST RESULT: OK`.

## Story and design principles

- Romanian folklore is a core differentiator. Keep creature names, places, and cultural references accurate and intentional.
- The world should feel dangerous, old, inhabited, and occasionally absurd.
- Humour should emerge from character voice, local superstition, bureaucracy, petty village concerns, gallows humour, and unexpected reactions. Avoid turning every scene into a joke.
- Preserve readable combat: player, enemies, hazards, interactables, objectives, and effects must remain distinguishable against dark environments.
- Prioritise player feedback, enemy telegraphs, responsive controls, meaningful exploration, and varied environments.
- Avoid scope expansion without a clear contribution to the core loop.

## Production tools

The creator uses the following tools alongside Godot and GitHub:

- **Claude** — implementation partner / coding agent. Use the repository as shared context; ask Claude to read this file first and keep it updated.
- **ChatGPT** — product direction, game design, architecture review, code review, QA planning, prioritisation, commercial strategy, and task/spec drafting.
- **Meshy** — AI 3D asset creation for game models, props, environment assets, image-to-3D, texturing, rigging and animation. Use it for 3D elements that complement the 2D gameplay and pixel-art direction; validate topology, scale, texture budget, rigging and performance in Godot before accepting assets.
- **PixelLab** — pixel-art and sprite creation.
- **Fish Audio** — voice/audio generation.

When proposing generated assets, include:
1. Intended in-game use and required dimensions/format.
2. Style constraints and palette.
3. Animation/frame requirements, if relevant.
4. Import settings and Godot integration notes.
5. Commercial-use/licensing and attribution checks for the generated output and any source material.

Do not assume tool outputs are automatically cleared for commercial use. Maintain an asset register with source, creator/tool, generation date, licence/terms checked, attribution requirements, and where the asset is used.

## AI collaboration protocol

### Before starting work
1. Read this file and the relevant project files.
2. Identify the active branch and current state.
3. Check recent commits before making recommendations about existing work.
4. State assumptions and distinguish observed implementation from proposed design.

### Task ownership
- Claude can implement scoped code changes and tests.
- ChatGPT can review the diff, architecture, edge cases, UX implications, and acceptance criteria.
- Either assistant may propose work; implementation should be committed to a feature branch or the agreed source branch with a clear commit message.
- Avoid both assistants editing the same files concurrently.
- Do not overwrite or force-push another agent's work.
- Use pull requests for substantial changes when practical.

### Handoff format
Every implementation task should include:
- **Goal**
- **Relevant files**
- **Current behaviour**
- **Required behaviour**
- **Constraints / non-goals**
- **Acceptance criteria**
- **Test command and expected result**
- **Files changed and commit SHA** on completion

### Review checklist
- Does the change preserve the established dark-but-funny tone?
- Does it fit the current Godot architecture and existing code style?
- Are controls, feedback, and accessibility/readability considered?
- Are save/load and progression states handled?
- Does the change work in desktop and web exports where applicable?
- Are performance and asset-size implications acceptable?
- Are assets and audio cleared for commercial use?
- Does the headless autotest pass, plus any focused manual test?

## Known facts vs open questions

Known:
- Unity-to-Godot migration is complete.
- The current web deployment is published from `gh-pages`.
- The game has four main regional arcs and four major folklore bosses, plus an optional Bear encounter.
- The tone is dark with humour.
- The creator uses Claude, a mesh/3D asset tool, PixelLab, and Fish Audio.

To confirm and update:
- Which tool owns each asset category (3D models, pixel sprites, portraits, voice, SFX, music).
- Current end-to-end playtime and how much content is fully playable.
- Current known bugs, unfinished systems, and performance targets.
- Final pricing, release model (Early Access vs full release), and platform scope.

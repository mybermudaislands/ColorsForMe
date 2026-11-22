# Prompt for a new conversation

Copy everything in the block below into the new conversation.

```text
Continue work on the ColorsForMe addon for WoW Forever 1.60.1, interface 16001.

Working directory: the repository root (the folder that contains ColorsForMe\)
Addon source: ColorsForMe\
Approved design: ColorsForMe-Design.md
Implementation plan: docs\superpowers\plans\2026-11-13-colorsforme.md
Game directory: <WoW folder>\_forever_
Installed addon directory: <WoW folder>\_forever_\Interface\AddOns\ColorsForMe

Read the design and plan first, then inspect the actual files and applicable instructions. The user approved the design and chose the sequential approach: first capture current behavior with tests and split the large core without intentional behavior changes, then implement and verify the requested improvements separately. Execute the plan incrementally, adapting details only when evidence requires it. The user is not a programmer, so respond in Russian, explain essential decisions clearly, and ask targeted questions when game observations or choices are needed. Write code, comments and project documentation in English.

The user authorizes reading the game directory and installing addon versions into the installed addon directory for testing. If the harness denies access, request the required permission; do not bypass the restriction. Inspect the current installed version before changing anything, preserve a verified backup outside the active AddOns directory, do not remove unrelated files or SavedVariables, and install only after local checks. At appropriate checkpoints ask the user to run /reload and report what happened. Do not claim that a client test passed without user feedback.

Requirements: preserve current modes, saved settings, minimap button, gryphon/wyvern controls, original texture restoration and combat deferral; remove the author's name from the options title and center the title; remove the displayed /forevercolor probe mention but retain the command; investigate displaying the existing minimap icon in the game's addon list using supported client capabilities; identify and recolor safely addressable decorative borders missed by the addon, including the Escape menu, social interface, minimap-adjacent items and the Blizzard color picker. Verify actual client frame and texture identities instead of guessing. Keep existing quest-marker/background behavior during the refactor and discuss any later changes with the user.

Do not replace Blizzard texture files or atlases, add overlays to imitate their art, recolor unrelated functional indicators, introduce networking or persistent polling, bypass protected/forbidden APIs, or assume zero performance cost. Measure performance and test conflicts where possible; report limitations honestly. Use existing project and harness rules. Do not commit or create branches unless the user explicitly requests it. Do not delegate to subagents unless explicitly authorized.

Current planning observations, not guarantees: the source TOC says version 0.4.5; addon Lua files are already split, but Core.lua combines most responsibilities. No Lua interpreter was found in PATH and no existing project tests were found during planning. Access to the game directory was rejected by the harness despite user authorization. Resolve these issues using approved methods before relying on runtime tests or client inspection. The design and plan were prepared; no addon source or installed addon changes were made in that planning session.

Start with Task 1. Tell the user what you are checking, establish a reliable baseline, and preserve existing work. If a stage requires in-game verification, pause for the user's feedback rather than reporting it as complete.
```

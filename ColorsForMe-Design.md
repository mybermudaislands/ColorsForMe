# ColorsForMe restructuring and coverage design

## Purpose

Keep ColorsForMe a lightweight WoW Forever 1.60.1 addon that recolors existing decorative interface elements, while making its implementation easier to maintain and expanding coverage only when individual elements are verified.

## Current baseline

The working source is `ColorsForMe/`, with interface version 16001 and addon version 0.4.5 in `ColorsForMe.toc`. `Core.lua` currently combines configuration, discovery, texture matching, coloring, caching and event handling. `ExtraChrome.lua`, `Diagnostics.lua`, `Options.lua` and `MinimapButton.lua` provide additional rules, diagnostics and UI. Existing documentation describes older versions and is not proof of current runtime behavior. The installed client and addon were not inspected because access to the game directory was denied during initial analysis.

## Approaches

1. Selected: establish a repeatable baseline, split existing responsibilities without intentionally changing behavior, then introduce UI changes and verified coverage improvements in separate stages. This isolates regressions and preserves a known-good fallback.
2. Rewrite and expand coverage together. This was rejected because simultaneous architectural and behavioral changes make regressions harder to locate and validate.

## Scope and constraints

- Preserve existing modes, saved settings, minimap behavior, slash commands, combat deferral and reset behavior through the restructuring stage. Do not delete diagnostic commands merely because their mention is removed from the options window.
- Remove the author from the options title, center the title, and remove the probe command mention from the options window. Preserve the author metadata unless separately requested.
- Investigate whether the existing minimap icon can be displayed in this client's addon list using supported metadata or UI capabilities. Verify in the client and report limitations rather than inventing support.
- Investigate the Escape menu, social interface, minimap-adjacent controls, location and search borders, calendar, the control below the calendar, and the Blizzard color picker. Identify actual frame ownership and individual texture regions before adding narrowly scoped rules. Ask for screenshots or in-game diagnostics where the target cannot be identified reliably.
- Recolor existing eligible decorative regions only. Never replace Blizzard texture files or atlas assignments, add overlays to imitate their art, recolor functional indicators or bypass forbidden or protected UI restrictions. The addon's own icon remains an addon asset.
- Preserve safety around combat, alpha and restoration of original color and desaturation. Confirm that disabling or resetting remains reversible for supported objects. Do not promise identical classic artwork when color operations alone cannot achieve it.
- Do not add networking, persistent polling, frequent global UI scans, third-party dependencies or protected-action overrides. Initial discovery, relevant load-on-demand events and explicitly requested diagnostics are permitted when bounded and measured. Weak in-memory caches are rebuilt after reload; only serializable settings and explicit diagnostic output are persistent.
- Existing quest marker and background coloring must be inventoried separately. Do not silently remove or expand it during the behavior-preserving restructuring stage. Ask the user before any later change to those existing semantics.

## Proposed module boundaries

The final names and number of files should follow actual dependency analysis and remain simple. The intended responsibilities are: addon initialization and event lifecycle; saved settings and mode transitions; decorative roots and eligibility rules; bounded discovery and event-driven integration; color application, original-state restoration and weak caches; targeted client-specific decorations and gryphon adjustments; opt-in diagnostics; options and color picker; minimap button. Modules share the existing addon namespace and load in an explicit `.toc` order. Avoid introducing a framework or gratuitous abstraction.

## Validation and release

Before refactoring, inventory observable behavior and establish automated checks using a lightweight mocked WoW API where feasible. Exercise load order, saved-variable initialization, mode changes, color-picker cancellation, restoration, combat deferral, delayed windows, cache behavior, minimap dragging, eligibility exclusions and existing diagnostics. Record untested client-only behaviors explicitly. Compare tests before and after each behavior-preserving change.

For each newly covered target, document evidence identifying its frame and texture region, its intended decoration, and why nearby functional art is excluded. Add focused regression tests and confirm the visual result in the actual client, including reset and combat behavior where relevant. Treat inaccessible or unverified regions as unresolved rather than broadening matching rules.

Assess performance through static review, instrumentation or profiling when available, and an in-game A/B comparison with comparable settings and scenarios. Report FPS and frame-time observations as measurements, not guarantees. Check errors and conflicts with other addons separately. Avoid collecting or sharing account information unnecessarily from SavedVariables or diagnostics.

Before installing a test build, obtain access to the specified game directory, inspect the existing installation, and preserve the user's existing files and SavedVariables. Install only the addon files needed for the agreed test, keep a recoverable backup without deleting unrelated files, and ask the user to run `/reload` and report results. A live-client check is required before claiming visual compatibility or absence of performance impact.

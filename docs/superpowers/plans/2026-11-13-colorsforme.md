# ColorsForMe Restructuring and Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for inline execution, or superpowers:subagent-driven-development only if the user explicitly authorizes delegation. Steps use checkbox syntax for tracking. This plan is a staged roadmap: runtime discoveries in later stages may require a focused follow-up plan before implementation.

**Goal:** Preserve the working addon while making it maintainable, improving requested UI details and safely extending verified decorative coverage.

**Architecture:** First capture and test existing behavior, then move existing code into focused modules while retaining the addon namespace and explicit TOC load order. Make requested behavior changes only after the behavior-preserving refactor, and add each client-specific decoration through evidence-backed, narrowly scoped rules.

**Tech Stack:** WoW Forever interface 16001, Lua, Blizzard addon APIs, a lightweight local Lua mock test harness with no runtime addon dependencies.

**Spec:** `ColorsForMe-Design.md` in the project working directory.

## Global Constraints

- Work in the repository root; addon source is `ColorsForMe\`.
- Target client: WoW Forever 1.60.1, interface 16001. Check actual client build and APIs before assuming availability.
- Preserve `ColorsForMeDB`, existing modes, minimap behavior, slash commands, combat deferral, reset behavior and existing rules during refactoring.
- Do not replace Blizzard textures or atlas assignments, introduce overlays, touch unrelated functional art, bypass protected or forbidden UI restrictions, add networking, or add persistent UI polling.
- Weak runtime object caches are rebuilt after reload. Saved settings persist, and explicitly requested diagnostic output may be persisted.
- Do not delete unrelated installed files, addon settings, or the user's work. Preserve a recoverable copy of the installed addon before changing it.
- User authorizes reading the game directory and installing the addon into `<WoW folder>\_forever_\Interface\AddOns`. Tool permissions still govern access. If blocked, request access through the harness rather than bypassing it.
- Do not assume game-client testing, FPS safety or complete texture coverage until supported by observed evidence.
- Do not commit or create branches unless explicitly requested. Keep documentation and code in English and provide a Russian summary to the user.

## Review Focus

1. Missing, malformed or partially populated saved settings must not prevent login. Task 1 tests defaults and existing valid values.
2. A color change or reset during combat must eventually apply the latest requested state after combat. Tasks 1 and 2 test both paths.
3. A load-on-demand or initially hidden window must be discovered without repeatedly traversing already scanned roots. Tasks 1, 2 and 5 test lifecycle and bounded discovery.
4. Picker cancellation must restore the prior mode and RGB while ignoring late callbacks. Tasks 1 and 3 test cancellation and subsequent reopening.
5. Functional art, protected/forbidden objects and inaccessible methods must not be changed or crash the addon. Tasks 1, 2 and 5 cover exclusions and failures.

## Target file map

Paths below are relative to `ColorsForMe\` unless otherwise stated. Preserve the shared `(addonName, ns)` namespace and the current externally used `ns` names. Keep existing public behavior before changing rules.

| Path | Responsibility |
| --- | --- |
| `ColorsForMe.toc` | Ordered runtime module manifest and supported addon metadata. |
| `Core.lua` | Shared helpers and initialization only, with minimal lifecycle coordination. |
| `Settings.lua` | Saved-variable validation, modes and user-setting transitions. |
| `DecorRules.lua` | Known roots, decoration whitelists and eligibility classification. |
| `ColorEngine.lua` | Original-state capture, weak color caches, painting and restoration. |
| `Discovery.lua` | Bounded traversal, direct decorations, lifecycle hooks and load-on-demand discovery. |
| `ExtraChrome.lua` | Existing targeted extra rules and gryphon adjustment until a tested smaller split is justified. |
| `Diagnostics.lua` | Explicit opt-in diagnostics, not periodic discovery. |
| `Options.lua` | Settings window, picker, and existing slash command routing. |
| `MinimapButton.lua` | Existing minimap icon and drag handling. |
| `../tests/` | Mock WoW API, fixture objects, test cases and runner outside the shipped addon directory. |
| `../reports/` | Baseline, coverage evidence, performance observations and client-test results, with no account identifiers. |

Existing references may require a different internal ordering or a small dependency adjustment during extraction. Record the actual order in the TOC and keep every commit-sized stage runnable. Do not add modules with no distinct responsibility.

### Task 1: Establish the baseline and repeatable checks

**Files:** Read all existing addon files; create `../tests/run.lua`, `../tests/wow_mock.lua`, `../tests/baseline.lua`, `../reports/baseline.md`; do not modify the addon yet.

**Interfaces:** The runner loads files listed in `ColorsForMe.toc` in order using one shared addon namespace. The mock supplies only the WoW APIs needed by each fixture and records changes to texture RGB, alpha, desaturation, discovery calls, events and hooks.

- [ ] Record source and installed addon versions, existing filenames, settings schema, command behavior and client build where accessible. Inventory `ns` exports and cross-file dependencies. Mark client and installed-copy findings as unavailable if access is denied.
- [ ] Locate an already installed compatible Lua interpreter, including `lua`, `luajit`, or `texlua`, without downloading or executing unknown software. No interpreter was found in `PATH` during planning. If none is available, request an approved installation method or use an already available trusted runtime; do not claim runtime tests succeeded.
- [ ] Implement a mock loader and baseline assertions for missing, partial and valid `ColorsForMeDB`; classic, custom and reset; alpha and original desaturation; same-color cache behavior; mode changes during combat followed by `PLAYER_REGEN_ENABLED`.
- [ ] Add assertions for picker cancel and late callbacks; hidden and load-on-demand roots; repeated `OnShow` without new full traversal; forbidden objects; excluded portrait, icon and functional state regions; minimap dragging and retained slash commands.
- [ ] Run `lua tests/run.lua` from the project directory, substituting the verified interpreter command where needed. Record the exact command and results. Baseline tests document observed behavior, including defects, rather than silently changing it.
- [ ] List any current failures, untestable behavior and baseline uncertainties in `reports/baseline.md`. Stop before refactoring if the baseline cannot distinguish a regression from a pre-existing failure.

### Task 2: Split the core without changing behavior

**Files:** Modify `Core.lua`, `ExtraChrome.lua` only where dependencies require it, and `ColorsForMe.toc`; create `Settings.lua`, `DecorRules.lua`, `ColorEngine.lua`, `Discovery.lua`; extend `../tests/baseline.lua` and `../tests/wow_mock.lua` as needed.

**Interfaces:** Preserve `ns.Print`, `ns.InCombat`, `ns.Roots`, `ns.ReadAtlas`, `ns.ReadPath`, `ns.Eligible`, `ns.ScanOne`, `ns.RepaintKnownColors`, `ns.Restore`, `ns.ApplyAll`, `ns.SetMode(mode, color)`, and `ns.GetStats()` with their existing callers and return conventions. Any new internal exports must have a single clear owner and explicit TOC dependency.

- [ ] Map each existing function and local state variable to its target module, including initialization and event registration. Choose an order that preserves when `ExtraChrome.lua` extends `ns.Roots` and supplies optional callbacks.
- [ ] Move rules, color engine, discovery and settings in small increments, adding regression assertions before any dependency seam that the baseline does not cover. Preserve the exact existing eligibility rules, including their current exceptions.
- [ ] After each increment run `lua tests/run.lua` with the verified interpreter. Compare to Task 1, investigate every new failure, and do not proceed on an unexplained regression.
- [ ] Check TOC file existence and load order, Lua syntax, global writes, callback references, saved settings and Lua compatibility. If available, run LuaHelper diagnostics and distinguish actual errors from missing WoW API declarations.
- [ ] Run the full test suite, compare runtime behavior against the baseline, and record discrepancies. Only then prepare a test installation under Task 6 and ask for `/reload` before proceeding with broader changes.

### Task 3: Make the requested options-window changes

**Files:** Modify `Options.lua`; add `../tests/options.lua` and any mock support.

**Interfaces:** `ns.ToggleOptions()` and `ns.OpenPicker()` retain their behavior. `panel.TitleText` displays exactly `ColorsForMe` and is visually centered within the title bar without colliding with its close button. `/forevercolor probe` remains implemented.

- [ ] Add assertions that the title has no author, uses a centered anchor and alignment, and that visible options text does not contain `/forevercolor probe` while the slash handler still accepts `probe`.
- [ ] Run the focused test and confirm it fails on the baseline. Apply only the title and displayed text changes, retaining adjacent content and behavior.
- [ ] Run the focused and full test suites. In the client, verify title placement at supported UI scales, narrow screen sizes and after moving the window; verify picker cancellation and the close button.

### Task 4: Investigate the addon-list icon

**Files:** Inspect client addon-list implementation when accessible; modify `ColorsForMe.toc` only if a supported metadata field is verified; add the outcome to `../reports/client-coverage.md`.

**Interfaces:** Reuse `Interface\\AddOns\\ColorsForMe\\ColorWheel.tga` if the client supports an addon icon field and accepts that format. Do not modify the game addon-list implementation or replace Blizzard assets.

- [ ] Identify the actual client list and exact metadata or other supported mechanism from the installed client source or observable client behavior. Verify accepted path and file format, including whether a TGA asset is accepted.
- [ ] If a supported TOC field is confirmed, add a manifest assertion, demonstrate it fails before the change, add the field, and rerun tests. Install the candidate and ask the user to verify the icon in the addon list after the client has reloaded or restarted as required by the client.
- [ ] If support cannot be established or the list has no icon capability, leave runtime UI untouched and record the limitation and evidence. Do not claim completion of this visual item without the client's confirmation.

### Task 5: Identify and add verified decorative regions

**Files:** Modify `DecorRules.lua`, `Discovery.lua` or `ExtraChrome.lua` only for verified targets; add `../tests/coverage.lua`; maintain `../reports/client-coverage.md`.

**Interfaces:** Existing `ns.Eligible(tex, category, nineSlice)` and `ns.ScanOne(rootName, category, forced)` remain the integration points. Any target-specific direct handler must use the existing color engine, obey combat deferral and restoration, and verify exact native ownership or identifiers.

- [ ] Build a target table with separate entries for Escape menu, social/Battle.net, day/night indicator, search, zone title, calendar, control below calendar and color picker. Record frame name, child path, texture atlas/path/ID, source of evidence, what must remain unchanged, and verification status. Request screenshots or explicit in-game diagnostics when ownership or identity is uncertain.
- [ ] For each target, inspect client UI sources if available and compare them with actual in-game behavior. Explicitly investigate why existing `GameMenuFrame`, `FriendsFrame` and `ColorPickerFrame` code does not yield the requested result; treat each explanation as a hypothesis until verified.
- [ ] For each confirmed independently addressable decorative region, add tests that the exact region changes and nearby icons, text, wheel, preview, hover, alert and content art do not. Cover hidden creation, later display, reset, combat and forbidden/inaccessible behavior as applicable. Run each test and confirm the missing behavior fails.
- [ ] Add the narrowest verified target rule, using bounded discovery and the existing original-state cache. Run focused and full tests. Never use a blanket rule for an unknown window or guess a texture identity.
- [ ] Install and request `/reload` at sensible checkpoints. Ask the user to test classic, custom, reset and reopening for each affected target, and record outcomes and screenshots only with consent. Leave mixed or non-addressable texture regions unresolved if safe color-only treatment is impossible.
- [ ] Inventory existing quest-marker and background recoloring separately. Do not remove or expand it without discussing its visible behavior with the user.

### Task 6: Safe installation and in-game acceptance

**Files:** Read `<WoW folder>\_forever_\Interface\AddOns\ColorsForMe\` when permission is granted; copy the current project addon into that location; place a uniquely named recoverable backup outside the active `AddOns` directory, for example under `backups\` in the repository root.

**Interfaces:** Installation contains the exact TOC-listed files and the existing icon asset. `WTF` and SavedVariables are not modified or deleted by the installation procedure.

- [ ] Request any required external-directory permission through the harness. Inspect existing installed files, including local custom or unexpected files, before copying; do not delete or overwrite unrecognized user content without asking.
- [ ] Make a timestamped backup of the existing addon folder outside `Interface\AddOns`, verify the backup exists and contains the original files, and retain it. If there is no existing installation, record that fact.
- [ ] Copy the intended addon files without deleting unrelated content. Compare source and destination hashes for each copied file, confirm TOC paths and icon asset, and report exactly which version was installed.
- [ ] Ask the user to run `/reload` and check for errors, settings preservation, the minimap button, color modes and the targeted changes. Explain how to restore the backup if needed. Do not claim client acceptance before feedback.

### Task 7: Performance, conflict and security review

**Files:** Inspect all runtime addon files and tests; create `../reports/performance.md` and update `../reports/client-coverage.md`.

**Interfaces:** Preserve bounded discovery, weak caches, existing explicit diagnostics and combat-safe deferred application. A temporary drag-only `OnUpdate` is distinguishable from a permanent polling loop.

- [ ] Audit event registrations, hooks, discovery limits, cache lifetime, allocation-heavy paths, texture writes, protected UI access and error handling. Include worst-case repeated Blizzard addon loads, game-menu opens, picker dragging and first-time window display.
- [ ] Instrument the mock with counters and assert repeat opens avoid full rescans except for explicitly targeted refreshes; assert custom color changes do not rescan roots, and drag `OnUpdate` is removed on drag stop. Compare measurements before and after the refactor using identical fixtures.
- [ ] Review code for unexpected network operations, unsafe external dependencies, unintended global overrides and the collection of user data. Do not claim this review proves the absence of all conflicts or client risks.
- [ ] With user cooperation, compare addon disabled versus enabled under comparable location, settings, other addons and activities. Record FPS and frame-time observations where available, first-open and color-change stutters, errors and methodology. Avoid attributing causes without controlled evidence. If proper profiling is unavailable, explicitly say so.
- [ ] Run all tests and diagnostics, review every unresolved target and client limitation, and deliver a Russian summary of changed files, validation results, user-observed results and remaining risks.

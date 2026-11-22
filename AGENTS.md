# AGENTS.md (ColorsForMe)

Workspace-level rules (git, secrets, releases, language, style) live outside this repository in the maintainer's workspace and are not copied here.

## Commit identity

Use the GitHub noreply identity, never a private email. Set it repo-locally (not globally):

```
git config user.name mybermudaislands
git config user.email 317432022+mybermudaislands@users.noreply.github.com
```

## Layout

- Repo root = `Colors For Me\`. Addon folder = `ColorsForMe\` (contains `ColorsForMe.toc`). The release zip contains `ColorsForMe\` at its top level.
- `tests\` = mocked WoW API tests (`run.lua`, `wow_mock.lua`, `baseline.lua`, `compare_reference.lua`). Run with Lua 5.1 from the repo root: `lua5.1 tests/run.lua`.
- Local-only and git-ignored: `*-backup-*\` snapshots, WTF/SavedVariables, zips, `.superpowers\`, `.cache\`. Design/plan/progress docs (`docs\`, `reports\`, `ColorsForMe-Design.md`, `NEXT-CHAT-PROMPT.md`) are tracked and must not contain absolute local paths or personal data.

## Architecture (load order from the toc)

`Roots.lua` (ns.Roots: known Blizzard frame name -> category), `Settings.lua` (saved-variable init, mode controller), `TextureAccess.lua` (ReadAtlas/ReadPath), `DecorAtlases.lua` (atlas tables, ns.IsDecorAtlas), `DecorRules.lua` (ns.Eligible), `ColorEngine.lua` (capture/paint/restore, weak caches), `Core.lua` (Print, InCombat), `Discovery.lua` (bounded traversal, OnShow hooks, events, ns.SetMode, direct decoration handlers), `ExtraChrome.lua` (extra eligibility rules, quest markers, gryphon lift, own-window recolor), `Diagnostics.lua` (probe, inspect), `Options.lua` (settings window, picker, slash commands), `MinimapButton.lua`.

Shared state is the addon namespace `ns`. SavedVariables: `ColorsForMeDB` (`mode`, `custom`, `minimapAngle`, `gryphonLift`, diagnostics `lastProbe`, `lastTargetProbes`).

## Gotchas

- Only `SetDesaturation` and `SetVertexColor` are used. Never replace textures/atlases, add overlay textures, or hook-override Blizzard functions.
- Never paint in combat: use `blocked()` and `queueCombatRetry()` (retry on `PLAYER_REGEN_ENABLED`).
- No timers, polling or permanent `OnUpdate`. The only `OnUpdate` is the minimap button during a drag.
- Every texture access goes through `pcall` and `issecretvalue` checks (`safeObject`). Keep that when adding code.
- Add a new target by exact frame/region/atlas name, never by wildcard. `MacroFrameTextBackground` subtree and portrait/icon textures are deliberately excluded.
- `StoreFrame`, `CatalogShopFrame`, `SocialUIFrame` must be skipped when `IsForbidden()`.
- `TradeFrame.RecipientOverlay.portrait` must never be recolored (only the ring and two border textures).
- `ExtraChrome.lua` once had a Lua syntax error from backslash escapes (see `ColorsForMe\CHANGELOG_RU.txt`, 0.4.2). Syntax-check Lua after editing.
- `WINDOW_ATLAS` has a known duplicate key `ui-frame-innertopleft` (same value, harmless).
- `ColorsForMe\README_RU.txt` and `CHANGELOG_RU.txt` are Russian docs that ship in the addon folder; keep their version in sync with the toc. `PERFORMANCE_AUDIT_RU.txt` is a historical audit of 0.3.2 and stays as is.

## Release

Release is tag-driven (`vX.Y.Z` pushes trigger `.github\workflows\release.yml`). The pipeline is disabled until the repo variable `RELEASE_ENABLED` is set to `true`. See `RELEASING.md`. Bump `## Version:` in the toc and add a `CHANGELOG.md` entry before tagging.

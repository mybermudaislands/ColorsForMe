# Baseline observations

## Source and installed copy

The project and installed addon both declare version 0.4.5 and interface 16001. On 2026-11-13, SHA-256 hashes matched for each of the ten files in the project and installed addon directories. This comparison does not establish in-game behavior or client build.

## Static diagnostics

LuaHelper 0.2.29 reported one warning in `Core.lua`: the `WINDOW_ATLAS` table contains the duplicate key `ui-frame-innertopleft` at line 148. The duplicate has the same value and is not evidence of a runtime failure. No code was changed.

## Test tooling

The QuestListForMe tools directory contains a portable Lua interpreter and compiler. Its previous project documentation reports Lua 5.1.5 and identifies a LuaBinaries archive. The retained archive hash matches the previous project's recorded hash, but the hash is not publisher authentication and the interpreter executable is unsigned. Windows Defender custom scanning was invoked for the tools directory. The user authorized running the interpreter after being informed of the limitation. The interpreter reports Lua 5.1.5.

Run from the repository root: `& '<path to>\lua5.1.exe' tests\run.lua`. The current suite passes 14 baseline cases, using mocked WoW APIs. The runner's intentional failure mode was also run and correctly returned exit code 1. These are characterization tests, not proof of actual in-game behavior.

## Pending

The baseline does not yet cover the full set of existing decoration rules, every specific direct-decoration handler, all diagnostic commands or all API failures. Continue expanding tests before refactoring the affected portions of the core. The client build, actual UI behavior, performance, protected-action behavior and installed addon compatibility remain unverified. The working directory is not a Git repository, so a Git worktree and Git-based plan tracking are unavailable without changing the project's existing setup.

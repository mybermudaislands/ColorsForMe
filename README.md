# ColorsForMe

A lightweight World of Warcraft addon for the **WoW Forever** client (interface 16001, Classic-era engine) that recolors selected original Blizzard decorative UI art (frame borders, action bar trim, unit frame rings, minimap ring, window chrome and similar). It does not replace any texture or atlas and does not move, hide or restyle any window. It only changes the color of known decorative textures through the standard `SetDesaturation` and `SetVertexColor` calls, and it can restore the original colors at any time.

[Русская версия](README.ru.md)

## Features

- **Classic Gray**: desaturates the covered decorative art so the brown/bronze trim becomes neutral gray.
- **Custom Color**: pick any color with the standard Blizzard color picker. Cancel in the picker returns the previous color.
- **Reset**: restores the exact original color and desaturation of every texture the addon touched.
- **Gryphon/Wyvern tint relief** (Custom Color mode only): a setting from 0% to 150% in 25% steps that brightens the action bar gryphon and wyvern art, which a dark custom color otherwise makes too dark. It does nothing in Classic Gray and Reset.
- **Minimap button**: left-click opens the settings window, right-click opens the color picker, drag moves the button around the minimap. The addon also has an Addon Compartment entry.
- **Targeted coverage only**: the addon looks at a fixed list of known Blizzard frames (action bars, minimap, player/target/focus frames, objective tracker, micro menu, damage meter windows, and many standard windows such as character, spellbook, quest log, merchant, trade, mail, loot, bags, map, game menu, social/friends, group finder and others). Only individually identified decorative textures are recolored. Icons, portraits, text, buttons, item and quest art are left alone.
- **Light on resources**: no timers and no polling. Each texture is captured and colored once and then cached. Work is deferred while you are in combat and runs when combat ends. No external libraries.
- Settings are saved per account in `ColorsForMeDB` (mode, custom color, minimap button position, gryphon relief).

## Installation

1. Close World of Warcraft.
2. Download the latest `ColorsForMe-x.y.z.zip` from the Releases page of this repository, or copy the `ColorsForMe` folder from this repository.
3. Put the `ColorsForMe` folder into your AddOns folder (the `Interface\AddOns` folder of your WoW Forever client). You should end up with `...\Interface\AddOns\ColorsForMe\ColorsForMe.toc`.
4. Start the game and make sure ColorsForMe is enabled in the AddOns list.

Updating: replace the `ColorsForMe` folder. Do not delete your `WTF` folder if you want to keep your settings.

## Slash commands

`/forevercolor` or `/cfm`:

| Command | What it does |
|---|---|
| `/forevercolor` (also `options`, `config`) | Opens or closes the settings window |
| `/forevercolor classic` (also `gray`) | Classic Gray mode |
| `/forevercolor custom` (also `color`) | Opens the color picker for Custom Color mode |
| `/forevercolor reset` (also `original`) | Restores the original colors |
| `/forevercolor status` | Prints the current mode, number of touched texture layers and whether work is waiting for combat to end |
| `/forevercolor scan` | Manually rechecks the currently loaded Blizzard frames |
| `/forevercolor probe [FrameName]` | Developer diagnostic: records candidate textures of a known Blizzard frame into `ColorsForMeDB` (read-only, out of combat only). Run it, then `/reload` to write the data to disk |
| `/forevercolor inspect` | Developer diagnostic: prints the frame ancestry and texture atlas/path under the mouse cursor (out of combat only) |

## Known limits

- The addon was written for WoW Forever (interface 16001). Frame names for some Forever windows are not confirmed in a live client. If a window is not recolored, its decorative layer is simply not recognized yet. The addon intentionally has no "recolor every texture of a window" rule.
- Only color multipliers are used, so a dark brown background cannot always be turned into a perfectly neutral gray without replacing the original texture.
- Recoloring is not applied during combat. It is queued and applied when combat ends.
- Frames the client marks as forbidden to addons (for example some store frames) are skipped.
- The built-in text documents in the addon folder (`README_RU.txt`, `CHANGELOG_RU.txt`, `PERFORMANCE_AUDIT_RU.txt`) are in Russian. `README_RU.txt` and `CHANGELOG_RU.txt` cover the current version; `PERFORMANCE_AUDIT_RU.txt` is a historical audit of version 0.3.2.

## Development

Tests use a mocked WoW API and run with a plain Lua 5.1 interpreter from the repository root: `lua5.1 tests/run.lua`. They are characterization tests, not proof of in-game behavior.

## License

Released under the MIT License. See [LICENSE](LICENSE).

# Client coverage investigation

## Evidence and limitations

The user reports that the installed 0.4.5 refactoring candidate loads without observed errors, both Reset buttons behave correctly, and the main game menu recolors. The user reports that the other targets below do not recolor as expected. These are client observations, not automated visual tests. The reason for the game menu change is not established.

The accessible `_forever_\Interface` directory contains installed addons, but no unpacked Blizzard UI sources were found there. Searches for `FriendsFrame.xml` and `Blizzard_AddonList` under the game directory found no matching source files. The existing code contains comments referring to client XML, but those comments alone do not verify the current client's live objects or the identity of the reported artwork.

| Target | Existing code and evidence | Status and exclusions |
| --- | --- | --- |
| Game menu | `GameMenuFrame` is a root; `Discovery.lua` separately refreshes its `Border` and selected header tiles. | User reports recoloring. Preserve menu buttons and text. The specific reason for improvement is unknown. |
| Social and Battle.net friends | `FriendsFrame` and `CommunitiesFrame` are registered roots. `FriendsFrame.NineSlice` gets a targeted refresh. | The user reports the visible border stays unchanged. The actual host and texture are not verified. Preserve friend entries, portraits, status and buttons. |
| Color picker | `ColorPickerFrame` is a registered root and gets an explicit scan on opening. | The actual border host and texture are not verified. Preserve wheel, sliders, preview and buttons. |
| Action Bars 2-8 | `Roots.lua` registers `MultiBarBottomLeft`, `MultiBarBottomRight`, `MultiBarLeft`, `MultiBarRight`, `MultiBar5` through `MultiBar8` and named buttons. | The user's reported bar borders are not identified. Preserve icons, cooldowns, highlights and state indicators. |
| Character portrait level border | `PlayerFrame` is a registered root and `PlayerFrameContainer.FrameTexture` is a direct candidate. | The level border's actual object and whether it is independent of text or state artwork are unknown. Preserve level text, portraits and indicators. |
| Minimap day/night, search, location, calendar and nearby control | Some minimap roots already exist, but the requested exact regions were not identified in this session. | Do not add rules without client evidence; preserve indicators and interactive art. |
| Addon-list icon | The installed TOC has no verified supported icon field; the addon supplies `ColorWheel.tga`. The actual Forever addon-list source was not found. | Capability, accepted metadata, format and client display are unverified. No manifest or Blizzard UI changes made. |

## Gryphons and wyverns

`ColorEngine.lua` sets desaturation to 1 for eligible artwork. `AdjustGryphonColor` in `ExtraChrome.lua` applies only in custom mode, and calculates each tint channel as `channel + (1 - channel) * lift`. At lift 1, the tint becomes white but desaturation remains 1. Therefore the existing algorithm removes the chosen tint at maximum relief while retaining grayscale. This explains the parameters set by the code, not the precise pixels rendered by the client.

The user requested retaining the selected hue while increasing brightness, for example a light green wyvern when green is selected. The candidate now raises RGB channels proportionally toward their maximum without changing desaturation or texture assets. Pure black remains black because it has no hue to preserve. The original texture's darkest details cannot be made brighter than the multiplication permits. Local tests exercise intermediate and maximum relief, reset and extreme dark values; visual acceptance in the client is pending.

## Subsequent screenshots

The user's screenshots show the Social outer frame and side tabs, borders around extra action buttons, the color picker's outer border and header, and several minimap-adjacent controls still in their original color. They establish the visible targets, not the underlying object names, texture IDs or whether decoration can be independently changed. The screenshots also show functional elements and content which must not be recolored. Collect in-game diagnostic evidence before adding any rules.

## FriendsFrame probe

The user opened Social and ran the existing targeted probe, then reloaded. The saved report identifies interface 16001, build 70938, one scanned root and 142 candidate textures without truncation. It includes multiple `UI-Frame-Metal` and `UI-Frame-DiamondMetal` edge and corner atlases marked ineligible, but their immediate hosts are unnamed. Some atlas names occur more than once. The report does not record object ancestry, visibility or geometry, so it cannot establish which instances are the outer visible border rather than other nested frames. Named tab entries also include active-tab artwork which can convey selection state and must not be treated as decorative by name alone. Existing direct `FriendsFrame.NineSlice` processing and eligibility results do not prove which pixels were actually changed. More targeted identification is needed before a safe rule can be added.

## Extended relief candidate

The user confirmed the earlier hue-preserving relief looked good and asked for 50 additional percentage points. The new candidate keeps 0%-100% unchanged and adds 125% and 150% settings. Above 100% the normalized tint gradually blends toward white, reducing saturation while retaining its hue where one exists. This changes color only, does not replace texture art, and cannot guarantee a 50% increase in rendered pixel brightness. Black remains black. The user reports a noticeable difference between 100% and 150% and accepts the 150% appearance. They could not visually distinguish 125% from 150%.

## Enhanced probe

The opt-in probe now records a per-scan child-index path for each host, the region index, host visibility and the texture rectangle when available. These are diagnostic observations, not stable object identifiers or permission to recolor an entire host. The probe still uses its existing bounded traversal and only stores texture metadata, not displayed text or social-list contents. A new client probe is necessary to establish whether these fields reveal the visible Social border. Existing reports and known targets for minimap and character-level borders remain insufficient to authorize new recoloring rules.

## Follow-up Social probe

The enhanced FriendsFrame report was saved successfully and contains 142 entries. Every recorded host has `visible = false`, and none has a recorded rectangle. The report therefore does not identify the currently visible Social border. Possible explanations include the Social window being closed at the time of the probe or the visible window using another root; the data do not distinguish these possibilities. Use the existing read-only `/forevercolor inspect` command while the pointer is over the visible window to investigate its ancestry. The client files inspected under `Data/wowf` are packaged data and index files; no unpacked Forever Blizzard UI source or existing local CASC extraction tool was located. The visual targets around the minimap and the level border remain unverified.

## Mouse inspection and targeted reports

The user reports that pointing at several locations in the visible Social window returned `SocialUIFrame` in the mouse-focus ancestry. This confirms that the object participates in the visible window, not which of its individual texture regions form the requested border. The character-level area returned `PlayerFrame`; the day/night and search areas returned `Minimap` and unnamed descendants of `MinimapCluster`. The mouse-focus object was not itself a texture in these samples, so atlas and file IDs were unavailable.

The diagnostic command now accepts `SocialUIFrame` as a diagnostic-only target without adding it to automatic coloring roots. Targeted probes for `SocialUIFrame`, `MinimapCluster` and `PlayerFrame` retain separate reports and include texture metadata even when the old name-based diagnostic filter would omit it. Each scan retains the existing 350-entry and traversal limits, and checks whether the root is forbidden. No screen text or friend-list entries are collected. These reports require a client run and might still be truncated or lack sufficient ownership evidence. They do not authorize coloring icons or indicators.

## Social border candidate from client probe

The later SocialUIFrame probe recorded the visible outer NineSlice's exact seven metal edge/corner atlas names and the portrait-metal top-left corner. Its rectangles align with the exterior boundaries of the visible Social window, and the probe's structural eligibility identifies the host as the root's `NineSlice`. It also records an unlabeled center region and several functional elements, none of which are authorized by this finding. The Social and minimap reports each reached the 350-entry limit and are incomplete. The PlayerFrame report was not truncated and contains `UI-HUD-UnitFrame-SmallCircle`, but its precise semantic role and independence from level or state indicators remain unconfirmed. The minimap report contains multiple controls and day/night-related assets, some hidden; their exact decorative boundaries remain unconfirmed.

The candidate implementation registers SocialUIFrame with a special restricted category. It reads only the root's NineSlice and applies color only to the eight exact observed border atlases, using the existing capture, restoration and combat-deferral engine. It does not scan or recolor the Social content or add a broad window rule. Locally mocked tests cover a hidden window, selected border atlases, excluded icon/background and an identical atlas outside the NineSlice, custom color and combat-deferred reset. Actual client rendering and reopen behavior await user testing.

## Social acceptance and level/day-night candidates

The user reports that the Social window now recolors and retains the color as intended. The user accepted its observed behavior in the client.

An independently maintained [Forever UI source mirror](https://github.com/Ketho/wow-ui-source-forever) provides additional evidence but is not a verified copy of the installed build. Its [player template](https://github.com/Ketho/wow-ui-source-forever/blob/forever/Interface/AddOns/Blizzard_UnitFrame/Camelot/PlayerFrameTemplates.xml) assigns `UI-HUD-UnitFrame-SmallCircle` both to a level background and a PvP background; its [player frame](https://github.com/Ketho/wow-ui-source-forever/blob/forever/Interface/AddOns/Blizzard_UnitFrame/Mainline/PlayerFrame.xml) distinguishes `PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.LevelBackgroundCircle` from `PvpBackgroundCircle`. The installed-client probe separately observed that atlas near the player portrait, but did not record the named object relationship. The candidate checks the exact level object and atlas rather than matching the atlas globally. Local tests confirm the same-atlas PvP object is excluded; the installed client must confirm actual behavior.

The mirror's [day/night source](https://github.com/Ketho/wow-ui-source-forever/blob/forever/Interface/AddOns/Blizzard_Minimap/Camelot/Diel.lua) creates `MinimapCluster.DielFrame`, with a separate `UI-HUD-Minimap-Frame-Cycle` border and day/night background. The installed-client report observed that border atlas on a hidden host but was truncated before proving the live DielFrame relationship. The candidate checks the exact DielFrame and border atlas and does not color the day/night background. If the installed client has different objects, the candidate may do nothing. Client testing is required.

Search, zone title and calendar decoration remain unresolved. The available report includes button and state artwork and was truncated, so no new rules for them were added. Target level circles are also outside the current player-only candidate.

## Target and focus level candidates

The user supplied a screenshot showing the player's recolored circle and the unchanged target and focus level circles. The independently maintained Forever mirror's [target template](https://github.com/Ketho/wow-ui-source-forever/blob/forever/Interface/AddOns/Blizzard_UnitFrame/Camelot/TargetFrameTemplates.xml), [target logic](https://github.com/Ketho/wow-ui-source-forever/blob/forever/Interface/AddOns/Blizzard_UnitFrame/Camelot/TargetFrame.lua), and [target frame XML](https://github.com/Ketho/wow-ui-source-forever/blob/forever/Interface/AddOns/Blizzard_UnitFrame/Mainline/TargetFrame.xml) identify `TargetFrameContent.TargetFrameContentMain.LevelBackgroundCircle` and the shared `UI-HUD-UnitFrame-SmallCircle` atlas, with FocusFrame inheriting the target template. The mirror is not confirmed as the exact installed build. The test candidate restricts changes to that named circle on TargetFrame and FocusFrame and requires the exact atlas. It leaves matching PvP textures and other artwork alone, checks initially and when either frame appears, and uses the existing combat queue and original-state cache. Client verification is pending.

The user identified the minimap controls as tracking, zone name and calendar. The control below the calendar opens a list of addons according to the user, but its exact object and owner are not established here. `MinimapButtonButton` is installed and its source contains button collection and exclusion logic, but installation alone does not prove that it owns the pictured control or explain why ColorsForMe is absent. No changes to the other addon, registration, or minimap control art were made.

## Addon compartment plate candidate

The user confirmed that the target and focus level circles work as intended in the client. The [independent Forever UI source mirror's compartment XML](https://github.com/Ketho/wow-ui-source-forever/blob/forever/Interface/AddOns/Blizzard_Minimap/Mainline/AddonCompartment.xml) describes `AddonCompartmentFrame` anchored directly under `GameTimeFrame`, with a separate numeric text element, a normal `ui-hud-minimap-button` texture, a pushed texture and a highlight. This is consistent with the user's screenshot and description but does not independently establish that the mirror matches the installed build or that the pictured control is that object.

The candidate checks the exact global object, its forbidden status, its normal texture's exact atlas, and that it is distinct from the pressed and highlighted textures. It then colors only that normal texture through the existing engine. It does not alter button text, clicks, highlight, pressed texture or addon registrations. Local tests passed; the actual client's object identity, rendering and behavior remain to be confirmed. The mirror's [calendar XML](https://github.com/Ketho/wow-ui-source-forever/blob/forever/Interface/AddOns/Blizzard_Minimap/Mainline/GameTime.xml) lists day-specific normal, pushed and highlight textures, but does not establish a separately addressable decorative calendar border. Tracking and zone-header artwork also remain unresolved.

The mirror's [compartment logic](https://github.com/Ketho/wow-ui-source-forever/blob/forever/Interface/AddOns/Blizzard_Minimap/Mainline/AddonCompartment.lua) registers addons that provide `AddonCompartmentFunc` metadata. Before the subsequent registration candidate, the ColorsForMe TOC did not declare that field. If the user's control is this compartment and the client uses the same code, that could explain its absence from this particular list. This is a hypothesis, not client verification.

## Registration candidate and failed minimap appearance

The user reports that tracking, zone title, calendar and the addon-list control did not recolor. The user requested pausing those targets and explicitly asked for addon-compartment registration. The source TOC previously had neither `AddonCompartmentFunc` nor `IconTexture`; the installed Leatrix Plus and Maps manifests include compartment handlers. ColorsForMe now declares its own handler, which opens the existing settings panel and does not close an already open panel. No `IconTexture` was added, no icon asset or minimap button was changed, and client confirmation remains pending.

The user subsequently confirmed the ColorsForMe entry appears without an icon and requested the existing minimap icon. The TOC now references the same `ColorWheel.tga` asset in `IconTexture`. Local checks verify the path matches the minimap button; display in the installed client remains pending.

## Quest artwork inventory

Existing `ExtraChrome.lua` includes objective-tracker quest-marker atlases and paths plus restricted name patterns; `DecorRules.lua` also recognizes objective-tracker header background objects and selected header atlases. These pre-existing rules were neither removed nor expanded in this session.

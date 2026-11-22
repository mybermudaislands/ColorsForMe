-- ColorsForMe 0.4.6: optional chrome additions.
-- The stable 0.3.2 scanner/color cache remains responsible for ALL mutations.
-- Only a known frame/root or a verified name/path can authorize a color change.
local addonName, ns = ...
local _G, type = _G, type
local lower, find = string.lower, string.find

-- Optional native frames. Missing names are ignored, not created.
-- Legacy has Forever-specific UI names; leave unverified layers untouched.
local candidateRoots = {
    ColorPickerFrame = "window",       -- Blizzard's color picker, NOT its wheel
    PaperDollFrame = "window",         -- named stat-pane decoration only
    GameMenuFrame = "gameMenu",        -- known from 0.3.2
    RaidFrame = "window",
    RaidInfoFrame = "window",
    LFDParentFrame = "window",
    LFGListFrame = "window",
    LookingForGroupFrame = "window",
    GroupFinderFrame = "window",
    -- Blizzard_GroupFinder_VanillaStyle (Forever/classic), including its tabs.
    LFGParentFrame = "window",
    LFGListingFrame = "window",
    LFGBrowseFrame = "window",
    LFGWhoListFrame = "window",
    -- Blizzard store variants: original storefront and newer catalog UI.
    StoreFrame = "window",
    CatalogShopFrame = "window",
    LegacySystemFrame = "window",
    LegacySystemUI = "window",
    LegacySystemRewardsFrame = "window",
    LegacyRewardsFrame = "window",
    LegacyProgressTrackFrame = "window",
    LegacySystemProgressTrackFrame = "window",
    ProgressTrackFrame = "window",
    AchievementFrame = "window",
    FriendsFrame = "window",
    CompactRaidFrameManager = "window",
    CompactRaidFrameManagerDisplayFrame = "window",
}
for frameName, category in pairs(candidateRoots) do
    ns.Roots[frameName] = category
end

local function safe(v)
    return v ~= nil and (not issecretvalue or not issecretvalue(v))
end
local function objectName(v)
    if not safe(v) or type(v.GetName) ~= "function" then return nil end
    local ok, name = pcall(v.GetName, v)
    if ok and safe(name) and type(name) == "string" then return lower(name) end
end
local function safeParent(v)
    if not safe(v) or type(v.GetParent) ~= "function" then return nil end
    local ok, parent = pcall(v.GetParent, v)
    if ok and safe(parent) then return parent end
end

local function oneOf(atlas, entries)
    return type(atlas) == "string" and entries[lower(atlas)] == true
end
local QUEST_MARKER_ATLASES = {
    ["questpoi-icon"] = true,
    ["questpoi-quest-icon"] = true,
    ["questpoi-questicon"] = true,
    ["quest-questicon"] = true,
    ["quest-normal"] = true,
    ["quest-turnin"] = true,
    ["quest-inprogress"] = true,
    ["quest-questionmark"] = true,
    ["quest-exclamationmark"] = true,
    ["quest-complete"] = true,
}
local QUEST_MARKER_PATHS = {
    ["interface\\worldmap\\ui-questpoi-icons"] = true,
    ["interface\\worldmap\\ui-questpoi-numbericons"] = true,
    ["interface\\questframe\\ui-questpoi-icons"] = true,
}

local function stripExtension(s)
    if type(s) ~= "string" then return "" end
    return s:gsub("%.blp$", ""):gsub("%.tga$", "")
end
local function questMarker(tex, atlas, path)
    -- Only called while traversing the native ObjectiveTracker root. Never
    -- touch map pins, minimap dots, or third-party quest addons.
    if oneOf(atlas, QUEST_MARKER_ATLASES) then return true end
    if QUEST_MARKER_PATHS[stripExtension(path)] then return true end
    if type(atlas) == "string" then
        local a = lower(atlas)
        -- Quest markers may contain multiple layers. Only their static
        -- artwork belongs here: never status glows, hover or selection art.
        if not find(a, "glow", 1, true) and not find(a, "highlight", 1, true)
            and not find(a, "selected", 1, true) and not find(a, "alert", 1, true)
            and (find(a, "^questpoi%-") or find(a, "^quest%-questmarker%-") or
                 find(a, "^ui%-hud%-objectivetracker%-questicon")) then return true end
    end
    -- Explicitly named native tracker marker regions, not other icon frames.
    local name = objectName(tex)
    return name and (find(name, "questobjective", 1, true) or
        find(name, "questpoi", 1, true)) and
        (find(name, "questicon", 1, true) or find(name, "poiicon", 1, true)) or false
end

local CHARACTER_STATS_BACKDROP_ATLASES = {
    -- From Blizzard_UIPanels_Game/Camelot/CharacterFrame.xml.
    -- These are the *two* right-hand panel background layers, not stats text,
    -- category headers, character model, portraits, or item images.
    ["ui-character-info-stat-bg"] = true,
    ["ui-character-info-stat-stonebg3"] = true,
}
local function isStatsBackdrop(tex, atlas)
    local frame = _G.CharacterFrame
    if not safe(frame) then return false end
    local host = frame.RightPaneHost or _G.CharacterFrameRightPaneHost
    if not safe(host) then return false end

    local name = type(atlas) == "string" and lower(atlas) or ""
    if not CHARACTER_STATS_BACKDROP_ATLASES[name] then return false end

    -- Direct descendant of the exact Blizzard character-stats background host.
    -- This deliberately excludes left-side model art and all data rows.
    return safeParent(tex) == host
end

local function isRaidManagerBackground(tex, atlas)
    local manager = _G.CompactRaidFrameManager
    if not safe(manager) or tex ~= manager.Background then return false end
    return type(atlas) == "string" and find(lower(atlas), "^gm%-bgopen%-") ~= nil
end

-- The vanilla-style LFG panels draw this *border* outside NineSlice.
-- Match the exact three texture objects from Blizzard's Forever XML, never
-- their background, role icons, scroll lines, buttons, or search results.
local function isVanillaLFGInnerBorder(tex, atlas)
    if atlas ~= "common-insideframe" then return false end
    local listing = _G.LFGListingFrame
    if safe(listing) and safe(listing.Inset) and
        tex == listing.Inset.Border then return true end
    local browse = _G.LFGBrowseFrame
    if safe(browse) and safe(browse.Inset) and
        tex == browse.Inset.Border then return true end
    local who = _G.LFGWhoListFrame
    return safe(who) and tex == who.insideFrame or false
end

local CHROME_ATLAS = {
    ["ui-dialogbox-border"] = true,
    ["ui-dialogbox-header"] = true,
    ["ui-frame-titletile"] = true,
    ["ui-frame-titletilebg"] = true,
}
local CHROME_PATH = {
    ["interface\\dialogframe\\ui-dialogbox-border"] = true,
    ["interface\\dialogframe\\ui-dialogbox-header"] = true,
    ["interface\\dialogframe\\ui-dialogbox-border-dark"] = true,
    ["interface\\framegeneral\\ui-frame"] = true,
}
local function namedChrome(tex, atlas, path)
    if oneOf(atlas, CHROME_ATLAS) or CHROME_PATH[stripExtension(path)] then return true end
    local name = objectName(tex)
    if not name then return false end
    -- Only exact native decorative region names (not arbitrary matching terms).
    if name == "gamemenuframeborder" or name == "gamemenuframeheader" or
        name == "gamemenuframetitleborder" then return true end
    return false
end

function ns.AdditionalDecorEligibility(tex, category, nineSlice, atlas, path)
    if category == "objective" then
        return questMarker(tex, atlas, path)
    end
    if category == "gameMenu" then
        return namedChrome(tex, atlas, path)
    end
    if category == "window" then
        if isVanillaLFGInnerBorder(tex, atlas) then return true end
        if isStatsBackdrop(tex, atlas) or isRaidManagerBackground(tex, atlas) then return true end
        -- Frame corner/title trim may be separate from the NineSlice, but
        -- require a known art asset: no broad wildcard for unknown windows.
        if type(atlas) == "string" and (
            find(lower(atlas), "^ui%-frame%-titletile") or
            find(lower(atlas), "^ui%-dialogbox%-border")) then return true end
    end
    return false
end

local gryphonFamily = setmetatable({}, {__mode = "k"})
function ns.AdjustGryphonColor(tex, r, g, b)
    if not ColorsForMeDB or ColorsForMeDB.mode ~= "custom" then return r, g, b end
    local amount = ColorsForMeDB.gryphonLift or 0
    if amount <= 0 then return r, g, b end
    local isGryphon = gryphonFamily[tex]
    if isGryphon == nil then
        local atlas = ns.ReadAtlas(tex)
        local a = type(atlas) == "string" and lower(atlas) or ""
        isGryphon = a == "ui-hud-actionbar-gryphon-left" or
            a == "ui-hud-actionbar-gryphon-right" or
            a == "ui-hud-actionbar-wyvern-left" or
            a == "ui-hud-actionbar-wyvern-right"
        gryphonFamily[tex] = isGryphon
    end
    if not isGryphon then return r, g, b end
    -- Raise brightness proportionally without washing the selected hue to gray.
    local brightest = math.max(r, g, b)
    if brightest == 0 then return r, g, b end
    local normalLift = math.min(amount, 1)
    r, g, b = r + (r / brightest - r) * normalLift,
        g + (g / brightest - g) * normalLift,
        b + (b / brightest - b) * normalLift
    local extraLift = math.max(0, math.min(0.5, amount - 1))
    return r + (1 - r) * extraLift,
        g + (1 - g) * extraLift,
        b + (1 - b) * extraLift
end

function ns.SetGryphonLift(v)
    if not ColorsForMeDB then return end
    v = tonumber(v)
    if not v then return end
    v = math.max(0, math.min(1.5, math.floor(v*4+.5)/4))
    if ColorsForMeDB.gryphonLift == v then return end
    ColorsForMeDB.gryphonLift = v
    if ns.RepaintKnownColors then ns.RepaintKnownColors() end
    if ns.RefreshOptions then ns.RefreshOptions() end
end

-- Explicitly called by the addon options and picker only on opening.
function ns.ColorizeOwnWindow(rootName)
    if not ColorsForMeDB or ColorsForMeDB.mode == "reset" or ns.InCombat() then return end
    local frame = _G[rootName]
    if not safe(frame) then return end
    if ns.ScanOne then ns.ScanOne(rootName, "window", false) end
end

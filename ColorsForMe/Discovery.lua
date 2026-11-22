-- Discovery and lifecycle for known Blizzard interface roots.
local addonName, ns = ...

local _G = _G
local type, pairs, ipairs = type, pairs, ipairs
local lower, find = string.lower, string.find
local blocked = ns.InCombat

local function safeObject(v)
    return v ~= nil and (not issecretvalue or not issecretvalue(v))
end

local roots = ns.Roots

local isDecorAtlas = ns.IsDecorAtlas

local readAtlas = ns.ReadAtlas
local eligible = ns.Eligible

-- PERFORMANCE ENGINE (0.3.2)
-- A texture is captured and colored once. Previously discovered textures are
-- NEVER rediscovered on every target change / frame display / color selection.
-- No timers, repeated UI polling or persistent OnUpdate in this engine.
local visited = setmetatable({}, { __mode = "k" })
local scannedRoots = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })
local pending = false
local events = CreateFrame("Frame")
local didHookMeter = false
local initialized = false

local function queueCombatRetry()
    if pending then return end
    pending = true
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local colorEngine = ns.CreateColorEngine(blocked, queueCombatRetry)
local paint, repaintKnown, restoreAll = colorEngine.Paint, colorEngine.RepaintKnown, colorEngine.Restore
ns.RepaintKnownColors = repaintKnown
ns.Restore = restoreAll

-- Traversal is bounded AND each object is visited just once per discovery
-- cycle. Multiple named roots under the same action bar do not rescan it.
local function visit(frame, category, nineSlice, depth, budget, forced)
    if not frame or depth > 8 or budget[1] >= 700 or not safeObject(frame) then return end
    -- Blizzard_MacroUI: MacroFrameTextBackground is a TooltipBackdropTemplate.
    -- Its NineSlice is the macro SCRIPT INPUT background, not window chrome.
    -- Exclude the complete subtree, including its decorative-looking border
    -- slices. The outer MacroFrame NineSlice remains eligible and unchanged.
    if frame == _G.MacroFrameTextBackground then return end
    if not forced and visited[frame] then return end
    if type(frame.GetRegions) ~= "function" then return end
    budget[1] = budget[1] + 1
    visited[frame] = true
    local ok, regions = pcall(function() return {frame:GetRegions()} end)
    if ok and regions then
        for _, region in ipairs(regions) do
            if safeObject(region) then
                local good, yes = pcall(eligible, region, category, nineSlice)
                if good and yes then paint(region, forced) end
            end
        end
    end
    if depth == 8 or type(frame.GetChildren) ~= "function" then return end
    local okChildren, children = pcall(function() return {frame:GetChildren()} end)
    if not okChildren or not children then return end
    for _, child in ipairs(children) do
        if safeObject(child) and child ~= _G.ColorsForMeMinimapButton
            and child ~= _G.ColorsForMeOptions then
            local structural = nineSlice
            if category == "window" or category == "gameMenu" then
                -- Only NineSlice allows structural matching. A full BorderFrame
                -- may contain portraits/icons/active controls.
                local okNine, childNine = pcall(function()
                    if frame.NineSlice == child then return true end
                    -- GameMenu has no portrait: its independent BorderFrame
                    -- contains decoration, unlike generic portrait windows.
                    return category == "gameMenu" and frame.BorderFrame == child
                end)
                structural = structural or (okNine and childNine)
            end
            visit(child, category, structural, depth + 1, budget, forced)
        end
    end
end

local function directWindowDecoration(root, forced)
    -- Named Blizzard decoration outside the NineSlice. No portrait icon art.
    local ok, candidates = pcall(function()
        local title = root.TitleBar or root.TitleContainer
        local portrait = root.PortraitContainer or root.PortraitFrame or root.PortraitBorder
        return {
            root.TopTileStreaks,
            title and (title.Background or title.Bg),
            title and title.Left, title and title.Middle, title and title.Right,
            portrait and portrait.Border,
            root.HeaderLeft, root.HeaderRight, root.Border,
        }
    end)
    if not ok then return end
    for index, tex in pairs(candidates) do
        if safeObject(tex) and type(tex.GetObjectType) == "function" then
            local okType, kind = pcall(tex.GetObjectType, tex)
            if okType and kind == "Texture" then
                local matched, decor = pcall(eligible, tex, "window", false)
                -- Only known stand-alone decoration parents may bypass an
                -- absent atlas name. Never paint a raw portrait or icon.
                if (matched and decor) or (index <= 6) then paint(tex, forced) end
            end
        end
    end
end

-- Forever SharedXML: GameMenuFrame is a MainMenuFrameTemplate, whose
-- ornamental frame is .Border (DialogBorderTemplate), not .BorderFrame.
-- FriendsFrame is a ButtonFrameTemplate; its outer chrome is .NineSlice.
-- Revisit ONLY these two exact decoration containers after OnShow because
-- Blizzard may apply a NineSlice layout after the initial cached root scan.
-- No global frame walk, no new textures and no persistent update callback.
local GAME_MENU_HEADER_TILES = {
    LeftBG = "ui-frame-diamondmetal-header-cornerleft",
    RightBG = "ui-frame-diamondmetal-header-cornerright",
    CenterBG = "_ui-frame-diamondmetal-header-tile",
}
local SOCIAL_BORDER_ATLASES = {
    ["!ui-frame-metal-edgeleft"] = true,
    ["!ui-frame-metal-edgeright"] = true,
    ["_ui-frame-metal-edgetop"] = true,
    ["_ui-frame-metal-edgebottom"] = true,
    ["ui-frame-metal-cornertopright"] = true,
    ["ui-frame-metal-cornerbottomleft"] = true,
    ["ui-frame-metal-cornerbottomright"] = true,
    ["ui-frame-portraitmetal-cornertopleft"] = true,
}
local function paintTargetChrome(rootName, forced)
    if rootName ~= "GameMenuFrame" and rootName ~= "FriendsFrame" and rootName ~= "SocialUIFrame" then return end
    if not ColorsForMeDB or ColorsForMeDB.mode == "reset" then return end
    if blocked() then queueCombatRetry(); return end
    local root = _G[rootName]
    if not safeObject(root) then return end

    local ok, border, header = pcall(function()
        if rootName == "GameMenuFrame" then return root.Border, root.Header end
        return root.NineSlice, nil
    end)
    if not ok or not safeObject(border) or type(border.GetRegions) ~= "function" then return end

    -- These are exclusive Blizzard border hosts. The dialog's Bg is an actual
    -- content background and must stay untouched; so must the Friends portrait.
    local bgOK, background = pcall(function() return border.Bg end)
    if not bgOK then background = nil end
    local centerOK, center = pcall(function() return border.Center end)
    if not centerOK then center = nil end
    local got, regions = pcall(function() return {border:GetRegions()} end)
    if got and regions then
        for _, tex in ipairs(regions) do
            if safeObject(tex) and tex ~= background and tex ~= center
                and type(tex.GetObjectType) == "function" then
                local okType, kind = pcall(tex.GetObjectType, tex)
                if okType and kind == "Texture" then
                    local atlas = rootName == "SocialUIFrame" and readAtlas(tex)
                    if rootName ~= "SocialUIFrame" or (type(atlas) == "string" and SOCIAL_BORDER_ATLASES[lower(atlas)]) then
                        paint(tex, forced)
                    end
                end
            end
        end
    end

    -- In Forever the three header tiles use distinct DiamondMetal atlases,
    -- outside the border NineSlice. Never touch header text or menu buttons.
    if rootName == "GameMenuFrame" and safeObject(header) then
        for key, atlasName in pairs(GAME_MENU_HEADER_TILES) do
            local okTex, tex = pcall(function() return header[key] end)
            if okTex and safeObject(tex) then
                local atlas = readAtlas(tex)
                if type(atlas) == "string" and lower(atlas) == atlasName then
                    paint(tex, forced)
                end
            end
        end
    end
end

local function scanOne(rootName, category, forced)
    if blocked() then queueCombatRetry(); return false end
    local root = _G[rootName]
    if not root or not safeObject(root) or type(root.GetRegions) ~= "function" then return false end
    if not forced and scannedRoots[root] then return true end
    -- The same object might already have been visited as a child of another
    -- root before it became a visible, independent window/button.
    local rescan = forced or (visited[root] and not scannedRoots[root])
    if category ~= "social" then visit(root, category, false, 0, {0}, rescan) end
    if category == "window" or category == "gameMenu" then
        directWindowDecoration(root, forced)
    end
    paintTargetChrome(rootName, forced)
    scannedRoots[root] = true
    return true
end
ns.ScanOne = scanOne

-- TradeFrame.xml (Forever): these are three distinct ORIGINAL Blizzard
-- decorative textures, not the recipient's portrait. No texture replacement.
-- They live outside the inherited window NineSlice and are missed by its scan.
local function paintTradeRecipientTrim(forced)
    if not ColorsForMeDB or ColorsForMeDB.mode == "reset" then return end
    if blocked() then queueCombatRetry(); return end
    local trade = _G.TradeFrame
    if not safeObject(trade) then return end

    -- TradeFrame.RecipientOverlay.portraitFrame is the bronze portrait RING.
    -- The adjacent portrait texture is trade.RecipientOverlay.portrait and
    -- must NEVER be recolored.
    local ok, ring = pcall(function()
        return trade.RecipientOverlay and trade.RecipientOverlay.portraitFrame
    end)
    if ok and safeObject(ring) then
        local okType, kind = pcall(ring.GetObjectType, ring)
        if okType and kind == "Texture" then paint(ring, forced) end
    end

    -- Native vertical divider and its bottom corner; verified in Forever's
    -- Blizzard_UIPanels_Game/Mainline/TradeFrame.xml.
    for _, name in ipairs({"TradeRecipientLeftBorder", "TradeRecipientBotLeftCorner"}) do
        local tex = _G[name]
        if safeObject(tex) and type(tex.GetObjectType) == "function" then
            local okType, kind = pcall(tex.GetObjectType, tex)
            if okType and kind == "Texture" then paint(tex, forced) end
        end
    end
end

local function paintTargetLevelCircle(rootName, forced)
    if not ColorsForMeDB or ColorsForMeDB.mode == "reset" then return end
    if blocked() then queueCombatRetry(); return end
    local ok, circle = pcall(function()
        local frame = _G[rootName]
        local content = frame and frame.TargetFrameContent
        local main = content and content.TargetFrameContentMain
        return main and main.LevelBackgroundCircle
    end)
    if not ok or not safeObject(circle) then return end
    local atlas = readAtlas(circle)
    if type(atlas) == "string" and lower(atlas) == "ui-hud-unitframe-smallcircle" then
        paint(circle, forced)
    end
end

-- Exact independent art named by Blizzard unit frame templates, NOT portraits.
local function paintDirectDeco(forced)
    if blocked() then queueCombatRetry(); return end
    if not ColorsForMeDB or ColorsForMeDB.mode == "reset" then return end
    for _, name in ipairs({"TargetFrame", "FocusFrame", "PlayerFrame"}) do
        local f = _G[name]
        if safeObject(f) then
            local ok, tex = pcall(function()
                local container = f.TargetFrameContainer or f.PlayerFrameContainer
                return container and container.FrameTexture
            end)
            if ok and safeObject(tex) then
                local typeOK, kind = pcall(tex.GetObjectType, tex)
                if typeOK and kind == "Texture" then paint(tex, forced) end
            end
        end
    end
    paintTargetLevelCircle("TargetFrame", forced)
    paintTargetLevelCircle("FocusFrame", forced)
    -- The level and PvP circles can share an atlas; only the level object is decor.
    local okLevel, levelCircle = pcall(function()
        local content = _G.PlayerFrame and _G.PlayerFrame.PlayerFrameContent
        local main = content and content.PlayerFrameContentMain
        return main and main.LevelBackgroundCircle
    end)
    if okLevel and safeObject(levelCircle) then
        local atlas = readAtlas(levelCircle)
        if type(atlas) == "string" and lower(atlas) == "ui-hud-unitframe-smallcircle" then
            paint(levelCircle, forced)
        end
    end
    -- DielFrame's border is separate from its day/night indicator texture.
    local okDiel, diel = pcall(function()
        return _G.MinimapCluster and _G.MinimapCluster.DielFrame
    end)
    if okDiel and safeObject(diel) then
        local okRegions, regions = pcall(function()
            if type(diel.IsForbidden) == "function" and diel:IsForbidden() then return {} end
            return {diel:GetRegions()}
        end)
        if okRegions then
            for _, tex in ipairs(regions) do
                if safeObject(tex) then
                    local atlas = readAtlas(tex)
                    if type(atlas) == "string" and lower(atlas) == "ui-hud-minimap-frame-cycle" then
                        paint(tex, forced)
                    end
                end
            end
        end
    end
    -- The addon compartment's plain plate is separate from its text and states.
    local compartment = _G.AddonCompartmentFrame
    if safeObject(compartment) then
        local ok, normal, pushed, highlight = pcall(function()
            if type(compartment.IsForbidden) == "function" and compartment:IsForbidden() then return end
            return compartment:GetNormalTexture(), compartment:GetPushedTexture(), compartment:GetHighlightTexture()
        end)
        if ok and safeObject(normal) and normal ~= pushed and normal ~= highlight then
            local atlas = readAtlas(normal)
            if type(atlas) == "string" and lower(atlas) == "ui-hud-minimap-button" then
                paint(normal, forced)
            end
        end
    end
    -- Exact Blizzard_CompactRaidFrames background/outer trim.
    -- The GM-bgOpen atlas varies with group role; never touch marker buttons,
    -- pings, dropdowns, status art, or any protected raid unit elements.
    local manager = _G.CompactRaidFrameManager
    if safeObject(manager) then
        local ok, bg = pcall(function() return manager.Background end)
        if ok and safeObject(bg) then
            local atlas = readAtlas(bg)
            if type(atlas) == "string" and
                (find(lower(atlas), "^gm%-bgopen%-") ~= nil) then
                local okType, kind = pcall(bg.GetObjectType, bg)
                if okType and kind == "Texture" then paint(bg, forced) end
            end
        end
    end
    local compass = _G.MinimapCompassTexture
    if safeObject(compass) then
        local atlas = readAtlas(compass)
        if isDecorAtlas(atlas, "minimap", false) then
            paint(compass, forced)
        end
    end
    -- Only known trade DECORATION; never paint portrait content or items.
    paintTradeRecipientTrim(forced)
end

local function isDisplayed(frame)
    if not frame or type(frame.IsVisible) ~= "function" then return false end
    local ok, visible = pcall(frame.IsVisible, frame)
    return ok and safeObject(visible) and visible == true
end

-- Secure OnShow hooks only on whole windows/bars or individual dynamically
-- created aura buttons. Callback is O(1) after the first discovery.
local function canWatch(name, category)
    if category == "window" or category == "gameMenu" or category == "social" or category == "damage"
        or category == "unitframe" or category == "objective" then return true end
    if category == "bar" then
        if find(name, "^BuffButton%d+$") or find(name, "^DebuffButton%d+$")
            or find(name, "^TemporaryEnchantFrameBuff%d+$") then return true end
        -- A bar container may be shown later via Edit Mode. Do not hook
        -- individual action buttons, which frequently change visibility.
        return not find(name, "Button%d+$")
    end
    return false
end

local function watchRoot(rootName, category, frame)
    if hooked[frame] or not canWatch(rootName, category) then return end
    if type(frame.HookScript) ~= "function" then return end
    local ok = pcall(frame.HookScript, frame, "OnShow", function()
        if rootName == "TargetFrame" or rootName == "FocusFrame" then
            paintTargetLevelCircle(rootName, false)
        end
        -- This is constant-time and occurs only when the TRADE window opens.
        -- The original scanner intentionally caches windows; these three
        -- outside-NineSlice textures need an explicit first-appearance check.
        if rootName == "TradeFrame" then paintTradeRecipientTrim(false) end
        -- Exact, bounded chrome refresh; bypass the cached root-tree visit.
        -- forced re-reads tint only for these few pieces if Blizzard reset it.
        if rootName == "GameMenuFrame" or rootName == "FriendsFrame" or rootName == "SocialUIFrame" then
            paintTargetChrome(rootName, true)
        end
        if scannedRoots[frame] or not ColorsForMeDB
            or ColorsForMeDB.mode == "reset" then return end
        if blocked() then
            queueCombatRetry()
        else
            pcall(scanOne, rootName, category, false)
        end
    end)
    if ok then hooked[frame] = true end
end

local function discoverOne(rootName, category, forced)
    local frame = _G[rootName]
    if not frame or not safeObject(frame) then return end
    -- Blizzard_StoreUI declares StoreFrame forbidden. Do not inspect or hook
    -- either storefront when the client marks it inaccessible to addons.
    if rootName == "StoreFrame" or rootName == "CatalogShopFrame" or rootName == "SocialUIFrame" then
        local ok, forbidden = pcall(function()
            return type(frame.IsForbidden) == "function" and frame:IsForbidden()
        end)
        if not ok or forbidden then return end
    end
    if type(frame.GetRegions) ~= "function" then return end
    watchRoot(rootName, category, frame)
    if ColorsForMeDB and ColorsForMeDB.mode ~= "reset" and isDisplayed(frame) then
        if forced or not scannedRoots[frame] then scanOne(rootName, category, forced) end
    end
end

local function discoverAvailable(forced)
    if not initialized or not ColorsForMeDB then return end
    if blocked() then queueCombatRetry(); return end
    for name, category in pairs(roots) do
        discoverOne(name, category, forced)
    end
    paintDirectDeco(forced)
end

local function ensureMeterHook()
    if didHookMeter or not hooksecurefunc or not _G.DamageMeterMixin
        or type(_G.DamageMeterMixin.SetupSessionWindow) ~= "function" then return end
    local ok = pcall(hooksecurefunc, _G.DamageMeterMixin, "SetupSessionWindow", function()
        -- Unlike 0.3.1: NO full applyAll() on each session update.
        -- Only find the six known native session roots, and each is scanned
        -- once; subsequent callbacks are a few table lookups.
        if not ColorsForMeDB or ColorsForMeDB.mode == "reset" then return end
        if blocked() then queueCombatRetry(); return end
        for i = 1, 6 do
            local name = "DamageMeterSessionWindow" .. i
            discoverOne(name, "damage", false)
        end
    end)
    if ok then didHookMeter = true end
end

local function applyAll(forced)
    if not ColorsForMeDB then return end
    if blocked() then queueCombatRetry(); return end
    if pending then
        pending = false
        events:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
    if ColorsForMeDB.mode == "reset" then
        restoreAll()
        return
    end
    ensureMeterHook()
    discoverAvailable(forced == true)
    repaintKnown()
end

-- Manual /scan intentionally rescans visible Blizzard frames. Normal use
-- takes the cheap cached path instead.
ns.ApplyAll = function() applyAll(true) end

ns.SetMode = ns.CreateModeController(blocked, queueCombatRetry, discoverAvailable, repaintKnown, restoreAll)

function ns.GetStats()
    return colorEngine.GetCount(), ColorsForMeDB and ColorsForMeDB.mode or "uninitialized", pending
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            ns.InitSaved()
        elseif initialized and type(arg1) == "string" and find(arg1, "^Blizzard_") then
            -- Only NEW visible Blizzard windows; no repaint of old roots.
            discoverAvailable(false)
            ensureMeterHook()
        end
    elseif event == "PLAYER_LOGIN" then
        initialized = true
        applyAll(false)
    elseif event == "PLAYER_REGEN_ENABLED" and pending then
        applyAll(false)
    end
end)

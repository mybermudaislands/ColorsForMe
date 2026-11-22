local test, mock = ...

local function fixture(saved)
    local state = mock.create()
    local root = state:root("MainActionBar")
    local trim = mock.texture("ui-hud-actionbar-frame")
    local icon = mock.texture("ui-hud-actionbar-icon")
    root.regions = {trim, icon}
    state:load(saved)
    return state, root, trim, icon
end

test("missing saved variables initialize classic defaults", function()
    local state = fixture()
    assert(state.env.ColorsForMeDB.mode == "classic")
    assert(state.env.ColorsForMeDB.custom.r == 0.65)
    assert(state.env.ColorsForMeDB.minimapAngle == 140)
end)

test("partial saved variables are repaired", function()
    local state = fixture({mode = "custom", custom = {r = 0.2}})
    assert(state.env.ColorsForMeDB.custom.r == 0.2)
    assert(state.env.ColorsForMeDB.custom.g == 0.65)
end)

test("valid saved settings survive initialization", function()
    local state = fixture({mode = "custom", custom = {r = 0.1, g = 0.2, b = 0.3}, minimapAngle = 45})
    assert(state.env.ColorsForMeDB.mode == "custom")
    assert(state.env.ColorsForMeDB.custom.g == 0.2 and state.env.ColorsForMeDB.minimapAngle == 45)
end)

test("classic custom and reset preserve original alpha and color", function()
    local state, _, tex, icon = fixture()
    assert(tex.desat == 1 and tex.color[1] == 1 and tex.color[4] == 0.4)
    assert(icon.colorWrites == 0 and icon.desatWrites == 0)
    state.ns.SetMode("custom", {r = 0.2, g = 0.3, b = 0.4})
    assert(tex.color[1] == 0.2 and tex.color[2] == 0.3 and tex.color[3] == 0.4 and tex.color[4] == 0.4)
    assert(tex.desatWrites == 1)
    state.ns.SetMode("reset")
    assert(tex.color[1] == 0.8 and tex.color[2] == 0.7 and tex.color[3] == 0.6 and tex.color[4] == 0.4)
    assert(tex.desat == 0.2)
end)

test("gryphon relief brightens custom tint without losing hue and restores originals", function()
    local state = mock.create()
    local root = state:root("MainActionBar")
    local wyvern = mock.texture("ui-hud-actionbar-wyvern-left")
    local gryphon = mock.texture("ui-hud-actionbar-gryphon-right")
    local trim = mock.texture("ui-hud-actionbar-frame")
    root.regions = {wyvern, gryphon, trim}
    state:load({mode = "custom", custom = {r = 0.2, g = 0.5, b = 0.1}, gryphonLift = 0})
    state.ns.SetGryphonLift(0.5)
    assert(math.abs(wyvern.color[1] - 0.3) < 0.000001)
    assert(math.abs(wyvern.color[2] - 0.75) < 0.000001)
    assert(math.abs(wyvern.color[3] - 0.15) < 0.000001)
    state.ns.SetGryphonLift(1)
    assert(math.abs(wyvern.color[1] - 0.4) < 0.000001 and wyvern.color[2] == 1)
    assert(math.abs(wyvern.color[3] - 0.2) < 0.000001 and wyvern.desat == 1)
    assert(math.abs(gryphon.color[1] - 0.4) < 0.000001 and gryphon.color[2] == 1)
    assert(trim.color[1] == 0.2 and trim.color[2] == 0.5 and trim.color[3] == 0.1)
    state.ns.SetMode("custom", {r = 0, g = 0, b = 0})
    assert(wyvern.color[1] == 0 and wyvern.color[2] == 0 and wyvern.color[3] == 0)
    state.ns.SetMode("reset")
    assert(wyvern.color[1] == 0.8 and wyvern.color[2] == 0.7 and wyvern.color[3] == 0.6)
    assert(wyvern.desat == 0.2 and wyvern.color[4] == 0.4)
end)

test("gryphon relief handles extremely dark nonzero colors", function()
    local state = mock.create()
    local root = state:root("MainActionBar")
    local wyvern = mock.texture("ui-hud-actionbar-wyvern-right")
    root.regions = {wyvern}
    state:load({mode = "custom", custom = {r = 0, g = 1e-320, b = 0}, gryphonLift = 1})
    assert(wyvern.color[1] == 0 and wyvern.color[2] == 1 and wyvern.color[3] == 0)
end)

test("extended gryphon relief adds lighter tint while preserving existing levels", function()
    local state = mock.create()
    local root = state:root("MainActionBar")
    local wyvern = mock.texture("ui-hud-actionbar-wyvern-left")
    local gryphon = mock.texture("ui-hud-actionbar-gryphon-right")
    local trim = mock.texture("ui-hud-actionbar-frame")
    root.regions = {wyvern, gryphon, trim}
    state:load({mode = "custom", custom = {r = 0.2, g = 0.5, b = 0.1}, gryphonLift = 1})
    state.ns.SetGryphonLift(1.25)
    assert(state.env.ColorsForMeDB.gryphonLift == 1.25)
    assert(math.abs(wyvern.color[1] - 0.55) < 0.000001 and wyvern.color[2] == 1)
    assert(math.abs(wyvern.color[3] - 0.4) < 0.000001)
    state.ns.SetGryphonLift(1.5)
    assert(math.abs(wyvern.color[1] - 0.7) < 0.000001 and wyvern.color[2] == 1)
    assert(math.abs(wyvern.color[3] - 0.6) < 0.000001)
    assert(math.abs(gryphon.color[1] - 0.7) < 0.000001)
    assert(trim.color[1] == 0.2 and trim.color[2] == 0.5 and trim.color[3] == 0.1)
    state.ns.SetGryphonLift(2)
    assert(state.env.ColorsForMeDB.gryphonLift == 1.5)
    state.ns.SetMode("reset")
    assert(wyvern.color[1] == 0.8 and wyvern.desat == 0.2)
end)

test("repeated custom selection performs no texture writes or scans", function()
    local state, root, tex = fixture()
    state.ns.SetMode("custom", {r = 0.1, g = 0.2, b = 0.3})
    local writes, reads = tex.colorWrites, root.regionReads
    state.ns.SetMode("custom", {r = 0.1, g = 0.2, b = 0.3})
    assert(tex.colorWrites == writes and root.regionReads == reads)
end)

test("combat defers latest mode and restores after combat", function()
    local state, _, tex = fixture()
    state:setCombat(true)
    state.ns.SetMode("custom", {r = 0.1, g = 0.2, b = 0.3})
    assert(tex.color[1] == 1)
    state:setCombat(false)
    state:event("PLAYER_REGEN_ENABLED")
    assert(tex.color[1] == 0.1)
    state:setCombat(true)
    state.ns.SetMode("reset")
    assert(tex.color[1] == 0.1)
    state:setCombat(false)
    state:event("PLAYER_REGEN_ENABLED")
    assert(tex.color[1] == 0.8 and tex.desat == 0.2)
end)

test("minimap button drag only uses OnUpdate during drag", function()
    local state = fixture()
    local button = assert(state.env.ColorsForMeMinimapButton)
    assert(button.scripts.OnUpdate == nil)
    button.scripts.OnDragStart(button)
    assert(type(button.scripts.OnUpdate) == "function")
    button.scripts.OnDragStop(button)
    assert(button.scripts.OnUpdate == nil)
end)

test("slash commands remain registered", function()
    local state = fixture()
    assert(state.env.SLASH_COLORSFORME1 == "/forevercolor")
    assert(state.env.SLASH_COLORSFORME2 == "/cfm")
    assert(type(state.env.SlashCmdList.COLORSFORME) == "function")
end)

test("addon compartment opens settings without closing an already open window", function()
    local toc = assert(io.open("ColorsForMe/ColorsForMe.toc", "r"))
    local manifest = toc:read("*a")
    toc:close()
    local handler = manifest:match("##%s*AddonCompartmentFunc:%s*([^%s]+)")
    assert(handler, "addon compartment handler is missing from the manifest")
    local state = fixture()
    local click = assert(state.env[handler], "addon compartment handler is missing")
    click("ColorsForMe", "LeftButton")
    local panel = assert(state.env.ColorsForMeOptions)
    assert(panel:IsShown(), "addon compartment must open settings")
    click("ColorsForMe", "LeftButton")
    assert(panel:IsShown(), "repeated clicks must not close settings")
    state.ns.ToggleOptions()
    assert(not panel:IsShown(), "existing toggle must still close settings")
end)

test("addon compartment uses the existing minimap icon", function()
    local toc = assert(io.open("ColorsForMe/ColorsForMe.toc", "r"))
    local manifest = toc:read("*a")
    toc:close()
    local iconPath = manifest:match("##%s*IconTexture:%s*([^%s]+)")
    local state = fixture()
    local minimapIcon = assert(state.env.ColorsForMeMinimapButton.regions[1].path)
    assert(iconPath == minimapIcon, "compartment icon must match the minimap icon")
    local file = assert(io.open("ColorsForMe/ColorWheel.tga", "rb"))
    file:close()
end)

test("login is silent while explicit status command still responds", function()
    local state = mock.create()
    local messages = {}
    state.env.DEFAULT_CHAT_FRAME.AddMessage = function(_, text) table.insert(messages, text) end
    state:load()
    assert(#messages == 0, "login must not print an addon message")
    state.env.SlashCmdList.COLORSFORME("status")
    assert(#messages == 1 and messages[1]:find("Mode=", 1, true))
end)

test("probe distinguishes unnamed border hosts without changing textures", function()
    local state = mock.create()
    local root = state:root("FriendsFrame")
    local first = state.env.CreateFrame("Frame", nil, root)
    local second = state.env.CreateFrame("Frame", nil, root)
    first.visible, second.visible = true, false
    local visible = mock.texture("ui-frame-metal-edgetop")
    local hidden = mock.texture("ui-frame-metal-edgetop")
    visible.GetRect = function() return 10, 20, 300, 5 end
    hidden.GetRect = function() error("not available") end
    first.regions, second.regions = {visible}, {hidden}
    state:load({mode = "reset"})
    state.ns.Probe("FriendsFrame")
    local entries = state.env.ColorsForMeDB.lastProbe.entries
    assert(#entries == 2)
    local byPath = {}
    for _, entry in ipairs(entries) do
        assert(entry.framePath, "probe must record a host path")
        byPath[entry.framePath] = entry
    end
    local a, b = byPath["FriendsFrame/1"], byPath["FriendsFrame/2"]
    assert(a and b, "probe must identify unnamed hosts separately")
    assert(a.visible == true and b.visible == false)
    assert(a.rect and a.rect.left == 10 and a.rect.bottom == 20
        and a.rect.width == 300 and a.rect.height == 5)
    assert(b.rect == nil)
    assert(visible.colorWrites == 0 and hidden.colorWrites == 0)
end)

test("targeted probes retain separate read-only reports for observed interface roots", function()
    local state = mock.create()
    local names = {"SocialUIFrame", "MinimapCluster", "PlayerFrame"}
    local textures = {}
    for _, name in ipairs(names) do
        local root = state:root(name)
        local tex = mock.texture("unclassified-art")
        root.regions = {tex}
        textures[name] = tex
    end
    state:load({mode = "reset"})
    assert(state.ns.Roots.SocialUIFrame == "social", "social root must use its restricted handler")
    for _, name in ipairs(names) do state.ns.Probe(name) end
    local reports = assert(state.env.ColorsForMeDB.lastTargetProbes, "targeted reports were not retained")
    for _, name in ipairs(names) do
        local report = assert(reports[name], "missing report for " .. name)
        assert(report.scannedRoots == 1 and #report.entries == 1)
        assert(report.entries[1].root == name and report.entries[1].atlas == "unclassified-art")
        assert(textures[name].colorWrites == 0 and textures[name].desatWrites == 0)
    end
    assert(state.env.ColorsForMeDB.lastProbe == reports.PlayerFrame)
end)

test("options title is centered and probe remains a command but not visible text", function()
    local state = fixture()
    state.ns.ToggleOptions()
    local panel = assert(state.env.ColorsForMeOptions)
    assert(panel.TitleText.text == "ColorsForMe", "title must not include the author")
    assert(panel.TitleText.point[1] == "TOP" and panel.TitleText.point[2] == panel
        and panel.TitleText.point[3] == "TOP", "title must be centered on the window")
    assert(panel.TitleText.justify == "CENTER")
    for _, font in ipairs(panel.fonts) do
        assert(not (font.text or ""):find("/forevercolor probe", 1, true))
    end
    local target
    state.ns.Probe = function(value) target = value end
    state.env.SlashCmdList.COLORSFORME("probe FriendsFrame")
    assert(target == "FriendsFrame")
end)

test("hidden window is scanned once when shown", function()
    local state = mock.create()
    local root = state:root("CharacterFrame")
    root.visible = false
    local tex = mock.texture("ui-frame-topcornerright")
    root.regions = {tex}
    state:load()
    assert(tex.colorWrites == 0)
    root:Show()
    assert(tex.colorWrites == 1)
    local reads = root.regionReads
    root:Hide()
    root:Show()
    assert(root.regionReads == reads)
end)

test("social outer border changes without recoloring functional artwork", function()
    local state = mock.create()
    local root = state:root("SocialUIFrame")
    root.visible = false
    local border = state.env.CreateFrame("Frame", nil, root)
    root.NineSlice = border
    local edge = mock.texture("!UI-Frame-Metal-EdgeLeft")
    local corner = mock.texture("UI-Frame-PortraitMetal-CornerTopLeft")
    local center = mock.texture("other-background")
    local icon = mock.texture("social-friend-icon")
    local unrelated = mock.texture("!UI-Frame-Metal-EdgeLeft")
    border.regions = {edge, corner, center}
    root.regions = {icon, unrelated}
    state:load()
    assert(edge.colorWrites == 0)
    root:Show()
    assert(edge.colorWrites == 1 and corner.colorWrites == 1, "social border was not colored")
    assert(center.colorWrites == 0 and icon.colorWrites == 0 and unrelated.colorWrites == 0)
    state.ns.SetMode("custom", {r = 0.2, g = 0.5, b = 0.1})
    assert(edge.color[1] == 0.2 and edge.color[2] == 0.5)
    state:setCombat(true)
    state.ns.SetMode("reset")
    assert(edge.color[1] == 0.2)
    state:setCombat(false)
    state:event("PLAYER_REGEN_ENABLED")
    assert(edge.color[1] == 0.8 and edge.desat == 0.2)
    assert(center.colorWrites == 0 and icon.colorWrites == 0 and unrelated.colorWrites == 0)
end)

test("player level circle changes but identical pvp circle does not", function()
    local state = mock.create()
    local root = state:root("PlayerFrame")
    local content = state.env.CreateFrame("Frame", nil, root)
    local main = state.env.CreateFrame("Frame", nil, content)
    root.PlayerFrameContent = content
    content.PlayerFrameContentMain = main
    local level = mock.texture("UI-HUD-UnitFrame-SmallCircle")
    local pvp = mock.texture("UI-HUD-UnitFrame-SmallCircle")
    main.LevelBackgroundCircle = level
    main.PvpBackgroundCircle = pvp
    main.regions = {level, pvp}
    state:load()
    assert(level.colorWrites == 1, "player level background was not colored")
    assert(pvp.colorWrites == 0)
    state.ns.SetMode("custom", {r = 0.2, g = 0.5, b = 0.1})
    assert(level.color[1] == 0.2 and level.color[2] == 0.5)
    state:setCombat(true)
    state.ns.SetMode("reset")
    assert(level.color[1] == 0.2)
    state:setCombat(false)
    state:event("PLAYER_REGEN_ENABLED")
    assert(level.color[1] == 0.8 and level.desat == 0.2 and pvp.colorWrites == 0)
end)

test("target and focus level circles recolor without changing pvp artwork", function()
    local state = mock.create()
    local objects = {}
    for _, name in ipairs({"TargetFrame", "FocusFrame"}) do
        local root = state:root(name)
        root.visible = false
        local content = state.env.CreateFrame("Frame", nil, root)
        local main = state.env.CreateFrame("Frame", nil, content)
        root.TargetFrameContent = content
        content.TargetFrameContentMain = main
        local level = mock.texture("UI-HUD-UnitFrame-SmallCircle")
        local pvp = mock.texture("UI-HUD-UnitFrame-SmallCircle")
        main.LevelBackgroundCircle = level
        main.regions = {level, pvp}
        objects[name] = {root = root, level = level, pvp = pvp}
    end
    state:load({mode = "reset"})
    state.ns.SetMode("custom", {r = 0.2, g = 0.5, b = 0.1})
    for _, obj in pairs(objects) do
        obj.root:Show()
        assert(obj.level.color[1] == 0.2, "level circle was not colored")
        assert(obj.pvp.colorWrites == 0)
    end
    state:setCombat(true)
    state.ns.SetMode("reset")
    state:setCombat(false)
    state:event("PLAYER_REGEN_ENABLED")
    for _, obj in pairs(objects) do
        assert(obj.level.color[1] == 0.8 and obj.level.desat == 0.2)
        assert(obj.pvp.colorWrites == 0)
    end
end)

test("day night border changes without recoloring its indicator", function()
    local state = mock.create()
    local cluster = state:root("MinimapCluster")
    local diel = state.env.CreateFrame("Frame", nil, cluster)
    cluster.DielFrame = diel
    local border = mock.texture("UI-HUD-Minimap-Frame-Cycle")
    local day = mock.texture("UI-HUD-Minimap-DayCycle")
    local other = mock.texture("UI-HUD-Minimap-Frame-Cycle")
    diel.regions = {border, day}
    cluster.regions = {other}
    state:load()
    assert(border.colorWrites == 1, "day night border was not colored")
    assert(day.colorWrites == 0 and other.colorWrites == 0)
    state.ns.SetMode("custom", {r = 0.2, g = 0.5, b = 0.1})
    assert(border.color[1] == 0.2 and border.color[2] == 0.5)
    state.ns.SetMode("reset")
    assert(border.color[1] == 0.8 and border.desat == 0.2)
    assert(day.colorWrites == 0 and other.colorWrites == 0)
end)

test("addon compartment normal plate changes without touching button states", function()
    local state = mock.create()
    local button = state:root("AddonCompartmentFrame")
    local normal = mock.texture("ui-hud-minimap-button")
    local pushed = mock.texture("ui-hud-minimap-button-down")
    local highlight = mock.texture("UI-Common-MouseHilight")
    button.GetNormalTexture = function() return normal end
    button.GetPushedTexture = function() return pushed end
    button.GetHighlightTexture = function() return highlight end
    state:load()
    assert(normal.colorWrites == 1, "addon compartment plate was not colored")
    assert(pushed.colorWrites == 0 and highlight.colorWrites == 0)
    state.ns.SetMode("custom", {r = 0.2, g = 0.5, b = 0.1})
    assert(normal.color[1] == 0.2 and normal.color[2] == 0.5)
    state.ns.SetMode("reset")
    assert(normal.color[1] == 0.8 and normal.desat == 0.2)
    assert(pushed.colorWrites == 0 and highlight.colorWrites == 0)
end)

test("load on demand window is discovered", function()
    local state = mock.create()
    state:load()
    local root = state:root("CharacterFrame")
    local tex = mock.texture("ui-frame-topcornerright")
    root.regions = {tex}
    state:event("ADDON_LOADED", "Blizzard_CharacterUI")
    assert(tex.colorWrites == 1)
end)

test("forbidden store is not traversed", function()
    local state = mock.create()
    local root = state:root("StoreFrame")
    root.IsForbidden = function() return true end
    root.regions = {mock.texture("ui-frame-topcornerright")}
    state:load()
    assert(root.regionReads == 0 and root.regions[1].colorWrites == 0)
end)

test("picker cancel restores mode and ignores late change callbacks", function()
    local state = fixture()
    local picker = state.env.CreateFrame("Frame", "ColorPickerFrame")
    picker.SetupColorPickerAndShow = function(self, info) self.info = info end
    picker.GetColorRGB = function() return 0.1, 0.2, 0.3 end
    state.ns.OpenPicker()
    picker.info.swatchFunc()
    assert(state.env.ColorsForMeDB.mode == "custom")
    picker.info.cancelFunc()
    assert(state.env.ColorsForMeDB.mode == "classic")
    assert(state.env.ColorsForMeDB.custom.r == 0.65)
    picker.info.swatchFunc()
    assert(state.env.ColorsForMeDB.mode == "classic")
    local old = picker.info
    state.ns.OpenPicker()
    old.swatchFunc()
    assert(state.env.ColorsForMeDB.mode == "classic")
    picker.info.swatchFunc()
    assert(state.env.ColorsForMeDB.mode == "custom")
end)

test("inaccessible texture methods do not crash discovery", function()
    local state = mock.create()
    local root = state:root("MainActionBar")
    local tex = mock.texture("ui-hud-actionbar-frame")
    tex.GetVertexColor = function() error("unavailable") end
    root.regions = {tex}
    state:load()
    assert(tex.colorWrites == 0 and tex.desatWrites == 0)
end)

test("eligibility separates verified decoration from functional artwork", function()
    local state = fixture()
    local samples = {
        {"ui-hud-unitframe-player-portraiton", "unitframe", true},
        {"ui-hud-unitframe-player-healthbar", "unitframe", false},
        {"ui-hud-minimap-frame", "minimap", true},
        {"ui-hud-minimap-tracking-icon", "minimap", false},
        {"ui-hud-micromenu-buttonbg-up", "micromenu", true},
        {"ui-hud-micromenu-character", "micromenu", false},
        {"ui-damagemeters-header-bar", "damage", true},
        {"ui-damagemeters-icon", "damage", false},
        {"ui-frame-topcornerright", "window", true},
        {"ui-frame-portrait-texture", "window", false},
    }
    for _, sample in ipairs(samples) do
        assert(state.ns.Eligible(mock.texture(sample[1]), sample[2], false) == sample[3], sample[1])
    end
end)

test("known roots load from dedicated module before core", function()
    local toc = assert(io.open("ColorsForMe/ColorsForMe.toc", "r"))
    local manifest = toc:read("*a")
    toc:close()
    local rootsPos = assert(manifest:find("Roots.lua", 1, true), "Roots.lua is not in the manifest")
    local corePos = assert(manifest:find("Core.lua", 1, true))
    assert(rootsPos < corePos)
    local state = fixture()
    assert(state.ns.Roots.MainActionBar == "bar")
    assert(state.ns.Roots.ColorPickerFrame == "window")
    assert(state.ns.Roots.GameMenuFrame == "gameMenu")
    assert(state.ns.Roots.ActionButton12 == "bar")
    assert(state.ns.Roots.BuffButton40 == "bar")
    assert(state.ns.Roots.ContainerFrame13 == "window")
end)

test("saved variable initialization loads from settings module", function()
    local toc = assert(io.open("ColorsForMe/ColorsForMe.toc", "r"))
    local manifest = toc:read("*a")
    toc:close()
    local settingsPos = assert(manifest:find("Settings.lua", 1, true), "Settings.lua is not in the manifest")
    assert(settingsPos < assert(manifest:find("Core.lua", 1, true)))
    local state = fixture({mode = "invalid", custom = {r = 2, g = -1, b = 0.4}, minimapAngle = 0 / 0})
    assert(state.env.ColorsForMeDB.mode == "classic")
    assert(state.env.ColorsForMeDB.custom.r == 0.65)
    assert(state.env.ColorsForMeDB.custom.g == 0.65)
    assert(state.env.ColorsForMeDB.custom.b == 0.4)
    assert(state.env.ColorsForMeDB.minimapAngle == 140)
end)

test("texture access module preserves safe atlas and path reads", function()
    local toc = assert(io.open("ColorsForMe/ColorsForMe.toc", "r"))
    local manifest = toc:read("*a")
    toc:close()
    local pos = assert(manifest:find("TextureAccess.lua", 1, true), "TextureAccess.lua is not in the manifest")
    assert(pos < assert(manifest:find("Core.lua", 1, true)))
    local state = fixture()
    local tex = mock.texture("My-Atlas")
    tex.path = "Interface/Buttons/UI-Quickslot.BLP"
    assert(state.ns.ReadAtlas(tex) == "My-Atlas")
    assert(state.ns.ReadPath(tex) == "interface\\buttons\\ui-quickslot.blp")
    tex.GetTextureFilePath = function() error("not available") end
    assert(state.ns.ReadPath(tex) == "interface\\buttons\\ui-quickslot.blp")
    tex.GetAtlas = function() error("not available") end
    assert(state.ns.ReadAtlas(tex) == nil)
    tex.GetTexture = function() return 123 end
    assert(state.ns.ReadPath(tex) == nil)
end)

test("decoration atlas rules load independently of core", function()
    local toc = assert(io.open("ColorsForMe/ColorsForMe.toc", "r"))
    local manifest = toc:read("*a")
    toc:close()
    local pos = assert(manifest:find("DecorAtlases.lua", 1, true), "DecorAtlases.lua is not in the manifest")
    assert(pos < assert(manifest:find("Core.lua", 1, true)))
    local state = fixture()
    local t = state.ns.IsDecorAtlas
    assert(t("UI-HUD-ACTIONBAR-FRAME-DIVIDER-MIDDLE", "bar", false))
    assert(t("ui-hud-minimap-frame", "minimap", false))
    assert(t("ui-frame-fancy-border", "window", true))
    assert(not t("ui-frame-fancy-border", "window", false))
    assert(not t("ui-frame-fancy-border", "gameMenu", true))
    assert(not t(nil, "bar", false))
end)

test("eligibility module preserves file and extension rules", function()
    local toc = assert(io.open("ColorsForMe/ColorsForMe.toc", "r"))
    local manifest = toc:read("*a")
    toc:close()
    local pos = assert(manifest:find("DecorRules.lua", 1, true), "DecorRules.lua is not in the manifest")
    assert(pos < assert(manifest:find("Core.lua", 1, true)))
    local state = fixture()
    local tex = mock.texture()
    tex.path = "Interface/Buttons/UI-Quickslot.BLP"
    assert(state.ns.Eligible(tex, "bar", false))
    tex.path = "Interface/Buttons/UI-Quickslot-Depress.BLP"
    assert(not state.ns.Eligible(tex, "bar", false))
    tex.path = "Interface/DialogFrame/UI-DialogBox-Border"
    assert(state.ns.Eligible(tex, "gameMenu", false))
    assert(state.ns.Eligible(tex, "window", false))
    tex.path = nil
    assert(state.ns.Eligible(tex, "window", true))
    assert(not state.ns.Eligible(tex, "window", false))
    state.ns.AdditionalDecorEligibility = function() error("unsupported object") end
    assert(not state.ns.Eligible(tex, "window", false))
end)

test("color engine module preserves forced scans and original restoration", function()
    local toc = assert(io.open("ColorsForMe/ColorsForMe.toc", "r"))
    local manifest = toc:read("*a")
    toc:close()
    local pos = assert(manifest:find("ColorEngine.lua", 1, true), "ColorEngine.lua is not in the manifest")
    assert(pos < assert(manifest:find("Core.lua", 1, true)))
    local state, _, tex = fixture()
    state.ns.SetMode("custom", {r = 0.2, g = 0.3, b = 0.4})
    tex.color = {0.9, 0.9, 0.9, 0.25}
    tex.desat = 0
    state.ns.ApplyAll()
    assert(tex.color[1] == 0.2 and tex.color[4] == 0.25 and tex.desat == 1)
    state.ns.SetMode("reset")
    assert(tex.color[1] == 0.8 and tex.color[4] == 0.4 and tex.desat == 0.2)
    local count = state.ns.GetStats()
    assert(count == 1)
end)

test("discovery module loads after bootstrap and retains API", function()
    local toc = assert(io.open("ColorsForMe/ColorsForMe.toc", "r"))
    local manifest = toc:read("*a")
    toc:close()
    local corePos = assert(manifest:find("Core.lua", 1, true))
    local discoveryPos = assert(manifest:find("Discovery.lua", 1, true), "Discovery.lua is not in the manifest")
    local extraPos = assert(manifest:find("ExtraChrome.lua", 1, true))
    assert(corePos < discoveryPos and discoveryPos < extraPos)
    local state = fixture()
    assert(type(state.ns.ScanOne) == "function")
    assert(type(state.ns.ApplyAll) == "function")
    assert(type(state.ns.SetMode) == "function")
    assert(type(state.ns.Print) == "function")
end)

test("mode controller retains clamping and discovers windows after reset", function()
    local state = mock.create()
    state:load()
    assert(type(state.ns.CreateModeController) == "function", "mode controller has not been extracted")
    assert(state.ns.SetMode("unknown") == false)
    assert(state.ns.SetMode("reset"))
    local root = state:root("CharacterFrame")
    local tex = mock.texture("ui-frame-topcornerright")
    root.regions = {tex}
    assert(state.ns.SetMode("custom", {r = -1, g = 2, b = 0.4}))
    assert(state.env.ColorsForMeDB.custom.r == 0 and state.env.ColorsForMeDB.custom.g == 1)
    assert(tex.colorWrites == 1 and tex.color[1] == 0 and tex.color[2] == 1)
end)

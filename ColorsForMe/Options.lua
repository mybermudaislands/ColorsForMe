-- Only a separate, ordinary configuration dialog is created. Existing game
-- frames, buttons and skins are not moved, hidden or replaced.
local addonName, ns = ...
local panel
local status, rgbInfo, liftInfo

local function printColor(c)
    return string.format("R %.2f   G %.2f   B %.2f", c.r, c.g, c.b)
end

function ns.RefreshOptions()
    if not panel then return end
    local count, mode, deferred = ns.GetStats()
    local modeText = mode == "classic" and "Classic Gray" or (mode == "custom" and "Custom Color" or "Original Forever")
    status:SetText("Current: " .. modeText .. "   |   Decor layers: " .. count
        .. (deferred and " (waiting for combat to end)" or ""))
    rgbInfo:SetText("Custom color: " .. printColor(ColorsForMeDB.custom))
    if liftInfo then
        local n = math.floor((ColorsForMeDB.gryphonLift or 0) * 100 + 0.5)
        liftInfo:SetText("Gryphon/Wyvern custom tint relief: " .. n .. "%")
    end
end

local pickerSession = 0
local function openPicker()
    if not ColorsForMeDB then return end
    if not ColorPickerFrame or type(ColorPickerFrame.SetupColorPickerAndShow) ~= "function" then
        ns.Print("This client does not expose the supported ColorPickerFrame API.")
        return
    end
    -- The original mode and color must remain independent of the live preview.
    -- Never keep a reference to the DB's mutable custom table.
    pickerSession = pickerSession + 1
    local session = pickerSession
    local previousMode = ColorsForMeDB.mode
    local old = ColorsForMeDB.custom
    local previousColor = {r = old.r, g = old.g, b = old.b}
    local cancelled = false
    local function changed()
        if cancelled or session ~= pickerSession then return end
        local r, g, b = ColorPickerFrame:GetColorRGB()
        if type(r) == "number" and type(g) == "number" and type(b) == "number" then
            ns.SetMode("custom", {r=r, g=g, b=b})
        end
    end
    local function cancel()
        if cancelled or session ~= pickerSession then return end
        cancelled = true -- block any late swatchFunc dispatched by the picker
        ns.SetMode(previousMode, previousColor)
    end
    ColorPickerFrame:SetupColorPickerAndShow({
        r = previousColor.r, g = previousColor.g, b = previousColor.b,
        hasOpacity = false,
        swatchFunc = changed,
        opacityFunc = changed,
        cancelFunc = cancel,
    })
    -- Only existing decorative frame art, not wheel/slider/preview or buttons.
    if ns.ColorizeOwnWindow then ns.ColorizeOwnWindow("ColorPickerFrame") end
end

ns.OpenPicker = openPicker

local function makeButton(parent, label, x, y, w, action)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(w, 27)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetText(label)
    btn:SetScript("OnClick", action)
    return btn
end

local function createOptions()
    if panel then return end
    panel = CreateFrame("Frame", "ColorsForMeOptions", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(420, 298)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self)
        if not ns.InCombat() then self:StartMoving() end
    end)
    panel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    panel:Hide()
    panel.TitleText:ClearAllPoints()
    panel.TitleText:SetPoint("TOP", panel, "TOP", 0, -5)
    panel.TitleText:SetWidth(320)
    panel.TitleText:SetJustifyH("CENTER")
    panel.TitleText:SetText("ColorsForMe")

    local intro = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    intro:SetPoint("TOPLEFT", 20, -38)
    intro:SetWidth(380)
    intro:SetJustifyH("LEFT")
    intro:SetText("Only original Blizzard decorative art is recolored.")

    makeButton(panel, "Classic Gray", 20, -76, 116, function()
        ns.SetMode("classic")
    end)
    makeButton(panel, "Custom Color...", 145, -76, 128, openPicker)
    makeButton(panel, "Reset", 283, -76, 115, function()
        ns.SetMode("reset")
    end)

    status = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", 20, -122)
    status:SetWidth(390)
    status:SetJustifyH("LEFT")
    rgbInfo = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    rgbInfo:SetPoint("TOPLEFT", 20, -144)
    rgbInfo:SetWidth(390)
    rgbInfo:SetJustifyH("LEFT")

    local info = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    info:SetPoint("TOPLEFT", 20, -173)
    info:SetWidth(382)
    info:SetJustifyH("LEFT")
    info:SetText("Only separately addressable decorative art is recolored.")

    liftInfo = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    liftInfo:SetPoint("TOPLEFT", 20, -202)
    liftInfo:SetWidth(360)
    liftInfo:SetJustifyH("LEFT")
    makeButton(panel, "-", 20, -220, 35, function()
        if ns.SetGryphonLift then ns.SetGryphonLift((ColorsForMeDB.gryphonLift or 0) - 0.25) end
    end)
    makeButton(panel, "+", 60, -220, 35, function()
        if ns.SetGryphonLift then ns.SetGryphonLift((ColorsForMeDB.gryphonLift or 0) + 0.25) end
    end)
    local explanation = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    explanation:SetPoint("TOPLEFT", 104, -222)
    explanation:SetWidth(293)
    explanation:SetJustifyH("LEFT")
    explanation:SetText("Custom Color only. Gray mode is already at max brightness.")
    ns.RefreshOptions()
end

local function openOptions()
    createOptions()
    if panel:IsShown() then panel:Hide() else
        ns.RefreshOptions()
        panel:Show()
        if ns.ColorizeOwnWindow then ns.ColorizeOwnWindow("ColorsForMeOptions") end
    end
end
ns.ToggleOptions = openOptions

function ColorsForMe_AddonCompartmentClick()
    if not panel or not panel:IsShown() then openOptions() end
end

SLASH_COLORSFORME1 = "/forevercolor"
SLASH_COLORSFORME2 = "/cfm"
SlashCmdList.COLORSFORME = function(text)
    local cmd = (text or ""):match("^%s*(%S+)")
    cmd = cmd and cmd:lower() or ""
    if cmd == "" or cmd == "options" or cmd == "config" then
        openOptions()
    elseif cmd == "classic" or cmd == "gray" then
        ns.SetMode("classic")
        ns.Print("Classic Gray selected.")
    elseif cmd == "custom" or cmd == "color" then
        openPicker()
    elseif cmd == "reset" or cmd == "original" then
        ns.SetMode("reset")
        ns.Print("Original color parameters restored (or queued until out of combat).")
    elseif cmd == "probe" then
        ns.Probe((text or ""):match("^%s*%S+%s+(%S+)"))
    elseif cmd == "inspect" then
        ns.InspectMouse()
    elseif cmd == "scan" then
        ns.ApplyAll()
        ns.Print("Rechecked loaded Blizzard decorative frames.")
    elseif cmd == "status" then
        local count, mode, deferred = ns.GetStats()
        ns.Print("Mode=" .. mode .. ", touched layers=" .. count .. ", combat queue=" .. tostring(deferred))
    else
        ns.Print("/forevercolor: classic | custom | reset | scan | status | probe | inspect")
    end
end

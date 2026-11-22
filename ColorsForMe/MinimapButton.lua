-- ColorsForMe 0.4.5 - a standard-style minimap shortcut.
-- It is NOT a recolor overlay and never changes the Minimap frame itself.
local _, ns = ...
local button
local dragging = false
local sin, cos, rad = math.sin, math.cos, math.rad
local atan2 = math.atan2 or function(y, x)
    if x == 0 then return y >= 0 and math.pi / 2 or -math.pi / 2 end
    local a = math.atan(y / x)
    if x < 0 then return a + (y >= 0 and math.pi or -math.pi) end
    return a
end

local function position()
    if not button or not Minimap or not ColorsForMeDB then return end
    local a = rad(ColorsForMeDB.minimapAngle or 140)
    local radius = (Minimap:GetWidth() / 2) + 13
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", cos(a) * radius, sin(a) * radius)
end

local function setAngleFromCursor()
    local cx, cy = Minimap:GetCenter()
    if not cx or not cy then return end
    local scale = UIParent:GetEffectiveScale()
    if not scale or scale == 0 then return end
    local x, y = GetCursorPosition()
    local deg = math.deg(atan2(y / scale - cy, x / scale - cx))
    ColorsForMeDB.minimapAngle = deg
    position()
end

local function createButton()
    if button or not Minimap then return end
    button = CreateFrame("Button", "ColorsForMeMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    -- Standard Blizzard tracking-button ring geometry (52x52 anchored at
    -- TOPLEFT of a 32x32 button); the icon itself is strictly inside the ring.
    -- This does not replace any texture of Blizzard's minimap.
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexture("Interface\\AddOns\\ColorsForMe\\ColorWheel.tga")
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("ColorsForMe", 0.95, 0.95, 0.95)
        GameTooltip:AddLine("Left-click: color settings", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Custom Color", 1, 1, 1)
        GameTooltip:AddLine("Drag: move around minimap", 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnClick", function(_, mouseButton)
        if dragging then return end
        if mouseButton == "RightButton" and ns.OpenPicker then
            ns.OpenPicker()
        elseif ns.ToggleOptions then
            ns.ToggleOptions()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        if ns.InCombat() then return end
        dragging = true
        GameTooltip:Hide()
        self:SetScript("OnUpdate", setAngleFromCursor) -- active ONLY during a drag
    end)
    button:SetScript("OnDragStop", function(self)
        if dragging then setAngleFromCursor() end
        dragging = false
        self:SetScript("OnUpdate", nil)
    end)
    position()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", createButton)

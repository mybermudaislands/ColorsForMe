local _, ns = ...
local _G = _G
local lower, find = string.lower, string.find
local readAtlas, readPath = ns.ReadAtlas, ns.ReadPath
local isDecorAtlas = ns.IsDecorAtlas

local function safeObject(v)
    return v ~= nil and (not issecretvalue or not issecretvalue(v))
end

local function isWindowMetalFile(path)
    if not path then return false end
    return find(path, "interface\\framegeneral\\uiframemetal", 1, true) ~= nil
        or find(path, "interface\\framegeneral\\ui%-frame") ~= nil
end

local function hasAnyLiteral(path, list)
    if not path then return false end
    for i = 1, #list do
        if find(path, list[i], 1, true) then return true end
    end
    return false
end

-- Static button-slot borders only, never pressed or debuff artwork.
local BAR_FILES = {
    "interface\\buttons\\ui-quickslot",
    "interface\\buttons\\ui-quickslot2",
    "interface\\buttons\\ui-empty-slot",
}
local function isStaticButtonBorder(path)
    if not path then return false end
    path = path:gsub("%.blp$", ""):gsub("%.tga$", "")
    for i = 1, #BAR_FILES do
        if path == BAR_FILES[i] then return true end
    end
    return false
end
local GAME_MENU_FILES = {
    "interface\\dialogframe\\ui-dialogbox-border",
    "interface\\dialogframe\\ui-dialogbox-header",
    "interface\\framegeneral\\uiframemetal",
    "interface\\framegeneral\\ui-frame",
}

-- The structural flag denotes a verified decoration container, not a general frame.
function ns.Eligible(tex, category, nineSlice)
    if not tex or not safeObject(tex) or type(tex.GetObjectType) ~= "function" then return false end
    local ok, objectType = pcall(tex.GetObjectType, tex)
    if not ok or objectType ~= "Texture" then return false end
    if type(tex.GetVertexColor) ~= "function" or type(tex.SetVertexColor) ~= "function" then return false end
    if type(tex.GetDesaturation) ~= "function" or type(tex.SetDesaturation) ~= "function" then return false end
    local atlas = readAtlas(tex)
    if isDecorAtlas(atlas, category, nineSlice) then return true end
    local path = readPath(tex)
    if category == "bar" then
        if isStaticButtonBorder(path) then return true end
    end
    if nineSlice and (category == "window" or category == "gameMenu") then return true end
    if category == "objective" then
        local obj = _G.ObjectiveTrackerFrame
        local quest = _G.QuestObjectiveTracker
        local heads = {obj and obj.Header, quest and quest.Header, _G.QuestObjectiveTrackerHeader}
        for _, head in pairs(heads) do
            if safeObject(head) and (tex == head.Background or tex == head.BackgroundLeft
              or tex == head.BackgroundRight or tex == head.HeaderBackground
              or tex == head.Bg) then return true end
        end
        if type(atlas) == "string" then
            local a = lower(atlas)
            if (find(a, "^ui%-hud%-objective%-tracker%-header") or
                find(a, "^ui%-hud%-objectivetracker%-header")) and
                not find(a, "icon", 1, true) and not find(a, "button", 1, true)
                and not find(a, "collapse", 1, true) then return true end
        end
    end
    if category == "gameMenu" and ((nineSlice and isWindowMetalFile(path))
        or hasAnyLiteral(path, GAME_MENU_FILES)) then return true end
    if category == "window" and ((nineSlice and isWindowMetalFile(path))
        or hasAnyLiteral(path, GAME_MENU_FILES)) then return true end
    if ns.AdditionalDecorEligibility then
        local okExtra, allow = pcall(ns.AdditionalDecorEligibility, tex, category, nineSlice, atlas, path)
        return okExtra and allow == true
    end
    return false
end

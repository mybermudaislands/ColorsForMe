local _, ns = ...
local lower, find = string.lower, string.find

-- Original Blizzard decorative atlases. Functional state artwork is excluded.
local BAR_ATLAS = {
    ["ui-hud-actionbar-frame"] = true,
    ["ui-hud-actionbar-gryphon-left"] = true,
    ["ui-hud-actionbar-gryphon-right"] = true,
    ["ui-hud-actionbar-wyvern-left"] = true,
    ["ui-hud-actionbar-wyvern-right"] = true,
    ["ui-hud-actionbar-iconframe"] = true,
    ["ui-hud-actionbar-iconframe-slot"] = true,
    ["ui-hud-actionbar-iconframe-background"] = true,
    ["ui-hud-actionbar-slot"] = true,
    ["ui-hud-actionbar-button-border"] = true,
}
local MINIMAP_ATLAS = {
    ["ui-hud-minimap-frame"] = true,
    ["ui-hud-minimap-button"] = true,
}
local WINDOW_ATLAS = {
    ["!ui-frame-righttile"] = true,
    ["!ui-frame-lefttile"] = true,
    ["!ui-frame-innerrighttile"] = true,
    ["!ui-frame-innerlefttile"] = true,
    ["_ui-frame-btnbottile"] = true,
    ["_ui-frame-bot"] = true,
    ["_ui-frame-innertoptile"] = true,
    ["_ui-frame-innerbottile"] = true,
    ["_ui-frame-titletilebg"] = true,
    ["_ui-frame-titletile"] = true,
    ["_ui-frame-toptilestreaks"] = true,
    ["ui-frame-topcornerright"] = true,
    ["ui-frame-innertopright"] = true,
    ["ui-frame-topleftcornernoportrait"] = true,
    ["ui-frame-innertopleft"] = true,
    ["ui-frame-innerbotleftcorner"] = true,
    ["ui-frame-innerbotright"] = true,
    ["ui-frame-botcornerleft"] = true,
    ["ui-frame-topleftcorner"] = true,
    ["ui-frame-botcornerright"] = true,
    ["ui-frame-topcornerrightsimple"] = true,
    ["ui-frame-innersplitleft"] = true,
    ["ui-frame-innersplitright"] = true,
    ["ui-frame-btndivright"] = true,
    ["ui-frame-btndivleft"] = true,
    ["uiframe-tab-left"] = true,
    ["uiframe-tab-right"] = true,
    ["_uiframe-tab-center"] = true,
    ["ui-frame-innertopleft"] = true,
    ["ui-frame-topcornerleft"] = true,
    ["ui-frame-btndivmiddle"] = true,
    ["ui-frame-portrait"] = true,
}
local UNIT_ATLAS = {
    ["ui-hud-unitframe-player-portraiton"] = true,
    ["ui-hud-unitframe-player-portraiton-classresource"] = true,
    ["ui-hud-unitframe-player-portraiton-cornerembellishment"] = true,
    ["ui-hud-unitframe-target-portraiton"] = true,
    ["ui-hud-unitframe-targetoftarget-portraiton"] = true,
    ["ui-hud-unitframe-target-portraiton-elite"] = true,
    ["ui-hud-unitframe-target-portraiton-rare"] = true,
}
local DAMAGE_ATLAS = { ["ui-damagemeters-header-bar"] = true }
local MICRO_ATLAS = {
    ["ui-hud-micromenu-buttonbg-up"] = true,
    ["ui-hud-micromenu-buttonbg-down"] = true,
}

function ns.IsDecorAtlas(atlas, category, isNineSlice)
    if type(atlas) ~= "string" or atlas == "" then return false end
    atlas = lower(atlas)
    if category == "bar" then
        return BAR_ATLAS[atlas] == true
            or find(atlas, "^ui%-hud%-actionbar%-frame%-divider") ~= nil
    elseif category == "minimap" then
        return MINIMAP_ATLAS[atlas] == true
    elseif category == "unitframe" then
        return UNIT_ATLAS[atlas] == true
    elseif category == "damage" then
        return DAMAGE_ATLAS[atlas] == true
    elseif category == "micromenu" then
        return MICRO_ATLAS[atlas] == true
    elseif category == "gameMenu" then
        return WINDOW_ATLAS[atlas] == true
    elseif category == "window" then
        return WINDOW_ATLAS[atlas] == true
            or (isNineSlice and (
                find(atlas, "^ui%-frame%-[%w_%-]+%-border") ~= nil
                or find(atlas, "^ui%-frame%-[%w_%-]+%-edge") ~= nil
                or find(atlas, "^ui%-frame%-[%w_%-]+%-corner") ~= nil
            ))
    end
    return false
end

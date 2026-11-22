-- Read-only developer diagnostics. They do NOT change textures.
local addonName, ns = ...
local _G = _G
local type, pairs, ipairs = type, pairs, ipairs
local find, lower = string.find, string.lower
local function safeObject(v)
    return v ~= nil and (not issecretvalue or not issecretvalue(v))
end

local function objectName(x)
    if x and type(x.GetName) == "function" then
        local ok, name = pcall(x.GetName, x)
        if ok and (not issecretvalue or not issecretvalue(name)) and name then
            return name
        end
    end
    return "(unnamed)"
end

local function isTexture(region)
    if not region or type(region.GetObjectType) ~= "function" then return false end
    local ok, t = pcall(region.GetObjectType, region)
    return ok and t == "Texture"
end

local function describeTexture(tex)
    local a = ns.ReadAtlas(tex)
    local p = ns.ReadPath(tex)
    local id = nil
    if type(tex.GetTextureFileID) == "function" then
        local ok, v = pcall(tex.GetTextureFileID, tex)
        if ok and (not issecretvalue or not issecretvalue(v)) and type(v) == "number" then id = v end
    end
    return a, p, id
end

local function visibleFrame(frame)
    if type(frame.IsVisible) ~= "function" then return nil end
    local ok, value = pcall(frame.IsVisible, frame)
    if ok and safeObject(value) and type(value) == "boolean" then return value end
end

local function textureRect(tex)
    if type(tex.GetRect) ~= "function" then return nil end
    local ok, left, bottom, width, height = pcall(tex.GetRect, tex)
    if not ok or not safeObject(left) or not safeObject(bottom)
        or not safeObject(width) or not safeObject(height) then return nil end
    if type(left) ~= "number" or type(bottom) ~= "number"
        or type(width) ~= "number" or type(height) ~= "number" then return nil end
    return {left = left, bottom = bottom, width = width, height = height}
end

local function candidate(a, p, name)
    local value = lower(tostring(a or "") .. " " .. tostring(p or "") .. " " .. name)
    -- Diagnostic only; its broad filter never authorizes a texture change.
    return find(value, "border", 1, true) ~= nil
        or find(value, "frame", 1, true) ~= nil
        or find(value, "minimap", 1, true) ~= nil
        or find(value, "nine", 1, true) ~= nil
        or find(value, "gryphon", 1, true) ~= nil
        or find(value, "wyvern", 1, true) ~= nil
        or find(value, "slot", 1, true) ~= nil
        or find(value, "bronze", 1, true) ~= nil
        or find(value, "micromenu", 1, true) ~= nil
        or find(value, "damagemeter", 1, true) ~= nil
        or find(value, "objectivetracker", 1, true) ~= nil
        or find(value, "unitframe", 1, true) ~= nil
end

local detailedTargets = {SocialUIFrame = "window", MinimapCluster = "minimap", PlayerFrame = "unitframe"}

function ns.Probe(target)
    if type(target) ~= "string" or target == "" then target = nil end
    if target and not ns.Roots[target] and not detailedTargets[target] then
        ns.Print("Unknown Blizzard root: " .. target .. ". Use /forevercolor inspect to identify it.")
        return
    end
    if ns.InCombat() then
        ns.Print("Run /forevercolor probe out of combat.")
        return
    end
    local report = { build = select(2, GetBuildInfo()), interface = select(4, GetBuildInfo()), entries = {} }
    local entries = report.entries
    local scannedRoots = 0
    local MAX = 350

    local function visit(frame, rootName, category, depth, nine, budget, framePath)
        if not safeObject(frame) or depth > 7 or budget[1] >= 900 or #entries >= MAX then return end
        if type(frame.GetRegions) ~= "function" then return end
        budget[1] = budget[1] + 1
        local okRegions, regions = pcall(function() return {frame:GetRegions()} end)
        if not okRegions then return end
        for regionIndex, region in ipairs(regions) do
            if safeObject(region) and isTexture(region) then
                local atlas, path, fileID = describeTexture(region)
                local name = objectName(region)
                if (detailedTargets[target] or candidate(atlas, path, name)) and #entries < MAX then
                    entries[#entries + 1] = {
                        root = rootName, frame = objectName(frame), region = name,
                        atlas = atlas or "", path = path or "", fileID = fileID,
                        framePath = framePath, regionIndex = regionIndex,
                        visible = visibleFrame(frame), rect = textureRect(region),
                        -- 'eligible' is the exact same matcher used by the color engine.
                        eligible = ns.Eligible(region, category, nine) and true or false,
                    }
                end
            end
        end
        if depth >= 7 or type(frame.GetChildren) ~= "function" then return end
        local okChildren, children = pcall(function() return {frame:GetChildren()} end)
        if not okChildren then return end
        for childIndex, child in ipairs(children) do
            if safeObject(child) then
                local okNine, childNine = pcall(function()
                    return nine or (category == "window" and _G[rootName] and
                        child == _G[rootName].NineSlice)
                end)
                visit(child, rootName, category, depth + 1,
                    (okNine and childNine) or false, budget, framePath .. "/" .. childIndex)
            end
        end
    end

    local function inspectRoot(rootName, category)
        local root = _G[rootName]
        -- StoreFrame can be forbidden to addons; even diagnostics must skip it.
        if root then
            local ok, forbidden = pcall(function()
                return type(root.IsForbidden) == "function" and root:IsForbidden()
            end)
            if not ok or forbidden then root = nil end
        end
        if safeObject(root) and (not target or rootName == target) then
            scannedRoots = scannedRoots + 1
            if category == "window" then
                -- Diagnostics may inspect the entire Blizzard window (read-only).
                visit(root, rootName, category, 0, false, {0}, rootName)
            else
                visit(root, rootName, category, 0, false, {0}, rootName)
            end
        end
    end
    for rootName, category in pairs(ns.Roots) do
        inspectRoot(rootName, category)
    end
    if target == "SocialUIFrame" and not ns.Roots[target] then inspectRoot(target, detailedTargets[target]) end

    table.sort(entries, function(a, b)
        return a.root .. a.frame .. a.region < b.root .. b.frame .. b.region
    end)
    report.scannedRoots = scannedRoots
    report.truncated = #entries >= MAX
    if not ColorsForMeDB then return end
    ColorsForMeDB.lastProbe = report
    if detailedTargets[target] then
        if type(ColorsForMeDB.lastTargetProbes) ~= "table" then ColorsForMeDB.lastTargetProbes = {} end
        ColorsForMeDB.lastTargetProbes[target] = report
    end
    local totalEligible = 0
    for _, e in ipairs(entries) do if e.eligible then totalEligible = totalEligible + 1 end end
    ns.Print("Probe: " .. scannedRoots .. " Blizzard roots; " .. #entries
        .. " candidate textures in report (" .. totalEligible .. " matched the whitelist).")
    ns.Print("Open the target window, run /forevercolor probe [FrameName], then /reload.")
    ns.Print("For analysis, send WTF\\Account\\...\\SavedVariables\\ColorsForMe.lua")
end

function ns.InspectMouse()
    if ns.InCombat() then ns.Print("Use inspect out of combat."); return end
    if type(GetMouseFoci) ~= "function" then
        ns.Print("GetMouseFoci is unavailable.")
        return
    end
    local okFocus, focus = pcall(GetMouseFoci)
    if not okFocus then ns.Print("Cannot inspect that frame safely."); return end
    local first = focus and focus[1]
    if not first then ns.Print("No UI frame under mouse cursor."); return end
    local current = first
    local ancestry = {}
    for i = 1, 8 do
        if not current then break end
        ancestry[#ancestry + 1] = objectName(current)
        if type(current.GetParent) ~= "function" then break end
        local okParent, parent = pcall(current.GetParent, current)
        if not okParent or not safeObject(parent) then break end
        current = parent
    end
    ns.Print("Mouse: " .. table.concat(ancestry, " > "))
    local atlas, path, fileID
    if isTexture(first) then atlas, path, fileID = describeTexture(first) end
    ns.Print("Texture: atlas=" .. tostring(atlas) .. " path=" .. tostring(path) .. " id=" .. tostring(fileID))
end

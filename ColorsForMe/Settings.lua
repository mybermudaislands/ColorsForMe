local _, ns = ...

function ns.InitSaved()
    if type(ColorsForMeDB) ~= "table" then ColorsForMeDB = {} end
    if type(ColorsForMeDB.custom) ~= "table" then ColorsForMeDB.custom = {} end
    local c = ColorsForMeDB.custom
    for _, k in ipairs({"r", "g", "b"}) do
        if type(c[k]) ~= "number" or c[k] < 0 or c[k] > 1 then c[k] = 0.65 end
    end
    if type(ColorsForMeDB.minimapAngle) ~= "number"
        or ColorsForMeDB.minimapAngle ~= ColorsForMeDB.minimapAngle then
        ColorsForMeDB.minimapAngle = 140
    end
    if ColorsForMeDB.mode ~= "classic" and ColorsForMeDB.mode ~= "custom"
        and ColorsForMeDB.mode ~= "reset" then
        ColorsForMeDB.mode = "classic"
    end
end

function ns.CreateModeController(blocked, queueCombatRetry, discoverAvailable, repaintKnown, restoreAll)
    return function(mode, color)
        if mode ~= "classic" and mode ~= "custom" and mode ~= "reset"
            or type(ColorsForMeDB) ~= "table" then return false end
        local oldMode = ColorsForMeDB.mode
        local old = ColorsForMeDB.custom
        local new = nil
        if color then
            local function bound(v) return math.max(0, math.min(1, tonumber(v) or 1)) end
            new = {r = bound(color.r), g = bound(color.g), b = bound(color.b)}
        end
        if oldMode == mode and (not new or
            (old.r == new.r and old.g == new.g and old.b == new.b)) then
            return true
        end
        if new then ColorsForMeDB.custom = new end
        ColorsForMeDB.mode = mode
        if not blocked() then
            if mode == "reset" then
                restoreAll()
            else
                if oldMode == "reset" then discoverAvailable(false) end
                repaintKnown()
            end
        else
            queueCombatRetry()
        end
        if ns.RefreshOptions then ns.RefreshOptions() end
        return true
    end
end

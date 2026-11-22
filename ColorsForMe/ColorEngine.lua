local _, ns = ...

local function safeObject(v)
    return v ~= nil and (not issecretvalue or not issecretvalue(v))
end

function ns.CreateColorEngine(blocked, queueCombatRetry)
    local original = setmetatable({}, { __mode = "k" })
    local applied = setmetatable({}, { __mode = "k" })
    local changedCount = 0

    local function capture(tex)
        local existing = original[tex]
        if existing then return existing end
        local okColor, r, g, b, a = pcall(tex.GetVertexColor, tex)
        local okDesat, desat = pcall(tex.GetDesaturation, tex)
        if not okColor or not okDesat then return nil end
        if not safeObject(r) or not safeObject(g) or not safeObject(b)
            or not safeObject(a) or not safeObject(desat) then return nil end
        if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number"
            or type(a) ~= "number" or type(desat) ~= "number" then return nil end
        local state = { r = r, g = g, b = b, a = a, desat = desat }
        original[tex] = state
        changedCount = changedCount + 1
        return state
    end

    local function colorValues()
        if ColorsForMeDB.mode == "custom" then
            local c = ColorsForMeDB.custom
            return c.r, c.g, c.b
        end
        return 1, 1, 1
    end

    -- Only supported methods acting on texture color are called here.
    local function paint(tex, forced)
        if blocked() then queueCombatRetry(); return end
        if not ColorsForMeDB or ColorsForMeDB.mode == "reset" or not safeObject(tex) then return end
        local prev = capture(tex)
        if not prev then return end
        local r, g, b = colorValues()
        if ns.AdjustGryphonColor then
            r, g, b = ns.AdjustGryphonColor(tex, r, g, b)
        end
        local cache = applied[tex]
        local colorCurrent = cache and cache.r == r and cache.g == g and cache.b == b
        if colorCurrent and not forced then return end

        local shouldDesaturate = not cache
        local alpha = prev.a
        if forced then
            local okD, d = pcall(tex.GetDesaturation, tex)
            if okD and safeObject(d) and type(d) == "number" then
                shouldDesaturate = d ~= 1
            end
            local okC, cr, cg, cb, ca = pcall(tex.GetVertexColor, tex)
            if okC and safeObject(cr) and safeObject(cg) and safeObject(cb)
                and safeObject(ca) and type(ca) == "number" then
                alpha = ca
                if type(cr) == "number" and type(cg) == "number" and type(cb) == "number"
                    and cr == r and cg == g and cb == b then colorCurrent = true
                else
                    colorCurrent = false
                end
            end
        end
        if shouldDesaturate then
            local ok = pcall(tex.SetDesaturation, tex, 1)
            if not ok then return end
        end
        if not colorCurrent then
            local ok = pcall(tex.SetVertexColor, tex, r, g, b, alpha)
            if not ok then return end
        end
        if cache then
            cache.r, cache.g, cache.b = r, g, b
        else
            applied[tex] = {r = r, g = g, b = b}
        end
    end

    local function repaintKnown()
        if blocked() then queueCombatRetry(); return end
        if not ColorsForMeDB or ColorsForMeDB.mode == "reset" then return end
        for tex in pairs(original) do
            if safeObject(tex) then paint(tex) end
        end
    end

    local function restoreAll()
        if blocked() then queueCombatRetry(); return end
        for tex, cache in pairs(applied) do
            local prev = original[tex]
            if prev and safeObject(tex) then
                pcall(tex.SetDesaturation, tex, prev.desat)
                pcall(tex.SetVertexColor, tex, prev.r, prev.g, prev.b, prev.a)
            end
            applied[tex] = nil
        end
    end

    return {
        Paint = paint,
        RepaintKnown = repaintKnown,
        Restore = restoreAll,
        GetCount = function() return changedCount end,
    }
end

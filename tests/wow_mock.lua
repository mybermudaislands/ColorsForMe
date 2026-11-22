local M = {}

function M.create()
    local env = setmetatable({}, {__index = _G})
    env._G = env
    env.SlashCmdList = {}
    env.DEFAULT_CHAT_FRAME = {AddMessage = function() end}
    local frames = {}
    local combat = false
    local frameMethods = {}
    local regionMethods = {}

    function regionMethods:GetObjectType() return "Texture" end
    function regionMethods:GetAtlas() return self.atlas end
    function regionMethods:GetTexture() return self.path end
    function regionMethods:GetName() return self.name end
    function regionMethods:GetParent() return self.parent end
    function regionMethods:GetVertexColor() return unpack(self.color) end
    function regionMethods:GetDesaturation() return self.desat end
    function regionMethods:SetVertexColor(r, g, b, a)
        self.color = {r, g, b, a}
        self.colorWrites = self.colorWrites + 1
    end
    function regionMethods:SetDesaturation(value)
        self.desat = value
        self.desatWrites = self.desatWrites + 1
    end

    function frameMethods:GetRegions()
        self.regionReads = self.regionReads + 1
        return unpack(self.regions)
    end
    function frameMethods:GetChildren() return unpack(self.children) end
    function frameMethods:GetName() return self.name end
    function frameMethods:GetObjectType() return "Frame" end
    function frameMethods:IsVisible() return self.visible end
    function frameMethods:IsShown() return self.visible end
    function frameMethods:SetScript(event, fn) self.scripts[event] = fn end
    function frameMethods:HookScript(event, fn)
        self.hooks[event] = self.hooks[event] or {}
        table.insert(self.hooks[event], fn)
    end
    function frameMethods:RegisterEvent(event) self.events[event] = true end
    function frameMethods:UnregisterEvent(event) self.events[event] = nil end
    function frameMethods:Show()
        self.visible = true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
        for _, fn in ipairs(self.hooks.OnShow or {}) do fn(self) end
    end
    function frameMethods:Hide() self.visible = false end
    function frameMethods:SetText(value) self.text = value end
    function frameMethods:SetPoint(...) self.point = {...} end
    function frameMethods:ClearAllPoints() self.point = nil end
    function frameMethods:SetJustifyH(value) self.justify = value end
    function frameMethods:SetWidth(value) self.width = value end
    function frameMethods:SetSize(w, h) self.width, self.height = w, h end
    function frameMethods:GetWidth() return self.width or 140 end
    function frameMethods:GetCenter() return 100, 100 end
    function frameMethods:GetFrameLevel() return 1 end
    function frameMethods:GetEffectiveScale() return 1 end
    function frameMethods:CreateFontString()
        local font = setmetatable({}, {__index = frameMethods})
        table.insert(self.fonts, font)
        return font
    end
    function frameMethods:CreateTexture()
        local texture = M.texture()
        texture.parent = self
        function texture:SetSize() end
        function texture:SetPoint() end
        function texture:SetTexture(path) self.path = path end
        table.insert(self.regions, texture)
        return texture
    end
    for _, name in ipairs({"SetFrameStrata", "SetFrameLevel", "EnableMouse", "SetMovable", "RegisterForDrag", "RegisterForClicks", "StartMoving", "StopMovingOrSizing"}) do
        frameMethods[name] = function() end
    end

    function env.CreateFrame(_, name, parent)
        local frame = setmetatable({name = name, parent = parent, regions = {}, children = {}, fonts = {}, scripts = {}, hooks = {}, events = {}, visible = false, regionReads = 0}, {__index = frameMethods})
        frame.TitleText = setmetatable({}, {__index = frameMethods})
        if name then env[name] = frame end
        if parent and parent.children then table.insert(parent.children, frame) end
        table.insert(frames, frame)
        return frame
    end
    function env.InCombatLockdown() return combat end
    env.UIParent = env.CreateFrame("Frame", "UIParent")
    env.Minimap = env.CreateFrame("Frame", "Minimap", env.UIParent)
    env.Minimap.visible = true
    env.GameTooltip = {SetOwner = function() end, AddLine = function() end, Show = function() end, Hide = function() end}
    env.GetCursorPosition = function() return 110, 110 end
    env.GetBuildInfo = function() return "test", "test", "test", 16001 end

    local state = {env = env, frames = frames}
    function state:setCombat(value) combat = value end
    function state:event(event, arg)
        local count = #frames
        for i = 1, count do
            local frame = frames[i]
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, arg) end
        end
    end
    function state:root(name)
        local root = env.CreateFrame("Frame", name, env.UIParent)
        root.visible = true
        return root
    end
    function state:load(saved)
        env.ColorsForMeDB = saved
        local ns = {}
        local toc = assert(io.open("ColorsForMe/ColorsForMe.toc", "r"))
        for line in toc:lines() do
            local filename = line:match("^%s*([^#%s]+%.lua)%s*$")
            if filename then
                local chunk = assert(loadfile("ColorsForMe/" .. filename))
                setfenv(chunk, env)
                chunk("ColorsForMe", ns)
            end
        end
        toc:close()
        self.ns = ns
        self:event("ADDON_LOADED", "ColorsForMe")
        self:event("PLAYER_LOGIN")
        return ns
    end
    return state
end

function M.texture(atlas, color, desat)
    local tex = {atlas = atlas, color = color or {0.8, 0.7, 0.6, 0.4}, desat = desat or 0.2, colorWrites = 0, desatWrites = 0}
    return setmetatable(tex, {__index = {
        GetObjectType = function() return "Texture" end,
        GetAtlas = function(self) return self.atlas end,
        GetTexture = function(self) return self.path end,
        GetName = function(self) return self.name end,
        GetParent = function(self) return self.parent end,
        GetVertexColor = function(self) return unpack(self.color) end,
        GetDesaturation = function(self) return self.desat end,
        SetVertexColor = function(self, r, g, b, a) self.color = {r, g, b, a}; self.colorWrites = self.colorWrites + 1 end,
        SetDesaturation = function(self, value) self.desat = value; self.desatWrites = self.desatWrites + 1 end,
    }})
end

return M

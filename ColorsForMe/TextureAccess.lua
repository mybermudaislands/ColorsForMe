local _, ns = ...
local lower = string.lower

local function safeObject(v)
    return v ~= nil and (not issecretvalue or not issecretvalue(v))
end

function ns.ReadAtlas(tex)
    if not tex or type(tex.GetAtlas) ~= "function" then return nil end
    local ok, atlas = pcall(tex.GetAtlas, tex)
    if ok and safeObject(atlas) then return atlas end
end

function ns.ReadPath(tex)
    if not tex then return nil end
    if type(tex.GetTextureFilePath) == "function" then
        local ok, path = pcall(tex.GetTextureFilePath, tex)
        if ok and safeObject(path) and type(path) == "string" then return lower(path):gsub("/", "\\") end
    end
    if type(tex.GetTexture) == "function" then
        local ok, path = pcall(tex.GetTexture, tex)
        if ok and safeObject(path) and type(path) == "string" then return lower(path):gsub("/", "\\") end
    end
end

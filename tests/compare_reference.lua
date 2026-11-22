-- Compare a reference addon directory with the current source before installation.
local reference = assert(arg[1], "Pass the reference addon directory as the first argument")
local mock = assert(loadfile("tests/wow_mock.lua"))()
local referenceState = mock.create()
local referenceNS = {}

for _, filename in ipairs({"Core.lua", "ExtraChrome.lua"}) do
    local chunk = assert(loadfile(reference .. "/" .. filename))
    setfenv(chunk, referenceState.env)
    chunk("ColorsForMe", referenceNS)
end

local state = mock.create()
state:load()
for name, category in pairs(referenceNS.Roots) do
    assert(state.ns.Roots[name] == category, "Changed or missing root: " .. name)
end
for name, category in pairs(state.ns.Roots) do
    assert(referenceNS.Roots[name] == category, "Unexpected root: " .. name)
end

local file = assert(io.open(reference .. "/Core.lua", "r"))
local source = file:read("*a")
file:close()
local atlases = {"", "unknown", "ui-frame-extra-border", "ui-hud-objective-tracker-header-icon"}
for atlas in source:gmatch('%["([^"]+)"%]%s*=%s*true') do
    atlases[#atlases + 1] = atlas
end
local categories = {"bar", "minimap", "unitframe", "damage", "micromenu", "gameMenu", "window", "objective", "unknown"}
local comparisons = 0
for _, atlas in ipairs(atlases) do
    for _, category in ipairs(categories) do
        for _, nineSlice in ipairs({false, true}) do
            local tex = mock.texture(atlas)
            local expected = referenceNS.Eligible(tex, category, nineSlice)
            local actual = state.ns.Eligible(tex, category, nineSlice)
            assert(actual == expected, "Eligibility differs for " .. atlas .. ", " .. category .. ", " .. tostring(nineSlice))
            comparisons = comparisons + 1
        end
    end
end
print("Reference roots match; atlas eligibility comparisons: " .. comparisons)

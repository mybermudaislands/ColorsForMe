local total, failed = 0, 0
local function test(name, fn)
    total = total + 1
    local ok, err = pcall(fn)
    if ok then
        print("PASS " .. name)
    else
        failed = failed + 1
        print("FAIL " .. name .. ": " .. tostring(err))
    end
end

local mock = assert(loadfile("tests/wow_mock.lua"))()
assert(loadfile("tests/baseline.lua"))(test, mock)
if arg and arg[1] == "--selftest-failure" then
    test("intentional runner failure", function() assert(false, "intentional failure") end)
end
print(string.format("Results: %d passed, %d failed", total - failed, failed))
if failed > 0 then os.exit(1) end

-- ColorsForMe 0.4.5 | author: tinybeast
-- World of Warcraft: Forever (1.60.1 / interface 16001)
-- No art is replaced. No Blizzard global function or UI method is overwritten.
local _, ns = ...

function ns.Print(text)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff9cb6cfColorsForMe|r: " .. tostring(text))
    end
end

function ns.InCombat()
    return InCombatLockdown and InCombatLockdown()
end

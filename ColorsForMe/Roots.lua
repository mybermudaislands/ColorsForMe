-- Only original Blizzard UI roots are considered. Unknown or addon-owned
-- artwork is never discovered by traversing UIParent or enumerating all frames.
local _, ns = ...
local roots = {
    MainActionBar = "bar",
    MultiBarBottomLeft = "bar", MultiBarBottomRight = "bar",
    MultiBarLeft = "bar", MultiBarRight = "bar",
    MultiBar5 = "bar", MultiBar6 = "bar", MultiBar7 = "bar", MultiBar8 = "bar",
    StanceBar = "bar", PetActionBar = "bar", BagsBar = "bar",
    MinimapCluster = "minimap", Minimap = "minimap",
    -- Exact Blizzard unit-frame decorative atlas only; no bar fills or state art.
    PlayerFrame = "unitframe", TargetFrame = "unitframe", FocusFrame = "unitframe",
    -- Native meter windows are named by Blizzard (see DamageMeter.lua).
    DamageMeterSessionWindow1 = "damage", DamageMeterSessionWindow2 = "damage",
    DamageMeterSessionWindow3 = "damage", DamageMeterSessionWindow4 = "damage",
    DamageMeterSessionWindow5 = "damage",
    DamageMeterSessionWindow6 = "damage",
    ObjectiveTrackerFrame = "objective", QuestObjectiveTracker = "objective",
    QuestObjectiveTrackerHeader = "objective",
    -- Micro-menu buttons: ONLY the independent decorative BG atlas.
    MicroMenu = "micromenu", MicroMenuContainer = "micromenu",
    -- The following Blizzard windows are optional/load-on-demand.
    CharacterFrame = "window", SpellBookFrame = "window",
    PlayerSpellsFrame = "window", PlayerTalentFrame = "window",
    ProfessionsFrame = "window", ProfessionsBookFrame = "window",
    ProfessionsSkillLineFrame = "window",
    TradeSkillFrame = "window", MerchantFrame = "window",
    QuestFrame = "window", QuestLogFrame = "window",
    GossipFrame = "window", ClassTrainerFrame = "window",
    FriendsFrame = "window", SocialUIFrame = "social", BankFrame = "window",
    CommunitiesFrame = "window", GuildFrame = "window", GuildRosterFrame = "window",
    PVEFrame = "window", LFGFrame = "window",
    GroupFinderFrame = "window", DelvesCompanionFrame = "window",
    MailFrame = "window", OpenMailFrame = "window",
    AchievementFrame = "window", CollectionsJournal = "window",
    MountJournal = "window", PetJournal = "window",
    InspectFrame = "window", TradeFrame = "window",
    AuctionHouseFrame = "window", AuctionFrame = "window",
    MacroFrame = "window", DressUpFrame = "window", LootFrame = "window",
    ItemTextFrame = "window", GameMenuFrame = "gameMenu",
    WorldMapFrame = "window", QuestMapFrame = "window",
    SettingsPanel = "window", EncounterJournal = "window",
    -- Party / raid manager style Blizzard panels.
    CompactRaidFrameManager = "window", CompactRaidFrameManagerDisplayFrame = "window",
    CompactRaidFrameContainer = "window", CompactPartyFrame = "window",
    -- Combined-bag variants on modern clients.
    ContainerFrameCombinedBags = "window", CombinedBagFrame = "window",
    -- Blizzard's normal bag frames, not replacement bag addons.
}
for i = 1, 13 do roots["ContainerFrame" .. i] = "window" end
-- The individual stock microbuttons may not be children of a named container
-- on every UI layout. Scanning each known Blizzard button stays safe.
for _, name in ipairs({
    "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
    "ProfessionMicroButton", "QuestLogMicroButton", "AchievementMicroButton",
    "GuildMicroButton", "LFDMicroButton", "EJMicroButton",
    "CollectionsMicroButton", "MainMenuMicroButton", "HelpMicroButton",
    "StoreMicroButton", "SocialsMicroButton",
}) do roots[name] = "micromenu" end
-- Confirmed Blizzard global action-button names. Useful when a particular
-- bar's container does not inherit its button textures on the current build.
for _, stem in ipairs({"ActionButton", "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton", "MultiBarLeftButton", "MultiBarRightButton",
    "MultiBar5Button", "MultiBar6Button", "MultiBar7Button", "MultiBar8Button"}) do
    for i = 1, 12 do roots[stem .. i] = "bar" end
end
-- Stock aura buttons; only their independently drawn border art is eligible.
for _, stem in ipairs({"BuffButton", "DebuffButton", "TemporaryEnchantFrameBuff"}) do
    for i = 1, 40 do roots[stem .. i] = "bar" end
end
ns.Roots = roots

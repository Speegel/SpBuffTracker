-- SpBuffTracker
-- Tracks player consumables and buffs in WoW 1.12
-- Author: Claude

-- Addon variables
SpBuffTracker = {
    version = "1.1",
    trackedBuffs = {},
    categories = {
        "Food",
        "Potions",
        "Weapon Enchants",
        "Auras"
    },
    defaultBuffs = {
        ["Food"] = {
            {name = "Well Fed", texture = "Interface\\Icons\\Spell_Misc_Food", priority = 1, enabled = true},
            {name = "Dirge's Kickin' Chimaerok Chops", texture = "Interface\\Icons\\INV_Misc_Food_65", priority = 2, enabled = true},
            {name = "Blessed Sunfruit", texture = "Interface\\Icons\\INV_Misc_Food_41", priority = 3, enabled = true},
        },
        ["Potions"] = {
            {name = "Greater Arcane Elixir", texture = "Interface\\Icons\\INV_Potion_25", priority = 1, enabled = true},
            {name = "Elixir of the Mongoose", texture = "Interface\\Icons\\INV_Potion_32", priority = 2, enabled = true},
            {name = "Flask of Supreme Power", texture = "Interface\\Icons\\INV_Potion_41", priority = 3, enabled = true},
            {name = "Flask of the Titans", texture = "Interface\\Icons\\INV_Potion_62", priority = 4, enabled = true},
            {name = "Mageblood Potion", texture = "Interface\\Icons\\INV_Potion_45", priority = 5, enabled = true},
        },
        ["Weapon Enchants"] = {
            {name = "Sharpened", texture = "Interface\\Icons\\INV_Sword_20", priority = 1, enabled = true},
            {name = "Flametongue", texture = "Interface\\Icons\\Spell_Fire_FlameTounge", priority = 2, enabled = true},
            {name = "Windfury", texture = "Interface\\Icons\\Spell_Nature_Cyclone", priority = 3, enabled = true},
            {name = "Deadly Poison", texture = "Interface\\Icons\\Ability_Rogue_DualWeild", priority = 4, enabled = true},
        },
        ["Auras"] = {
            {name = "Arcane Intellect", texture = "Interface\\Icons\\Spell_Holy_MagicalSentry", priority = 1, enabled = true},
            {name = "Power Word: Fortitude", texture = "Interface\\Icons\\Spell_Holy_WordFortitude", priority = 2, enabled = true},
            {name = "Mark of the Wild", texture = "Interface\\Icons\\Spell_Nature_Regeneration", priority = 3, enabled = true},
            {name = "Blessing of Kings", texture = "Interface\\Icons\\Spell_Magic_MageArmor", priority = 4, enabled = true},
            {name = "Blessing of Might", texture = "Interface\\Icons\\Spell_Holy_FistOfJustice", priority = 5, enabled = true},
        },
    },
    -- UI elements
    frame = nil,
    categoryFrames = {},
    buffFrames = {},
    settingsFrame = nil,
    -- Buff mapping for click-to-cast
    buffMapping = {
        ["Well Fed"] = nil, -- Consumable, no direct cast
        ["Dirge's Kickin' Chimaerok Chops"] = nil, -- Consumable, no direct cast
        ["Blessed Sunfruit"] = nil, -- Consumable, no direct cast
        ["Greater Arcane Elixir"] = nil, -- Consumable, no direct cast
        ["Elixir of the Mongoose"] = nil, -- Consumable, no direct cast
        ["Flask of Supreme Power"] = nil, -- Consumable, no direct cast
        ["Flask of the Titans"] = nil, -- Consumable, no direct cast
        ["Mageblood Potion"] = nil, -- Consumable, no direct cast
        ["Sharpened"] = nil, -- Weapon enchant, no direct cast
        ["Flametongue"] = "Flametongue Weapon",
        ["Windfury"] = "Windfury Weapon",
        ["Deadly Poison"] = "Deadly Poison",
        ["Arcane Intellect"] = "Arcane Intellect",
        ["Power Word: Fortitude"] = "Power Word: Fortitude",
        ["Mark of the Wild"] = "Mark of the Wild",
        ["Blessing of Kings"] = "Blessing of Kings",
        ["Blessing of Might"] = "Blessing of Might",
    },
    -- Character profile
    playerName = nil,
    profiles = {},
}

-- Initialize settings table first
SpBuffTracker.settings = {
    locked = false,
    scale = 1.0,
    showMissing = true,
    showBuffTimer = true,
    showIcons = true,
    showBuffNames = true,
    hideInCombat = false,
    categoryVisibility = {},
}

-- Function to ensure settings are properly initialized
function SpBuffTracker_EnsureSettings()
    -- Make sure settings table exists
    if not SpBuffTracker.settings then
        SpBuffTracker.settings = {
            locked = false,
            scale = 1.0,
            showMissing = true,
            showBuffTimer = true,
            showIcons = true,
            showBuffNames = true,
            hideInCombat = false,
            categoryVisibility = {},
        }
    end
    
    -- Make sure categoryVisibility table exists
    if not SpBuffTracker.settings.categoryVisibility then
        SpBuffTracker.settings.categoryVisibility = {}
    end
    
    -- Make sure all categories have visibility setting
    for _, category in ipairs(SpBuffTracker.categories) do
        if SpBuffTracker.settings.categoryVisibility[category] == nil then
            SpBuffTracker.settings.categoryVisibility[category] = true
        end
    end
    
    -- Make sure showBuffNames exists
    if SpBuffTracker.settings.showBuffNames == nil then
        SpBuffTracker.settings.showBuffNames = true
    end
    
    -- Make sure hideInCombat exists
    if SpBuffTracker.settings.hideInCombat == nil then
        SpBuffTracker.settings.hideInCombat = false
    end
end

-- Profile management functions
function SpBuffTracker_SaveProfile()
    if not SpBuffTracker.playerName then
        SpBuffTracker.playerName = UnitName("player")
    end
    
    -- Save current settings to player profile
    SpBuffTracker.profiles[SpBuffTracker.playerName] = {
        settings = SpBuffTracker.settings,
        trackedBuffs = {}
    }
    
    -- Copy the tracked buffs (only name and enabled state)
    for category, buffs in pairs(SpBuffTracker.trackedBuffs) do
        SpBuffTracker.profiles[SpBuffTracker.playerName].trackedBuffs[category] = {}
        for i, buffInfo in ipairs(buffs) do
            table.insert(SpBuffTracker.profiles[SpBuffTracker.playerName].trackedBuffs[category], {
                name = buffInfo.name,
                enabled = buffInfo.enabled
            })
        end
    end
end

function SpBuffTracker_LoadProfile()
    if not SpBuffTracker.playerName then
        SpBuffTracker.playerName = UnitName("player")
    end
    
    -- Check if we have a profile for this player
    if not SpBuffTracker.profiles[SpBuffTracker.playerName] then
        return
    end
    
    -- Load settings
    local profile = SpBuffTracker.profiles[SpBuffTracker.playerName]
    
    -- Copy settings
    for key, value in pairs(profile.settings) do
        SpBuffTracker.settings[key] = value
    end
    
    -- Apply tracked buff settings
    for category, buffs in pairs(profile.trackedBuffs) do
        for i, buffInfo in ipairs(buffs) do
            -- Find the buff in our current trackedBuffs and update enabled status
            for j, currentBuff in ipairs(SpBuffTracker.trackedBuffs[category] or {}) do
                if currentBuff.name == buffInfo.name then
                    currentBuff.enabled = buffInfo.enabled
                    break
                end
            end
        end
    end
end

-- Initialize the addon
function SpBuffTracker_OnLoad()
    -- Ensure settings are properly initialized
    SpBuffTracker_EnsureSettings()
    
    -- Initialize profile
    SpBuffTracker.playerName = UnitName("player")
    
    -- Then initialize default settings
    for _, category in ipairs(SpBuffTracker.categories) do
        SpBuffTracker.settings.categoryVisibility[category] = true
        SpBuffTracker.trackedBuffs[category] = {}
        
        -- Initialize with default buffs
        for _, buffInfo in ipairs(SpBuffTracker.defaultBuffs[category]) do
            table.insert(SpBuffTracker.trackedBuffs[category], {
                name = buffInfo.name,
                texture = buffInfo.texture,
                priority = buffInfo.priority,
                enabled = buffInfo.enabled,
                active = false,
                timeLeft = 0,
            })
        end
    end
    
    -- Register slash commands
    SLASH_SPBUFFTRACKER1 = "/spbufftracker"
    SLASH_SPBUFFTRACKER2 = "/sbt"
    SlashCmdList["SPBUFFTRACKER"] = SpBuffTracker_SlashCommand
    
    -- Register events
    SpBuffTracker_CreateUI()
    SpBuffTracker.frame = SpBuffTracker.frame or CreateFrame("Frame")
    SpBuffTracker.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    SpBuffTracker.frame:RegisterEvent("UNIT_AURA")
    SpBuffTracker.frame:RegisterEvent("PLAYER_AURAS_CHANGED")
    SpBuffTracker.frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat
    SpBuffTracker.frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leaving combat
    
    -- Event handler
    SpBuffTracker.frame:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            -- Load player profile
            SpBuffTracker_LoadProfile()
            -- Create UI after a slight delay to make sure everything is loaded
            SpBuffTracker.initTimer = SpBuffTracker.initTimer or CreateFrame("Frame")
            SpBuffTracker.initTimer:SetScript("OnUpdate", function()
                -- Only initialize once
                if not SpBuffTracker.initialized then
                    SpBuffTracker_CreateUI()
                    SpBuffTracker.frame:Show() -- Make sure frame is shown on login
                    SpBuffTracker.initialized = true
                end
                SpBuffTracker.initTimer:SetScript("OnUpdate", nil)
            end)
        elseif event == "UNIT_AURA" or event == "PLAYER_AURAS_CHANGED" then
            if arg1 == "player" or not arg1 then
                SpBuffTracker_UpdateBuffs()
            end
        elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            -- Combat state changed, update visibility
            SpBuffTracker_UpdateBuffs()
        end
    end)
    
    -- Create the update timer
    local updateTimer = CreateFrame("Frame")
    updateTimer:SetScript("OnUpdate", function()
        -- Only update every 0.5 seconds
        if not SpBuffTracker.lastUpdate or GetTime() - SpBuffTracker.lastUpdate >= 0.5 then
            SpBuffTracker_UpdateBuffs()
            SpBuffTracker.lastUpdate = GetTime()
        end
    end)
    
    -- Show welcome message
    DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker v"..SpBuffTracker.version.." loaded. Type /sbt for help.")
end

-- WoW 1.12 style event handling
local loadingFrame = CreateFrame("Frame")
loadingFrame:RegisterEvent("ADDON_LOADED")
loadingFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "SpBuffTracker" then
        SpBuffTracker_OnLoad()
        DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker v"..SpBuffTracker.version.." initialized!")
        loadingFrame:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Initialize when the file is loaded
-- SpBuffTracker_EnsureSettings()
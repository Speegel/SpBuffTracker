-- SpBuffTracker
-- Tracks player consumables and buffs in WoW 1.12
-- Author: Claude

-- Addon variables
SpBuffTracker = {
    version = "1.0",
    trackedBuffs = {},
    categories = {
        "Food",
        "Potions",
        "Weapon Enchants",
        "Auras"
    },
    defaultBuffs = {
        ["Food"] = {
            {name = "Well Fed", texture = "Interface\\Icons\\Spell_Misc_Food", priority = 1},
            {name = "Dirge's Kickin' Chimaerok Chops", texture = "Interface\\Icons\\INV_Misc_Food_65", priority = 2},
            {name = "Blessed Sunfruit", texture = "Interface\\Icons\\INV_Misc_Food_41", priority = 3},
        },
        ["Potions"] = {
            {name = "Greater Arcane Elixir", texture = "Interface\\Icons\\INV_Potion_25", priority = 1},
            {name = "Elixir of the Mongoose", texture = "Interface\\Icons\\INV_Potion_32", priority = 2},
            {name = "Flask of Supreme Power", texture = "Interface\\Icons\\INV_Potion_41", priority = 3},
            {name = "Flask of the Titans", texture = "Interface\\Icons\\INV_Potion_62", priority = 4},
            {name = "Mageblood Potion", texture = "Interface\\Icons\\INV_Potion_45", priority = 5},
        },
        ["Weapon Enchants"] = {
            {name = "Sharpened", texture = "Interface\\Icons\\INV_Sword_20", priority = 1},
            {name = "Flametongue", texture = "Interface\\Icons\\Spell_Fire_FlameTounge", priority = 2},
            {name = "Windfury", texture = "Interface\\Icons\\Spell_Nature_Cyclone", priority = 3},
            {name = "Deadly Poison", texture = "Interface\\Icons\\Ability_Rogue_DualWeild", priority = 4},
        },
        ["Auras"] = {
            {name = "Arcane Intellect", texture = "Interface\\Icons\\Spell_Holy_MagicalSentry", priority = 1},
            {name = "Power Word: Fortitude", texture = "Interface\\Icons\\Spell_Holy_WordFortitude", priority = 2},
            {name = "Mark of the Wild", texture = "Interface\\Icons\\Spell_Nature_Regeneration", priority = 3},
            {name = "Blessing of Kings", texture = "Interface\\Icons\\Spell_Magic_MageArmor", priority = 4},
            {name = "Blessing of Might", texture = "Interface\\Icons\\Spell_Holy_FistOfJustice", priority = 5},
        },
    },
    -- UI elements
    frame = nil,
    categoryFrames = {},
    buffFrames = {},
    -- Settings
    settings = {
        locked = false,
        scale = 1.0,
        showMissing = true,
        showBuffTimer = true,
        showIcons = true,
        categoryVisibility = {},
    },
}

-- Initialize default settings
for _, category in ipairs(SpBuffTracker.categories) do
    SpBuffTracker.settings.categoryVisibility[category] = true
    SpBuffTracker.trackedBuffs[category] = {}
    
    -- Initialize with default buffs
    for _, buffInfo in ipairs(SpBuffTracker.defaultBuffs[category]) do
        table.insert(SpBuffTracker.trackedBuffs[category], {
            name = buffInfo.name,
            texture = buffInfo.texture,
            priority = buffInfo.priority,
            active = false,
            timeLeft = 0,
        })
    end
end

-- Slash command handler
function SpBuffTracker_SlashCommand(msg)
    if msg == "show" then
        SpBuffTracker.frame:Show()
    elseif msg == "hide" then
        SpBuffTracker.frame:Hide()
    elseif msg == "lock" then
        SpBuffTracker.settings.locked = true
        SpBuffTracker_CreateUI() -- Refresh UI
    elseif msg == "unlock" then
        SpBuffTracker.settings.locked = false
        SpBuffTracker_CreateUI() -- Refresh UI
    elseif msg == "reset" then
        SpBuffTracker_ResetPosition()
    elseif msg:match("^scale (%d+%.?%d*)$") then
        local scale = tonumber(msg:match("^scale (%d+%.?%d*)$"))
        if scale and scale > 0.5 and scale <= 2.0 then
            SpBuffTracker.settings.scale = scale
            SpBuffTracker_CreateUI() -- Refresh UI
        else
            DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Scale must be between 0.5 and 2.0")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker commands:")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt show - Show the tracker")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt hide - Hide the tracker")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt lock - Lock the tracker position")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt unlock - Unlock the tracker position")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt reset - Reset tracker position")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt scale X.X - Set the tracker scale (0.5-2.0)")
    end
end

-- Resets the position of the main frame
function SpBuffTracker_ResetPosition()
    SpBuffTracker.frame:ClearAllPoints()
    SpBuffTracker.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

-- Create the buff tracker UI
function SpBuffTracker_CreateUI()
    -- Create main frame if it doesn't exist
    if not SpBuffTracker.frame then
        SpBuffTracker.frame = CreateFrame("Frame", "SpBuffTrackerFrame", UIParent)
        SpBuffTracker.frame:SetWidth(200)
        SpBuffTracker.frame:SetHeight(30)
        SpBuffTracker.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        SpBuffTracker.frame:SetMovable(true)
        SpBuffTracker.frame:EnableMouse(true)
        SpBuffTracker.frame:RegisterForDrag("LeftButton")
        SpBuffTracker.frame:SetScript("OnDragStart", function()
            if not SpBuffTracker.settings.locked then
                SpBuffTracker.frame:StartMoving()
            end
        end)
        SpBuffTracker.frame:SetScript("OnDragStop", function()
            SpBuffTracker.frame:StopMovingOrSizing()
        end)
        
        -- Title bar
        local titleBar = CreateFrame("Frame", nil, SpBuffTracker.frame)
        titleBar:SetHeight(20)
        titleBar:SetPoint("TOPLEFT", SpBuffTracker.frame, "TOPLEFT", 0, 0)
        titleBar:SetPoint("TOPRIGHT", SpBuffTracker.frame, "TOPRIGHT", 0, 0)
        
        local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
        titleBg:SetAllPoints()
        titleBg:SetTexture(0, 0, 0, 0.5)
        
        local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
        titleText:SetText("SpBuffTracker")
        
        -- Close button
        local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", 0, 0)
        closeButton:SetScript("OnClick", function()
            SpBuffTracker.frame:Hide()
        end)
        
        -- Settings button
        local settingsButton = CreateFrame("Button", nil, titleBar)
        settingsButton:SetWidth(16)
        settingsButton:SetHeight(16)
        settingsButton:SetPoint("TOPLEFT", titleBar, "TOPLEFT", 4, -2)
        settingsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
        settingsButton:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton-Highlight")
        settingsButton:SetScript("OnClick", function()
            SpBuffTracker_ToggleSettings()
        end)
    end
    
    -- Clear existing category frames
    for _, frame in pairs(SpBuffTracker.categoryFrames) do
        frame:Hide()
        frame = nil
    end
    SpBuffTracker.categoryFrames = {}
    
    -- Clear existing buff frames
    for _, frames in pairs(SpBuffTracker.buffFrames) do
        for _, frame in pairs(frames) do
            frame:Hide()
            frame = nil
        end
    end
    SpBuffTracker.buffFrames = {}
    
    -- Apply scale
    SpBuffTracker.frame:SetScale(SpBuffTracker.settings.scale)
    
    -- Create category frames
    local prevFrame = SpBuffTracker.frame
    local totalHeight = 20 -- Title bar height
    
    for _, category in ipairs(SpBuffTracker.categories) do
        if SpBuffTracker.settings.categoryVisibility[category] then
            local categoryFrame = CreateFrame("Frame", nil, SpBuffTracker.frame)
            categoryFrame:SetHeight(18)
            categoryFrame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, 0)
            categoryFrame:SetPoint("TOPRIGHT", prevFrame, "BOTTOMRIGHT", 0, 0)
            
            local categoryBg = categoryFrame:CreateTexture(nil, "BACKGROUND")
            categoryBg:SetAllPoints()
            categoryBg:SetTexture(0.1, 0.1, 0.3, 0.5)
            
            local categoryText = categoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            categoryText:SetPoint("LEFT", categoryFrame, "LEFT", 5, 0)
            categoryText:SetText(category)
            
            -- Toggle category visibility button
            local toggleButton = CreateFrame("Button", nil, categoryFrame)
            toggleButton:SetWidth(14)
            toggleButton:SetHeight(14)
            toggleButton:SetPoint("RIGHT", categoryFrame, "RIGHT", -5, 0)
            toggleButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
            toggleButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
            toggleButton:SetScript("OnClick", function()
                SpBuffTracker_ToggleCategory(category)
            end)
            
            SpBuffTracker.categoryFrames[category] = categoryFrame
            prevFrame = categoryFrame
            totalHeight = totalHeight + 18
            
            -- Create buff frames for this category
            SpBuffTracker.buffFrames[category] = {}
            
            -- Sort buffs by priority
            table.sort(SpBuffTracker.trackedBuffs[category], function(a, b)
                return a.priority < b.priority
            end)
            
            for i, buffInfo in ipairs(SpBuffTracker.trackedBuffs[category]) do
                local buffFrame = CreateFrame("Frame", nil, SpBuffTracker.frame)
                buffFrame:SetHeight(20)
                buffFrame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, 0)
                buffFrame:SetPoint("TOPRIGHT", prevFrame, "BOTTOMRIGHT", 0, 0)
                
                local buffBg = buffFrame:CreateTexture(nil, "BACKGROUND")
                buffBg:SetAllPoints()
                buffBg:SetTexture(0, 0, 0, 0.3)
                
                if i % 2 == 0 then
                    buffBg:SetTexture(0.1, 0.1, 0.1, 0.3)
                end
                
                -- Buff icon
                local buffIcon = buffFrame:CreateTexture(nil, "ARTWORK")
                buffIcon:SetWidth(16)
                buffIcon:SetHeight(16)
                buffIcon:SetPoint("LEFT", buffFrame, "LEFT", 5, 0)
                buffIcon:SetTexture(buffInfo.texture)
                
                -- Buff name
                local buffName = buffFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                buffName:SetPoint("LEFT", buffIcon, "RIGHT", 5, 0)
                buffName:SetText(buffInfo.name)
                
                -- Buff timer
                local buffTimer = buffFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                buffTimer:SetPoint("RIGHT", buffFrame, "RIGHT", -5, 0)
                buffTimer:SetText("")
                
                -- Buff status indicator
                local statusTexture = buffFrame:CreateTexture(nil, "OVERLAY")
                statusTexture:SetWidth(buffFrame:GetWidth())
                statusTexture:SetHeight(buffFrame:GetHeight())
                statusTexture:SetPoint("TOPLEFT", buffFrame, "TOPLEFT", 0, 0)
                statusTexture:SetTexture(1, 0, 0, 0.1) -- Red for missing
                statusTexture:Hide()
                
                -- Store references
                buffFrame.icon = buffIcon
                buffFrame.name = buffName
                buffFrame.timer = buffTimer
                buffFrame.status = statusTexture
                buffFrame.buffInfo = buffInfo
                
                table.insert(SpBuffTracker.buffFrames[category], buffFrame)
                prevFrame = buffFrame
                totalHeight = totalHeight + 20
            end
        end
    end
    
    -- Set the height of the main frame
    SpBuffTracker.frame:SetHeight(totalHeight)
    
    -- Update buff status
    SpBuffTracker_UpdateBuffs()
end

-- Toggle category visibility
function SpBuffTracker_ToggleCategory(category)
    SpBuffTracker.settings.categoryVisibility[category] = not SpBuffTracker.settings.categoryVisibility[category]
    SpBuffTracker_CreateUI() -- Refresh UI
end

-- Create settings panel
function SpBuffTracker_CreateSettingsPanel()
    if SpBuffTracker.settingsFrame then
        SpBuffTracker.settingsFrame:Show()
        return
    end
    
    local frame = CreateFrame("Frame", "SpBuffTrackerSettingsFrame", UIParent)
    frame:SetWidth(250)
    frame:SetHeight(300)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("SpBuffTracker Settings")
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Show Missing Buffs option
    local showMissingCheckbox = CreateFrame("CheckButton", "SpBuffTrackerShowMissingCheckbox", frame, "UICheckButtonTemplate")
    showMissingCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -40)
    showMissingCheckbox:SetChecked(SpBuffTracker.settings.showMissing)
    getglobal(showMissingCheckbox:GetName().."Text"):SetText("Highlight Missing Buffs")
    showMissingCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.showMissing = showMissingCheckbox:GetChecked()
        SpBuffTracker_UpdateBuffs()
    end)
    
    -- Show Buff Timer option
    local showTimerCheckbox = CreateFrame("CheckButton", "SpBuffTrackerShowTimerCheckbox", frame, "UICheckButtonTemplate")
    showTimerCheckbox:SetPoint("TOPLEFT", showMissingCheckbox, "BOTTOMLEFT", 0, -10)
    showTimerCheckbox:SetChecked(SpBuffTracker.settings.showBuffTimer)
    getglobal(showTimerCheckbox:GetName().."Text"):SetText("Show Buff Timer")
    showTimerCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.showBuffTimer = showTimerCheckbox:GetChecked()
        SpBuffTracker_UpdateBuffs()
    end)
    
    -- Show Icons option
    local showIconsCheckbox = CreateFrame("CheckButton", "SpBuffTrackerShowIconsCheckbox", frame, "UICheckButtonTemplate")
    showIconsCheckbox:SetPoint("TOPLEFT", showTimerCheckbox, "BOTTOMLEFT", 0, -10)
    showIconsCheckbox:SetChecked(SpBuffTracker.settings.showIcons)
    getglobal(showIconsCheckbox:GetName().."Text"):SetText("Show Buff Icons")
    showIconsCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.showIcons = showIconsCheckbox:GetChecked()
        SpBuffTracker_CreateUI() -- Refresh UI
    end)
    
    -- Scale slider
    local scaleSlider = CreateFrame("Slider", "SpBuffTrackerScaleSlider", frame, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", showIconsCheckbox, "BOTTOMLEFT", 0, -30)
    scaleSlider:SetWidth(200)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetValue(SpBuffTracker.settings.scale)
    getglobal(scaleSlider:GetName().."Text"):SetText("UI Scale")
    getglobal(scaleSlider:GetName().."Low"):SetText("0.5")
    getglobal(scaleSlider:GetName().."High"):SetText("2.0")
    scaleSlider:SetScript("OnValueChanged", function()
        local scale = floor(scaleSlider:GetValue() * 10 + 0.5) / 10
        SpBuffTracker.settings.scale = scale
        SpBuffTracker_CreateUI() -- Refresh UI
    end)
    
    -- Category visibility options
    local categoryText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryText:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -20)
    categoryText:SetText("Category Visibility:")
    
    local prevElement = categoryText
    for i, category in ipairs(SpBuffTracker.categories) do
        local checkbox = CreateFrame("CheckButton", "SpBuffTrackerCategory"..i.."Checkbox", frame, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", prevElement, "BOTTOMLEFT", 0, -10)
        checkbox:SetChecked(SpBuffTracker.settings.categoryVisibility[category])
        getglobal(checkbox:GetName().."Text"):SetText(category)
        checkbox:SetScript("OnClick", function()
            SpBuffTracker.settings.categoryVisibility[category] = checkbox:GetChecked()
            SpBuffTracker_CreateUI() -- Refresh UI
        end)
        prevElement = checkbox
    end
    
    SpBuffTracker.settingsFrame = frame
end

-- Toggle settings panel
function SpBuffTracker_ToggleSettings()
    SpBuffTracker_CreateSettingsPanel()
    if SpBuffTracker.settingsFrame:IsVisible() then
        SpBuffTracker.settingsFrame:Hide()
    else
        SpBuffTracker.settingsFrame:Show()
    end
end

-- Format time in MM:SS format
function SpBuffTracker_FormatTime(seconds)
    if seconds <= 0 then
        return ""
    end
    
    local minutes = floor(seconds / 60)
    seconds = seconds % 60
    
    if minutes > 0 then
        return string.format("%d:%02d", minutes, seconds)
    else
        return string.format("%ds", seconds)
    end
end

-- Check if a specific buff is active
function SpBuffTracker_IsBuffActive(buffName)
    local i = 1
    local name, _, _, _, _, duration, expirationTime = UnitBuff("player", i)
    
    while name do
        if name == buffName then
            local timeLeft = 0
            if expirationTime and expirationTime > 0 then
                timeLeft = expirationTime - GetTime()
                if timeLeft < 0 then timeLeft = 0 end
            end
            return true, timeLeft
        end
        i = i + 1
        name, _, _, _, _, duration, expirationTime = UnitBuff("player", i)
    end
    
    return false, 0
end

-- Check if weapon has a temporary enchant
function SpBuffTracker_HasWeaponEnchant(slot)
    local hasEnchant, timeLeft = GetWeaponEnchantInfo()
    if slot == 1 then
        return hasEnchant, timeLeft or 0
    else
        return false, 0
    end
end

-- Update buff status
function SpBuffTracker_UpdateBuffs()
    for category, buffs in pairs(SpBuffTracker.trackedBuffs) do
        for i, buffInfo in ipairs(buffs) do
            local isActive, timeLeft = false, 0
            
            -- Check different types of buffs
            if category == "Weapon Enchants" then
                -- For weapon enchants, we need to check both weapons
                local hasMainEnchant, mainTimeLeft = SpBuffTracker_HasWeaponEnchant(1)
                local hasOffEnchant, offTimeLeft = SpBuffTracker_HasWeaponEnchant(2)
                
                -- This is simplified - in a real addon you'd want to check the actual enchant type
                if hasMainEnchant or hasOffEnchant then
                    isActive = true
                    timeLeft = max(mainTimeLeft or 0, offTimeLeft or 0)
                end
            else
                -- For normal buffs
                isActive, timeLeft = SpBuffTracker_IsBuffActive(buffInfo.name)
            end
            
            -- Update buff info
            buffInfo.active = isActive
            buffInfo.timeLeft = timeLeft
            
            -- Update buff frame if it exists
            if SpBuffTracker.buffFrames[category] and SpBuffTracker.buffFrames[category][i] then
                local frame = SpBuffTracker.buffFrames[category][i]
                
                -- Show/hide icon based on settings
                if SpBuffTracker.settings.showIcons then
                    frame.icon:Show()
                else
                    frame.icon:Hide()
                end
                
                -- Update timer text
                if SpBuffTracker.settings.showBuffTimer and isActive and timeLeft > 0 then
                    frame.timer:SetText(SpBuffTracker_FormatTime(timeLeft))
                else
                    frame.timer:SetText("")
                end
                
                -- Update status indicator
                if SpBuffTracker.settings.showMissing and not isActive then
                    frame.status:Show()
                else
                    frame.status:Hide()
                end
            end
        end
    end
end

-- Initialize the addon
function SpBuffTracker_OnLoad()
    -- Register slash commands
    SLASH_SPBUFFTRACKER1 = "/spbufftracker"
    SLASH_SPBUFFTRACKER2 = "/sbt"
    SlashCmdList["SPBUFFTRACKER"] = SpBuffTracker_SlashCommand
    
    -- Register events
    SpBuffTracker.frame = SpBuffTracker.frame or CreateFrame("Frame")
    SpBuffTracker.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    SpBuffTracker.frame:RegisterEvent("UNIT_AURA")
    SpBuffTracker.frame:RegisterEvent("PLAYER_AURAS_CHANGED")
    
    -- Event handler
    SpBuffTracker.frame:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            SpBuffTracker_CreateUI()
        elseif event == "UNIT_AURA" or event == "PLAYER_AURAS_CHANGED" then
            if arg1 == "player" or not arg1 then
                SpBuffTracker_UpdateBuffs()
            end
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

-- Run initialization
SpBuffTracker_OnLoad()
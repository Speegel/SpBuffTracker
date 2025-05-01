-- SpBuffTracker Settings Module
-- Contains settings UI and functionality

-- Create settings panel
function SpBuffTracker_CreateSettingsPanel()
    -- Make sure we initialize our variables first
    -- SpBuffTracker_EnsureSettings()
    
    -- Debug message
    DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Creating settings panel")
    
    -- Destroy old frame if it exists
    if SpBuffTracker.settingsFrame then
        SpBuffTracker.settingsFrame:Hide()
    end
    
    -- Get frame position before creating settings
    local mainFramePos = {}
    if SpBuffTracker.frame then
        mainFramePos.point, mainFramePos.relativeTo, mainFramePos.relativePoint, mainFramePos.x, mainFramePos.y = SpBuffTracker.frame:GetPoint()
    end
    
    -- Create the main settings frame
    local frame = CreateFrame("Frame", "SpBuffTrackerSettingsFrame", UIParent)
    SpBuffTracker.settingsFrame = frame
    
    frame:SetWidth(300)
    frame:SetHeight(400)
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
        
        -- Restore main frame position if it changed
        if SpBuffTracker.frame and mainFramePos.point then
            SpBuffTracker.frame:ClearAllPoints()
            SpBuffTracker.frame:SetPoint(mainFramePos.point, mainFramePos.relativeTo, mainFramePos.relativePoint, mainFramePos.x, mainFramePos.y)
        end
        
        -- Save settings to profile
        SpBuffTracker_SaveProfile()
    end)
    
    -- Create content directly in frame instead of using a scroll frame for simplicity
    -- First section - Display Options
    local sectionTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sectionTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -40)
    sectionTitle:SetText("Display Options:")
    
    -- Show Missing Buffs option
    local showMissingCheckbox = CreateFrame("CheckButton", "SpBuffTrackerShowMissingCheckbox", frame, "UICheckButtonTemplate")
    showMissingCheckbox:SetPoint("TOPLEFT", sectionTitle, "BOTTOMLEFT", 10, -10)
    showMissingCheckbox:SetChecked(SpBuffTracker.settings.showMissing)
    getglobal(showMissingCheckbox:GetName().."Text"):SetText("Highlight Missing Buffs")
    showMissingCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.showMissing = showMissingCheckbox:GetChecked()
        SpBuffTracker_UpdateBuffs()
    end)
    
    -- Show Buff Timer option
    local showTimerCheckbox = CreateFrame("CheckButton", "SpBuffTrackerShowTimerCheckbox", frame, "UICheckButtonTemplate")
    showTimerCheckbox:SetPoint("TOPLEFT", showMissingCheckbox, "BOTTOMLEFT", 0, -5)
    showTimerCheckbox:SetChecked(SpBuffTracker.settings.showBuffTimer)
    getglobal(showTimerCheckbox:GetName().."Text"):SetText("Show Buff Timer")
    showTimerCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.showBuffTimer = showTimerCheckbox:GetChecked()
        SpBuffTracker_UpdateBuffs()
    end)
    
    -- Show Icons option
    local showIconsCheckbox = CreateFrame("CheckButton", "SpBuffTrackerShowIconsCheckbox", frame, "UICheckButtonTemplate")
    showIconsCheckbox:SetPoint("TOPLEFT", showTimerCheckbox, "BOTTOMLEFT", 0, -5)
    showIconsCheckbox:SetChecked(SpBuffTracker.settings.showIcons)
    getglobal(showIconsCheckbox:GetName().."Text"):SetText("Show Buff Icons")
    showIconsCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.showIcons = showIconsCheckbox:GetChecked()
        SpBuffTracker_CreateUI() -- Refresh UI
    end)
    
    -- Show Buff Names option
    local showBuffNamesCheckbox = CreateFrame("CheckButton", "SpBuffTrackerShowBuffNamesCheckbox", frame, "UICheckButtonTemplate")
    showBuffNamesCheckbox:SetPoint("TOPLEFT", showIconsCheckbox, "BOTTOMLEFT", 0, -5)
    showBuffNamesCheckbox:SetChecked(SpBuffTracker.settings.showBuffNames)
    getglobal(showBuffNamesCheckbox:GetName().."Text"):SetText("Show Buff Names")
    showBuffNamesCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.showBuffNames = showBuffNamesCheckbox:GetChecked()
        SpBuffTracker_UpdateBuffs()
    end)
    
    -- Hide in Combat option
    local hideInCombatCheckbox = CreateFrame("CheckButton", "SpBuffTrackerHideInCombatCheckbox", frame, "UICheckButtonTemplate")
    hideInCombatCheckbox:SetPoint("TOPLEFT", showBuffNamesCheckbox, "BOTTOMLEFT", 0, -5)
    hideInCombatCheckbox:SetChecked(SpBuffTracker.settings.hideInCombat)
    getglobal(hideInCombatCheckbox:GetName().."Text"):SetText("Hide in Combat")
    hideInCombatCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.hideInCombat = hideInCombatCheckbox:GetChecked()
        SpBuffTracker_UpdateBuffs()
    end)
    
    -- Scale slider
    local scaleTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleTitle:SetPoint("TOPLEFT", hideInCombatCheckbox, "BOTTOMLEFT", 0, -10)
    scaleTitle:SetText("UI Scale:")
    
    local scaleSlider = CreateFrame("Slider", "SpBuffTrackerScaleSlider", frame, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", scaleTitle, "BOTTOMLEFT", 5, -10)
    scaleSlider:SetWidth(250)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetValue(SpBuffTracker.settings.scale)
    getglobal(scaleSlider:GetName().."Text"):SetText(SpBuffTracker.settings.scale)
    getglobal(scaleSlider:GetName().."Low"):SetText("0.5")
    getglobal(scaleSlider:GetName().."High"):SetText("2.0")
    scaleSlider:SetScript("OnValueChanged", function()
        local scale = math.floor(scaleSlider:GetValue() * 10 + 0.5) / 10
        SpBuffTracker.settings.scale = scale
        getglobal(scaleSlider:GetName().."Text"):SetText(scale)
        SpBuffTracker_CreateUI() -- Refresh UI
        
        -- Maintain position after scaling
        if mainFramePos.point then
            SpBuffTracker.frame:ClearAllPoints()
            SpBuffTracker.frame:SetPoint(mainFramePos.point, mainFramePos.relativeTo, mainFramePos.relativePoint, mainFramePos.x, mainFramePos.y)
        end
    end)
    
    -- Category visibility options
    local categoryText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryText:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", -5, -15)
    categoryText:SetText("Category Visibility:")
    
    local prevElement = categoryText
    for i, category in ipairs(SpBuffTracker.categories) do
        local currentCategory = category
        local checkbox = CreateFrame("CheckButton", "SpBuffTrackerCategory"..i.."Checkbox", frame, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", prevElement, "BOTTOMLEFT", 0, 0)
        checkbox:SetChecked(SpBuffTracker.settings.categoryVisibility[category])
        getglobal(checkbox:GetName().."Text"):SetText(category)
        checkbox:SetScript("OnClick", function()
            -- SpBuffTracker.settings.categoryVisibility[category] = checkbox:GetChecked()
            -- SpBuffTracker_CreateUI() -- Refresh UI
            SpBuffTracker_ToggleCategory(currentCategory)
            -- Maintain position after redrawing
            if mainFramePos.point then
                SpBuffTracker.frame:ClearAllPoints()
                SpBuffTracker.frame:SetPoint(mainFramePos.point, mainFramePos.relativeTo, mainFramePos.relativePoint, mainFramePos.x, mainFramePos.y)
            end
        end)
        prevElement = checkbox
    end
    
    -- Show the frame
    frame:Show()
    
    -- Debug message
    DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Settings panel created and shown")
    return frame
end

-- Toggle settings panel
function SpBuffTracker_ToggleSettings()
    -- Debug message
    DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Toggling settings panel")
    
    if SpBuffTracker.settingsFrame and SpBuffTracker.settingsFrame:IsVisible() then
        SpBuffTracker.settingsFrame:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Settings panel hidden")
    else
        SpBuffTracker_CreateSettingsPanel()
    end
end
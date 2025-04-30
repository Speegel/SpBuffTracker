-- SpBuffTracker Settings Module
-- Contains settings UI and functionality

-- Create settings panel
function SpBuffTracker_CreateSettingsPanel()
    if SpBuffTracker.settingsFrame then
        SpBuffTracker.settingsFrame:Show()
        return
    end
    
    -- Get frame position before creating settings
    local mainFramePos = {}
    if SpBuffTracker.frame then
        mainFramePos.point, mainFramePos.relativeTo, mainFramePos.relativePoint, mainFramePos.x, mainFramePos.y = SpBuffTracker.frame:GetPoint()
    end
    
    local frame = CreateFrame("Frame", "SpBuffTrackerSettingsFrame", UIParent)
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
    
    -- Scrollable content area
    local scrollFrame = CreateFrame("ScrollFrame", "SpBuffTrackerSettingsScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -40, 20)
    
    local scrollChild = CreateFrame("Frame", "SpBuffTrackerSettingsScrollChild", scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(600) -- Set initial height, will adjust as needed
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Show Missing Buffs option
    local showMissingCheckbox = CreateFrame("CheckButton", "SpBuffTrackerShowMissingCheckbox", scrollChild, "UICheckButtonTemplate")
    showMissingCheckbox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, -10)
    showMissingCheckbox:SetChecked(SpBuffTracker.settings.showMissing)
    getglobal(showMissingCheckbox:GetName().."Text"):SetText("Highlight Missing Buffs")
    showMissingCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.showMissing = showMissingCheckbox:GetChecked()
        SpBuffTracker_UpdateBuffs()
    end)
    
    -- Show Buff Timer option
    local showTimerCheckbox = CreateFrame("CheckButton", "SpBuffTrackerShowTimerCheckbox", scrollChild, "UICheckButtonTemplate")
    showTimerCheckbox:SetPoint("TOPLEFT", showMissingCheckbox, "BOTTOMLEFT", 0, -10)
    showTimerCheckbox:SetChecked(SpBuffTracker.settings.showBuffTimer)
    getglobal(showTimerCheckbox:GetName().."Text"):SetText("Show Buff Timer")
    showTimerCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.showBuffTimer = showTimerCheckbox:GetChecked()
        SpBuffTracker_UpdateBuffs()
    end)
    
    -- Show Icons option
    local showIconsCheckbox = CreateFrame("CheckButton", "SpBuffTrackerShowIconsCheckbox", scrollChild, "UICheckButtonTemplate")
    showIconsCheckbox:SetPoint("TOPLEFT", showTimerCheckbox, "BOTTOMLEFT", 0, -10)
    showIconsCheckbox:SetChecked(SpBuffTracker.settings.showIcons)
    getglobal(showIconsCheckbox:GetName().."Text"):SetText("Show Buff Icons")
    showIconsCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.showIcons = showIconsCheckbox:GetChecked()
        SpBuffTracker_CreateUI() -- Refresh UI
    end)
    
    -- Show Buff Names option
    local showBuffNamesCheckbox = CreateFrame("CheckButton", "SpBuffTrackerShowBuffNamesCheckbox", scrollChild, "UICheckButtonTemplate")
    showBuffNamesCheckbox:SetPoint("TOPLEFT", showIconsCheckbox, "BOTTOMLEFT", 0, -10)
    showBuffNamesCheckbox:SetChecked(SpBuffTracker.settings.showBuffNames)
    getglobal(showBuffNamesCheckbox:GetName().."Text"):SetText("Show Buff Names")
    showBuffNamesCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.showBuffNames = showBuffNamesCheckbox:GetChecked()
        SpBuffTracker_UpdateBuffs()
    end)
    
    -- Hide in Combat option
    local hideInCombatCheckbox = CreateFrame("CheckButton", "SpBuffTrackerHideInCombatCheckbox", scrollChild, "UICheckButtonTemplate")
    hideInCombatCheckbox:SetPoint("TOPLEFT", showBuffNamesCheckbox, "BOTTOMLEFT", 0, -10)
    hideInCombatCheckbox:SetChecked(SpBuffTracker.settings.hideInCombat)
    getglobal(hideInCombatCheckbox:GetName().."Text"):SetText("Hide in Combat")
    hideInCombatCheckbox:SetScript("OnClick", function()
        SpBuffTracker.settings.hideInCombat = hideInCombatCheckbox:GetChecked()
        SpBuffTracker_UpdateBuffs()
    end)
    
    -- Scale slider
    local scaleSlider = CreateFrame("Slider", "SpBuffTrackerScaleSlider", scrollChild, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", hideInCombatCheckbox, "BOTTOMLEFT", 0, -30)
    scaleSlider:SetWidth(scrollChild:GetWidth() - 30)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetValue(SpBuffTracker.settings.scale)
    getglobal(scaleSlider:GetName().."Text"):SetText("UI Scale")
    getglobal(scaleSlider:GetName().."Low"):SetText("0.5")
    getglobal(scaleSlider:GetName().."High"):SetText("2.0")
    scaleSlider:SetScript("OnValueChanged", function()
        local scale = math.floor(scaleSlider:GetValue() * 10 + 0.5) / 10
        SpBuffTracker.settings.scale = scale
        SpBuffTracker_CreateUI() -- Refresh UI
        
        -- Maintain position after scaling
        if mainFramePos.point then
            SpBuffTracker.frame:ClearAllPoints()
            SpBuffTracker.frame:SetPoint(mainFramePos.point, mainFramePos.relativeTo, mainFramePos.relativePoint, mainFramePos.x, mainFramePos.y)
        end
    end)
    
    -- Category visibility options
    local categoryText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryText:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -20)
    categoryText:SetText("Category Visibility:")
    
    local prevElement = categoryText
    for i, category in ipairs(SpBuffTracker.categories) do
        local checkbox = CreateFrame("CheckButton", "SpBuffTrackerCategory"..i.."Checkbox", scrollChild, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", prevElement, "BOTTOMLEFT", 0, -10)
        checkbox:SetChecked(SpBuffTracker.settings.categoryVisibility[category])
        getglobal(checkbox:GetName().."Text"):SetText(category)
        checkbox:SetScript("OnClick", function()
            SpBuffTracker.settings.categoryVisibility[category] = checkbox:GetChecked()
            SpBuffTracker_CreateUI() -- Refresh UI
            
            -- Maintain position after redrawing
            if mainFramePos.point then
                SpBuffTracker.frame:ClearAllPoints()
                SpBuffTracker.frame:SetPoint(mainFramePos.point, mainFramePos.relativeTo, mainFramePos.relativePoint, mainFramePos.x, mainFramePos.y)
            end
        end)
        prevElement = checkbox
    end
    
    -- Buff selection section
    local buffSelectionText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buffSelectionText:SetPoint("TOPLEFT", prevElement, "BOTTOMLEFT", 0, -20)
    buffSelectionText:SetText("Buff Selection:")
    
    prevElement = buffSelectionText
    local totalHeight = 0
    
    -- Add each category and its buffs
    for _, category in ipairs(SpBuffTracker.categories) do
        -- Category header
        local categoryHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        categoryHeader:SetPoint("TOPLEFT", prevElement, "BOTTOMLEFT", 0, -10)
        categoryHeader:SetText(category)
        prevElement = categoryHeader
        totalHeight = totalHeight + 20
        
        -- Buffs in this category
        for i, buffInfo in ipairs(SpBuffTracker.trackedBuffs[category]) do
            local buffCheckbox = CreateFrame("CheckButton", "SpBuffTracker"..category..i.."Checkbox", scrollChild, "UICheckButtonTemplate")
            buffCheckbox:SetPoint("TOPLEFT", prevElement, "BOTTOMLEFT", 15, -5) -- Indented
            
            -- Initialize enabled status if not set
            if buffInfo.enabled == nil then
                buffInfo.enabled = true
            end
            
            buffCheckbox:SetChecked(buffInfo.enabled)
            getglobal(buffCheckbox:GetName().."Text"):SetText(buffInfo.name)
            buffCheckbox:SetScript("OnClick", function()
                buffInfo.enabled = buffCheckbox:GetChecked()
                SpBuffTracker_CreateUI() -- Refresh UI
                
                -- Maintain position after redrawing
                if mainFramePos.point then
                    SpBuffTracker.frame:ClearAllPoints()
                    SpBuffTracker.frame:SetPoint(mainFramePos.point, mainFramePos.relativeTo, mainFramePos.relativePoint, mainFramePos.x, mainFramePos.y)
                end
            end)
            prevElement = buffCheckbox
            totalHeight = totalHeight + 25
        end
    end
    
    -- Set scroll child height based on content
    scrollChild:SetHeight(math.max(600, totalHeight + 100))
    
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
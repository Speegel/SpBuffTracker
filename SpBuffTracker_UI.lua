-- SpBuffTracker UI Module
-- Contains UI creation and management functions

-- Create the buff tracker UI
function SpBuffTracker_CreateUI()
    -- Ensure settings are properly initialized
    SpBuffTracker_EnsureSettings()
    
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
        
        -- Main background
        local mainBg = SpBuffTracker.frame:CreateTexture(nil, "BACKGROUND")
        mainBg:SetAllPoints()
        mainBg:SetTexture(0, 0, 0, 0.5)
        
        -- Title bar
        local titleBar = CreateFrame("Frame", nil, SpBuffTracker.frame)
        titleBar:SetHeight(20)
        titleBar:SetPoint("TOPLEFT", SpBuffTracker.frame, "TOPLEFT", 0, 0)
        titleBar:SetPoint("TOPRIGHT", SpBuffTracker.frame, "TOPRIGHT", 0, 0)
        
        local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
        titleBg:SetAllPoints()
        titleBg:SetTexture(0.1, 0.1, 0.3, 0.8)
        
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
        -- Make sure the category visibility is set (safety check)
        if SpBuffTracker.settings.categoryVisibility[category] == nil then
            SpBuffTracker.settings.categoryVisibility[category] = true
        end
        
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
            
            -- Buff frames for this category
            SpBuffTracker.buffFrames[category] = {}
            
            -- Sort buffs by priority
            table.sort(SpBuffTracker.trackedBuffs[category], function(a, b)
                return a.priority < b.priority
            end)
            
            for i, buffInfo in ipairs(SpBuffTracker.trackedBuffs[category]) do
                -- Only show if the buff is enabled
                if buffInfo.enabled then
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
                    
                    -- Make the buff clickable
                    local clickableArea = CreateFrame("Button", nil, buffFrame)
                    clickableArea:SetAllPoints()
                    clickableArea:SetScript("OnClick", function()
                        SpBuffTracker_BuffClicked(buffInfo.name)
                    end)
                    clickableArea:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                    
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
                    
                    -- Buff status indicator - full frame
                    local statusTexture = buffFrame:CreateTexture(nil, "OVERLAY")
                    statusTexture:SetAllPoints(buffFrame)
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
    end
    
    -- Set the height of the main frame
    SpBuffTracker.frame:SetHeight(totalHeight)
    
    -- Update buff status
    SpBuffTracker_UpdateBuffs()
end

-- Toggle category visibility
function SpBuffTracker_ToggleCategory(category)
    -- Make sure settings are initialized
    SpBuffTracker_EnsureSettings()
    
    -- Toggle the visibility
    SpBuffTracker.settings.categoryVisibility[category] = not SpBuffTracker.settings.categoryVisibility[category]
    SpBuffTracker_CreateUI() -- Refresh UI
end

-- Resets the position of the main frame
function SpBuffTracker_ResetPosition()
    SpBuffTracker.frame:ClearAllPoints()
    SpBuffTracker.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end
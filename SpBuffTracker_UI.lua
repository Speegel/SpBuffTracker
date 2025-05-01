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
        
        -- Create a content frame for all the buff categories/entries
        SpBuffTracker.contentFrame = CreateFrame("Frame", "SpBuffTrackerContentFrame", SpBuffTracker.frame)
        SpBuffTracker.contentFrame:SetPoint("TOPLEFT", SpBuffTracker.frame, "TOPLEFT", 0, -20) -- Below title bar
        SpBuffTracker.contentFrame:SetPoint("TOPRIGHT", SpBuffTracker.frame, "TOPRIGHT", 0, -20)
    end
    
    -- Apply scale
    SpBuffTracker.frame:SetScale(SpBuffTracker.settings.scale)
    
    -- Initialize tables
    if not SpBuffTracker.collapsedCategories then SpBuffTracker.collapsedCategories = {} end
    if not SpBuffTracker.categoryFrames then SpBuffTracker.categoryFrames = {} end
    if not SpBuffTracker.buffFrames then SpBuffTracker.buffFrames = {} end
    
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
    
    -- Create category frames
    local prevFrame = SpBuffTracker.contentFrame
    local totalHeight = 0
    
    for _, category in ipairs(SpBuffTracker.categories) do
        -- Make sure the category visibility is set (safety check)
        if SpBuffTracker.settings.categoryVisibility[category] == nil then
            SpBuffTracker.settings.categoryVisibility[category] = true
        end
        
        -- Make sure the collapsed state is initialized
        if SpBuffTracker.collapsedCategories[category] == nil then
            SpBuffTracker.collapsedCategories[category] = false
        end
        
        if SpBuffTracker.settings.categoryVisibility[category] then
            -- Create category header frame
            local categoryFrame = CreateFrame("Frame", nil, SpBuffTracker.contentFrame)
            categoryFrame:SetHeight(18)
            
            if prevFrame == SpBuffTracker.contentFrame then
                categoryFrame:SetPoint("TOPLEFT", prevFrame, "TOPLEFT", 0, 0)
                categoryFrame:SetPoint("TOPRIGHT", prevFrame, "TOPRIGHT", 0, 0)
            else
                categoryFrame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, 0)
                categoryFrame:SetPoint("TOPRIGHT", prevFrame, "BOTTOMRIGHT", 0, 0)
            end
            
            local categoryBg = categoryFrame:CreateTexture(nil, "BACKGROUND")
            categoryBg:SetAllPoints()
            categoryBg:SetTexture(0.1, 0.1, 0.3, 0.5)
            
            local categoryText = categoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            categoryText:SetPoint("LEFT", categoryFrame, "LEFT", 5, 0)
            categoryText:SetText(category)
            
            -- Toggle category collapse button
            local toggleButton = CreateFrame("Button", nil, categoryFrame)
            toggleButton:SetWidth(14)
            toggleButton:SetHeight(14)
            toggleButton:SetPoint("RIGHT", categoryFrame, "RIGHT", -5, 0)
            
            -- Set the appropriate texture based on collapsed state
            if SpBuffTracker.collapsedCategories[category] then
                toggleButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
            else
                toggleButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
            end
            
            toggleButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
            
            -- Store the category name directly on the button for use in the click handler
            toggleButton.categoryName = category
            
            toggleButton:SetScript("OnClick", function()
                local catName = this.categoryName
                if catName then
                    SpBuffTracker_ToggleCategory(catName)
                else
                    DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Error - category name is nil")
                end
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
            
            -- Only create buff entries if category is not collapsed
            if not SpBuffTracker.collapsedCategories[category] then
                for i, buffInfo in ipairs(SpBuffTracker.trackedBuffs[category]) do
                    -- Only show if the buff is enabled
                    if buffInfo.enabled then
                        local buffFrame = CreateFrame("Frame", nil, SpBuffTracker.contentFrame)
                        buffFrame:SetHeight(20)
                        buffFrame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, 0)
                        buffFrame:SetPoint("TOPRIGHT", prevFrame, "BOTTOMRIGHT", 0, 0)
                        
                        local buffBg = buffFrame:CreateTexture(nil, "BACKGROUND")
                        buffBg:SetAllPoints()
                        
                        if math.mod(i, 2) == 0 then
                            buffBg:SetTexture(0.1, 0.1, 0.1, 0.3)
                        else
                            buffBg:SetTexture(0, 0, 0, 0.2)
                        end
                        
                        -- Make the buff clickable
                        local clickableArea = CreateFrame("Button", nil, buffFrame)
                        clickableArea:SetAllPoints()
                        clickableArea.buffName = buffInfo.name
                        clickableArea:SetScript("OnClick", function()
                            SpBuffTracker_BuffClicked(this.buffName)
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
    end
    
    -- Set the height of the content frame
    SpBuffTracker.contentFrame:SetHeight(totalHeight)
    
    -- Set the height of the main frame (title bar + content)
    SpBuffTracker.frame:SetHeight(20 + totalHeight)
    
    -- Update buff status
    SpBuffTracker_UpdateBuffs()
end

-- Toggle category collapse state with minimal UI updates
function SpBuffTracker_ToggleCategory(category)
    -- Toggle the collapsed state
    SpBuffTracker.collapsedCategories[category] = not SpBuffTracker.collapsedCategories[category]
    
    -- Change the toggle button texture
    if SpBuffTracker.categoryFrames[category] and SpBuffTracker.categoryFrames[category]:GetChildren() then
        local toggleButton = SpBuffTracker.categoryFrames[category]:GetChildren()
        if toggleButton then
            if SpBuffTracker.collapsedCategories[category] then
                toggleButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
            else
                toggleButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
            end
        end
    end
    
    -- Create or hide the buff frames without rebuilding everything
    SpBuffTracker_RefreshCategory(category)
    
    -- Update the full layout
    SpBuffTracker_UpdateLayout()
    
    -- Update buff statuses
    SpBuffTracker_UpdateBuffs()
end

-- Update a specific category's buffs without recreating the entire UI
function SpBuffTracker_RefreshCategory(category)
    -- Find the category frame
    local categoryFrame = SpBuffTracker.categoryFrames[category]
    if not categoryFrame then return end
    
    -- Clear existing buff frames for this category
    if SpBuffTracker.buffFrames[category] then
        for _, frame in pairs(SpBuffTracker.buffFrames[category]) do
            frame:Hide()
            frame = nil
        end
    end
    SpBuffTracker.buffFrames[category] = {}
    
    -- If category is collapsed, we're done
    if SpBuffTracker.collapsedCategories[category] then
        return
    end
    
    -- Sort buffs by priority
    table.sort(SpBuffTracker.trackedBuffs[category], function(a, b)
        return a.priority < b.priority
    end)
    
    -- Category is expanded, create buff frames
    local prevFrame = categoryFrame
    
    for i, buffInfo in ipairs(SpBuffTracker.trackedBuffs[category]) do
        -- Only show if the buff is enabled
        if buffInfo.enabled then
            local buffFrame = CreateFrame("Frame", nil, SpBuffTracker.contentFrame)
            buffFrame:SetHeight(20)
            buffFrame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, 0)
            buffFrame:SetPoint("TOPRIGHT", prevFrame, "BOTTOMRIGHT", 0, 0)
            
            local buffBg = buffFrame:CreateTexture(nil, "BACKGROUND")
            buffBg:SetAllPoints()
            
            if math.mod(i, 2) == 0 then
                buffBg:SetTexture(0.1, 0.1, 0.1, 0.3)
            else
                buffBg:SetTexture(0, 0, 0, 0.2)
            end
            
            -- Make the buff clickable
            local clickableArea = CreateFrame("Button", nil, buffFrame)
            clickableArea:SetAllPoints()
            clickableArea.buffName = buffInfo.name
            clickableArea:SetScript("OnClick", function()
                SpBuffTracker_BuffClicked(this.buffName)
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
        end
    end
end

-- Update the layout without recreating the entire UI
function SpBuffTracker_UpdateLayout()
    local prevFrame = SpBuffTracker.contentFrame
    local totalHeight = 0
    
    -- Process each category
    for _, category in ipairs(SpBuffTracker.categories) do
        if SpBuffTracker.settings.categoryVisibility[category] and SpBuffTracker.categoryFrames[category] then
            local categoryFrame = SpBuffTracker.categoryFrames[category]
            
            -- Position the category frame
            categoryFrame:ClearAllPoints()
            if prevFrame == SpBuffTracker.contentFrame then
                categoryFrame:SetPoint("TOPLEFT", prevFrame, "TOPLEFT", 0, 0)
                categoryFrame:SetPoint("TOPRIGHT", prevFrame, "TOPRIGHT", 0, 0)
            else
                categoryFrame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, 0)
                categoryFrame:SetPoint("TOPRIGHT", prevFrame, "BOTTOMRIGHT", 0, 0)
            end
            
            prevFrame = categoryFrame
            totalHeight = totalHeight + 18
            
            -- If category not collapsed, position buff frames
            if not SpBuffTracker.collapsedCategories[category] and SpBuffTracker.buffFrames[category] then
                for _, buffFrame in ipairs(SpBuffTracker.buffFrames[category]) do
                    buffFrame:ClearAllPoints()
                    buffFrame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, 0)
                    buffFrame:SetPoint("TOPRIGHT", prevFrame, "BOTTOMRIGHT", 0, 0)
                    
                    prevFrame = buffFrame
                    totalHeight = totalHeight + 20
                end
            end
        end
    end
    
    -- Update the content frame height
    SpBuffTracker.contentFrame:SetHeight(totalHeight)
    
    -- Update the main frame height
    SpBuffTracker.frame:SetHeight(20 + totalHeight)
end

-- Resets the position of the main frame
function SpBuffTracker_ResetPosition()
    SpBuffTracker.frame:ClearAllPoints()
    SpBuffTracker.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end
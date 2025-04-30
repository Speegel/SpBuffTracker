-- SpBuffTracker Buffs Module
-- Contains buff tracking functionality

-- Format time in MM:SS format
function SpBuffTracker_FormatTime(seconds)
    if seconds <= 0 then
        return ""
    end
    
    local minutes = math.floor(seconds / 60)
    seconds = math.mod(seconds, 60)
    
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
    -- Hide in combat if setting is enabled
    if SpBuffTracker.settings.hideInCombat and UnitAffectingCombat("player") then
        if SpBuffTracker.frame:IsVisible() then
            SpBuffTracker.frame:Hide()
            SpBuffTracker.wasVisibleBeforeCombat = true
        end
        return
    elseif SpBuffTracker.wasVisibleBeforeCombat and not UnitAffectingCombat("player") then
        SpBuffTracker.frame:Show()
        SpBuffTracker.wasVisibleBeforeCombat = false
    end

    for category, buffs in pairs(SpBuffTracker.trackedBuffs) do
        for i, buffInfo in ipairs(buffs) do
            -- Only update if the buff is enabled
            if buffInfo.enabled then
                local isActive, timeLeft = false, 0
                
                -- Check different types of buffs
                if category == "Weapon Enchants" then
                    -- For weapon enchants, we need to check both weapons
                    local hasMainEnchant, mainTimeLeft = SpBuffTracker_HasWeaponEnchant(1)
                    local hasOffEnchant, offTimeLeft = SpBuffTracker_HasWeaponEnchant(2)
                    
                    -- This is simplified - in a real addon you'd want to check the actual enchant type
                    if hasMainEnchant or hasOffEnchant then
                        isActive = true
                        timeLeft = math.max(mainTimeLeft or 0, offTimeLeft or 0)
                    end
                else
                    -- For normal buffs
                    isActive, timeLeft = SpBuffTracker_IsBuffActive(buffInfo.name)
                end
                
                -- Update buff info
                buffInfo.active = isActive
                buffInfo.timeLeft = timeLeft
                
                -- Find the corresponding buff frame
                local frameIndex = nil
                for j, frame in ipairs(SpBuffTracker.buffFrames[category] or {}) do
                    if frame.buffInfo.name == buffInfo.name then
                        frameIndex = j
                        break
                    end
                end
                
                -- Update buff frame if it exists
                if frameIndex and SpBuffTracker.buffFrames[category] and SpBuffTracker.buffFrames[category][frameIndex] then
                    local frame = SpBuffTracker.buffFrames[category][frameIndex]
                    
                    -- Show/hide icon based on settings
                    if SpBuffTracker.settings.showIcons then
                        frame.icon:Show()
                    else
                        frame.icon:Hide()
                    end
                    
                    -- Show/hide buff name based on settings
                    if SpBuffTracker.settings.showBuffNames then
                        frame.name:Show()
                    else
                        frame.name:Hide()
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
end

-- Handle buff clicks
function SpBuffTracker_BuffClicked(buffName)
    local spellName = SpBuffTracker.buffMapping[buffName]
    
    if spellName then
        -- Check if player has this spell
        local spellRank = 0
        local i = 1
        while true do
            local sName, sRank = GetSpellName(i, BOOKTYPE_SPELL)
            if not sName then break end
            
            if sName == spellName then
                -- Found the spell, cast the highest rank
                spellRank = sRank
            end
            
            i = i + 1
        end
        
        if spellRank and spellRank ~= 0 then
            -- Cast the spell
            CastSpellByName(spellName .. "(" .. spellRank .. ")")
            DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Casting " .. spellName .. "(" .. spellRank .. ")")
        else
            DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: You don't know the spell " .. spellName)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: No spell mapping for " .. buffName)
    end
end
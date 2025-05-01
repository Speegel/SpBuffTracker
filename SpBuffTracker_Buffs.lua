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

-- Check if a specific buff is active using vanilla WoW 1.12 buff functions
function SpBuffTracker_IsBuffActive(buffName)
    -- Loop through all player buffs
    local i = 0
    local maxBuffs = 32 -- Maximum number of buffs to check
    
    while i < maxBuffs do
        local buffIndex = GetPlayerBuff(i, "HELPFUL")
        if buffIndex < 0 then
            break -- No more buffs
        end
        
        -- Get the buff's name
        local texture = GetPlayerBuffTexture(buffIndex)
        local currentBuffName = SpBuffTracker_GetBuffNameFromTexture(texture)
        
        -- If found the buff we're looking for
        if currentBuffName == buffName then
            local timeLeft = GetPlayerBuffTimeLeft(buffIndex)
            return true, timeLeft or 0
        end
        
        i = i + 1
    end
    
    return false, 0
end

-- Helper function to get buff name from texture
function SpBuffTracker_GetBuffNameFromTexture(texture)
    -- Look through our tracked buffs to find the one matching this texture
    for _, category in ipairs(SpBuffTracker.categories) do
        for _, buffInfo in ipairs(SpBuffTracker.trackedBuffs[category] or {}) do
            if buffInfo.texture == texture then
                return buffInfo.name
            end
        end
    end
    
    -- Check default buffs as well
    for _, category in ipairs(SpBuffTracker.categories) do
        for _, buffInfo in ipairs(SpBuffTracker.defaultBuffs[category] or {}) do
            if buffInfo.texture == texture then
                return buffInfo.name
            end
        end
    end
    
    return nil
end

-- Check if weapon has a temporary enchant
function SpBuffTracker_HasWeaponEnchant(slot)
    -- In vanilla WoW, weapon buffs are checked differently
    local hasMainHandEnchant, mainHandExpiration, mainHandCharges, 
          hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()
    
    if slot == 1 and hasMainHandEnchant then
        return true, mainHandExpiration / 1000 -- Convert from ms to seconds
    elseif slot == 2 and hasOffHandEnchant then
        return true, offHandExpiration / 1000 -- Convert from ms to seconds
    end
    
    return false, 0
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
-- SpBuffTracker Commands Module
-- Contains slash command handlers

-- Slash command handler
function SpBuffTracker_SlashCommand(msg)
    if msg == "show" then
        -- Make sure frame exists before showing it
        if not SpBuffTracker.frame then
            SpBuffTracker_CreateUI()
        end
        SpBuffTracker.frame:Show()
        DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Showing frame")
    elseif msg == "hide" then
        if SpBuffTracker.frame then
            SpBuffTracker.frame:Hide()
            DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Hiding frame")
        end
    elseif msg == "lock" then
        SpBuffTracker.settings.locked = true
        DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Frame locked")
        SpBuffTracker_CreateUI() -- Refresh UI
    elseif msg == "unlock" then
        SpBuffTracker.settings.locked = false
        DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Frame unlocked")
        SpBuffTracker_CreateUI() -- Refresh UI
    elseif msg == "reset" then
        SpBuffTracker_ResetPosition()
        DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Position reset")
    elseif string.find(msg, "^scale%s+%d+%.?%d*$") then
        -- Changed to use string.find for Lua 5.0 compatibility
        local _, _, scaleText = string.find(msg, "^scale%s+(%d+%.?%d*)$")
        local scale = tonumber(scaleText)
        if scale and scale > 0.5 and scale <= 2.0 then
            SpBuffTracker.settings.scale = scale
            SpBuffTracker_CreateUI() -- Refresh UI
            DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Scale set to " .. scale)
        else
            DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker: Scale must be between 0.5 and 2.0")
        end
    elseif msg == "settings" or msg == "config" then
        SpBuffTracker_ToggleSettings()
    else
        DEFAULT_CHAT_FRAME:AddMessage("SpBuffTracker commands:")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt show - Show the tracker")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt hide - Hide the tracker")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt lock - Lock the tracker position")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt unlock - Unlock the tracker position")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt reset - Reset tracker position")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt scale X.X - Set the tracker scale (0.5-2.0)")
        DEFAULT_CHAT_FRAME:AddMessage("/sbt settings - Open settings panel")
    end
end
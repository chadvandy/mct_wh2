-- _init.lua files are solely for controlling the initialization functions. Everything else belongs in another file.
local mct = get_mct()



core:add_listener(
    "MCT_Init_SP",
    "LoadingGame",
    true, 
    function(context)
        if not cm.game_interface:model():is_multiplayer() then
            ModLog("henk")
            mct:load_and_start(context, false)
        else
            ModLog("MP: ferk")
            mct:load_and_start(context, true)
        end
    end,
    true
)

-- listen for the host changing settings in MP, so the client can get some form of UX
core:add_listener(
    "MCT_ClientMpUX",
    "MctFinalized",
    function(context)
        mct:log(cm:get_local_faction(true))
        mct:log(cm:get_saved_value("mct_host"))
        return cm:is_multiplayer() and cm:get_local_faction(true) ~= cm:get_saved_value("mct_host")
    end,
    function(context)
        local button = find_uicomponent(core:get_ui_root(), "menu_bar", "buttongroup", "button_mct_options")
        if not is_uicomponent(button) then
            --??????
            mct:log("MCT_ClientMpUX exploded, please send help.")
            return
        end
        
        -- highlight and change the tooltip
        button:Highlight(true, false)
        button:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069").."||"..effect.get_localised_string("mct_button_client_change"), true)

        -- once the panel opens, cancel the pulse and revert to default tooltip
        core:add_listener(
            "MCT_ClientMpUx2",
            "MctPanelOpened",
            true,
            function(context)
                if not is_uicomponent(button) then
                    -- ?!?!?!?!?!?!
                    mct:log("Bloop broken! MCT_ClientMpUx2")
                    return
                end

                button:Highlight(false, false)
                button:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069"), true)
            end,
            false
        )
    end,
    true
)
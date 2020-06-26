local mct = get_mct()

real_timer.register_repeating("mct_button_highlight", 100)

core:add_listener(
    "check_for_button",
    "RealTimeTrigger",
    function(context) 
        return context.string == "mct_button_highlight" and
        is_uicomponent(find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar", "button_mct_options"))
    end,
    function(context)
        local uic = find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar", "button_mct_options")

        real_timer.unregister("mct_button_highlight")
        core:remove_listener("check_for_button")

        if not mct._finalized then

            uic:Highlight(true, false)
            uic:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069").."||"..effect.get_localised_string("mct_button_unfinalized"), true)
        end
    end,
    true
)

core:add_listener(
    "check_for_finalization",
    "MctFinalized",
    true,
    function(context)
        local uic = find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar", "button_mct_options")
        if is_uicomponent(uic) then

            -- turn off highlight!
            uic:Highlight(false, false)
        end
    end,
    false
)
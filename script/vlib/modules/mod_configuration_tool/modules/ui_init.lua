local mct = get_mct()

if core:is_campaign() then
    -- check if the game mode is campaign - if aye, make the button
    -- needed to create the button on the top left corner of the screen
    local function create_campaign_button()
        -- parent for the buttons on the top-left bar
        local button_group = find_uicomponent(core:get_ui_root(), "menu_bar", "buttongroup")
        local new_button = UIComponent(button_group:CreateComponent("button_mct_options", "ui/templates/round_small_button"))

        -- set the tooltip to the one on the frontend button
        new_button:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069"), true)
        local img_path = effect.get_skinned_image_path("icon_options.png")
        new_button:SetImagePath(img_path)

        -- make sure it's on the button group, and set its z-priority to be as high as its parents
        new_button:PropagatePriority(button_group:Priority())
        button_group:Adopt(new_button:Address())

        mct.ui:set_mct_button(new_button)

        mct.ui:ui_created()
    end

    core:add_ui_created_callback(function() create_campaign_button() end)
elseif core:is_battle() then
    local bm = get_bm()

    local function create_button()
        local button_group = find_uicomponent(core:get_ui_root(), "menu_bar", "buttongroup")
        local new_button = UIComponent(button_group:CreateComponent("button_mct_options", "ui/templates/round_small_button"))

        -- set the tooltip to the one on the frontend button
        new_button:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069"), true)
        local img_path = effect.get_skinned_image_path("icon_options.png")
        new_button:SetImagePath(img_path)

        -- make sure it's on the button group, and set its z-priority to be as high as its parents
        new_button:PropagatePriority(button_group:Priority())
        button_group:Adopt(new_button:Address())
        --ModLog("end")

        mct.ui:set_mct_button(new_button)

        mct.ui:ui_created()
    end

    --- TODO swap to real timer?
    bm:repeat_callback(
        function()
            local button_group = find_uicomponent(core:get_ui_root(), "menu_bar", "buttongroup")
            if is_uicomponent(button_group) then
                bm:remove_process("check_for_ui")
                create_button()
            end
        end,
        100,
        "check_for_ui"
    )

    --core:trigger_custom_event("MctPanelOpened", {["mct"] = mct, ["ui_obj"] = self})

    -- lock the finalize settings button
    core:add_listener(
        "MctPanelOpened",
        "MctPanelOpened",
        true,
        function(context)
            local mct = context:mct()
            local ui_obj = context:ui_obj()

            local mod_settings_panel = ui_obj.mod_settings_panel
            if is_uicomponent(mod_settings_panel) then
                local finalize_button = UIComponent(mod_settings_panel:Find("button_mct_finalize_settings"))
                if is_uicomponent(finalize_button) then
                    ui_obj:SetState(finalize_button, "inactive")
                    ui_obj:SetTooltipText(finalize_button, effect.get_localised_string("mct_button_finalize_settings_battle"), true)

                    local finalize_button_txt = find_uicomponent(finalize_button, "button_txt")
                    ui_obj:SetStateText(finalize_button_txt, "[[col:red]]" .. effect.get_localised_string("mct_button_finalize_setting") .. "[[/col]]")
                end
            end
        end,
        true
    )
elseif core:is_frontend() then
    local function check_highlight()
        local uic = find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar", "button_mct_options")

        mct.ui:set_mct_button(uic)

        -- if the mct_settings.lua file doesn't exist, do da highlight
        local first_load = mct._first_load

        if first_load then
            uic:Highlight(true, false)
            uic:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069").."||"..effect.get_localised_string("mct_button_unfinalized"), true)

            -- turn off the highlight when you press da button
            core:add_listener(
                "check_for_finalization",
                "ComponentLClickUp",
                function(context)
                    return context.string == "button_mct_options"
                end,
                function(context)
                    local uic = find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar", "button_mct_options")
                    if is_uicomponent(uic) then

                        -- turn off highlight!
                        uic:Highlight(false, false)
                        -- return tooltip to default
                        uic:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069"), true)
                    end
                end,
                false
            )
        end
    end

    core:add_listener(
        "button_check!",
        "RealTimeTrigger",
        function(context)
            return context.string == "check_for_da_button" and is_uicomponent(find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar"))
        end,
        function(context)
            mct:log("button_check!")
            -- ModLog("button_check!")
            real_timer.unregister("check_for_da_button")
            core:remove_listener("button_check!")

            local button_group = find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar")

            local button = UIComponent(button_group:CreateComponent("button_mct_options", "ui/templates/round_small_button"))

            -- set the tooltip & img
            button:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069"), true)
            local img_path = effect.get_skinned_image_path("icon_options.png")
            button:SetImagePath(img_path)
        
            -- refresh the button group layout
            button_group:Layout()

            check_highlight()

            mct.ui:ui_created()
        end,
        false
    )

    real_timer.register_singleshot("check_for_da_button", 0)
end
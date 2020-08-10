local bm = get_bm()
local mct = get_mct()

local function create_button()
    -- parent for the buttons on the top-left bar
    --ModLog("test 1")
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

    mct:load_and_start()
end

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
                ui_obj:uic_SetState(finalize_button, "inactive")
                ui_obj:uic_SetTooltipText(finalize_button, effect.get_localised_string("mct_button_finalize_settings_battle"), true)

                local finalize_button_txt = find_uicomponent(finalize_button, "button_txt")
                ui_obj:uic_SetStateText(finalize_button_txt, "[[col:red]]" .. effect.get_localised_string("mct_button_finalize_setting") .. "[[/col]]")
            end
        end
    end,
    true
)
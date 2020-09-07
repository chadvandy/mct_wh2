-- check if the game mode is campaign - if aye, make the button
-- needed to create the button on the top left corner of the screen
local function create_campaign_button()
    local mct = get_mct()

    mct.ui:ui_created()

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
end

core:add_ui_created_callback(function() create_campaign_button() end)
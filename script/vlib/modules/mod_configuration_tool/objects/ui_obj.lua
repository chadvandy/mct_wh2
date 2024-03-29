---- MCT UI Object. INTERNAL USE ONLY.
--- @class mct_ui

-- TODO differentiate betterly between "vlib_ui" which is general UI stuff, and "mct_ui" which is stuff specific to, welp.
-- TODO cleanup crew.

---@type mct_ui
local ui_obj = {
    --- TODO conglomerate these two into one table.
    ---@type table<string, fun()> The actions done for each individual tab.
    _tab_actions = {},
    _tab_validity = {},
    -- UICs

    -- the MCT button
    mct_button = nil,

    -- script dummy
    dummy = nil,

    -- full panel
    panel = nil,

    -- left side UICs
    mod_row_list_view = nil,
    mod_row_list_box = nil,

    -- right top UICs
    mod_details_panel = nil,

    -- right bottom UICs
    mod_settings_panel = nil,

    -- currently selected mod UIC
    selected_mod_row = nil,

    -- var to read whether there have been any settings changed while the panel has been opened
    locally_edited = false,

    game_ui_created = false,

    ui_created_callbacks = {},

    -- a better way to read if any settings have been changed
    -- table of mod keys (only added when a setting is changed)
    -- within each mod key table, option keys (only added when that specific option changed)
    -- within each option key table, two field - old_value (for finalized-setting) and new_value (for selected-setting) (option key table removed if new_value is set to old_value)
    changed_settings = {},

    -- stashed popups, stored within this table, enjoy.
    stashed_popups = {},

    -- if the panel is openeded or closededed
    opened = false,
    notify_num = 0,
}

local mct = get_mct()
local vlib = get_vlib()
local log,logf,err,errf = vlib:get_log_functions("[mct_ui]")

function ui_obj:get_mct_button()
    return self.mct_button
end

function ui_obj:set_mct_button(uic)
    if not is_uicomponent(uic) then
        -- errmsg
        return false
    end

    self.mct_button = uic

    -- after getting the button, create the label counter, and then set it invisible
    local label = core:get_or_create_component("label_notify", "ui/vandy_lib/number_label", uic)
    label:SetStateText("0")
    label:SetTooltipText("Notifications", true)
    label:SetDockingPoint(3)
    label:SetDockOffset(5, -5)
    label:SetCanResizeWidth(true) label:SetCanResizeHeight(true)
    label:Resize(label:Width() /2, label:Height() /2)
    label:SetCanResizeWidth(false) label:SetCanResizeHeight(false)

    label:SetVisible(false)
end

function ui_obj:get_locally_edited()
    return (next(self.changed_settings) ~= nil)
end

--- this saves the changed-setting, called whenever @{mct_option:set_selected_setting} is called (except for creation).
function ui_obj:set_changed_setting(mod_key, option_key, new_value, is_popup_open)
    if not is_string(mod_key) then
        err("set_changed_setting() called, but the mod_key provided ["..tostring(mod_key).."] is not a valid string!")
        return false
    end

    if not is_string(option_key) then
        err("set_changed_setting() called for mod_key ["..mod_key.."], but the option_key provided ["..tostring(option_key).."] is not a valid string!")
        return false
    end

    local mct_mod = mct:get_mod_by_key(mod_key)
    local mct_option = mct_mod:get_option_by_key(option_key)

    -- add this as a table if it doesn't exist already
    if not is_table(self.changed_settings[mod_key]) then
        self.changed_settings[mod_key] = {}
    end

    -- ditto for the setting
    if not is_table(self.changed_settings[mod_key][option_key]) then
        self.changed_settings[mod_key][option_key] = {}
    end

    local old = nil
    --[[local new = nil

    if not is_nil(self.changed_settings[mod_key][option_key]["old_value"]) then
        old = self.changed_settings[mod_key][option_key]["old_value"]
    end

    if not is_nil(self.changed_settings[mod_key][option_key]["new_value"]) then
        new = self.changed_settings[mod_key][option_key]["new_value"]
    end]]

    if is_nil(old) then
        old = mct_option:get_finalized_setting()
    end

    -- if the new value is the finalized setting, remove it, UNLESS the popup is open
    if old == new_value and not is_popup_open then
        self.changed_settings[mod_key][option_key] = nil

        -- check to see if the mod_key obj needs to be removed too
        if self.changed_settings[mod_key] and next(self.changed_settings[mod_key]) == nil then
            self.changed_settings[mod_key] = nil
        end
    else
        self.changed_settings[mod_key][option_key]["old_value"] = old
        self.changed_settings[mod_key][option_key]["new_value"] = new_value
    end
end

function ui_obj:ui_created()
    log("UI created!")
    self.game_ui_created = true

    for i = 1, #self.ui_created_callbacks do

        local f = self.ui_created_callbacks[i]
        f()
    end
end

function ui_obj:add_ui_created_callback(callback)

    if not is_function(callback) then
        err("add_ui_created_callback() called, but the callback argument passed is not a function!")
        return false
    end

    if self.game_ui_created then
        -- trigger immediately
        callback()
    else
        self.ui_created_callbacks[#self.ui_created_callbacks+1] = callback
    end
end

function ui_obj:notify(str)
    local mct_button = self:get_mct_button()
    if not is_uicomponent(mct_button) then
        err("ui:notify() triggered but the mct button doesn't exist yet?")
        return false
    end

    if not is_string(str) then
        -- errmsg
        --return false
    end

    -- change the counter on the num label to be +1, set it visible if it's not
    local label = UIComponent(mct_button:Find("label_notify"))

    label:SetVisible(true)

    self.notify_num = self.notify_num + 1
    local num = self.notify_num

    label:SetStateText(tostring(num))

    -- highlight the MCT button because people are dolts
    mct_button:StartPulseHighlight(5, "active")
end

-- clear notifs
function ui_obj:clear_notifs()
    local mct_button = self:get_mct_button()
    if not is_uicomponent(mct_button) then
        -- errmsg
        return false
    end

    local label = UIComponent(mct_button:Find("label_notify"))
    label:SetStateText("")
    label:SetVisible(false)

    mct_button:StopPulseHighlight("active")

    self.notify_num = 0
end

-- stash a popup for when MCT is opened
function ui_obj:stash_popup(key, text, two_buttons, button_one_callback, button_two_callback)
    -- verify shit is alright
    --[[if not is_string(key) then
        err("stash_popup() called, but the key passed is not a string!")
        return false
    end

    if not is_string(text) then
        err("stash_popup() called, but the text passed is not a string!")
        return false
    end

    if is_nil(two_buttons) then
        two_buttons = false
    end

    if not is_boolean(two_buttons) then
        err("stash_popup() called, but the two_buttons arg passed is not a boolean!")
        return false
    end

    if not two_buttons then button_two_callback = function() end end]]

    -- save it locally!
    self.stashed_popups[#self.stashed_popups+1] = {
        key = key,
        text = text,
        two_buttons = two_buttons,
        button_one_callback = button_one_callback,
        button_two_callback = button_two_callback,
    }
end

--- TODO move popups into a vlib UI object.
-- create the actual popup, yay
function ui_obj:trigger_popup(key, text, two_buttons, button_one_callback, button_two_callback)

    -- verify shit is alright
    if not is_string(key) then
        err("trigger_popup() called, but the key passed is not a string!")
        return false
    end

    if is_function(text) then
        text = text()
    end

    if not is_string(text) then
        err("trigger_popup() called, but the text passed is not a string!")
        return false
    end

    if is_function(two_buttons) then
        two_buttons = two_buttons()
    end

    if not is_boolean(two_buttons) then
        err("trigger_popup() called, but the two_buttons arg passed is not a boolean!")
        return false
    end

    if not two_buttons then button_two_callback = function() end end

    -- build the popup panel itself
    local popup_parent = nil

    local frame = self.panel
    if is_uicomponent(frame) then
        frame:UnLockPriority()
        popup_parent = frame
    end

    local popup = core:get_or_create_component(key, "ui/mct/mct_dialogue", popup_parent)

    local function do_stuff()

        local both_group = UIComponent(popup:CreateComponent("both_group", "ui/mct/script_dummy"))
        local ok_group = UIComponent(popup:CreateComponent("ok_group", "ui/mct/script_dummy"))
        local DY_text = UIComponent(popup:CreateComponent("DY_text", "ui/vandy_lib/text/la_gioconda/center"))

        both_group:SetDockingPoint(8)
        both_group:SetDockOffset(0, 0)

        ok_group:SetDockingPoint(8)
        ok_group:SetDockOffset(0, 0)

        DY_text:SetDockingPoint(5)
        local ow, oh = popup:Width() * 0.9, popup:Height() * 0.8
        DY_text:Resize(ow, oh)
        DY_text:SetDockOffset(1, -35)
        DY_text:SetVisible(true)

        local cancel_img = effect.get_skinned_image_path("icon_cross.png")
        local tick_img = effect.get_skinned_image_path("icon_check.png")

        do
            local button_tick = UIComponent(both_group:CreateComponent("button_tick", "ui/templates/round_medium_button"))
            local button_cancel = UIComponent(both_group:CreateComponent("button_cancel", "ui/templates/round_medium_button"))

            button_tick:SetImagePath(tick_img)
            button_tick:SetDockingPoint(8)
            button_tick:SetDockOffset(-30, -10)
            button_tick:SetCanResizeWidth(false)
            button_tick:SetCanResizeHeight(false)

            button_cancel:SetImagePath(cancel_img)
            button_cancel:SetDockingPoint(8)
            button_cancel:SetDockOffset(30, -10)
            button_cancel:SetCanResizeWidth(false)
            button_cancel:SetCanResizeHeight(false)
        end

        do
            local button_tick = UIComponent(ok_group:CreateComponent("button_tick", "ui/templates/round_medium_button"))

            button_tick:SetImagePath(tick_img)
            button_tick:SetDockingPoint(8)
            button_tick:SetDockOffset(0, -10)
            button_tick:SetCanResizeWidth(false)
            button_tick:SetCanResizeHeight(false)
        end

        popup:PropagatePriority(1000)

        popup:LockPriority()

        -- grey out the rest of the world
        --popup:RegisterTopMost()

        local both_group = find_uicomponent(popup, "both_group")
        local ok_group = find_uicomponent(popup, "ok_group")

        if two_buttons then
            both_group:SetVisible(true)
            ok_group:SetVisible(false)
        else
            both_group:SetVisible(false)
            ok_group:SetVisible(true)
        end

        -- grab and set the text
        local tx = find_uicomponent(popup, "DY_text")

        local w,h = tx:TextDimensionsForText(text)
        tx:ResizeTextResizingComponentToInitialSize(w,h)

        _SetStateText(tx, text)

        tx:Resize(ow,oh)
        --w,h = tx:TextDimensionsForText(text)
        tx:ResizeTextResizingComponentToInitialSize(ow,oh)

        core:add_listener(
            key.."_button_pressed",
            "ComponentLClickUp",
            function(context)
                local button = UIComponent(context.component)
                return (button:Id() == "button_tick" or button:Id() == "button_cancel") and UIComponent(UIComponent(button:Parent()):Parent()):Id() == key
            end,
            function(context)
                local button = UIComponent(context.component)
                local id = context.string

                -- close the popup
                delete_component(popup)

                local frame = self.panel
                if is_uicomponent(frame) then
                    frame:LockPriority()
                end

                if id == "button_tick" then
                    button_one_callback()
                else
                    button_two_callback()
                end
            end,
            false
        )
    end

    core:add_listener(
        "do_stuff",
        "RealTimeTrigger",
        function(context)
            return context.string == "do_stuff"
        end,
        function(context)
            do_stuff()
        end,
        false
    )

    real_timer.register_singleshot("do_stuff", 5)
end

function ui_obj:clear_stashed_popups()

end

--- TODO don't automatically add them; use a listener system, whenever a popup is closed see if another one is pending. Will allow for hard-closing them all, or holding them in the notifications center.
function ui_obj:trigger_stashed_popups()
    local stashed_popups = self.stashed_popups

    local num_total = #stashed_popups

    if num_total == 0 then 
        -- do nothing?
    elseif num_total == 1 then
        -- just trigger it right away
        local stashed_popup = stashed_popups[1]
        self:create_popup(
            stashed_popup.key, 
            stashed_popup.text, 
            stashed_popup.two_buttons,
            stashed_popup.button_one_callback,
            stashed_popup.button_two_callback
        )
    else
        -- trigger 1 right away, and trigger the rest consecutively when button one/button two are clicked

        local bloop = {}

        -- backwards loop - start at the end and work backwards. necessary since we need to read entries from "bloop", since index 1 has to create index 2 popup
        for i = num_total, 1, -1 do
            local stashed_popup = stashed_popups[i]

            if i == num_total then
                bloop[i] = stashed_popup
            else -- edit the "stashed_popup" to trigger the next popup when it's closed
                local next_popup = bloop[i+1]
                local create_next_popup = function()
                    self:create_popup(
                        next_popup.key,
                        next_popup.text,
                        next_popup.two_buttons,
                        next_popup.button_one_callback,
                        next_popup.button_two_callback
                    )
                end

                local one_callback = stashed_popup.button_one_callback
                stashed_popup.button_one_callback = function() one_callback() create_next_popup() end

                local two_callback = stashed_popup.button_two_callback
                stashed_popup.button_two_callback = function() two_callback() create_next_popup() end

                bloop[i] = stashed_popup
            end
        end

        -- trigger the first one!
        local stashed_popup = bloop[1]

        self:create_popup(
            stashed_popup.key,
            stashed_popup.text,
            stashed_popup.two_buttons,
            stashed_popup.button_one_callback,
            stashed_popup.button_two_callback
        )
    end

    self.stashed_popups = {}
end

-- if it's the frontend, trigger popup immediately;
-- else, add the notify button + highlight
function ui_obj:create_popup(key, text, two_buttons, button_one_callback, button_two_callback)
    -- define the popup callback function - triggered immediately in frontend, and triggered when you open the panel for other modes (or immediately if panel is opened)
    log("creating popup with key ["..key.."].")

    -- check if the UI has been created; if not, stash it as a ui created callback
    if not self.game_ui_created then
        log("UI doesn't exist yet - creating the popup laterer")
        self:add_ui_created_callback(function() self:create_popup(key, text, two_buttons, button_one_callback, button_two_callback) end)
        return
    end

    if __game_mode == __lib_type_frontend then
        -- create the popup immediately
        log("triggering immediately because we're in frontend.")
        self:trigger_popup(key, text, two_buttons, button_one_callback, button_two_callback)
    else
        -- check if the MCT panel is currently open; if it is, trigger immediately, otherwise stash that ish

        if self.opened then
            -- ditto, make immejiately
            log("triggering immediately because the panel is openeded.")
            self:trigger_popup(key, text, two_buttons, button_one_callback, button_two_callback)
        else
            log("stashing it because we're not in frontend and the panel is closed.")

            -- add the notify, and stash the popup for when the panel is opened.
            self:notify()

            self:stash_popup(key, text, two_buttons, button_one_callback, button_two_callback)
        end
    end
end


function ui_obj:set_selected_mod(row_uic)
    -- deselect the former one
    local former = mct:get_selected_mod()
    if former then
        local former_uic = self.selected_mod_row
        if is_uicomponent(former_uic) then
            former_uic:SetState("unselected")
        end

        former:clear_uics(false)
    end
    
    if is_uicomponent(row_uic) then
        _SetState(row_uic, "selected")
        mct:set_selected_mod(row_uic:Id())
        self.selected_mod_row = row_uic

        self:populate_panel_on_mod_selected()
    elseif is_string(row_uic) then
        -- find the propa row and set the mod selected.
        local list_box = self.mod_row_list_box
        local row = find_uicomponent(list_box, row_uic)

        self:set_selected_mod(row)
    end
end

function ui_obj:get_selected_mod()
    return self.selected_mod_row
end

-- TODO steal escape in all game modes; seems difficult in frontend :(
function ui_obj:override_escape()
    local panel = self.panel

    -- frontend takes some hackiness :(
    if __game_mode == __lib_type_frontend then

        -- listen for the esc menu shortcut being pressed
        core:add_listener(
            "mct_esc_pressed",
            "ShortcutTriggered",
            function(context)
                return context.string == "escape_menu"
            end,
            function(context)

                -- trigger a listener on the next UI tick, to see if the escape menu has been opened
                real_timer.register_singleshot("next_tick", 0)
                core:add_listener(
                    "next_tick",
                    "RealTimeTrigger",
                    function(context)
                        return context.string == "next_tick"
                    end,
                    function(context)
                        -- find the quit menu
                        local esc_menu = find_uicomponent("quit_box")
                        if not is_uicomponent(esc_menu) then
                            -- ModLog("fuck")
                            return false
                        end
                        
                        -- press "cancel" to remove all the shits
                        local cancel_button = find_uicomponent(esc_menu, "both_group", "button_cancel")
                        cancel_button:SimulateLClick()

                        -- close the MCT panel
                        --- TODO make sure this doesn't trigger if there's invalid shit in the MCT, mebbeh do a popup?
                        self:close_frame()
                    end,
                    false
                )
            end,
            false
        )

        -- TODO finish this fucking fuck
    else
        if __game_mode == __lib_type_campaign then

        elseif __game_mode == __lib_type_battle then

        end
    end
end

function ui_obj:open_frame()
    -- check if one exists already
    local ok, msg = pcall(function()
    local test = self.panel

    self.locally_edited = false
    self.changed_settings = {}

    self.opened = true

    -- load up the profiles file
    mct.settings:read_profiles_file()

    -- make a new one!
    if not is_uicomponent(test) then
        -- create the new window and set it visible
        local new_frame = core:get_or_create_component("mct_options", "ui/mct/mct_frame")
        _SetVisible(new_frame, true)

        new_frame:PropagatePriority(500)

        --new_frame:RegisterTopMost()

        new_frame:LockPriority()

        -- resize the panel
        new_frame:SetCanResizeWidth(true) new_frame:SetCanResizeHeight(true)

        new_frame:Resize(new_frame:Width() * 4, new_frame:Height() * 2.5)

        --local sw, sh = core:get_screen_resolution()
        --new_frame:Resize(sw*0.99, sh*0.99)

        -- edit the name
        local title_plaque = find_uicomponent(new_frame, "title_plaque")
        local title = find_uicomponent(title_plaque, "title")
        _SetStateText(title, effect.get_localised_string("mct_ui_settings_title"))

        -- hide stuff from the gfx window
        find_uicomponent(new_frame, "checkbox_windowed"):SetVisible(false)
        find_uicomponent(new_frame, "ok_cancel_buttongroup"):SetVisible(false)
        find_uicomponent(new_frame, "button_advanced_options"):SetVisible(false)
        find_uicomponent(new_frame, "button_recommended"):SetVisible(false)
        find_uicomponent(new_frame, "dropdown_resolution"):SetVisible(false)
        find_uicomponent(new_frame, "dropdown_quality"):SetVisible(false)

        self.panel = new_frame

        -- create the close button
        self:create_close_button()

        -- create the large panels (left, right top/right bottom)
        self:create_panels()

        -- setup the actions panel UI (buttons + profiles)
        self:create_actions_panel()

        local ordered_mod_keys = {}
        for n in pairs(mct._registered_mods) do
            if n ~= "mct_mod" then
                table.insert(ordered_mod_keys, n)
            end
        end

        table.sort(ordered_mod_keys)

        -- create the MCT mod first
        table.insert(ordered_mod_keys, 1, "mct_mod")

        for i,n in ipairs(ordered_mod_keys) do
            local mod_obj = mct:get_mod_by_key(n)
            self:new_mod_row(mod_obj)
        end

        self:set_selected_mod("mct_mod")

        self:populate_profiles_dropdown_box()
        self:set_actions_states()

        -- TODO setup
        --self:override_escape()
    else
        test:SetVisible(true)
    end

    -- clear notifications + trigger any stashed popups
    self:trigger_stashed_popups()
    self:clear_notifs()

    core:trigger_custom_event("MctPanelOpened", {["mct"] = mct, ["ui_obj"] = self})

end) if not ok then err(msg) end
end

function ui_obj:set_actions_states()
    local actions_panel = self.actions_panel
    if not is_uicomponent(actions_panel) then
        err("set_actions_states() called, but the actions panel UIC is not found!")
        return false
    end

    local button_parent = find_uicomponent(actions_panel, "mct_profiles_button_parent")
    local profiles_new = find_uicomponent(button_parent, "mct_profiles_new")
    local profiles_delete = find_uicomponent(button_parent, "mct_profiles_delete")
    local profiles_save = find_uicomponent(button_parent, "mct_profiles_save")
    local profiles_apply = find_uicomponent(button_parent, "mct_profiles_apply")

    local selected_mod_key = mct:get_selected_mod_name()
    local selected_mod = mct:get_mod_by_key(selected_mod_key)

    local revert_to_defaults = find_uicomponent(actions_panel, "mct_revert_to_default")
    local button_mct_finalize_settings = find_uicomponent(actions_panel, "button_mct_finalize_settings")
    local mct_finalize_settings_on_mod = find_uicomponent(actions_panel, "mct_finalize_settings_on_mod")

    -- profiles_new is always allowed!
    _SetState(profiles_new, "active")

    -- check if there is any selected profile - if not, lock!
    local test = mct.settings:get_selected_profile()
    if not test or test == "" then
        _SetState(profiles_delete, "inactive")
        _SetState(profiles_save, "inactive")
        _SetState(profiles_apply, "inactive")
    else
        -- there is a current profile; enable delete
        _SetState(profiles_delete, "active")

        -- TODO check if any selected settings are different from profile settings, to enable/disable Save/Apply
        -- probably will be a hefty chunk of checking, so figure out an optimized way of doing it
        _SetState(profiles_save, "active")
        _SetState(profiles_apply, "active")
    end

    -- easy to start - if changed_settings is empty, lock everything!
    if not self:get_locally_edited() then
        _SetState(button_mct_finalize_settings, "inactive")
        _SetState(mct_finalize_settings_on_mod, "inactive")
    else
        -- set the finalize settings button to active; SOMETHING was changed!
        _SetState(button_mct_finalize_settings, "active")

        -- check if there are any changed settings for the currently selected mod
        if (not is_table(self.changed_settings[selected_mod_key])) or next(self.changed_settings[selected_mod_key]) == nil then
            -- no changed settings - lock this mod
            _SetState(mct_finalize_settings_on_mod, "inactive")
        else
            -- changed settings - unlock!
            _SetState(mct_finalize_settings_on_mod, "active")
        end
    end

    if selected_mod:are_any_settings_not_default() then
        _SetState(revert_to_defaults, "active")
    else
        _SetState(revert_to_defaults, "inactive")
    end
end


-- called each time the Profiles UI changes
function ui_obj:populate_profiles_dropdown_box()
    local actions_panel = self.actions_panel
    if not is_uicomponent(actions_panel) then
        err("populate_profiles_dropdown_box() called, but the actions_panel UIC is not found!")
        return false
    end

    core:remove_listener("mct_profiles_ui")
    core:remove_listener("mct_profiles_ui_close")

    self:set_actions_states()

    local dropdown_option_template = "ui/vandy_lib/dropdown_option"

    local profiles_dropdown = find_uicomponent(actions_panel, "mct_profiles_dropdown")

    -- get necessary bits & bobs
    local popup_menu = find_uicomponent(profiles_dropdown, "popup_menu")
    local popup_list = find_uicomponent(popup_menu, "popup_list")
    local selected_tx = find_uicomponent(profiles_dropdown, "dy_selected_txt")

    _SetStateText(selected_tx, "")

    local all_profiles = mct.settings:get_all_profile_keys()

    popup_list:DestroyChildren()

    if is_table(all_profiles) and next(all_profiles) ~= nil then
        local w,h = 0,0

        _SetState(profiles_dropdown, "active")

        local selected_boi = mct.settings:get_selected_profile()

        for i = 1, #all_profiles do
            local profile_key = all_profiles[i]

            --[[if selected_boi == "" or selected_boi == nil and i == 1 then
                mct.settings:set_selected_profile(profile_key)
            end]]

            local new_entry = core:get_or_create_component(profile_key, dropdown_option_template, popup_list)
            new_entry:SetTooltipText("", true)

            local off_y = 5 + (new_entry:Height() * (i-1))
            new_entry:SetDockingPoint(2)
            new_entry:SetDockOffset(0, off_y)

            w,h = new_entry:Dimensions()

            local txt = find_uicomponent(new_entry, "row_tx")
    
            _SetStateText(txt, profile_key)

            new_entry:SetCanResizeHeight(false)
            new_entry:SetCanResizeWidth(false)

            if profile_key == selected_boi then
                _SetState(new_entry, "selected")

                -- add the value's text to the actual dropdown box
                _SetStateText(selected_tx, profile_key)
            else
                _SetState(new_entry, "unselected")
            end
        end

        local border_top = find_uicomponent(popup_menu, "border_top")
        local border_bottom = find_uicomponent(popup_menu, "border_bottom")
        
        border_top:SetCanResizeHeight(true)
        border_top:SetCanResizeWidth(true)
        border_bottom:SetCanResizeHeight(true)
        border_bottom:SetCanResizeWidth(true)
    
        popup_list:SetCanResizeHeight(true)
        popup_list:SetCanResizeWidth(true)
        popup_list:Resize(w * 1.1, h * (#all_profiles) + 10)
        --popup_list:MoveTo(popup_menu:Position())
        popup_list:SetDockingPoint(2)
        --popup_list:SetDocKOffset()
    
        popup_menu:SetCanResizeHeight(true)
        popup_menu:SetCanResizeWidth(true)
        popup_list:SetCanResizeHeight(false)
        popup_list:SetCanResizeWidth(false)
        
        local w, h = popup_list:Bounds()
        popup_menu:Resize(w,h)
    else
        -- if there are no profiles, lock the dropdown and set text to empty
        _SetState(profiles_dropdown, "inactive")

        -- clear out the selected text
        _SetStateText(selected_tx, "")
    end

    core:add_listener(
        "mct_profiles_ui",
        "ComponentLClickUp",
        function(context)
            return context.string == "mct_profiles_dropdown"
        end,
        function(context)
            local box = UIComponent(context.component)
            local menu = find_uicomponent(box, "popup_menu")
            if is_uicomponent(menu) then
                if menu:Visible() then
                    menu:SetVisible(false)
                else
                    menu:SetVisible(true)
                    menu:RegisterTopMost()
                    -- next time you click something, close the menu!
                    core:add_listener(
                        "mct_profiles_ui_close",
                        "ComponentLClickUp",
                        true,
                        function(context)
                            if box:CurrentState() == "selected" then
                                _SetState(box, "active")
                            end

                            menu:SetVisible(false)
                            menu:RemoveTopMost()
                        end,
                        false
                    )
                end
            end
        end,
        true
    )

    -- Set Selected listeners
    core:add_listener(
        "mct_profiles_ui",
        "ComponentLClickUp",
        function(context)
            local uic = UIComponent(context.component)
            
            return UIComponent(uic:Parent()):Id() == "popup_list" and UIComponent(UIComponent(UIComponent(uic:Parent()):Parent()):Parent()):Id() == "mct_profiles_dropdown"
        end,
        function(context)
            core:remove_listener("mct_profiles_ui_close")

            local old_selected_uic = nil
            local new_selected_uic = UIComponent(context.component)

            local old_key = mct.settings:get_selected_profile()
            local new_key = new_selected_uic:Id()

            local popup_list = UIComponent(new_selected_uic:Parent())
            local popup_menu = UIComponent(popup_list:Parent())
            local dropdown_box = UIComponent(popup_menu:Parent())

            if is_string(old_key) then
                old_selected_uic = find_uicomponent(popup_list, old_key)
                if is_uicomponent(old_selected_uic) then
                    _SetState(old_selected_uic, "unselected")
                end
            end

            _SetState(new_selected_uic, "selected")
            mct.settings:set_selected_profile(new_key)
            
            local t = find_uicomponent(new_selected_uic, "row_tx"):GetStateText()
            --local tt = find_uicomponent(new_selected_uic, "row_tx"):GetTooltipText()
            local tx = find_uicomponent(dropdown_box, "dy_selected_txt")
    
            _SetStateText(tx, t)
            --mct.ui:SetTooltipText(dropdown_box, tt, true)
    
            -- set the menu invisible and unclick the box
            if dropdown_box:CurrentState() == "selected" then
                _SetState(dropdown_box, "active")
            end
    
            popup_menu:SetVisible(false)
            popup_menu:RemoveTopMost()
        end,
        true
    )
end

function ui_obj:create_actions_panel()
    -- clear out any existing listeners
    core:remove_listener("mct_profiles_new")
    core:remove_listener("mct_profiles_delete")
    core:remove_listener("mct_profiles_apply")
    core:remove_listener("mct_profiles_save")

    local panel = self.panel

    local actions_panel = core:get_or_create_component("actions_panel", "ui/vandy_lib/custom_image_tiled", panel)
    _SetState(actions_panel, "custom_state_2")
    _SetImagePath(actions_panel,"ui/skins/default/panel_stack.png",1)
    _SetDockingPoint(actions_panel, 7)
    _SetDockOffset(actions_panel, 10,-65)

    _SetCanResize(actions_panel, true)
    -- actions_panel:SetCanResizeWidth(true) actions_panel:SetCanResizeHeight(true)
    actions_panel:Resize(panel:Width() * 0.1625, panel:Height() * 0.38)
    
    self.actions_panel = actions_panel

    -- create "Profiles" text
    local profiles_title = core:get_or_create_component("mct_profiles_title", "ui/templates/panel_subtitle", actions_panel)
    profiles_title:Resize(actions_panel:Width() * 0.9, profiles_title:Height())
    profiles_title:SetDockingPoint(2)
    profiles_title:SetDockOffset(0, profiles_title:Height() * 0.1)

    local profiles_text = core:get_or_create_component("mct_profiles_title_text", "ui/vandy_lib/text/la_gioconda/center", profiles_title)
    profiles_text:SetVisible(true)

    profiles_text:SetDockingPoint(5)
    profiles_text:SetDockOffset(0, 0)
    profiles_text:Resize(profiles_title:Width() * 0.9, profiles_title:Height() * 0.9)

    local w,h = profiles_text:TextDimensionsForText("[[col:fe_white]]Profiles[[/col]]")

    profiles_text:ResizeTextResizingComponentToInitialSize(w, h)
    _SetStateText(profiles_text, "[[col:fe_white]]Profiles[[/col]]")

    profiles_title:SetTooltipText("{{tt:mct_profiles_tooltip}}", true)
    profiles_text:SetTooltipText("{{tt:mct_profiles_tooltip}}", true)

    -- create "Profiles" dropdown
    local profiles_dropdown = core:get_or_create_component("mct_profiles_dropdown", "ui/vandy_lib/dropdown_button_no_event", actions_panel)
    --local profiles_dropdown_text = find_uicomponent(profiles_dropdown, "dy_selected_txt")

    profiles_dropdown:SetVisible(true)
    profiles_dropdown:SetDockingPoint(2)
    profiles_dropdown:SetDockOffset(0, profiles_title:Height() * 1.2)

    local popup_menu = find_uicomponent(profiles_dropdown, "popup_menu")
    popup_menu:PropagatePriority(1000)
    popup_menu:SetVisible(false)

    local popup_list = find_uicomponent(popup_menu, "popup_list")

    delete_component(find_uicomponent(popup_list, "row_example"))

    -- add in profiles buttons
    local w, h = actions_panel:Dimensions()
    local b_w = w * 0.45

    local buttons_parent = core:get_or_create_component("mct_profiles_button_parent", "ui/mct/script_dummy", actions_panel)
    buttons_parent:Resize(w, h * 0.20)
    buttons_parent:SetDockingPoint(2)
    buttons_parent:SetDockOffset(0, profiles_title:Height() * 2.2)
    
    -- "New" button
    local profiles_new = core:get_or_create_component("mct_profiles_new", "ui/templates/square_medium_text_button_toggle", buttons_parent)
    profiles_new:SetVisible(true)
    profiles_new:Resize(b_w, profiles_new:Height())
    profiles_new:SetDockingPoint(1)
    profiles_new:SetDockOffset(15, -5)    
    
    do
        local uic = profiles_new
        local key = "mct_profiles_new"
        local txt = UIComponent(uic:Find("dy_province"))
        txt:SetTooltipText(effect.get_localised_string(key.."_tt"), true)
        _SetStateText(txt, effect.get_localised_string(key.."_txt"))

        core:add_listener(
            key,
            "ComponentLClickUp",
            function(context)
                return context.string == key
            end,
            function(context)
                if is_uicomponent(uic) then
                    _SetState(uic, 'active')
                end

                -- build the popup panel itself
                local popup = core:get_or_create_component("mct_profiles_new_popup", "ui/mct/mct_dialogue", panel)

                local both_group = UIComponent(popup:CreateComponent("both_group", "ui/mct/script_dummy"))
                local ok_group = UIComponent(popup:CreateComponent("ok_group", "ui/mct/script_dummy"))
                local DY_text = UIComponent(popup:CreateComponent("DY_text", "ui/vandy_lib/text/la_gioconda/center"))
        
                both_group:SetDockingPoint(8)
                both_group:SetDockOffset(0, 0)
        
                ok_group:SetDockingPoint(8)
                ok_group:SetDockOffset(0, 0)
        
                DY_text:SetVisible(true)
                DY_text:SetDockingPoint(5)
                local ow,oh = popup:Width() * 0.9, popup:Height() * 0.8
                DY_text:Resize(ow, oh)
                DY_text:SetDockOffset(1, -35)
        
                local cancel_img = effect.get_skinned_image_path("icon_cross.png")
                local tick_img = effect.get_skinned_image_path("icon_check.png")
        
                do
                    local button_tick = UIComponent(both_group:CreateComponent("button_tick", "ui/templates/round_medium_button"))
                    local button_cancel = UIComponent(both_group:CreateComponent("button_cancel", "ui/templates/round_medium_button"))
        
                    button_tick:SetImagePath(tick_img)
                    button_tick:SetDockingPoint(8)
                    button_tick:SetDockOffset(-30, -10)
                    button_tick:SetCanResizeWidth(false)
                    button_tick:SetCanResizeHeight(false)
        
                    button_cancel:SetImagePath(cancel_img)
                    button_cancel:SetDockingPoint(8)
                    button_cancel:SetDockOffset(30, -10)
                    button_cancel:SetCanResizeWidth(false)
                    button_cancel:SetCanResizeHeight(false)
                end
        
                do
                    local button_tick = UIComponent(ok_group:CreateComponent("button_tick", "ui/templates/round_medium_button"))
        
                    button_tick:SetImagePath(tick_img)
                    button_tick:SetDockingPoint(8)
                    button_tick:SetDockOffset(0, -10)
                    button_tick:SetCanResizeWidth(false)
                    button_tick:SetCanResizeHeight(false)
                end
                
                panel:UnLockPriority()

                -- grey out the rest of the world
                popup:PropagatePriority(1000)

                popup:LockPriority()

                -- TODO plop in a pretty title
                local default_text = "Hi! Type in your desired profile key below."

                local tx = find_uicomponent(popup, "DY_text")
        
                local function set_text(str)
                    local w,h = tx:TextDimensionsForText(str)
                    tx:ResizeTextResizingComponentToInitialSize(w,h)

                    _SetStateText(tx, str)
            
                    tx:Resize(ow,oh)
                    tx:ResizeTextResizingComponentToInitialSize(ow,oh)
                end

                set_text(default_text)

                local xx,yy = tx:GetDockOffset()
                yy = yy - 40
                tx:SetDockOffset(xx,yy)

                local input = core:get_or_create_component("text_input", "ui/common ui/text_box", popup)
                input:SetDockingPoint(8)
                input:SetDockOffset(0, input:Height() * -4.5)
                _SetStateText(input, "")
                input:SetInteractive(true)

                input:Resize(input:Width() * 0.75, input:Height())

                input:PropagatePriority(popup:Priority())

                local check_name = core:get_or_create_component("check_name", "ui/templates/square_medium_text_button_toggle", popup)
                check_name:PropagatePriority(input:Priority() + 100)
                check_name:SetDockingPoint(8)
                check_name:SetDockOffset(0, input:Height() * -3.0)

                check_name:Resize(input:Width() * 0.95, input:Height() * 1.45)

                local txt = find_uicomponent(check_name, "dy_province")
                _SetStateText(txt, "Check Name")
                txt:SetDockingPoint(5)
                txt:SetDockOffset(0,0)

                find_uicomponent(popup, "both_group"):SetVisible(true)
                find_uicomponent(popup, "ok_group"):SetVisible(false)

                local button_tick = find_uicomponent(popup, "both_group", "button_tick")
                _SetState(button_tick, "inactive")

                local current_name = ""

                core:add_listener(
                    "mct_profiles_new_popup_check_name",
                    "ComponentLClickUp",
                    function(context)
                        --log("NEW POPUP CHECK NAME")
                        return context.string == "check_name"
                    end,
                    function(context)
                        local ok, msg = pcall(function()
                            --log("NEW POPUP CHECK NAME 1")
                        _SetState(check_name, "active")

                        --log("NEW POPUP CHECK NAMe 2")

                        local current_key = input:GetStateText()
                        local test = mct.settings:test_profile_with_key(current_key)

                        if test == true then
                            _SetState(button_tick, "active")

                            current_name = current_key
                            set_text("Hi! Type in your desired profile key below.\nCurrent name: " .. current_name)
                        else
                            _SetState(button_tick, "inactive")
                            current_name = ""

                            if test == "bad_key" then
                                set_text("Hi! Type in your desired profile key below.\n[[col:red]]Invalid key - not a valid string![[/col]]")
                            elseif test == "exists" then
                                set_text("Hi! Type in your desired profile key below.\n[[col:red]]Invalid key - a profile with that name already exists![[/col]]")
                            elseif test == "blank_key" then
                                set_text("Hi! Type in your desired profile key below.\n[[col:red]]Invalid key - you have to insert a string![[/col]]")
                            end
                        end
                    end) if not ok then err(msg) end
                    end,
                    true
                )

                core:add_listener(
                    "mct_profiles_popup_close",
                    "ComponentLClickUp",
                    function(context)
                        return context.string == "button_tick" or context.string == "button_cancel"
                    end,
                    function(context)
                        delete_component(popup)

                        local panel = self.panel
                        if is_uicomponent(panel) then
                            panel:LockPriority()
                        end

                        if context.string == "button_tick" then
                            --local current_key = input:GetStateText()
                            
                            mct.settings:add_profile_with_key(current_name)
                        end

                        core:remove_listener("mct_profiles_new_popup_check_name")
                    end,
                    false
                )
            end,
            true
        )
    end
    
    -- "Delete" button
    local profiles_delete = core:get_or_create_component("mct_profiles_delete", "ui/templates/square_medium_text_button_toggle", buttons_parent)
    profiles_delete:SetVisible(true)
    profiles_delete:Resize(b_w, profiles_delete:Height())
    profiles_delete:SetDockingPoint(3)
    profiles_delete:SetDockOffset(-15, -5)

    do
        local uic = profiles_delete
        local key = "mct_profiles_delete"
        local txt = UIComponent(uic:Find("dy_province"))
        _SetTooltipText(txt, effect.get_localised_string(key.."_tt"), true)
        _SetStateText(txt, effect.get_localised_string(key.."_txt"))

        core:add_listener(
            key,
            "ComponentLClickUp",
            function(context)
                return context.string == key
            end,
            function(context)
                if is_uicomponent(uic) then
                    _SetState(uic, 'active')
                end
                -- trigger a popup with "Are you Sure?"
                -- yes: clear this profile from mct.settings, and selected_profile as well (just deselect profile entirely?) (probably!)
                -- no: close the popup, do naught
                ui_obj:create_popup(
                    "mct_profiles_delete_popup",
                    "Are you sure you would like to delete your Profile with the key ["..mct.settings:get_selected_profile().."]? This action is irreversible!",
                    true,
                    function(context) -- "button_tick" triggered for yes
                        mct.settings:delete_profile_with_key(mct.settings:get_selected_profile())
                    end,
                    function(context) -- "button_cancel" triggered for no
                        -- do nothing!
                    end
                )
            end,
            true
        )
    end

    -- "Save" button
    local profiles_save = core:get_or_create_component("mct_profiles_save", "ui/templates/square_medium_text_button_toggle", buttons_parent)
    profiles_save:SetVisible(true)
    profiles_save:Resize(b_w, profiles_save:Height())
    profiles_save:SetDockingPoint(7)
    profiles_save:SetDockOffset(15, 5)

    do
        local uic = profiles_save
        local key = "mct_profiles_save"
        local txt = UIComponent(uic:Find("dy_province"))
        _SetTooltipText(txt, effect.get_localised_string(key.."_tt"), true)
        _SetStateText(txt, effect.get_localised_string(key.."_txt"))

        core:add_listener(
            key,
            "ComponentLClickUp",
            function(context)
                return context.string == key
            end,
            function(context)
                if is_uicomponent(uic) then
                    _SetState(uic, 'active')
                end

                -- save the current stuff as the current profile
                mct.settings:save_profile_with_key(mct.settings:get_selected_profile())
            end,
            true
        )
    end

    -- "Apply" button
    local profiles_apply = core:get_or_create_component("mct_profiles_apply", "ui/templates/square_medium_text_button_toggle", buttons_parent)
    profiles_apply:SetVisible(true)
    profiles_apply:Resize(b_w, profiles_apply:Height())
    profiles_apply:SetDockingPoint(9)
    profiles_apply:SetDockOffset(-15, 5)

    do
        local uic = profiles_apply
        local key = "mct_profiles_apply"
        local txt = UIComponent(uic:Find("dy_province"))
        _SetTooltipText(txt, effect.get_localised_string(key.."_tt"), true)
        _SetStateText(txt, effect.get_localised_string(key.."_txt"))

        core:add_listener(
            key,
            "ComponentLClickUp",
            function(context)
                return context.string == key
            end,
            function(context)
                if is_uicomponent(uic) then
                    _SetState(uic, 'active')
                end

                -- apply the settings in this profile to all mods
                mct.settings:apply_profile_with_key(mct.settings:get_selected_profile())
            end,
            true
        )
    end

    local aw = actions_panel:Width() * 1.05

    -- create the "finalize" button on the main panel (for all mods)
    local finalize_button = core:get_or_create_component("button_mct_finalize_settings", "ui/templates/square_large_text_button", actions_panel)
    finalize_button:SetCanResizeWidth(true) finalize_button:SetCanResizeHeight(true)
    finalize_button:Resize(aw, finalize_button:Height())
    finalize_button:SetDockingPoint(8)
    finalize_button:SetDockOffset(0, finalize_button:Height() * -0.2)

    local finalize_button_txt = find_uicomponent(finalize_button, "button_txt")
    _SetState(finalize_button_txt, "inactive")
    _SetStateText(finalize_button_txt, effect.get_localised_string("mct_button_finalize_settings"))
    _SetState(finalize_button_txt, "active")
    _SetStateText(finalize_button_txt, effect.get_localised_string("mct_button_finalize_settings"))
    finalize_button:SetTooltipText(effect.get_localised_string("mct_button_finalize_settings_tt"), true)

    -- create the "finalize for mod" button on the actions menu
    local finalize_button_for_mod = core:get_or_create_component("mct_finalize_settings_on_mod", "ui/templates/square_large_text_button", actions_panel)
    finalize_button_for_mod:SetCanResizeWidth(true) finalize_button_for_mod:SetCanResizeHeight(true)
    finalize_button_for_mod:Resize(aw, finalize_button_for_mod:Height())
    finalize_button_for_mod:SetDockingPoint(8)
    finalize_button_for_mod:SetDockOffset(0, finalize_button_for_mod:Height() * -1.2)

    finalize_button_for_mod:SetTooltipText(effect.get_localised_string("mct_button_finalize_settings_for_mod_tt"), true)
    local finalize_button_for_mod_txt = find_uicomponent(finalize_button_for_mod, "button_txt")

    _SetState(finalize_button_for_mod_txt, "inactive")
    _SetStateText(finalize_button_for_mod_txt, effect.get_localised_string("mct_button_finalize_settings_for_mod"))

    _SetState(finalize_button_for_mod_txt, "active")
    _SetStateText(finalize_button_for_mod_txt, effect.get_localised_string("mct_button_finalize_settings_for_mod"))

    -- create "Revert to Default"
    local revert_to_default = core:get_or_create_component("mct_revert_to_default", "ui/templates/square_large_text_button", actions_panel)
    revert_to_default:SetCanResizeWidth(true) revert_to_default:SetCanResizeHeight(true)
    revert_to_default:Resize(aw, revert_to_default:Height())
    revert_to_default:SetDockingPoint(8)
    revert_to_default:SetDockOffset(0, revert_to_default:Height() * -2.2)

    local revert_to_default_txt = find_uicomponent(revert_to_default, "button_txt")
    _SetState(revert_to_default_txt, "inactive")
    _SetStateText(revert_to_default_txt, effect.get_localised_string("mct_button_revert_to_default"))
    _SetState(revert_to_default_txt, "active")
    _SetStateText(revert_to_default_txt, effect.get_localised_string("mct_button_revert_to_default"))

    revert_to_default:SetTooltipText(effect.get_localised_string("mct_button_revert_to_default_tt"), true)
end

function ui_obj:close_frame()
    errf("Deleting panel!")
    -- save the profiles file every time we close it up
    mct.settings:save_profiles_file()
    
    local panel = self.panel
    if is_uicomponent(panel) then
        logf("Deleting panel really!")
        -- delete_component(panel)
        panel:Destroy()
        logf("Deleting panel done!")
    end

    --core:remove_listener("left_or_right_pressed")
    core:remove_listener("MctRowClicked")
    core:remove_listener("MCT_SectionHeaderPressed")
    core:remove_listener("mct_highlight_finalized_any_pressed")

    -- clear saved vars
    self.panel = nil
    self.mod_row_list_view = nil
    self.mod_row_list_box = nil
    self.mod_details_panel = nil
    self.mod_settings_panel = nil
    self.selected_mod_row = nil
    self.actions_panel = nil

    self.changed_settings = {}
    self.locally_edited = false

    self.opened = false

    -- clear uic's attached to mct_options
    local mods = mct:get_mods()
    for _, mod in pairs(mods) do
        --mod:clear_uics_for_all_options()
        mod:clear_uics(true)
    end
end

function ui_obj:create_close_button()
    local panel = self.panel
    
    local close_button_uic = core:get_or_create_component("button_mct_close", "ui/templates/round_medium_button", panel)
    local img_path = effect.get_skinned_image_path("icon_cross.png")
    close_button_uic:SetImagePath(img_path)
    close_button_uic:SetTooltipText("Close panel", true)

    -- bottom center
    close_button_uic:SetDockingPoint(8)
    close_button_uic:SetDockOffset(0, -5)
end

function ui_obj:create_panels()
    local panel = self.panel
    -- LEFT SIDE
    local img_path = effect.get_skinned_image_path("parchment_texture.png")

    -- create image background
    local left_panel_bg = core:get_or_create_component("left_panel_bg", "ui/vandy_lib/custom_image_tiled", panel)
    _SetState(left_panel_bg, "custom_state_2") -- 50/50/50/50 margins
    left_panel_bg:SetImagePath(img_path,1) -- img attached to custom_state_2
    left_panel_bg:SetDockingPoint(1)
    left_panel_bg:SetDockOffset(20, 40)
    left_panel_bg:SetCanResizeWidth(true) left_panel_bg:SetCanResizeHeight(true)
    left_panel_bg:Resize(panel:Width() * 0.15, panel:Height() * 0.5)

    local w,h = left_panel_bg:Dimensions()

    -- make the stationary title (on left_panel_bg, doesn't scroll)
    local left_panel_title = core:get_or_create_component("left_panel_title", "ui/templates/parchment_divider_title", left_panel_bg)
    _SetStateText(left_panel_title, effect.get_localised_string("mct_ui_mods_header"))
    left_panel_title:Resize(left_panel_bg:Width(), left_panel_title:Height())
    left_panel_title:SetDockingPoint(2)
    left_panel_title:SetDockOffset(0,0)

    -- create listview
    local left_panel_listview = core:get_or_create_component("left_panel_listview", "ui/vandy_lib/vlist", left_panel_bg)
    left_panel_listview:SetCanResizeWidth(true) left_panel_listview:SetCanResizeHeight(true)
    left_panel_listview:Resize(w, h-left_panel_title:Height()-5) 
    left_panel_listview:SetDockingPoint(2)
    left_panel_listview:SetDockOffset(0, left_panel_title:Height() -5)

    local x,y = left_panel_listview:Position()
    local w,h = left_panel_listview:Bounds()

    local lclip = find_uicomponent(left_panel_listview, "list_clip")
    lclip:SetCanResizeWidth(true) lclip:SetCanResizeHeight(true)
    lclip:MoveTo(x,y)
    lclip:Resize(w,h)

    local lbox = find_uicomponent(lclip, "list_box")
    lbox:SetCanResizeWidth(true) lbox:SetCanResizeHeight(true)
    lbox:MoveTo(x,y)
    lbox:Resize(w,h+100)
    
    -- save the listview and list box into the obj
    self.mod_row_list_view = left_panel_listview
    self.mod_row_list_box = lbox

    -- RIGHT SIDE
    local right_panel = core:get_or_create_component("right_panel", "ui/mct/mct_frame", panel)
    right_panel:SetVisible(true)

    right_panel:SetCanResizeWidth(true) right_panel:SetCanResizeHeight(true)
    right_panel:Resize(panel:Width() - (left_panel_bg:Width() + 60), panel:Height() * 0.85)
    right_panel:SetDockingPoint(6)
    right_panel:SetDockOffset(-20, -20) -- margin on bottom + right
    --local x, y = left_panel_title:Position()
    --right_panel:MoveTo(x + left_panel_title:Width() + 20, y)

    -- hide unused stuff
    find_uicomponent(right_panel, "title_plaque"):SetVisible(false)
    find_uicomponent(right_panel, "checkbox_windowed"):SetVisible(false)
    find_uicomponent(right_panel, "ok_cancel_buttongroup"):SetVisible(false)
    find_uicomponent(right_panel, "button_advanced_options"):SetVisible(false)
    find_uicomponent(right_panel, "button_recommended"):SetVisible(false)
    find_uicomponent(right_panel, "dropdown_resolution"):SetVisible(false)
    find_uicomponent(right_panel, "dropdown_quality"):SetVisible(false)

    -- top side
    local mod_details_panel = core:get_or_create_component("mod_details_panel", "ui/vandy_lib/custom_image_tiled", right_panel)
    mod_details_panel:SetState("custom_state_2") -- 50/50/50/50 margins
    mod_details_panel:SetImagePath(img_path, 1) -- img attached to custom_state_2
    mod_details_panel:SetDockingPoint(2)
    mod_details_panel:SetDockOffset(0, 50)
    mod_details_panel:SetCanResizeWidth(true) mod_details_panel:SetCanResizeHeight(true)
    mod_details_panel:Resize(right_panel:Width() * 0.95, right_panel:Height() * 0.3)

    --[[local list_view = core:get_or_create_component("mod_details_panel", "ui/templates/vlist", mod_details_panel)
    list_view:SetDockingPoint(5)
    --list_view:SetDockOffset(0, 50)
    list_view:SetCanResizeWidth(true) list_view:SetCanResizeHeight(true)
    local w,h = mod_details_panel:Bounds()
    list_view:Resize(w,h)

    local mod_details_lbox = find_uicomponent(list_view, "list_clip", "list_box")
    mod_details_lbox:SetCanResizeWidth(true) mod_details_lbox:SetCanResizeHeight(true)
    local w,h = mod_details_panel:Bounds()
    mod_details_lbox:Resize(w,h)]]

    local mod_title = core:get_or_create_component("mod_title", "ui/templates/panel_subtitle", right_panel)
    local mod_author = core:get_or_create_component("mod_author", "ui/vandy_lib/text/la_gioconda/center", mod_details_panel)
    local mod_description = core:get_or_create_component("mod_description", "ui/vandy_lib/text/la_gioconda/center", mod_details_panel)
    --local special_button = core:get_or_create_component("special_button", "ui/mct/special_button", mod_details_panel)
    

    mod_title:SetDockingPoint(2)
    mod_title:SetCanResizeHeight(true) mod_title:SetCanResizeWidth(true)
    mod_title:Resize(mod_title:Width() * 3.5, mod_title:Height())

    local mod_title_txt = UIComponent(mod_title:CreateComponent("tx_mod_title", "ui/vandy_lib/text/fe_section_heading"))
    mod_title_txt:SetDockingPoint(5)
    mod_title_txt:SetCanResizeHeight(true) mod_title_txt:SetCanResizeWidth(true)
    mod_title_txt:Resize(mod_title:Width(), mod_title_txt:Height())

    self.mod_title_txt = mod_title_txt

    mod_author:SetVisible(true)
    mod_author:SetCanResizeHeight(true) mod_author:SetCanResizeWidth(true)
    mod_author:Resize(mod_details_panel:Width() * 0.8, mod_author:Height() * 1.5)
    mod_author:SetDockingPoint(2)
    mod_author:SetDockOffset(0, 40)

    mod_description:SetVisible(true)
    mod_description:SetCanResizeHeight(true) mod_description:SetCanResizeWidth(true)
    mod_description:Resize(mod_details_panel:Width() * 0.8, mod_description:Height() * 2)
    mod_description:SetDockingPoint(2)
    mod_description:SetDockOffset(0, 70)

    --special_button:SetDockingPoint(8)
    --special_button:SetDockOffset(0, -5)
    --special_button:SetVisible(false) -- TODO temp disabled

    self.mod_details_panel = mod_details_panel

    -- bottom side
    local mod_settings_panel = core:get_or_create_component("mod_settings_panel", "ui/vandy_lib/custom_image_tiled", right_panel)
    _SetState(mod_settings_panel, "custom_state_2") -- 50/50/50/50 margins
    mod_settings_panel:SetImagePath(img_path, 1) -- img attached to custom_state_2
    mod_settings_panel:SetDockingPoint(2)
    mod_settings_panel:SetDockOffset(0, mod_details_panel:Height() + 70)
    mod_settings_panel:SetCanResizeWidth(true) mod_settings_panel:SetCanResizeHeight(true)
    mod_settings_panel:Resize(right_panel:Width() * 0.95, right_panel:Height() * 0.50)

    local w, h = mod_settings_panel:Dimensions()

    -- TODO create a "tab holder" UIC, use a horizontal list component?
    -- TODO flexibly populate said tab holder.
    local tab_holder = core:get_or_create_component("tab_holder", "ui/campaign ui/script_dummy", mod_settings_panel)
    tab_holder:SetDockingPoint(1)
    tab_holder:SetDockOffset(0, -30)
    tab_holder:SetCanResizeWidth(true)
    tab_holder:SetCanResizeHeight(true)
    tab_holder:Resize(mod_settings_panel:Width() * 0.9, 30)
    tab_holder:SetCanResizeWidth(false)
    tab_holder:SetCanResizeHeight(false)

    -- TODO programatically create these! Hide/show on populate_panel_on_mod_selected!
    -- create the tabs
    local ui_path = "ui/templates/square_small_tab_toggle"
    local tabs = {
        {
            "settings",
            "icon_options_tab.png",
        },
        {
            "patch_notes",
            "icon_objectives.png",
        },
        {
            "logging",
            "icon_records_tab.png",
        }
    }

    -- set the left side (logging list view/mod settings) as 3/4th of the width
    local w = w * 0.99
    -- Create the tabs, and each listview sheet for the tabs.
    -- I use individual sheets that are hidden and set visible, instead of using one sheet and deleting/adding every time. This way is just slightly quicker on the UI.
    for i = 1, #tabs do
        local tab_table = tabs[i]
        ---@type string
        local name = tab_table[1]
        ---@type string
        local icon = tab_table[2]
        
        local tab = core:get_or_create_component(name.."_tab", ui_path, tab_holder)
        
        tab:SetDockingPoint(1)
        tab:SetDockOffset(tab:Width() * 1.2 * (i-1), 0)
        tab:SetImagePath(effect.get_skinned_image_path(icon), 0)

        -- Apply the text for each state.
        local states = {"selected", "inactive", "active"}
        for j = 1, #states do
            local state = states[j]
            tab:SetState(state)
        end
        
        -- TODO do some wrapper for ALL THIS boilerplate for listviews.
        local list_view = core:get_or_create_component(name.."_list_view", "ui/vandy_lib/vlist", mod_settings_panel)
        list_view:SetDockingPoint(1)
        list_view:SetDockOffset(0, 10)
        list_view:SetCanResizeWidth(true) list_view:SetCanResizeHeight(true)
        list_view:Resize(w,h-20)

        local list_clip = find_uicomponent(list_view, "list_clip")
        list_clip:SetCanResizeWidth(true) list_clip:SetCanResizeHeight(true)
        list_clip:SetDockingPoint(1)
        list_clip:SetDockOffset(0, 0)
        list_clip:Resize(w,h-20)

        local list_box = find_uicomponent(list_clip, "list_box")
        list_box:SetCanResizeWidth(true) list_box:SetCanResizeHeight(true)
        list_box:SetDockingPoint(1)
        list_box:SetDockOffset(0, 0)
        list_box:Resize(w,h-20)

        list_box:Layout()

        local l_handle = find_uicomponent(list_view, "vslider")
        l_handle:SetDockingPoint(6)
        l_handle:SetDockOffset(-20, 0)
    
        list_view:SetVisible(i == 1)
    end

    self.mod_settings_panel = mod_settings_panel
end

function ui_obj:set_tab_action(tab_name, callback)
    if not is_string(tab_name) then return false end
    if not is_function(callback) then return false end

    self._tab_actions[tab_name] = callback
end

--- TODO completely hide a tab if it's just not used.
function ui_obj:set_tab_validity_check(tab_name, callback)
    if not is_string(tab_name) then return false end
    if not is_function(callback) then return false end

    self._tab_validity[tab_name] = callback
end

-- Run through the tabs, and reposition them based on who is visible.
function ui_obj:position_tabs()
    local selected_mod = mct:get_selected_mod()
    local mod_settings_panel = self.mod_settings_panel
    local tab_holder = find_uicomponent(mod_settings_panel, "tab_holder")

    local num = 1

    for i = 0, tab_holder:ChildCount() -1 do
        local child = UIComponent(tab_holder:Find(i))

        if child:Visible() then
            child:SetDockOffset(child:Width() * 1.2 * (num-1), 0)
            num = num + 1
        end
    end
end

function ui_obj:set_tab_active(tab_name)
    local selected_mod = mct:get_selected_mod()
    local mod_settings_panel = self.mod_settings_panel
    local tab_holder = find_uicomponent(mod_settings_panel, "tab_holder")

    local logging_list_view = find_uicomponent(mod_settings_panel, "logging_list_view")
    local settings_list_view = find_uicomponent(mod_settings_panel, "settings_list_view")
    local patch_notes_list_view = find_uicomponent(mod_settings_panel, "patch_notes_list_view")

    local lists = {
        logging_list_view,
        settings_list_view,
        patch_notes_list_view,
    }

    for i = 0, tab_holder:ChildCount() -1 do
        local child = UIComponent(tab_holder:Find(i))
        if child:CurrentState() ~= "inactive" then
            if child:Id() == tab_name.."_tab" then
                local str = effect.get_localised_string("mct_"..tab_name.."_tab_selected")
                child:SetState("selected")
                child:SetTooltipText(str, true)
            else
                local str = effect.get_localised_string("mct_"..child:Id().."_active")
                child:SetState("active")
                child:SetTooltipText(str, true)
            end
        end
    end

    for i = 1, #lists do
        local list = lists[i]
        if list:Id() == tab_name.."_list_view" then
            list:SetVisible(true)

            self:populate_tab(tab_name, selected_mod, list)
        else
            list:SetVisible(false)
        end
    end
end

function ui_obj:populate_tab(tab_name, selected_mod, list_view)
    local action = self._tab_actions[tab_name]
    if is_function(action) then
        action(self, selected_mod, list_view)
    end
end

function ui_obj:clear_tabs()
    local mod_settings_panel = self.mod_settings_panel

    local logging_list_view = find_uicomponent(mod_settings_panel, "logging_list_view")
    local settings_list_view = find_uicomponent(mod_settings_panel, "settings_list_view")
    local patch_notes_list_view = find_uicomponent(mod_settings_panel, "patch_notes_list_view")

    local lists = {
        logging_list_view,
        settings_list_view,
        patch_notes_list_view,
    }

    local destroy_table = {}
    for i = 1, #lists do
        local list = lists[i]
        local box = find_uicomponent(list, "list_clip", "list_box")
        if box:ChildCount() ~= 0 then
            for j = 0, box:ChildCount() -1 do
                local child = UIComponent(box:Find(j))
                destroy_table[#destroy_table+1] = child
            end
        end
    end
    -- delet kill destroy
    delete_component(destroy_table)
end

function ui_obj:handle_tabs()
    local selected_mod = mct:get_selected_mod()
    local mod_settings_panel = self.mod_settings_panel
    local tab_holder = find_uicomponent(mod_settings_panel, "tab_holder")

    for tab_name,validity_check in pairs(self._tab_validity) do
        local ok,msg = validity_check(self, selected_mod)
        local tab = find_uicomponent(tab_holder, tab_name.."_tab")

        --- TODO hook it up so if no msg is returned, set the tab completely invisible.
        if not ok then
            if not msg then
                tab:SetVisible(false)
            else
                tab:SetVisible(true)
                tab:SetState("inactive")
                local str = effect.get_localised_string("mct_"..tab_name.."_tab_inactive") .. msg
                
                tab:SetTooltipText(str, true)
            end
        else
            tab:SetVisible(true)
            local str = effect.get_localised_string("mct_"..tab_name.."_tab_active")

            -- set it active!
            tab:SetState("active")
            tab:SetTooltipText(str, true)
        end
    end

    self:position_tabs()

    self:set_tab_active("settings")

    core:remove_listener("mct_tab_listeners")
    core:add_listener(
        "mct_tab_listeners",
        "ComponentLClickUp",
        function(context)
            local uic = UIComponent(context.component)
            return uicomponent_descended_from(uic, "tab_holder") and uicomponent_descended_from(uic, "mct_options")
        end,
        function(context)
            self:set_tab_active(context.string:gsub("_tab", ""))
        end,
        true
    )
end

function ui_obj:populate_panel_on_mod_selected()
    log("populating panel!")
    local selected_mod = mct:get_selected_mod()

    -- set the positions for all options in the mod
    selected_mod:set_positions_for_options()

    self:set_actions_states()

    log("Mod selected ["..selected_mod:get_key().."]")

    local mod_details_panel = self.mod_details_panel
    local mod_settings_panel = self.mod_settings_panel
    local mod_title_txt = self.mod_title_txt

    -- set up the mod details - name of selected mod, display author, and whatever blurb of text they want
    local mod_author = core:get_or_create_component("mod_author", "ui/vandy_lib/text/la_gioconda/center", mod_details_panel)
    local mod_description = core:get_or_create_component("mod_description", "ui/vandy_lib/text/la_gioconda/center", mod_details_panel)
    --local special_button = core:get_or_create_component("special_button", "ui/mct/special_button", mod_details_panel)

    local title, author, desc = selected_mod:get_localised_texts()

    -- setting up text & stuff
    do
        local function set_text(uic, text)
            local parent = UIComponent(uic:Parent())
            local ow, oh = parent:Dimensions()
            ow = ow * 0.8
            oh = oh

            _ResizeTextResizingComponentToInitialSize(uic, ow, oh)

            local w,h,n = uic:TextDimensionsForText(text)
            _SetStateText(uic, text)

            _ResizeTextResizingComponentToInitialSize(uic,w,h)
        end

        set_text(mod_title_txt, title)
        set_text(mod_author, author)
        set_text(mod_description, desc:format_with_linebreaks(150))
    end

    -- remove all stuff from previous mods (if any had stuff on them)
    self:clear_tabs()

    local ok, msg = pcall(function()
    self:create_sections_and_contents(selected_mod)
    end) if not ok then err(msg) end

    -- refresh the display once all the option rows are created!
    local box = find_uicomponent(mod_settings_panel, "settings_list_view", "list_clip", "list_box")
    if not is_uicomponent(box) then
        -- TODO issue
        return
    end

    box:Layout()

    self:handle_tabs()

    core:trigger_custom_event("MctPanelPopulated", {["mct"] = mct, ["ui_obj"] = self, ["mod"] = selected_mod})
end

function ui_obj:create_sections_and_contents(mod_obj)
    local mod_settings_panel = self.mod_settings_panel
    local mod_settings_box = find_uicomponent(mod_settings_panel, "settings_list_view", "list_clip", "list_box")

    core:remove_listener("MCT_SectionHeaderPressed")
    
    local ordered_section_keys = mod_obj:sort_sections()

    for _, section_key in ipairs(ordered_section_keys) do
        local section_obj = mod_obj:get_section_by_key(section_key);

        if not section_obj or section_obj._options == nil or next(section_obj._options) == nil then
            -- skip
        else
            -- make sure the dummy rows table is clear before doing anything
            section_obj._dummy_rows = {}

            -- first, create the section header
            local section_header = core:get_or_create_component("mct_section_"..section_key, "ui/vandy_lib/expandable_row_header", mod_settings_box)
            --local open = true

            section_obj._header = section_header

            core:add_listener(
                "MCT_SectionHeaderPressed",
                "ComponentLClickUp",
                function(context)
                    return context.string == "mct_section_"..section_key
                end,
                function(context)
                    local visible = section_obj:is_visible()
                    section_obj:set_visibility(not visible)
                end,
                true
            )

            -- TODO set text & width and shit
            section_header:SetCanResizeWidth(true)
            section_header:SetCanResizeHeight(false)
            section_header:Resize(mod_settings_box:Width() * 0.95, section_header:Height())
            section_header:SetCanResizeWidth(false)

            section_header:SetDockOffset(mod_settings_box:Width() * 0.005, 0)
            
            local child_count = find_uicomponent(section_header, "child_count")
            _SetVisible(child_count, false)

            local text = section_obj:get_localised_text()
            local tt_text = section_obj:get_tooltip_text()

            local dy_title = find_uicomponent(section_header, "dy_title")
            _SetStateText(dy_title, text)
            --dy_title:SetStateText(text)

            if tt_text ~= "" then
                _SetTooltipText(section_header, tt_text, true)
            end

            -- lastly, create all the rows and options within
            --local num_remaining_options = 0
            local valid = true

            -- this is the table with the positions to the options
            -- ie. options_table["1,1"] = "option 1 key"
            local options_table, num_remaining_options = section_obj:get_ordered_options()

            local x = 1
            local y = 1

            local function move_to_next()
                if x >= 3 then
                    x = 1
                    y = y + 1
                else
                    x = x + 1
                end
            end

            -- prevent infinite loops, will only do nothing 3 times
            local loop_num = 0

            --TODO resolve this to better make the dummy rows/columns when nothing is assigned to it

            while valid do
                --loop_num = loop_num + 1
                if num_remaining_options < 1 then
                    -- log("No more remaining options!")
                    -- no more options, abort!
                    break
                end

                if loop_num >= 3 then
                    break
                end

                local index = tostring(x) .. "," .. tostring(y)
                local option_key = options_table[index]

                -- check to see if any option was even made at this index!
                --[[if option_key == nil then
                    -- skip, go to the next index
                    move_to_next()

                    -- prevent it from looping without doing anything more than 6 times
                    loop_num = loop_num + 1
                else]]
                --loop_num = 0

                if option_key == nil then option_key = "MCT_BLANK" end
                
                local option_obj
                if is_string(option_key) then
                    --log("Populating UI option at index ["..index.."].\nOption key ["..option_key.."]")
                    if option_key == "NONE" then
                        -- no option objects remaining, kill the engine
                        break
                    end
                    if option_key == "MCT_BLANK" then
                        option_obj = option_key
                        loop_num = loop_num + 1
                    else
                        -- only iterate down this iterator when it's a real option
                        num_remaining_options = num_remaining_options - 1
                        loop_num = 0
                        option_obj = mod_obj:get_option_by_key(option_key)
                    end

                    if not mct:is_mct_option(option_obj) then
                        err("no option found with the key ["..option_key.."]. Issue!")
                    else
                        -- add a new column (and potentially, row, if x==1) for this position
                        self:new_option_row_at_pos(option_obj, x, y, section_key) 
                    end

                else
                    -- issue? break? dunno?
                    log("issue? break? dunno?")
                    break
                end
        
                -- move the coords down and to the left when the row is done, or move over one space if the row isn't done
                move_to_next()
                --end
            end

            -- set own visibility (for sections that default to closed)
            section_obj:uic_visibility_change(true)
        end
    end
end


function ui_obj:new_option_row_at_pos(option_obj, x, y, section_key)
    local mod_settings_panel = self.mod_settings_panel
    local list = find_uicomponent(mod_settings_panel, "settings_list_view")
    local mod_settings_box = find_uicomponent(list , "list_clip", "list_box")
    local section_obj = option_obj:get_mod():get_section_by_key(section_key)

    local w,h = list:Dimensions()
    w = w * 0.95
    h = h * 0.20

    if not mct:is_mct_section(section_obj) then
        log("the section obj isn't a section obj what the heckin'")
    end


    local dummy_row = core:get_or_create_component("settings_row_"..section_key.."_"..tostring(y), "ui/mct/script_dummy", mod_settings_box)

    -- TODO make sliders the entire row so text and all work fine
    -- TODO above isn't really needed, huh?

    -- check to see if it was newly created, and then apply these settings
    if x == 1 then
        -- logf("Creating new row w/ width %d and height %d", w, h)
        section_obj:add_dummy_row(dummy_row)

        _SetVisible(dummy_row, true)
        dummy_row:SetCanResizeHeight(true) dummy_row:SetCanResizeWidth(true)
        dummy_row:Resize(w,h)
        dummy_row:SetCanResizeHeight(false) dummy_row:SetCanResizeWidth(false)
        dummy_row:SetDockingPoint(0)
        local w_offset = w * 0.01
        dummy_row:SetDockOffset(w_offset, 0)
        dummy_row:PropagatePriority(mod_settings_box:Priority() +1)
    end

    -- column 1 docks center left, column 2 docks center, column 3 docks center right
    local pos_to_dock = {[1]=4, [2]=5, [3]=6}

    local column = core:get_or_create_component("settings_column_"..tostring(x), "ui/mct/script_dummy", dummy_row)

    -- set the column dimensions & position
    do
        w,h = dummy_row:Dimensions()
        w = w / 3
        _SetVisible(column, true)
        column:SetCanResizeHeight(true) column:SetCanResizeWidth(true)
        column:Resize(w, h)
        column:SetCanResizeHeight(false) column:SetCanResizeWidth(false)
        column:SetDockingPoint(pos_to_dock[x])
        --column:SetDockOffset(15, 0)
        column:PropagatePriority(dummy_row:Priority() +1)
    end


    if option_obj == "MCT_BLANK" then
        -- no need to do anything, skip
    else
        local dummy_option = core:get_or_create_component(option_obj:get_key(), "ui/mct/script_dummy", column)

        do
            -- set to be flush with the column dummy
            dummy_option:SetCanResizeHeight(true) dummy_option:SetCanResizeWidth(true)
            dummy_option:Resize(w, h)
            dummy_option:SetCanResizeHeight(false) dummy_option:SetCanResizeWidth(false)

            _SetVisible(dummy_option, true)
            
            --self:SetState(dummy_option, "custom_state_2")
            --dummy_option:SetImagePath("ui/skins/default/panel_back_border.png", 1)

            -- set to dock center
            dummy_option:SetDockingPoint(5)

            -- give priority over column
            dummy_option:PropagatePriority(column:Priority() +1)

            local dummy_border = core:get_or_create_component("border", "ui/vandy_lib/custom_image_tiled", dummy_option)
            dummy_border:SetCanResizeHeight(true) dummy_border:SetCanResizeWidth(true)
            dummy_border:Resize(w, h)
            dummy_border:SetCanResizeHeight(false) dummy_border:SetCanResizeWidth(false)

            dummy_border:SetState("custom_state_2")

            local border_path = option_obj:get_border_image_path()
            local border_visible = option_obj:get_border_visibility()

            if is_string(border_path) and border_path ~= "" then
                dummy_border:SetImagePath(border_path, 1)
            else -- some error; default to default
                dummy_border:SetImagePath("ui/skins/default/panel_back_border.png", 1)
            end

            dummy_border:SetVisible(border_visible)

            option_obj:set_uic_with_key("border", dummy_border, true)

            -- make some text to display deets about the option
            local option_text = core:get_or_create_component("text", "ui/vandy_lib/text/la_gioconda/unaligned", dummy_option)
            _SetVisible(option_text, true)
            option_text:SetDockingPoint(4)
            option_text:SetDockOffset(15, 0)

            -- set the tooltip on the "dummy", and remove anything from the option text
            dummy_option:SetInteractive(true)
            option_text:SetInteractive(false)

            if option_obj:get_tooltip_text() ~= "No tooltip assigned" then
                _SetTooltipText(dummy_option, option_obj:get_tooltip_text(), true)
            end

            -- create the interactive option
            local new_option = option_obj:ui_create_option(dummy_option)

            option_obj:set_uic_with_key("text", option_text, true)

            -- resize the text so it takes up the space of the dummy column that is not used by the option
            local n_w = new_option:Width()
            local t_w = dummy_option:Width()
            local ow = t_w - n_w - 35 -- -25 is for some spacing! -15 for the offset, -10 for spacing between the option to the right
            local _, oh = option_text:Dimensions()

            do         
                local w, h = option_text:TextDimensionsForText(option_obj:get_text())
                option_text:ResizeTextResizingComponentToInitialSize(w, h)

                _SetStateText(option_text, option_obj:get_text())

                option_text:Resize(ow, oh)
                w,h = option_text:TextDimensionsForText(option_obj:get_text())
                option_text:ResizeTextResizingComponentToInitialSize(ow, oh)
            end

            new_option:SetDockingPoint(6)
            new_option:SetDockOffset(-15, 0)

            option_obj:set_uic_visibility(option_obj:get_uic_visibility())

            option_obj:ui_select_value(option_obj:get_selected_setting(), true)

            -- TODO do all this shit through /script/campaign/mod/ or similar

            -- read if the option is read-only in campaign (and that we're in campaign)
            if __game_mode == __lib_type_campaign then
                if option_obj:get_read_only() then
                    option_obj:set_uic_locked(true, "mct_lock_reason_read_only", true)
                end

                -- if game is MP, and the local faction isn't the host, lock any non-local settings
                if cm:is_multiplayer() and cm:get_local_faction_name(true) ~= cm:get_saved_value("mct_host") then
                    log("local faction: "..cm:get_local_faction_name(true))
                    log("host faction: "..cm:get_saved_value("mct_host"))
                    -- if the option isn't local only, disable it
                    log("mp and client")
                    if not option_obj:get_local_only() then
                        log("option ["..option_obj:get_key().."] is not local only, locking!")
                        option_obj:set_uic_locked(true, "mct_lock_reason_mp_client", true)
                        --[[local state = new_option:CurrentState()f

                        --log("UIc state is ["..state.."]")
    
                        -- selected_inactive for checkbox buttons
                        if state == "selected" then
                            new_option:SetState("selected_inactive")
                        else
                            new_option:SetState("inactive")
                        end]]
                    end
                end
            end

            -- read-only in battle (do this elsewhere? (TODO))
            if __game_mode == __lib_type_battle then
                option_obj:set_uic_locked(true, "mct_lock_reason_battle", true)
            end

            -- TODO why the fuck do I do this?
            if option_obj:get_uic_locked() then
                option_obj:set_uic_locked(true)
            end

            --dummy_option:SetVisible(option_obj:get_uic_visibility())
        end
    end
end

function ui_obj:new_mod_row(mod_obj)
    local row = core:get_or_create_component(mod_obj:get_key(), "ui/vandy_lib/row_header", self.mod_row_list_box)
    row:SetVisible(true)
    row:SetCanResizeHeight(true) row:SetCanResizeWidth(true)
    row:Resize(self.mod_row_list_view:Width() * 0.95, row:Height() * 1.8)

    local txt = find_uicomponent(row, "name")

    txt:Resize(row:Width() * 0.9, row:Height() * 0.9)
    txt:SetDockingPoint(2)
    txt:SetDockOffset(10,0)

    local txt_txt = mod_obj:get_title()
    local author_txt = mod_obj:get_author()

    if not is_string(txt_txt) then
        txt_txt = "No title assigned"
    end

    txt_txt = txt_txt .. "\n" .. author_txt

    _SetStateText(txt, txt_txt)


    local date = find_uicomponent(row, "date")
    date:SetVisible(false)

    --date:SetDockingPoint(6)
    --self:SetStateText(date, author_txt)

    -- TODO DO NOT HAVE THIS BE A FUCKING LISTENER FOR EACH FUCKING MOD ROW WHAT THE BUTTHOLE DUDE
    core:add_listener(
        "MctRowClicked",
        "ComponentLClickUp",
        function(context)
            return UIComponent(context.component) == row
        end,
        function(context)
            local uic = UIComponent(context.component)

            if mct:get_selected_mod_name() ~= uic:Id() then
                -- trigger stuff on the right
                self:set_selected_mod(uic)
            end
        end,
        true
    )
end

function ui_obj:add_finalize_settings_popup(selected_mod)
    local frame = self.panel
    if is_uicomponent(frame) then
        frame:UnLockPriority()
    end

    local popup = core:get_or_create_component("mct_finalize_settings_popup", "ui/mct/mct_dialogue", frame)

    local both_group = UIComponent(popup:CreateComponent("both_group", "ui/mct/script_dummy"))
    local ok_group = UIComponent(popup:CreateComponent("ok_group", "ui/mct/script_dummy"))
    local DY_text = UIComponent(popup:CreateComponent("DY_text", "ui/vandy_lib/text/la_gioconda/center"))

    both_group:SetDockingPoint(8)
    both_group:SetDockOffset(0, 0)

    ok_group:SetDockingPoint(8)
    ok_group:SetDockOffset(0, 0)

    DY_text:SetDockingPoint(5)
    local ow, oh = popup:Width() * 0.9, popup:Height() * 0.8
    DY_text:Resize(ow, oh)
    DY_text:SetVisible(true)
    DY_text:SetDockOffset(1, -35)

    local cancel_img = effect.get_skinned_image_path("icon_cross.png")
    local tick_img = effect.get_skinned_image_path("icon_check.png")

    do
        local button_tick = UIComponent(both_group:CreateComponent("button_tick", "ui/templates/round_medium_button"))
        local button_cancel = UIComponent(both_group:CreateComponent("button_cancel", "ui/templates/round_medium_button"))

        button_tick:SetImagePath(tick_img)
        button_tick:SetDockingPoint(8)
        button_tick:SetDockOffset(-30, -10)
        button_tick:SetCanResizeWidth(false)
        button_tick:SetCanResizeHeight(false)

        button_cancel:SetImagePath(cancel_img)
        button_cancel:SetDockingPoint(8)
        button_cancel:SetDockOffset(30, -10)
        button_cancel:SetCanResizeWidth(false)
        button_cancel:SetCanResizeHeight(false)
    end

    do
        local button_tick = UIComponent(ok_group:CreateComponent("button_tick", "ui/templates/round_medium_button"))

        button_tick:SetImagePath(tick_img)
        button_tick:SetDockingPoint(8)
        button_tick:SetDockOffset(0, -10)
        button_tick:SetCanResizeWidth(false)
        button_tick:SetCanResizeHeight(false)
    end

    local tx = find_uicomponent(popup, "DY_text")
    tx:SetVisible(false)

    popup:SetCanResizeWidth(true)
    popup:SetCanResizeHeight(true)

    find_uicomponent(popup, "both_group"):SetVisible(false)
    find_uicomponent(popup, "ok_group"):SetVisible(true)

    local function do_stuff()

        -- grey out the rest of the world
        popup:PropagatePriority(1000)

        popup:LockPriority()

        -- this is the width/height of the parchment image
        local pw, ph = popup:GetCurrentStateImageDimensions(3)

        -- this is the width/height of the bottom bar image
        local bw, bh = popup:GetCurrentStateImageDimensions(2)

        local popup_width = popup:Width() * 2
        local popup_height = popup:Height() * 2

        --local sx, sy = core:get_screen_resolution()
        popup:Resize(popup_width, popup_height)

        popup:SetCanResizeWidth(false)
        popup:SetCanResizeHeight(false)


        -- resize the parchment and bottom bar to prevent ugly stretching
        local nbw, nbh = popup:GetCurrentStateImageDimensions(2)
        local height_gap = nbh-bh -- this is the height different in px between the stretched bottom bar and the old bottom bar

        -- set the bottom bar to exactly what it was before (but keep the width, dumbo)
        popup:ResizeCurrentStateImage(2, nbw, bh)

        -- set the parchment to the bottom bar's height gap
        local npw, nph = popup:GetCurrentStateImageDimensions(3)
        nph = nph + height_gap - 10
        popup:ResizeCurrentStateImage(3, npw, nph)

        -- position/dimensions of the entire popup
        local tx, ty = popup:Position()
        local tw, th = popup:Dimensions()

        -- get the proper x/y position of the parchment
        local w_offset = (tw - npw) / 2
        local h_offset = ((th - bh) - nph) / 2

        local x,y = tx+w_offset, ty+h_offset

        local top_row = core:get_or_create_component("header", "ui/mct/script_dummy", popup)

        top_row:SetDockingPoint(2)
        top_row:SetDockOffset(0,h_offset)
        top_row:SetCanResizeWidth(true) top_row:SetCanResizeHeight(true)

        --top_row:Resize(npw, top_row:Height())
        
        local mod_header = core:get_or_create_component("mod_header", "ui/vandy_lib/text/la_gioconda/unaligned", top_row)
        local old_value_header = core:get_or_create_component("old_value_header", "ui/vandy_lib/text/la_gioconda/unaligned", top_row)
        local new_value_header = core:get_or_create_component("new_value_header", "ui/vandy_lib/text/la_gioconda/unaligned", top_row)

        top_row:Resize(npw, mod_header:Height() * 1.2)

        mod_header:SetCanResizeWidth(true) mod_header:SetCanResizeHeight(true)
        old_value_header:SetCanResizeWidth(true) old_value_header:SetCanResizeHeight(true)
        new_value_header:SetCanResizeWidth(true) new_value_header:SetCanResizeHeight(true)

        mod_header:SetVisible(true)
        old_value_header:SetVisible(true)
        new_value_header:SetVisible(true)

        mod_header:Resize(npw * 0.25, mod_header:Height())
        old_value_header:Resize(npw*0.25, old_value_header:Height())
        new_value_header:Resize(npw*0.25, new_value_header:Height())

        top_row:SetCanResizeWidth(false) top_row:SetCanResizeHeight(false)

        local mod_header_text = effect.get_localised_string("mct_finalize_settings_popup_mod_header")
        local old_value_header_text = effect.get_localised_string("mct_finalize_settings_popup_old_value_header")
        local new_value_header_text = effect.get_localised_string("mct_finalize_settings_popup_new_value_header")

        mod_header:SetDockingPoint(4)
        mod_header:SetDockOffset(20, 0)
        _SetStateText(mod_header, mod_header_text)

        old_value_header:SetDockingPoint(5)
        old_value_header:SetDockOffset(-20, 0)
        _SetStateText(old_value_header, old_value_header_text)

        new_value_header:SetDockingPoint(6)
        new_value_header:SetDockOffset(-60, 0)
        _SetStateText(new_value_header, new_value_header_text)

        nph = nph - top_row:Height() - 10
        -- log("h offset: " ..tostring(h_offset))
        h_offset = h_offset + top_row:Height()
        -- log("h offset after: " ..tostring(h_offset))

        -- create the listview on the parchment
        local list_view = core:get_or_create_component("list_view", "ui/vandy_lib/vlist", popup)
        list_view:SetDockingPoint(2)
        list_view:SetDockOffset(0, h_offset)
        list_view:SetCanResizeHeight(true) list_view:SetCanResizeWidth(true)
        list_view:Resize(npw,nph)
        list_view:SetCanResizeHeight(false) list_view:SetCanResizeWidth(false)

        local list_clip = find_uicomponent(list_view, "list_clip")
        list_clip:SetDockingPoint(0)
        list_clip:SetDockOffset(0,20)
        list_clip:SetCanResizeHeight(true) list_clip:SetCanResizeWidth(true)
        list_clip:Resize(npw,nph-10)
        list_clip:SetCanResizeHeight(false) list_clip:SetCanResizeWidth(false)

        local list_box = find_uicomponent(list_clip, "list_box")
        list_box:SetDockingPoint(0)
        list_box:SetDockOffset(0,20)
        list_box:SetCanResizeHeight(true)
        list_box:Resize(npw,nph)
        -- list_box:SetCanResizeHeight(false) list_box:SetCanResizeWidth(false)

        local vslider = find_uicomponent(list_view, "vslider")
        vslider:SetDockingPoint(6)
        vslider:SetDockOffset(-w_offset, 0)

        vslider:SetVisible(true)

        local ok, msg = pcall(function()

        -- loop through all changed settings mod-keys and display them!
        local changed_settings = self.changed_settings
        
        local reverted_options = {}

        if not self:get_locally_edited() then
            -- do nothing! close the popup?
            return false
        end

        local text_uic = "ui/vandy_lib/text/la_gioconda/left"

        -- stupid fucking weird fix needed to prevent weird clipping on the list box
        local wtf = UIComponent(list_box:CreateComponent("wtf", "ui/campaign ui/script_dummy"))
        wtf:SetVisible(true)
        wtf:SetCanResizeHeight(true)
        wtf:SetCanResizeWidth(true)
        wtf:Resize(10, 10)
        wtf:SetCanResizeHeight(false)
        wtf:SetCanResizeWidth(false)

        for mod_key, mod_data in pairs(changed_settings) do
            if selected_mod and mod_key ~= selected_mod then
                -- skip
            else
                -- log("IN MOD KEY "..mod_key)
                -- add text row with the mod key
                local mod_display = UIComponent(list_box:CreateComponent(mod_key, text_uic))
            

                local mod_obj = mct:get_mod_by_key(mod_key)
                
                mod_display:SetVisible(true)
                mod_display:SetDockOffset(20, 0)
                mod_display:SetCanResizeWidth(true)
                mod_display:Resize(popup:Width() / 3, mod_display:Height())
                _SetStateText(mod_display, mod_obj:get_title())
                local tt = mod_obj:get_description()
                if tt ~= "" then
                    _SetTooltipText(mod_display, tt, true)
                end

                reverted_options[mod_key] = {}

                --- first, order by sections!
                local sections = {}
                for option_key, option_data in pairs(mod_data) do
                    local option_obj = mod_obj:get_option_by_key(option_key)

                    local section_key = option_obj:get_assigned_section()
                    if not sections[section_key] then sections[section_key] = {} end

                    sections[section_key][option_key] = option_data
                end

                for section_key, section_data in pairs(sections) do
                    logf("in section key %s", section_key)
                    local section_obj = mod_obj:get_section_by_key(section_key)

                    local section_display = UIComponent(list_box:CreateComponent(section_key, text_uic))
                    section_display:SetVisible(true)
                    section_display:SetDockOffset(30, 0)
                    section_display:SetCanResizeWidth(true)
                    section_display:Resize(popup:Width() / 3, section_display:Height())

                    _SetStateText(section_display, section_obj:get_localised_text())
                    local tt = section_obj:get_tooltip_text()
                    if tt ~= "" then
                        _SetTooltipText(section_display, tt, true)
                    end
                    
                    
                    for option_key,option_data in pairs(section_data) do
                        -- add a full row to put everything within!

                        local option_row = UIComponent(list_box:CreateComponent(option_key, "ui/mct/script_dummy"))
                        --core:get_or_create_component(option_key, "ui/mct/script_dummy", list_box)

                        option_row:Resize(npw, nph * 0.10)

                        local option_obj = mod_obj:get_option_by_key(option_key)

                        local option_display = UIComponent(option_row:CreateComponent(option_key.."_display", text_uic))
                        --core:get_or_create_component(option_key.."_display", "ui/vandy_lib/text/la_gioconda", option_row)

                        option_display:SetVisible(true)
                        _SetStateText(option_display, option_obj:get_text())
                        option_display:SetDockingPoint(4)
                        option_display:SetDockOffset(40, 0)
                        option_display:SetTooltipText(option_obj:get_tooltip_text(), true)

                        local old_value = option_data.old_value
                        local new_value = option_data.new_value

                        local old_value_txt = tostring(old_value)
                        local new_value_txt = tostring(new_value)

                        local option_type = option_obj:get_type()
                        local values = option_obj:get_values()

                        if option_type == "dropdown" then
                            -- log("looking for keys "..old_value.." and "..new_value.." in dropdown box ["..option_obj:get_key().."].")
                            for i = 1, #values do
                                local value = values[i]
                                -- log("in key "..value.key)
                                if value.key == old_value then
                                    local text = value.text

                                    local test_text = effect.get_localised_string(text)
                                    if test_text ~= "" then
                                        text = test_text
                                    end

                                    -- log(old_value.. " found, text is "..text)
                                    old_value_txt = text
                                elseif value.key == new_value then
                                    local text = value.text

                                    local test_text = effect.get_localised_string(text)
                                    if test_text ~= "" then
                                        text = test_text
                                    end

                                    -- log(new_value.. " found, text is "..text)
                                    new_value_txt = text
                                end
                            end
                        elseif option_type == "slider" then
                            old_value_txt = option_obj:slider_get_precise_value(old_value, true)
                            new_value_txt = option_obj:slider_get_precise_value(new_value, true)
                        end


                        local old_value_uic = core:get_or_create_component("old_value", text_uic, option_row)
                        _SetStateText(old_value_uic, old_value_txt)
                        old_value_uic:SetDockingPoint(5)
                        old_value_uic:SetDockOffset(-20, 0)
                        old_value_uic:SetVisible(true)

                        local old_value_checkbox = core:get_or_create_component("old_value_checkbox", "ui/templates/checkbox_toggle", option_row)
                        old_value_checkbox:SetState("active")
                        old_value_checkbox:SetDockingPoint(5)
                        old_value_checkbox:SetDockOffset(-5, 0)

                        local new_value_uic = core:get_or_create_component("new_value", text_uic, option_row)
                        _SetStateText(new_value_uic, new_value_txt)
                        new_value_uic:SetDockingPoint(6)
                        new_value_uic:SetDockOffset(-60, 0)
                        new_value_uic:SetVisible(true)

                        local new_value_checkbox = core:get_or_create_component("new_value_checkbox", "ui/templates/checkbox_toggle", option_row)
                        new_value_checkbox:SetState("selected")
                        new_value_checkbox:SetDockingPoint(6)
                        new_value_checkbox:SetDockOffset(-60, 0)

                        local is_new_value = true

                        -- TODO don't have one listener for every single one lmao
                        core:add_listener(
                            "mct_checkbox_ticked",
                            "ComponentLClickUp",
                            function(context)
                                local uic = UIComponent(context.component)
                                return uic == old_value_checkbox or uic == new_value_checkbox
                            end,
                            function(context)
                                -- log("mct checkbox ticked in the finalize settings popup!")
                                local uic = UIComponent(context.component)
                    
                                local mod_key = mod_key
                                local option_key = option_key
                                local status = context.string
                    
                                local opposite_uic = nil
                                local value = nil

                    
                                is_new_value = not is_new_value

                                if is_new_value then
                                    value = new_value
                                    new_value_checkbox:SetState("selected")
                                    old_value_checkbox:SetState("active")
                                    reverted_options[mod_key][option_key] = nil
                                else
                                    reverted_options[mod_key][option_key] = true
                                    value = old_value
                                    new_value_checkbox:SetState("active")
                                    old_value_checkbox:SetState("selected")
                                end

                                local ok, msg = pcall(function()

                                local mod_obj = mct:get_mod_by_key(mod_key)
                                local option_obj = mod_obj:get_option_by_key(option_key)

                                -- TODO don't change the background UI
                                self:set_changed_setting(mod_key, option_key, value, true)
                                --option_obj:set_selected_setting(value)
                                end) if not ok then err(msg) end
                            end,
                            true
                        )
                    end
                end
            end
        end

        core:add_listener(
            "closed_box",
            "ComponentLClickUp",
            function(context)
                local button = UIComponent(context.component)
                return (button:Id() == "button_tick" or button:Id() == "button_cancel") and UIComponent(UIComponent(button:Parent()):Parent()):Id() == "mct_finalize_settings_popup"
            end,
            function(context)
                core:remove_listener("mct_checkbox_ticked")

                local panel = self.panel
                panel:LockPriority()

                delete_component(popup)

                -- if accepted, Finalize!
                if context.string == "button_tick" then
                    -- loop through reverted-options to refresh their UI
                    --[[log("checking reverted options")
                    for mod_key, data in pairs(reverted_options) do
                        log("checking mod "..mod_key)
                        local mod_obj = mct:get_mod_by_key(mod_key)

                        for option_key, _ in pairs(data) do
                            log("checking option "..option_key)
                            local option_obj = mod_obj:get_option_by_key(option_key)

                            local option_data = self.changed_settings[mod_key][option_key]
                            log("assigning selected setting as old value: "..tostring(option_data.old_value))
                            option_obj:set_selected_setting(option_data.old_value)
                        end
                    end ]]

                    mct:finalize()
                    ui_obj:set_actions_states()
                else
                    -- nada
                end

            end,
            false
        )

        list_box:Layout()

        list_box:SetCanResizeHeight(true)
        list_box:Resize(list_box:Width(), list_box:Height() + 100)
        list_box:SetCanResizeHeight(false)

    end) if not ok then err(msg) end

    end

    core:add_listener(
        "do_stuff",
        "RealTimeTrigger",
        function(context)
            return context.string == "do_stuff"
        end,
        function(context)
            do_stuff()
        end,
        false
    )

    real_timer.register_singleshot("do_stuff", 5)
end

-- Finalize settings/print to settings file
core:add_listener(
    "mct_finalize_button_pressed",
    "ComponentLClickUp",
    function(context)
        return context.string == "button_mct_finalize_settings"
    end,
    function(context)
        -- create the popup - if there's anything in the changed_settings table!
        if ui_obj:get_locally_edited() then
            ui_obj:add_finalize_settings_popup()
        end
    end,
    true
)

core:add_listener(
    "mct_finalize_button_on_mod_pressed",
    "ComponentLClickUp",
    function(context)
        return context.string == "mct_finalize_settings_on_mod"
    end,
    function(context)
        if ui_obj:get_locally_edited() then
            ui_obj:add_finalize_settings_popup(mct:get_selected_mod_name())
        end
    end,
    true
)

-- Revert to defaults for the currently selected mod
core:add_listener(
    "mct_revert_to_defaults_pressed",
    "ComponentLClickUp",
    function(context)
        return context.string == "mct_revert_to_default"
    end,
    function(context)
        local selected_mod = mct:get_selected_mod()
        log("Reverting to defaults")

        if mct:is_mct_mod(selected_mod) then
            
            selected_mod:revert_to_defaults()
        else
            errf("revert_to_defaults button pressed, but there is no selected mod? Shouldn't ever happen, huh.")
        end
    end,
    true
)

core:add_listener(
    "mct_close_button_pressed",
    "ComponentLClickUp",
    function(context)
        return context.string == "button_mct_close" and uicomponent_descended_from(UIComponent(context.component), "mct_options")
    end,
    function(context)
        -- check if MCT was finalized or no changes were done during the latest UI operation
        if not ui_obj:get_locally_edited() then
            ui_obj:close_frame()
        else
            -- trigger a popup to either close with unsaved changes, or cancel the close procedure
            local key = "mct_unsaved"
            local text = "[[col:red]]WARNING: Unsaved Changes![[/col]]\n\nThere are unsaved changes in the Mod Configuration Tool!\nIf you would like to close anyway, press accept. If you want to go back and save your changes, press cancel and use Finalize Settings!"

            local actions_panel = ui_obj.actions_panel

            -- highlight the finalize buttons!
            local function func()
                local button_mct_finalize_settings = find_uicomponent(actions_panel, "button_mct_finalize_settings")
                local mct_finalize_settings_on_mod = find_uicomponent(actions_panel, "mct_finalize_settings_on_mod")
                
                button_mct_finalize_settings:StartPulseHighlight(2, "active")
                mct_finalize_settings_on_mod:StartPulseHighlight(2, "active")

                core:add_listener(
                    "mct_highlight_finalized_any_pressed",
                    "ComponentLClickUp",
                    function(context)
                        return context.string == "button_mct_finalize_settings" or context.string == "mct_finalize_settings_on_mod"
                    end,
                    function(context)
                        button_mct_finalize_settings:StopPulseHighlight()
                        mct_finalize_settings_on_mod:StopPulseHighlight()
                    end,
                    false
                )
            end

            ui_obj:create_popup(key, text, true, function() ui_obj:close_frame() end, function() func() end)

        end
    end,
    true
)

core:add_listener(
    "mct_button_pressed",
    "ComponentLClickUp",
    function(context)
        return context.string == "button_mct_options"
    end,
    function(context)
        ui_obj:open_frame()
    end,
    true
)

return ui_obj
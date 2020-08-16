local mct = mct

local template_type = mct._MCT_TYPES.template

local type = mct:create_class(template_type)

--[[function type.new(mct_mod, mct_option, key)
    local new_type = template_type.new(mct_mod, mct_option, key)

    setmetatable(new_type, type)
    
    return new_type
end]]

--------- OVERRIDEN SECTION -------------
-- These functions exist for every type, and have to be overriden from the version defined in template_types.

function type:check_validity(val)
    if not is_string(val) then
        return false
    end

    local values = self:get_values()
    
    -- check if this key exists as a dropdown option
    local valid = false
    for i = 1, #values do
        local test = values[i].key

        if val == test then
            valid = true
        end
    end

    return valid
end

function type:set_default()
    local option = self:get_option()

    local values = option:get_values()
    -- set the default value as the first added dropdown option
    option._default_setting = values[1]
end

function type:ui_select_value(val)
    local dropdown_box_uic = self:get_uic_with_key("mct_dropdown_box")
    if not is_uicomponent(dropdown_box_uic) then
        mct:error("ui_select_value() triggered for mct_option with key ["..self:get_key().."], but no dropdown_box_uic was found internally. Aborting!")
        return false
    end

    -- ditto
    local popup_menu = UIComponent(dropdown_box_uic:Find("popup_menu"))
    local popup_list = UIComponent(popup_menu:Find("popup_list"))
    local new_selected_uic = find_uicomponent(popup_list, val)

    local currently_selected_uic = nil

    for i = 0, popup_list:ChildCount() - 1 do
        local child = UIComponent(popup_list:Find(i))
        if child:CurrentState() == "selected" then
            currently_selected_uic = child
        end
    end

    -- unselected the currently-selected dropdown option
    if is_uicomponent(currently_selected_uic) then
        mct.ui:uic_SetState(currently_selected_uic, "unselected")
    else
        mct:error("ui_select_value() triggered for mct_option with key ["..self:get_key().."], but no currently_selected_uic with key was found internally. Investigate!")
        --return false
    end

    -- set the new option as "selected", so it's highlighted in the list; also lock it as the selected setting in the option_obj
    mct.ui:uic_SetState(new_selected_uic, "selected")
    --self:set_selected_setting(val)

    -- set the state text of the dropdown box to be the state text of the row
    local t = find_uicomponent(new_selected_uic, "row_tx"):GetStateText()
    local tt = find_uicomponent(new_selected_uic, "row_tx"):GetTooltipText()
    local tx = find_uicomponent(dropdown_box_uic, "dy_selected_txt")

    mct.ui:uic_SetStateText(tx, t)
    mct.ui:uic_SetTooltipText(dropdown_box_uic, tt, true)

    -- set the menu invisible and unclick the box
    if dropdown_box_uic:CurrentState() == "selected" then
        mct.ui:uic_SetState(dropdown_box_uic, "active")
    end

    popup_menu:SetVisible(false)
    popup_menu:RemoveTopMost()
end

function type:ui_change_state()
    local option = self:get_option()

    local option_uic = option:get_uics()[1]
    local text_uic = option:get_uic_with_key("text")

    local locked = option:get_uic_locked()
    local lock_reason = ""
    if locked then
        local lock_reason_tab = option._uic_lock_reason 
        if lock_reason_tab.is_localised then
            lock_reason = effect.get_localised_string(lock_reason_tab.text)
        else
            lock_reason = lock_reason_tab.text
        end

        if lock_reason == "" then
            -- revert to default? TODO
        end
    end
    -- disable the dropdown box
    local state = "active"
    local tt = option:get_tooltip_text()

    if locked then
        state = "inactive"
        tt = lock_reason .. "\n" .. tt
    end

    mct.ui:uic_SetState(option_uic, state)
    mct.ui:uic_SetTooltipText(text_uic, tt, true)
end

--------- UNIQUE SECTION -----------
-- These functions are unique for this type only. Be careful calling these!

---- Method to set the `dropdown_values`. This function takes a table of tables, where the inner tables have the fields ["key"], ["text"], ["tt"], and ["is_default"]. The latter three are optional.
--- ex:
---      mct_option:add_dropdown_values({
---          {key = "example1", text = "Example Dropdown Value", tt = "My dropdown value does this!", is_default = true},
---          {key = "example2", text = "Lame Dropdown Value", tt = "This dropdown value does another thing!", is_default = false},
---      })
--- @within API
function type:add_dropdown_values(dropdown_table)
    --[[if not self:get_type() == "dropdown" then
        mct:error("add_dropdown_values() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the option is not a dropdown! Returning false.")
        return false
    end]]

    if not is_table(dropdown_table) then
        mct:error("add_dropdown_values() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the dropdown_table supplied is not a table! Returning false.")
        return false
    end

    if is_nil(dropdown_table[1]) then
        mct:error("add_dropdown_values() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the dropdown_table supplied is an empty table! Returning false.")
        return false
    end

    for i = 1, #dropdown_table do
        local dropdown_option = dropdown_table[i]
        local key = dropdown_option.key
        local text = dropdown_option.text or ""
        local tt = dropdown_option.tt or ""
        local is_default = dropdown_option.default or false

        self:add_dropdown_value(key, text, tt, is_default)
    end
end

---- Used to create a single dropdown_value; also called within @{mct_option:add_dropdown_values}
--- @tparam string key The unique identifier for this dropdown value.
--- @tparam string text The localised text for this dropdown value.
--- @tparam string tt The localised tooltip for this dropdown value.
--- @tparam boolean is_default Whether or not to set this dropdown_value as the default one, when the dropdown box is created.
function type:add_dropdown_value(key, text, tt, is_default)
    --[[if not self:get_type() == "dropdown" then
        mct:error("add_dropdown_value() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the option is not a dropdown! Returning false.")
        return false
    end]]

    if not is_string(key) then
        mct:error("add_dropdown_value() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the key supplied is not a string! Returning false.")
        return false
    end

    text = text or ""
    tt = tt or ""

    local val = {
        key = key,
        text = text,
        tt = tt
    }

    local option = self:get_option()

    option._values[#option._values+1] = val

    -- check if it's the first value being assigned to the dropdown, to give at least one default value
    if #option._values == 1 then
        option:set_default_value(key)
    end

    if is_default then
        option:set_default_value(key)
    end

    -- if the UI already exists, refresh the dropdown box!
    if is_uicomponent(option:get_uics()[1]) then
        mct.ui:refresh_dropdown_box(option)
    end
end

return type
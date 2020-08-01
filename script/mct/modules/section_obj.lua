--- Section Object
-- @classmod mct_section

local mct = mct

local mct_section = {
    _key = "",
    _text = "No text assigned",
}

--- For internal use only. Use @{mct_mod:add_new_section}.
-- @tparam string key The key to identify the new mct_section.
-- @tparam mct_mod mod The mct_mod this section is a member of.
function mct_section.new(key, mod)
    local self = {}
    setmetatable(self, {__index = mct_section, __tostring = function() return "MCT_SECTION" end})

    -- the UI object for the header
    self._header = nil

    -- the UI object[s] of all dummy_rows attached to this mct_section, for visibility and such
    self._dummy_rows = {}

    -- k/v of all option objs attached
    self._options = {}

    self._visible = true
    
    self._key = key
    self._mod = mod

    self._visibility_change_callback = nil

    self._sort_order_function = self.sort_options_by_key

    self._ordered_options = {}

    return self
end

--- Get the ordered keys of all options in this section, based on the sort-order-function determined by @{mct_section:set_option_sort_function}.
-- @treturn {string,...} ordered_options An array of the ordered option keys, [1] is the first key, [2] is the second, so on.
-- @treturn number num_total The total number of options in this section, for UI creation.
-- @local
function mct_section:get_ordered_options()
    local ordered_options = self._ordered_options
    local num_total = 0

    for _,_ in pairs(ordered_options) do
        num_total = num_total + 1
    end
    return ordered_options, num_total
end

--- Set an option key at a specific index, for the @{mct_section:get_ordered_options} function.
-- Don't call this directly - use @{mct_section:set_option_sort_function}
-- @tparam string option_key The option key being placed at the index.
-- @tparam number x The x-value for the option. Somewhere between 1(left) and 3(right)
-- @tparam number y The y-value for the option. 1 is the top row, etc.
-- @local
function mct_section:set_option_at_index(option_key, x, y)
    if not is_string(option_key) then
        mct:error("set_option_at_index() called for section ["..self:get_key().."] in mct mod ["..self:get_mod():get_key().."], but the option_key provided was not a string! Returning false.")
        return false
    end

    if not is_number(x) then
        mct:error("set_option_at_index() called for section ["..self:get_key().."] in mct mod ["..self:get_mod():get_key().."], but the x arg provided was not a number! Returning false.")
        return false
    end

    if not is_number(y) then
        mct:error("set_option_at_index() called for section ["..self:get_key().."] in mct mod ["..self:get_mod():get_key().."], but the y arg provided was not a number! Returning false.")
        return false
    end

    local index = tostring(x)..","..tostring(y)

    mct:log("Setting option key ["..option_key.."] to pos ["..index.."] in section ["..self:get_key().."]")

    self._ordered_options[index] = option_key
end

--- Call the internal ._sort_order_function, determined by @{mct_section:set_option_sort_function}
-- @local
function mct_section:sort_options()
    -- perform the wrapped sort order function

    -- TODO protect it?
    -- protect it with a pcall to catch any issues with a custom sort order func
    return self:_sort_order_function()
end

--- One of the default sort-option function.
-- Sort the options by their option key - from "!my_option" to "zzz_my_option"
function mct_section:sort_options_by_key()
    local ret = {}
    local options = self:get_options()

    for option_key, _ in pairs(options) do
        table.insert(ret, option_key)
    end

    table.sort(ret)

    return ret
end

--- One of the default sort-option functions.
-- Sort the options by the order in which they were added in the `mct/settings/?.lua` file.
function mct_section:sort_options_by_index()
    local ret = {}

    local valid_options = self:get_options()

    -- table that has all mct_mod options listed in the order they were created via mct_mod:add_new_option
    -- array of option_keys!
    local order_by_option_added = self:get_mod()._options_by_index_order

    -- loop through this table, check to see if the option iterated is in this section, and if it is, add it to the ret table, next in line
    for i = 1, #order_by_option_added do
        local test = order_by_option_added[i]

        if valid_options[test] ~= nil then
            -- set this option key as the next in the ret table
            ret[#ret+1] = test
        end
    end

    return ret
end

--- Set the option-sort-function for this section's options.
-- You can pass "key_sort" for @{mct_section:sort_options_by_key}
-- You can pass "index_sort" for @{mct_section:sort_options_by_index}
-- You can also pass a full function, for example:
-- mct_section:set_option_sort_function(
--      function()
--          local ordered_options = {}
--          local options = mct_section:get_sections()
--          for option_key, option_obj in pairs(options) do
--              ordered_options[#ordered_options+1] = option_key
--          end
-- 
--          -- alphabetically sort the options
--          table.sort(ordered_options)
-- 
--          -- reverse the order
--          table.sort(ordered_options, function(a,b) return a > b end)
--      end
-- )
-- @tparam function|string sort_func The sort function provided. Either use one of the two strings above, or a custom function like the above example.
function mct_section:set_option_sort_function(sort_func)
    if is_string(sort_func) then
        if sort_func == "key_sort" then
            self._sort_order_function = self.sort_options_by_key
        elseif sort_func == "index_sort" then
            self._sort_order_function = self.sort_options_by_index
        else
            mct:error("set_option_sort_function() called for section ["..self:get_key().."], but the sort_func provided ["..sort_func.."] is an invalid string!")
            return false
        end
    elseif is_function(sort_func) then
        self._sort_order_function = sort_func
    else
        mct:error("set_option_sort_function() called for section ["..self:get_key().."], but the sort_func provided isn't a string or a function!")
        return false
    end
end

--- Clears the UICs saved in this section to prevent wild crashes or whatever.
-- @local
function mct_section:clear_uics()
    self._dummy_rows = {}
    self._header = {}
end

--- Saves the dummy rows (every 3 options in the UI is a dummy_row) in the mct_section.
-- @local
function mct_section:add_dummy_row(uic)
    if not is_uicomponent(uic) then
        mct:error("add_dummy_row() called for section ["..self:get_key().."], but the uic provided isn't a UIComponent!")
        return false
    end

    self._dummy_rows[#self._dummy_rows+1] = uic
end

--- The UI trigger for the section opening or closing.
-- Internal use only. Use @{mct_section:set_visibility} if you want to manually change the visibility elsewhere.
-- @tparam boolean event_free Whether to trigger the "MctSectionVisibilityChanged" event. True is sent when the section is first created.
function mct_section:uic_visibility_change(event_free)
    local visibility = self._visible

    local attached_rows = self._dummy_rows
    for i = 1, #attached_rows do
        if not is_uicomponent(attached_rows[i]) then
            -- skip
            attached_rows[i] = nil
        else
            local row = attached_rows[i]
            mct.ui:uic_SetVisible(row, visibility)
        end
    end

    -- also change the state of the UI header
    if visibility then
        mct.ui:uic_SetState(self._header, "selected")
        -- set to selected
    else
        mct.ui:uic_SetState(self._header, "active")
        -- set to active
    end

    if not event_free then
        core:trigger_custom_event("MctSectionVisibilityChanged", {["mct"] = mct, ["mod"] = self:get_mod(), ["section"] = self, ["visibility"] = visibility})

        self:process_callback()
    end
end

--- Add a callback to be triggered after @{mct_section:uic_visibility_change} is called.
-- @tparam function callback The callback to trigger when the visibility is changed.
function mct_section:add_section_visibility_change_callback(callback)
    if not is_function(callback) then
        mct:error("add_section_visibility_change_callback() called for section ["..self:get_key().."] in mod ["..self:get_mod():get_key()..", but the callback passed is not a function!")
        return false
    end

    self._visibility_change_callback = callback
end

--- Trigger the callback from @{mct_section:add_section_visibility_change_callback}
-- @local
function mct_section:process_callback()
    local f = self._visibility_change_callback

    -- no callback set, skip
    if not is_function(f) then
        return false
    end

    f(self)
end

--- Get the dummy rows for the options in this section.
-- Not really needed outside.
-- @local
function mct_section:get_dummy_rows()
    return self._dummy_rows or {}
end

--- Get the key for this section.
-- @treturn string The key for this section.
function mct_section:get_key()
    return self._key
end

--- Get the @{mct_mod} that owns this section.
-- @treturn mct_mod The owning mct_mod for this section.
function mct_section:get_mod()
    return self._mod
end

--- Get the header text for this section.
-- Either mct_[mct_mod_key]_[section_key]_section_text, in a .loc file,
-- or the text provided using @{mct_section:set_localised_text}
-- @treturn string The localised text for this section, used as the title.
function mct_section:get_localised_text()
    -- default to checking the loc files
    local text = effect.get_localised_string("mct_"..self:get_mod():get_key().."_"..self:get_key().."_section_text")
    if text ~= "" then
        --return text
    else

        -- nothing found, check for anything supplied by `set_localised_text()`, or send the default "No text assigned"
        text = self._text
        if is_table(text) then
            if text[2] == true then
                local test = effect.get_localised_string(text[1])
                if test ~= "" then
                    text = test
                end
            else
                text = text[1]
            end
        end

    end

    if not is_string(text) then
        text = "No text assigned"
    end

    return text
end

--- Grab whether this mct_section is set to be visible or not - whether it's "opened" or "closed"
-- Works to read the UI, as well.
-- @treturn boolean Whether the mct_section is currently visible, or whether the mct_section will be visible when it's next created.
function mct_section:is_visible()
    return self._visible
end

--- Set the visibility for the mct_section.
-- This works while the UI currently exists, or to set its visibility next time the panel is opened.
-- Triggers @{mct_section:uic_visibility_change} automatically.
-- @tparam boolean is_visible True for open, false for closed.
function mct_section:set_visibility(is_visible)
    if is_nil(is_visible) then enable = true end

    if not is_boolean(is_visible) then
        mct:error("set_visibility() called for section ["..self:get_key().."], but the is_visible argument passed isn't a boolean or nil! Returning false.")
        return false
    end

    self._visible = is_visible

    -- test if the UI object exists - if it does, call the UI wrapper!
    if is_uicomponent(self._header) then
        self:uic_visibility_change()
    end
end

--- Set the title for this section.
-- Works the same as always - you can pass hard text, ie. mct_section:set_localised_text("My Section")
-- or a localised key, ie. mct_section:set_localised_text("my_section_loc_key", true)
-- @tparam string text The localised text for this mct_section title. Either hard text, or a loc key.
-- @tparam boolean is_localised If setting a loc key as the localised text, set this to true.
function mct_section:set_localised_text(text, is_localised)
    if not is_string(text) then
        mct:error("set_localised_text() called for section ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the text supplied is not a string! Returning false.")
        return false
    end

    is_localised = is_localised or false

    if not is_boolean(is_localised) then
        mct:error("set_localised_text() called for section ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the is_localised arg supplied is not a boolean or nil! Returning false.")
        return false
    end

    self._text = {text, is_localised}
end

--- Assign an option to this section.
-- Automatically called through @{mct_option:set_assigned_section}.
-- @tparam mct_option option_obj The option object to assign into this section.
function mct_section:assign_option(option_obj)
    if is_string(option_obj) then
        -- try to get an option obj with this key
        option_obj = self:get_mod():get_option_by_key(option_obj)
    end

    if not mct:is_mct_option(option_obj) then
        mct:error("assign_option() called for section ["..self:get_key().."], but the option_obj provided ["..tostring(option_obj).."] is not an mct_option!  Cancelling")
        return false
    end

    self._options[option_obj:get_key()] = option_obj
end

--- Return all the options assigned to the mct_section.
-- @treturn {[string]=mct_object,...} The table of all the options in this mct_section.
function mct_section:get_options()
    return self._options
end

return mct_section
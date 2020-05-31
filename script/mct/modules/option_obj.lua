--- MCT Option Object
-- @module mct_option

local mct = mct

local mct_option = {
    _mod = nil,
    _key = "",
    _type = nil,
    _text = "No text assigned.",
    _tooltip_text = "No tooltip assigned.",

    __templates = {
        checkbox = "ui/templates/checkbox_toggle",
        dropdown = {"ui/templates/dropdown_button", "ui/vandy_lib/dropdown_option"},
        slider = "ui/templates/panel_slider_horizontal"
    }

    --_wrapped = nil
    --_callback = nil,
    --_selected_setting = nil,
    --_finalized_setting = nil
}

--local mct_checkbox_template = "ui/templates/checkbox_toggle"
--local mct_dropdown_template = {"ui/templates/dropdown_button", "ui/vandy_lib/dropdown_option"}
--local mct_slider_template = "ui/templates/panel_slider_horizontal"


function mct_option.new(mod, option_key, type)
    local self = {}
    setmetatable(self, {
        __index = mct_option,
        __tostring = function() return "MCT_OPTION" end
    })

    self._mod = mod
    self._key = option_key
    self._type = type or "NULL_TYPE"
    --self._text = text or ""
    --self._tooltip_text = tooltip_text or ""
    self._values = {}

    -- assigned section, used for UI, defaults to the last created section unless one is specified
    self._assigned_section = mod:get_last_section().key

    -- a callback triggered whenever the setting is changed within the UI
    self._option_set_callback = nil

    -- selected setting is the UI state and the default value; finalized setting is the saved setting in the file/etc
    self._selected_setting = nil
    self._finalized_setting = nil

    -- whether this option obj is read only for campaign
    self._read_only = true

    -- the UICs linked to this option (the option + the txt)
    self._uics = {}

    -- UIC options for construction
    self._uic_visible = true

    self._pos = {
        x = 0,
        y = 0
    }

    -- read the "type" field in the metatable's __templates field - ie., __templates[checkbox]
    self._template = self.__templates[type]
    
    --self._wrapped = wrapped

    return self
end

function mct_option:set_assigned_section(section_key)
    local mod = self:get_mod()
    if is_nil(mod:get_section_by_key(section_key)) then
        mct:log("set_assigned_section() called for option ["..self:get_key().."] in mod ["..mod:get_key().."] but no section with the key ["..section_key.."] was found!")
        return false
    end

    self._assigned_section = section_key
end

function mct_option:get_assigned_section()
    return self._assigned_section
end

function mct_option:get_read_only()
    return self._read_only
end

function mct_option:set_read_only(enabled)
    if is_nil(enabled) then
        enabled = true
    end

    --enabled = enabled or true

    if not is_boolean(enabled) then
        -- issue
        return false
    end

    self._read_only = enabled
end

function mct_option:get_mod()
    return self._mod
end

function mct_option:clear_uics()
    self._uics = {}
end

function mct_option:set_uics(uic_obj)
    -- check if it's a table of UIC's
    if is_table(uic_obj) then
        for i = 1, #uic_obj do
            local uic = uic_obj[i]
            if is_uicomponent(uic) then
                self._uics[#self._uics+1] = uic
            end
        end
        return
    end

    -- check if it's just one UIC
    if not is_uicomponent(uic_obj) then
        mct:error("set_uics() called for mct_option with key ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the uic_obj supplied was neither a UIC or a table of UICs! Returning false.")
        return false
    end

    self._uics[#self._uics+1] = uic_obj
end

function mct_option:get_uics()
    local uic_table = self._uics
    -- first, loop through the table of UICs to make sure they're all still valid; if any aren't, remove them
    for i = 1, #uic_table do
        local uic = uic_table[i]
        if not is_uicomponent(uic) then
            uic_table[i] = nil
        end
    end


    return uic_table
    --[[if not is_uicomponent(uic) then
        -- uic has been deleted/not created, that's fine, return false
        return false
    end

    return uic]]
end

function mct_option:set_uic_visibility(enable)
    -- default to true if a param isn't provided
    if is_nil(enable) then
        enable = true
    end

    if not is_boolean(enable) then
        mct:log("set_uic_visibility() called for option ["..self._key.."], but the argument provided is not a boolean. Returning false!")
        return false
    end

    self._uic_visible = enable

    -- if the UIC exists, set it to the new visibility!
    local uic_table = self:get_uics()
    --mct:log("DOING THIS")
    for i = 1, #uic_table do
        local uic = uic_table[i]
        if is_uicomponent(uic) then
            --mct:log("Setting component to the thing! ["..tostring(self:get_uic_visibility()).."].")
            uic:SetVisible(self:get_uic_visibility())
        end
    end
end

function mct_option:get_uic_visibility()
    return self._uic_visible
end

function mct_option:add_option_set_callback(callback)
    if not is_function(callback) then
        mct:error("Trying `add_option_set_callback()` on option ["..self._key.."], but the supplied callback is not a function. Returning false.")
        return false
    end

    --mct:log("TESTING saving callback on option ["..self._key.."].")

    self._option_set_callback = callback
end

function mct_option:process_callback()
    -- ONLY TRIGGER THIS IF A CALLBACK HAS BEEN SET?!?!?!?
    local cb = self._option_set_callback
    if is_function(cb) then
        --mct:log("TESTING calling callback on option ["..self._key.."].")
        --local ok, err = pcall(function() cb(self) end)
        --if not ok then mct:error(err) end
        cb(self)

        --core:trigger_custom_event("MctOptionCallback", {self, "option"}, {})
    end
end

function mct_option:override_position(x,y)
    if not is_number(x) or not is_number(y) then
        mct:error("override_position() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the x/y coordinates supplied are not numbers! Returning false")
        return false
    end

    -- set internal pos
    self._pos = {x=x,y=y}

    -- set coords defined in the mod obj
    local mod = self._mod
    local index = tostring(x)..","..tostring(y)
    mod._coords[index] = self._key
end

-- returns two vals, comma delimited (ie. local x,y = option:get_position())
function mct_option:get_position()
    return self._pos.x, self._pos.y
end

function mct_option:is_val_valid_for_type(val)
    local type = self:get_type()
    if type == "slider" then
        if not is_number(val) then
            return false
        end
        -- TODO check if the number is valid in the slider's number range
    elseif type == "checkbox" then
        if not is_boolean(val) then
            return false
        end
    elseif type == "dropdown" then
        if not is_string(val) then
            return false
        end
        -- TODO check if the dropdown value has been assigned as a value already
        --[[if not valid then
            return false
        end]]
    end

    return true
end

function mct_option:get_finalized_setting()
    return self._finalized_setting
end

function mct_option:set_finalized_setting_event_free(val)
    if self:is_val_valid_for_type(val) then
        self._finalized_setting = val
        self._selected_setting = val
    end
end

function mct_option:set_finalized_setting(val)
    if self:is_val_valid_for_type(val) then
        self._finalized_setting = val

        -- trigger an event to listen for externally
        core:trigger_custom_event("MctOptionSettingFinalized", {mct = mct, mod = self:get_mod(), option = self, setting = val})
    end
end

-- same as set_selected_setting, except it doesn't process a callback!
function mct_option:set_default_value(val)
    if self:is_val_valid_for_type(val) then
        self._selected_setting = val
    end
end

-- add a value as a selected setting, and then run the option-set-callback
function mct_option:set_selected_setting(val)
    if self:is_val_valid_for_type(val) then
        -- save the val as the currently selected setting, used for UI and finalization
        self._selected_setting = val

        -- run the callback, passing the mct_option along as an arg
        self:process_callback()
    end
end

function mct_option:ui_select_value(val)
    if self:is_val_valid_for_type(val) then
        

    end
end

function mct_option:get_selected_setting()
    mct:log("["..self._key.."], selected setting iiiiis: "..tostring(self._selected_setting))
    --[[if self._selected_setting == nil then
        self._selected_setting = self._default_value
    end]]

    --mct:log(tostring(self._selected_setting))
    return self._selected_setting
end

function mct_option:slider_set_values(min, max, current)
    if not self:get_type() == "slider" then
        mct:error("slider_set_values() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the option is not a slider! Returning false.")
        return false
    end

    if not is_number(min) then
        mct:error("slider_set_values() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the min value supplied ["..tostring(min).."] is not a number! Returning false.")
        return false
    end

    if not is_number(max) then
        mct:error("slider_set_values() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the max value supplied ["..tostring(max).."] is not a number! Returning false.")
        return false
    end

    if not is_number(current) then
        mct:error("slider_set_values() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the current value supplied ["..tostring(current).."] is not a number! Returning false.")
        return false
    end

    self._values = {
        min = min,
        max = max,
        current = current
    }

    self:set_default_value(current)
end

function mct_option:add_dropdown_values(dropdown_table)
    if not self:get_type() == "dropdown" then
        mct:error("add_dropdown_values() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the option is not a dropdown! Returning false.")
        return false
    end

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

function mct_option:add_dropdown_value(key, text, tt, is_default)
    if not self:get_type() == "dropdown" then
        mct:error("add_dropdown_value() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the option is not a dropdown! Returning false.")
        return false
    end

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

    self._values[#self._values+1] = val

    if is_default then
        self:set_default_value(key)
    end
end

function mct_option:get_values()
    return self._values
end

function mct_option:get_type()
    return self._type
end

function mct_option:get_uic_template()
    return self._template
end

function mct_option:get_key()
    return self._key
end

function mct_option:set_text(text, is_localised)
    if not is_string(text) then
        mct:error("set_text() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the text supplied is not a string! Returning false.")
        return false
    end

    is_localised = is_localised or false

    self._text = {text, is_localised}
end

function mct_option:set_tooltip_text(text, is_localised)
    if not is_string(text) then
        mct:error("set_tooltip_text() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the tooltip_text supplied is not a string! Returning false.")
        return false
    end

    is_localised = is_localised or false 

    self._tooltip_text = {text, is_localised}
end

function mct_option:get_text()
    -- default to checking the loc files
    local text = effect.get_localised_string("mct_"..self:get_mod():get_key().."_"..self:get_key().."_text")
    if text ~= "" then
        return text
    end
    -- nothing found, check for anything supplied by `set_text()`, or send the default "No text assigned"
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
    
    return text
end

function mct_option:get_tooltip_text()
    local text = effect.get_localised_string("mct_"..self._mod:get_key().."_"..self:get_key().."_tooltip")
    if text ~= "" then
        return text
    end

    -- nothing found, check for anything supplied by `set_tooltip()`, or send the default "No tooltip assigned"
    text = self._tooltip_text
    if is_table(text) then
        if text[2] then
            local test = effect.get_localised_string(text[1])
            if test ~= "" then
                text = test
            end
        else
            text = text[1]
        end
    end

    return text
end

return mct_option
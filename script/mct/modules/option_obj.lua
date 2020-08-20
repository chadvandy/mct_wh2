---- MCT Option Object
--- @class mct_option

-- TODO try and split up the different option types into separate smaller wrapped objects, wrapped with option_obj?
--- @type mct
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
        text_input = "ui/common ui/text_box",
        slider = {"ui/templates/cycle_button_arrow_previous", "ui/common ui/text_box", "ui/templates/cycle_button_arrow_next"}
    },

}


---- For internal use only. Called by @{mct_mod:add_new_option}.
--- @param mod mct_mod
--- @param option_key string
--- @param type string | "'slider'" | "'dropdown'" | "'checkbox'"
function mct_option.new(mod, option_key, type)
    local new_option = {}

    -- adopt all methods from the wrapped type!
    --[[for k,v in pairs(wrapped_type) do
        mct:log("assigning ["..k.."] from wrapped type ["..type.."] to mct_option ["..option_key.."].")
        new_option[k] = v
    end]]

    setmetatable(
        new_option, 
        {__index = mct_option, __tostring = function() return "MCT_OPTION" end} --new_option
    )

    new_option._mod = mod
    new_option._key = option_key
    new_option._type = type or "NULL_TYPE"
    --self._text = text or ""
    --self._tooltip_text = tooltip_text or ""
    new_option._values = {}

    -- create the wrapped type
    --new_option._wrapped_type = mct._MCT_TYPES[type]:new({mod=mod, option=new_option, key=option_key})

    new_option._wrapped_type = mct._MCT_TYPES[type]:new(new_option)

    if type == "slider" then
        new_option._values = {
            min = 0,
            max = 100,
            step_size = 1,
            step_size_precision = 0,
            precision = 0,
        }
    end

    -- assigned section, used for UI, defaults to the last created section unless one is specified
    new_option._assigned_section = mod:get_last_section():get_key()

    -- add the option to the mct_section
    new_option._mod:get_section_by_key(new_option._assigned_section):assign_option(new_option)

    -- default setting is the mct_mod default and the one to reset to;
    -- selected setting is the current UI state, defaults to default_setting if no finalized_setting;
    -- finalized setting is the saved setting in the file/etc;
    new_option._default_setting = nil
    new_option._selected_setting = nil
    new_option._finalized_setting = nil

    -- whether this option obj is read only for campaign
    new_option._read_only = false

    new_option._local_only = false
    new_option._mp_disabled = false

    -- the UICs linked to this option (the option + the txt)
    new_option._uics = {}

    -- UIC options for construction
    new_option._uic_visible = true
    new_option._uic_locked = false
    new_option._uic_lock_reason = {}
    new_option._uic_in_ui = true

    new_option._pos = {
        x = 0,
        y = 0
    }

    -- read the "type" field in the metatable's __templates field - ie., __templates[checkbox]
    new_option._template = new_option.__templates[type]
    
    --self._wrapped = wrapped

    return new_option
end

--[[function mct_option:__index(key)
    mct:log("start check in mct_option:__index")
    mct:log("calling: "..key)
    --mct:log("key: "..self:get_key())
    --mct:log("calling "..attempt.." on mct option "..self:get_key())
    local field = rawget(getmetatable(self), key)
    local retval = nil

    if type(field) == "nil" then
        mct:log("not found, check wrapped type!")
        -- not found in mct_option, check template_type!
        local wrapped_boi = rawget(self, "_wrapped_type")
        --if is_function(wrapped_boi) then
            --wrapped_boi = wrapped_boi()

            field = wrapped_boi and wrapped_boi[key]

            if type(field) == "function" then
                retval = function(obj, ...)
                    return field(wrapped_boi, ...)
                end
            else
                retval = field
            end
        --else
        --    mct:log("type:get_option() not found, fucker")
        --end
    else
        mct:log("found in mct_option")
        if type(field) == "function" then
            retval = function(obj, ...)
                return field(self, ...)
            end
        else
            retval = field
        end
    end
    
    return retval
end

function mct_option:__tostring()
    return "MCT_OPTION"
end]]

---- Read whether this mct_option is edited exclusively for the client, instead of passed between both PC's.
--- @treturn boolean local_only Whether this option is only edited on the local PC, instead of both.
function mct_option:get_local_only()
    return self._local_only
end

---- Set whether this mct_option is edited for just the local PC, or sent to both PC's.
--- For instance, this is useful for settings that don't edit the model, like enabling script logging.
--- @tparam boolean enabled True for local-only, false for passed-in-MP-and-only-editable-by-the-host.
function mct_option:set_local_only(enabled)
    if is_nil(enabled) then
        enabled = true
    end

    if not is_boolean(enabled) then
        mct:error("set_local_only() called for mct_mod ["..self:get_key().."], but the enabled argument passed is not a boolean or nil!")
        return false
    end

    self._local_only = enabled
end

---- Read whether this mct_option is available in multiplayer.
--- @treturn boolean mp_disabled Whether this mct_option is available in multiplayer or completely disabled.
function mct_option:get_mp_disabled()
    return self._mp_disabled
end

---- Set whether this mct_option exists for MP campaigns.
--- If set to true, this option is invisible for MP and completely untracked by MCT.
--- @tparam boolean enabled True for MP-disabled, false to MP-enabled
function mct_option:set_mp_disabled(enabled)
    if is_nil(enabled) then
        enabled = true
    end

    if not is_boolean(enabled) then
        mct:error("set_mp_disabled() called for mct_mod ["..self:get_key().."], but the enabled argument passed is not a boolean or nil!")
        return false
    end

    self._mp_disabled = enabled
end

--- Read whether this mct_option can be edited or not at the moment.
-- @treturn boolean read_only Whether this option is uneditable or not.
function mct_option:get_read_only()
    return self._read_only
end

---- Set whether this mct_option can be edited or not at the moment.
--- @tparam boolean enabled True for non-editable, false for editable.
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

---- Assigns the section_key that this option is a member of.
--- Calls @{mct_section:assign_option} internally.
--- @tparam string section_key The key for the section this option is being added to.
function mct_option:set_assigned_section(section_key)
    local mod = self:get_mod()
    local section = mod:get_section_by_key(section_key)
    if not mct:is_mct_section(section) then
        mct:log("set_assigned_section() called for option ["..self:get_key().."] in mod ["..mod:get_key().."] but no section with the key ["..section_key.."] was found!")
        return false
    end

    section:assign_option(self) -- this sets the option's self._assigned_section
end

---- Reads the assigned_section for this option.
--- @treturn string section_key The key of the section this option is assigned to.
function mct_option:get_assigned_section()
    return self._assigned_section
end

---- Get the @{mct_mod} object housing this option.
--- @return mct_mod @{mct_mod}
function mct_option:get_mod()
    return self._mod
end

---- Internal use only. Clears all the UIC objects attached to this boy.
--- @local
function mct_option:clear_uics(kill_selected)
    --self._selected_setting = nil
    self._uics = {}

    if kill_selected then
        self._selected_setting = nil
    end
end


---- Internal use only. Set UICs through the uic_obj
--- @local
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

---- Internal use only. Grab a UIC by a key
--- @local
function mct_option:get_uic_with_key(key)
    if self._uics == nil or self._uics == {} or self._uics[1] == nil then
        mct:error("get_uic_with_key() called for mct_option with key ["..self:get_key().."] but no uics are found! Returning false.")
        return false
    end

    local uic_table = self._uics
    
    for i = 1, #uic_table do
        local uic = uic_table[i]
        if is_uicomponent(uic) then
            if uic:Id() == key then
                return uic
            end
        end
    end

    return false
end

---- Internal use only. Get all UICs.
--- @local
function mct_option:get_uics()
    local uic_table = self._uics
    local copy = {}

    -- first, loop through the table of UICs to make sure they're all still valid; if any are, add them to a copy table
    for i = 1, #uic_table do
        local uic = uic_table[i]
        if is_uicomponent(uic) then
            copy[#copy+1] = uic
        end
    end

    self._uics = copy
    return self._uics
end

---- Set a UIC as visible or invisible, dynamically. If the UIC isn't created yet, it will get the applied setting when it is created.
--- @tparam boolean visibility True for visible, false for invisible.
--- @tparam boolean keep_in_ui This boolean determines whether this mct_option will exist at all in the UI. Tick this to true to make the option invisible but still have a "gap" in the UI where it would be placed. Set this to false to make that spot be taken by the next otion. ONLY AFFECTS INITIAL UI CREATION.
--- @within API
function mct_option:set_uic_visibility(visibility, keep_in_ui)
    -- default to true if a param isn't provided
    if is_nil(visibility) then
        visibility = true
    end

    -- ditto
    if is_nil(keep_in_ui) then
        keep_in_ui = true
    end

    if not is_boolean(visibility) then
        mct:log("set_uic_visibility() called for option ["..self._key.."], but the visibility argument provided is not a boolean. Returning false!")
        return false
    end    
    
    if not is_boolean(keep_in_ui) then
        mct:log("set_uic_visibility() called for option ["..self._key.."], but the keep_in_ui argument provided is not a boolean. Returning false!")
        return false
    end

    self._uic_in_ui = keep_in_ui
    self._uic_visible = visibility

    -- if the UIC exists, set it to the new visibility!
    local uic_table = self:get_uics()
    --mct:log("DOING THIS")
    for i = 1, #uic_table do
        local uic = uic_table[i]
        if is_uicomponent(uic) then
            --mct:log("Setting component to the thing! ["..tostring(self:get_uic_visibility()).."].")
            mct.ui:uic_SetVisible(uic, self:get_uic_visibility())
        end
    end
end

---- Get the current visibility for this mct_option.
--- @treturn boolean visibility True for visible, false for invisible.
--- @within API
function mct_option:get_uic_visibility()
    return self._uic_visible
end

---- Create a callback triggered whenever this option's setting changes within the MCT UI.
--- You can alternatively do this through core:add_listener(), using the "MctOptionSelectedSettingSet" event. The reason this callback is here, is for backwards compatibility.
--- The function will automatically be passed a context object (methods listed below) so you can read state of everything and go from there.
--- ex:
--- when the "enable" button is checked on or off, all other options are set visible or invisible
--- enable:add_option_set_callback(
---    function(context) 
---        local option = context:option()
---        local mct_mod = option:get_mod()
---
---        local val = context:setting()
---        local options = options_list
---
---        for i = 1, #options do
---            local i_option_key = options[i]
---            local i_option = mct_mod:get_option_by_key(i_option_key)
---            i_option:set_uic_visibility(val)
---        end
---    end
---)
--- @tparam function callback The callback triggered whenever this option is changed. Callback will be passed one argument - the `context` object for the listener. `context:mct()`, `context:option()`, `context:setting()`, and `context:is_creation()` (for if this was triggered on the UI being created) are the valid methods on context.
--- @tparam boolean is_context Set this to true if you want to treat this function with the new method of passing a context. If this is false or nil, it will pass the mct_option like before. For backwards compatibility - I'll probably take this out eventually.
--- @within API
function mct_option:add_option_set_callback(callback, is_context)
    if not is_function(callback) then
        mct:error("Trying `add_option_set_callback()` on option ["..self._key.."], but the supplied callback is not a function. Returning false.")
        return false
    end

    core:add_listener(
        "MctOption"..self:get_key().."Set",
        "MctOptionSelectedSettingSet",
        function(context)
            return context:option():get_key() == self:get_key()
        end,
        function(context)
            if is_context == true then
                callback(context)
            else
                callback(self)
            end
        end,
        true
    )
end

---- Manually set the x/y position for this option, within its section.
--- @warning Use with caution, this needs an overhaul in the future!
--- @tparam number x x-coord
--- @tparam number y y-coord
--- @within API
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

--- Get the x/y coordinates of the mct_option
--- Returns two vals, comma delimited (ie. local x,y = option:get_position())
--- @treturn number x x-coord
--- @treturn number y y-coord
--- @local
function mct_option:get_position()
    return self._pos.x, self._pos.y
end

function mct_option:get_wrapped_type()
    return self._wrapped_type
end

--- Internal checker to see if the values passed through mct_option methods are valid.
--- @tparam any val Value being tested for type.
function mct_option:is_val_valid_for_type(val)
    local wrapped = self:get_wrapped_type()

    return wrapped:check_validity(val)
end

function mct_option:check_validity(val)
    return self:get_wrapped_type():check_validity(val)
end

function mct_option:set_default()
    return self:get_wrapped_type():set_default()
end

---- Internal function that calls the operation to change an option's selected value. Exposed here so it can be called through presets and the like.
--- @param val any Set the selected setting as the passed value, tested with @{mct_option:is_val_valid_for_type}
--- @tparam boolean is_new_version Set this to true to skip calling @{mct_option:set_selected_setting} from within. This is done to keep the mod backwards compatible with the last patch, where the Order of Operations went ui_select_value -> set_selected_setting; the new Order of Operations is the inverse.
function mct_option:ui_select_value(val, is_new_version)
    if not self:is_val_valid_for_type(val) then
        mct:error("ui_select_value() called for option with key ["..self:get_key().."], but the val supplied ["..tostring(val).."] is not valid for the type!")
        return false
    end

    local option_uic = self:get_uics()[1]

    if not is_uicomponent(option_uic) then
        mct:error("ui_select_value() called for option with key ["..self:get_key().."], in mct_mod ["..self:get_mod():get_key().."], but this option doesn't currently exist in the UI! Aborting change.")
        return false
    end

    self:get_wrapped_type():ui_select_value(val)

    if not is_new_version then
        self:set_selected_seting(val)
    end

    mct.ui:set_actions_states()
end

function mct_option:ui_change_state()
    return self:get_wrapped_type():ui_change_state()
end

function mct_option:ui_create_option(dummy_parent)
    return self:get_wrapped_type():ui_create_option(dummy_parent)
end

-- type-specifics
function mct_option:slider_get_precise_value()
    return self:get_wrapped_type():slider_get_precise_value()
end

function mct_option:slider_set_step_size(...)
    return self:get_wrapped_type():slider_set_step_size(...)
end

function mct_option:slider_set_precision(...)
    return self:get_wrapped_type():slider_set_precision(...)
end

function mct_option:slider_set_min_max(...)
    return self:get_wrapped_type():slider_set_min_max(...)
end

function mct_option:add_dropdown_values(...)
    return self:get_wrapped_type():add_dropdown_values(...)
end

function mct_option:add_dropdown_value(...)
    return self:get_wrapped_type():add_dropdown_value(...)
end

function mct_option:refresh_dropdown_box()
    return self:get_wrapped_type():refresh_dropdown_box()
end


---- Getter for the "finalized_setting" for this `mct_option`.
--- @treturn any finalized_setting Finalized setting for this `mct_option` - either the default value set via @{mct_option:set_default_value}, or the latest saved value if in a campaign, or the latest mct_settings.lua - value if in a new campaign or in frontend.
--- @within API
function mct_option:get_finalized_setting()
    local test = self._finalized_setting

    if is_nil(test) then
        local default_val = self:get_default_value()
        if default_val ~= nil then
            self._finalized_setting = default_val
        else
            mct:error("get_finalized_setting() called for option ["..self:get_key().."], but there is no finalized or default setting for this option!")
            return nil
        end
    end

    return self._finalized_setting
end

-- TODO hookup is_event_free // decide on using it
---- Internal use only. Sets the finalized setting and triggers the event "MctOptionSettingFinalized".
--- @tparam any val Set the finalized setting as the passed value, tested with @{mct_option:is_val_valid_for_type}
--- @tparam boolean is_event_free Set to true to skip MctOptionSettingFinalized. Used by save/load version.
--- @local
function mct_option:set_finalized_setting(val, is_event_free)
    if self:is_val_valid_for_type(val) then
        if self:get_read_only() and __game_mode == __lib_type_campaign then
            -- can't change finalized setting for read onlys! Error!
            mct:error("set_finalized_setting() called for mct_option ["..self:get_key().."], but the option is read only! This REALLY shouldn't happen, investigate.")
            return false
        end

        -- save locally
        self._finalized_setting = val


        -- save on the mct_mod attached, too
        local mod = self:get_mod()
        mod._finalized_settings[self:get_key()] = val

        if self:get_selected_setting() ~= val then
            self:set_selected_setting(val)
        end

        -- trigger an event to listen for externally
        core:trigger_custom_event("MctOptionSettingFinalized", {mct = mct, mod = self:get_mod(), option = self, setting = val})
    end
end

--- Set the default setting when the mct_mod is first created and loaded. Also used for the "Revert to Defaults" option.
--- @tparam any val Set the default setting as the passed value, tested with @{mct_option:is_val_valid_for_type}
function mct_option:set_default_value(val)
    if self:is_val_valid_for_type(val) then
        self._default_setting = val
        --self._selected_setting = val
    end
end

---- Getter for the default setting for this mct_option.
--- @treturn any The modder-set default value.
function mct_option:get_default_value()
    -- if no default value was set, pick one automatically.
    local default_val = self._default_setting

    if is_nil(default_val) then
        -- pick the default value for the modder:
            -- false for checkbox
            -- between min/max for sliders
            -- first added option for dropdowns

        --local wrapped = self:get_wrapped_type()

        self:set_default()
    end

    return self._default_setting
end

---- Triggered via the UI object. Change the mct_option's selected value, and trigger the script event "MctOptionSelectedSettingSet". Can be listened through a listener, or by using @{mct_option:add_option_set_callback}.
--- @tparam any val Set the selected setting as the passed value, tested with @{mct_option:is_val_valid_for_type}
--- @tparam boolean is_creation Whether this is being set on the option's UI creation, or being set somewhere else.
--- @local
function mct_option:set_selected_setting(val, is_creation)
    if self:is_val_valid_for_type(val) then
        -- make sure nothing happens if the new val is the current setting
        if self:get_selected_setting() == val then
            return
        end

        -- save the val as the currently selected setting, used for UI and finalization
        self._selected_setting = val

        core:trigger_custom_event("MctOptionSelectedSettingSet", {mct = mct, option = self, setting = val, is_creation = is_creation} )

        if not is_creation then
            mct.ui:set_changed_setting(self:get_mod():get_key(), self:get_key(), val)
        end

        -- call ui_select_value if the UI exists
        if is_uicomponent(self:get_uics()[1]) then
            self:ui_select_value(val, true)
        end

        --[[if not event_free then
            -- run the callback, passing the mct_option along as an arg
            self:process_callback()
        end]]
    end
end

---- Getter for whether this UIC is currently locked.
--- @return boolean uic_locked Whether the UIC is set as locked.
function mct_option:get_uic_locked()
    return self._uic_locked
end

---- Set this option as disabled in the UI, so the user can't interact with it.
--- This will result in `mct_option:ui_change_state()` being called later on.
--- @tparam boolean should_lock Lock this UI option, preventing it from being interacted with.
--- @tparam string lock_reason The text to supply to the tooltip, to show the player why this is locked. This argument is ignored if should_lock is false.
--- @tparam boolean is_localised Set to true if lock_reason is a localised key; else, set it to false or leave it blank. Ignored ditto above.
function mct_option:set_uic_locked(should_lock, lock_reason, is_localised)
    if is_nil(should_lock) then 
        should_lock = true 
    end

    if not is_boolean(should_lock) then 
        mct:error("set_uic_locked() called for mct_option with key ["..self:get_key().."], but the should_lock argument passed is not a boolean or nil!")
        return false 
    end

    -- only care about localisation if it's being locked!
    if should_lock then
        if is_nil(lock_reason) then
            -- default lock_reason
        end

        if not is_string(lock_reason) then
            -- errmsg
            return false
        end

        if is_nil(is_localised) then
            is_localised = false
        end

        if not is_boolean(is_localised) then
            -- errmsg
            return false
        end

        self._uic_lock_reason = {text = lock_reason, is_localised = is_localised}
    else
        self._uic_lock_reason = {}
    end

    self._uic_locked = should_lock

    -- if the option already exists in UI, update its state
    if is_uicomponent(self:get_uics()[1]) then
        self:ui_change_state()
    end
end

---- Internal function to set the option UIC as disabled or enabled, for read-only/mp-disabled.
--- Use `mct_option:set_uic_locked()` for the external version of this.
--- @see mct_option:set_uic_locked
--[[function mct_option:ui_change_state()

end]]

function mct_option:get_lock_reason()
    local locked = self:get_uic_locked()

    local lock_reason = ""
    if locked then
        local lock_reason_tab = self._uic_lock_reason 
        if lock_reason_tab.is_localised then
            lock_reason = effect.get_localised_string(lock_reason_tab.text)
        else
            lock_reason = lock_reason_tab.text
        end

        if lock_reason == "" then
            -- revert to default? TODO
        end
    end

    return lock_reason
end

---- Getter for the current selected setting. This is the value set in @{mct_option:set_default_value} if nothing has been selected yet in the UI.
--- Used when finalizing settings.
--- @treturn any val The value set as the selected_setting for this mct_option.
--- @within API
function mct_option:get_selected_setting()
    -- no selected setting found - UI was just created!
    if self._selected_setting == nil then

        -- default to the current finalized setting
        if self:get_finalized_setting() ~= nil then
            self._selected_setting = self:get_finalized_setting()

        -- if no finalized setting, set to the default setting
        elseif self:get_default_value() ~= nil then
            self._selected_setting = self:get_default_value()
        end
    end

    return self._selected_setting
end

---- Getter for the available values for this mct_option - true/false for checkboxes, different stuff for sliders/dropdowns/etc.
--- @local
function mct_option:get_values()
    return self._values
end

---- Getter for this mct_option's type; slider, dropdown, checkbox
--- @local
function mct_option:get_type()
    return self._type
end

---- Getter for this option's UIC template for quick reference.
--- @local
function mct_option:get_uic_template()
    return self._template
end

---- Getter for this option's key.
--- @within API
--- @treturn string key mct_option's unique identifier
function mct_option:get_key()
    return self._key
end

---- Setter for this option's text, which displays next to the dropdown box/checkbox.
--- MCT will automatically read for text if there's a loc key with the format `mct_[mct_mod_key]_[mct_option_key]_text`.
--- @tparam string text The text string for this option. You can either supply hard text - ie., "My Cool Option" - or a loc key - ie., "`ui_text_replacements_my_cool_option`".
--- @tparam boolean is_localised True if a loc key was supplied for the text parameter.
function mct_option:set_text(text, is_localised)
    if not is_string(text) then
        mct:error("set_text() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the text supplied is not a string! Returning false.")
        return false
    end

    is_localised = is_localised or false

    self._text = {text, is_localised}
end

---- Setter for this option's tooltip, which displays when hovering over the option or the text.
--- MCT will automatically read for text if there's a loc key with the format `mct_[mct_mod_key]_[mct_option_key]_tooltip`.
--- @tparam string text The tootlip string for this option. You can either supply hard text - ie., "My Cool Option's Tooltip" - or a loc key - ie., "`ui_text_replacements_my_cool_option_tt`".
--- @tparam boolean is_localised True if a loc key was supplied for the text parameter.
function mct_option:set_tooltip_text(text, is_localised)
    if not is_string(text) then
        mct:error("set_tooltip_text() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the tooltip_text supplied is not a string! Returning false.")
        return false
    end

    is_localised = is_localised or false 

    self._tooltip_text = {text, is_localised}
end

---- Getter for this option's text. Will read the loc key, `mct_[mct_mod_key]_[mct_option_key]_text`, before seeing if any was supplied through @{mct_option:set_text}.
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

---- Getter for this option's text. Will read the loc key, `mct_[mct_mod_key]_[mct_option_key]_tooltip`, before seeing if any was supplied through @{mct_option:set_tooltip_text}.
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

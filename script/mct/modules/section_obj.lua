--- Section Object
-- @classmod mct_section

local mct = mct

local mct_section = {
    _key = "",
    _text = "No text assigned",
}

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

    return self
end

function mct_section:clear_uics()
    self._dummy_rows = {}
    self._header = {}
end

function mct_section:add_dummy_row(uic)
    if not is_uicomponent(uic) then
        -- errmsg
        return false
    end

    self._dummy_rows[#self._dummy_rows+1] = uic
end

function mct_section:uic_visibility_change(event_free)
    mct:log("uic visibility change yay")
    local visibility = self._visible
    mct:log("switching to "..tostring(visibility))

    local attached_rows = self._dummy_rows
    for i = 1, #attached_rows do
        mct:log("in loop "..tostring(i))
        if not is_uicomponent(attached_rows[i]) then
            -- skip
            mct:log("row here isn't a UIC")
            attached_rows[i] = nil
        else
            mct:log("UIC found, setting to visibility")
            local row = attached_rows[i]
            mct.ui:uic_SetVisible(row, visibility)
            --row:SetVisible(visibility)
        end
    end

    --[[if not is_uicomponent(self._header) then
        mct:error("running uic_visibility_change() for section ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the header UIC cannot be found! Returning false.")
        return false
    end]]

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

function mct_section:add_section_visibility_change_callback(callback)
    if not is_function(callback) then
        mct:error("add_section_visibility_change_callback() called for section ["..self:get_key().."] in mod ["..self:get_mod():get_key()..", but the callback passed is not a function!")
        return false
    end

    self._visibility_change_callback = callback
end

function mct_section:process_callback()
    local f = self._visibility_change_callback

    if not is_function(f) then
        -- errmsg
        -- should never happen
        return false
    end

    f(self)
end

function mct_section:get_dummy_rows()
    return self._dummy_rows or {}
end

function mct_section:get_key()
    return self._key
end

function mct_section:get_mod()
    return self._mod
end

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

function mct_section:is_visible()
    return self._visible
end

function mct_section:set_visibility(enable)
    if is_nil(enable) then enable = true end

    if not is_boolean(enable) then
        -- errmsg
        return false
    end

    self._visible = enable

    -- test if the UI object exists - if it does, call the UI wrapper!
    if is_uicomponent(self._header) then
        self:uic_visibility_change()
    end
end

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


function mct_section:assign_option(option_obj)
    if is_string(option_obj) then
        -- try to get an option obj with this key
        option_obj = self:get_mod():get_option_by_key(option_obj)
    end

    if not mct:is_mct_option(option_obj) then
        -- errmsg
        return false
    end

    self._options[option_obj:get_key()] = option_obj
end

function mct_section:get_options()
    return self._options
end


return mct_section
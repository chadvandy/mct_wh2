--- Section Object
-- @classmod mct_section

local mct = mct

local mct_section = {
    _key = "",
    _txt = "No text assigned",

    _mod = nil,

    _options = {},

    _visible = true,
}

function mct_section.new(key, mod)
    local self = {}
    setmetatable(self, {__index = mct_section, __tostring = "MCT_SECTION"})
    
    self._key = key
    self._mod = mod

    return self
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
        return text
    end

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
end

function mct_section:set_localised_text(text, is_localised)
    if not is_string(text) then
        mct:error("set_localised_text() called for section ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the text supplied is not a string! Returning false.")
        return false
    end

    is_localised = is_localised or false

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
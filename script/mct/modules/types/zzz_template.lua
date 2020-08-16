---- Template file for the "types" objects. Used for any functions shared by all types, and to catch any type-specific functions being called on the wrong type, ie. calling `slider_set_min_max` on a dropdown.
--- @class template_type

local mct = mct

local template_type = {}

function template_type:__index(attempt)
    mct:log("start")
    mct:log("calling: "..attempt)
    --mct:log("key: "..self:get_key())
    --mct:log("calling "..attempt.." on mct option "..self:get_key())
    local field = rawget(getmetatable(self), attempt)
    local retval = nil

    if type(field) == "nil" then
        mct:log("not found, checking mct_option")
        local wrapped = self:get_option()

        field = wrapped and wrapped[attempt]

        if type(field) == "function" then
            mct:log("func found")
            retval = function(obj, ...)
                return field(wrapped, ...)
            end
        else
            mct:log("non-func found")
            retval = field
        end
    else
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

function template_type:get_key()
    return self:get_option():get_key()
end

function template_type:get_mod()
    return self:get_option():get_mod()
end

function template_type:get_option()
    return self.option
end

--[[function template_type:get_type()
    return self.type
end]]

function template_type:override_error(function_name)
    mct:error(function_name .. "() called on mct_option ["..self:get_key().."] with type ["..self:get_type().."], but the function wasn't overriden! Investigate!")
    return false
end

function template_type:check_validity(value)
    return self:override_error("check_validity")
end

function template_type:set_default()
    return self:override_error("set_default")
end

function template_type:ui_select_value(val)
    return self:override_error("ui_select_value")
end

function template_type:ui_change_state(val)
    return self:override_error("ui_change_state")
end

---- Unique Calls ----
-- These only exist for specific types; put defaults here to check if they're called on the wrong type
function template_type:type_error(function_name, type_expected)
    mct:error(function_name .. "() called on mct_option ["..self:get_key().."] with type ["..self:get_type().."], but this function expects the type ["..type_expected.."]. Abortin'.")

    return false
end

---- Slider Only ----
function template_type:slider_get_precise_value()
    return self:type_error("slider_get_precise_value", "slider")
end

function template_type:slider_set_step_size()
    return self:type_error("slider_set_step_size", "slider")
end

function template_type:slider_set_precision()
    return self:type_error("slider_set_precision", "slider")
end

function template_type:slider_set_min_max()
    return self:type_error("slider_set_min_max", "slider")
end

---- Dropdown Only ----
function template_type:add_dropdown_values()
    return self:type_error("add_dropdown_values", "dropdown")
end

function template_type:add_dropdown_value()
    return self:type_error("add_dropdown_value", "dropdown")
end

return template_type
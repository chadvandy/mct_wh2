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

function type:check_validity(value)
    if not is_number(value) then
        return false
    end

    -- TODO check min/max
    -- TODO check precision

    return true
end

function type:set_default()
    local option = self:get_option()

    local values = self:get_values()

    local min = values.min
    local max = values.max

    -- get the "average" of the two numbers, (min+max)/2
    -- TODO set this with respect for the step sizes, precision, etc
    option._default_setting = (min+max)/2
end

function type:ui_select_value(val)
    local option = self:get_option()

    local option_uic = option:get_uics()[1]

    local right_button = find_uicomponent(option_uic, "right_button")
    local left_button = find_uicomponent(option_uic, "left_button")
    local text_input = find_uicomponent(option_uic, "text_input")

    --mct:log("ui select val for slider 2")

    local values = option:get_values()
    local max = values.max
    local min = values.min
    local step_size = values.step_size
    local step_size_precision = values.step_size_precision

    --mct:log("ui select val for slider 3")

    -- enable both buttons & push new value
    right_button:SetState("active")
    left_button:SetState("active")

    if val >= max then
        right_button:SetState("inactive")
        left_button:SetState("active")

        val = max
    elseif val <= min then
        left_button:SetState("inactive")
        right_button:SetState("active")

        val = min
    end

    -- TODO move step size edits out of this one?
    local step_size_str = self:slider_get_precise_value(step_size, true, step_size_precision)

    left_button:SetTooltipText("-"..step_size_str, true)
    right_button:SetTooltipText("+"..step_size_str, true)

    --local current = self:get_precise_value(self:get_selected_setting(), false)
    local current_str = self:slider_get_precise_value(option:get_selected_setting(), true)

    text_input:SetStateText(tostring(current_str))
    text_input:SetInteractive(false)
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

    local left_button = find_uicomponent(option_uic, "left_button")
    local right_button = find_uicomponent(option_uic, "right_button")
    --local text_input = find_uicomponent(option_uic, "text_input")

    local state = "active"
    local tt = option:get_tooltip_text()
    if locked then
        state = "inactive"
        tt = lock_reason .. "\n" .. tt
    end

    --mct.ui:uic_SetInteractive(text_input, not locked)
    mct.ui:uic_SetState(left_button, state)
    mct.ui:uic_SetState(right_button, state)
    mct.ui:uic_SetTooltipText(text_uic, tt, true)
end

--------- UNIQUE SECTION -----------
-- These functions are unique for this type only. Be careful calling these!

function type:slider_get_precise_value(value, as_string, override_precision)
    if not is_number(value) then
        -- errmsg
        return false
    end

    if is_nil(as_string) then
        as_string = false
    end

    if not is_boolean(as_string) then
        -- errmsg
        return false
    end


    local function round_num(num, numDecimalPlaces)
        local mult = 10^(numDecimalPlaces or 0)
        if num >= 0 then
            return math.floor(num * mult + 0.5) / mult
        else
            return math.ceil(num * mult - 0.5) / mult
        end
    end

    local function round(num, places, is_string)
        if not is_string then
            return round_num(num, places)
        end

        return string.format("%."..(places or 0) .. "f", num)
    end

    local option = self:get_option()

    local values = option:get_values()
    local precision = values.precision

    if is_number(override_precision) then
        precision = override_precision
    end

    return round(value, precision, as_string)
end

---- Set function to set the step size for moving left/right through the slider.
--- Works with floats and other numbers. Use the optional second argument if using floats/decimals
--- @tparam number step_size The number to jump when using the left/right button.
--- @tparam number step_size_precision The precision for the step size, to prevent weird number changing. If the step size is 0.2, for instance, the precision would be 1, for one-decimal-place.
function type:slider_set_step_size(step_size, step_size_precision)
    --[[if not self:get_type() == "slider" then
        mct:error("slider_set_step_size() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the option is not a slider! Returning false.")
        return false
    end]]

    if not is_number(step_size) then
        mct:error("slider_set_step_size() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the step size value supplied ["..tostring(step_size).."] is not a number! Returning false.")
        return false
    end

    if is_nil(step_size_precision) then
        step_size_precision = 0
    end

    if not is_number(step_size_precision) then
        mct:error("slider_set_step_size() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the step size precision value supplied ["..tostring(step_size_precision).."] is not a number! Returning false.")
        return false
    end
    
    local option = self:get_option()

    option._values.step_size = step_size
    option._values.step_size_precision = step_size_precision
end

---- Setter for the precision on the slider's displayed value. Necessary when working with decimal numbers.
--- The number should be how many decimal places you want, ie. if you are using one decimal place, send 1 to this function; if you are using none, send 0.
--- @tparam number precision The precision used for floats.
function type:slider_set_precision(precision)
    --[[if not self:get_type() == "slider" then
        mct:error("slider_set_precision() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the option is not a slider! Returning false.")
        return false
    end]]

    if not is_number(precision) then
        mct:error("slider_set_precision() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the min value supplied ["..tostring(precision).."] is not a number! Returning false.")
        return false
    end

    local option = self:get_option()

    option._values.precision = precision
end

---- Setter for the minimum and maximum values for the slider. If the UI already exists, this method will do a quick check to make sure the current value is between the new min/max, and it will change the lock states of the left/right buttons if necessary.
--- @tparam number min The minimum number the slider value can reach.
--- @tparam number max The maximum number the slider value can reach.
--- @within API
function type:slider_set_min_max(min, max)
    --[[if not self:get_type() == "slider" then
        mct:error("slider_set_min_max() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the option is not a slider! Returning false.")
        return false
    end]]

    if not is_number(min) then
        mct:error("slider_set_min_max() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the min value supplied ["..tostring(min).."] is not a number! Returning false.")
        return false
    end

    if not is_number(max) then
        mct:error("slider_set_min_max() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the max value supplied ["..tostring(max).."] is not a number! Returning false.")
        return false
    end

    --[[if not is_number(current) then
        mct:error("slider_set_values() called for option ["..self:get_key().."] in mct_mod ["..self:get_mod():get_key().."], but the current value supplied ["..tostring(current).."] is not a number! Returning false.")
        return false
    end]]

    local option = self:get_option()

    option._values.min = min
    option._values.max = max

    -- if the UI exists, change the buttons and set the value if it's above the max/below the min
    local uic = option:get_uics()[1]
    if is_uicomponent(uic) then
        local current_val = option:get_selected_setting()

        if current_val > max then
            option:set_selected_setting(max)
        elseif current_val < min then
            option:set_selected_setting(min)
        else
            option:set_selected_setting(current_val)
        end
    end
end

return type
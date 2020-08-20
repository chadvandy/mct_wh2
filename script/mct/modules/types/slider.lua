local mct = mct

local template_type = mct._MCT_TYPES.template

local lua_type = type
local type = {}

function type:new(option_obj)
    local self = {}

    --[[for k,v in pairs(getmetatable(tt)) do
        mct:log("assigning ["..k.."] to checkbox_type from template_type.")
        self[k] = v
    end
]]
    setmetatable(self, type)

    --[[for k,v in pairs(type) do
        mct:log("assigning ["..k.."] to checkbox_type from self!")
        self[k] = v
    end]]

    self.option = option_obj

    local tt = template_type:new(option_obj)

    self.template_type = tt

    return self
end

function type:__index(attempt)
    --mct:log("start check in type:__index")
    --mct:log("calling: "..attempt)
    --mct:log("key: "..self:get_key())
    --mct:log("calling "..attempt.." on mct option "..self:get_key())
    local field = rawget(getmetatable(self), attempt)
    local retval = nil

    if lua_type(field) == "nil" then
        --mct:log("not found, check mct_option")
        -- not found in mct_option, check template_type!
        local wrapped_boi = rawget(self, "option")

        field = wrapped_boi and wrapped_boi[attempt]

        if lua_type(field) == "nil" then
            --mct:log("not found in wrapped_type or mct_option, check in template_type!")
            -- not found in mct_option or wrapped_type, check in template_type
            local wrapped_boi_boi = rawget(self, "template_type")
            
            field = wrapped_boi_boi and wrapped_boi_boi[attempt]
            if lua_type(field) == "function" then
                retval = function(obj, ...)
                    return field(wrapped_boi_boi, ...)
                end
            else
                retval = field
            end
        else
            if lua_type(field) == "function" then
                retval = function(obj, ...)
                    return field(wrapped_boi, ...)
                end
            else
                retval = field
            end
        end
    else
        --mct:log("found in wrapped_type")
        if lua_type(field) == "function" then
            retval = function(obj, ...)
                return field(self, ...)
            end
        else
            retval = field
        end
    end
    
    return retval
end

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
    local values = self:get_values()

    local min = values.min
    local max = values.max

    -- get the "average" of the two numbers, (min+max)/2
    -- TODO set this with respect for the step sizes, precision, etc
    self:set_default_value((min+max)/2)
end

function type:ui_select_value(val)
    local option_uic = self:get_uics()[1]
    if not is_uicomponent(option_uic) then
        mct:error("ui_select_value() triggered for mct_option with key ["..self:get_key().."], but no option_uic was found internally. Aborting!")
        return false
    end

    --print_all_uicomponent_children(option_uic)

    local right_button = find_uicomponent(option_uic, "right_button")
    local left_button = find_uicomponent(option_uic, "left_button")
    local text_input = find_uicomponent(option_uic, "text_input")

    --mct:log("ui select val for slider 2")

    local values = self:get_values()
    local max = values.max
    local min = values.min
    local step_size = values.step_size
    local step_size_precision = values.step_size_precision

    mct:log(values)

    --mct:log("ui select val for slider 3")

    -- enable both buttons & push new value
    mct.ui:uic_SetState(right_button, "active")
    mct.ui:uic_SetState(left_button, "active")


    if val >= max then
        mct.ui:uic_SetState(right_button, "inactive")
        mct.ui:uic_SetState(left_button, "active")

        val = max
    elseif val <= min then
        mct.ui:uic_SetState(left_button, "inactive")
        mct.ui:uic_SetState(right_button, "active")

        val = min
    end

    -- TODO move step size edits out of this one?
    local step_size_str = self:slider_get_precise_value(step_size, true, step_size_precision)

    mct.ui:uic_SetTooltipText(left_button, "-"..step_size_str, true)
    mct.ui:uic_SetTooltipText(right_button, "+"..step_size_str, true)

    --local current = self:get_precise_value(self:get_selected_setting(), false)
    local current_str = self:slider_get_precise_value(self:get_selected_setting(), true)

    text_input:SetStateText(tostring(current_str))
    text_input:SetInteractive(false)
end

function type:ui_change_state()
    local option_uic = self:get_uics()[1]
    local text_uic = self:get_uic_with_key("text")

    local locked = self:get_uic_locked()
    local lock_reason = self:get_lock_reason()

    local left_button = find_uicomponent(option_uic, "left_button")
    local right_button = find_uicomponent(option_uic, "right_button")
    --local text_input = find_uicomponent(option_uic, "text_input")

    local state = "active"
    local tt = self:get_tooltip_text()
    if locked then
        state = "inactive"
        tt = lock_reason .. "\n" .. tt
    end

    --mct.ui:uic_SetInteractive(text_input, not locked)
    mct.ui:uic_SetState(left_button, state)
    mct.ui:uic_SetState(right_button, state)
    mct.ui:uic_SetTooltipText(text_uic, tt, true)
end

-- UIC Properties:
-- Value
-- minValue
-- maxValue
-- Notify (unused?)
-- update_frequency (doesn't change anything?)
function type:ui_create_option(dummy_parent)
    local templates = self:get_uic_template()
    --local values = option_obj:get_values()

    local left_button_template = templates[1]
    local right_button_template = templates[3]
    
    local text_input_template = templates[2]

    -- hold it all in a dummy
    local new_uic = core:get_or_create_component("mct_slider", "ui/mct/script_dummy", dummy_parent)
    new_uic:SetVisible(true)
    new_uic:Resize(dummy_parent:Width() * 0.4, dummy_parent:Height())

    local left_button = core:get_or_create_component("left_button", left_button_template, new_uic)
    local right_button = core:get_or_create_component("right_button", right_button_template, new_uic)
    local text_input = core:get_or_create_component("text_input", text_input_template, new_uic)

    text_input:SetCanResizeWidth(true)
    text_input:Resize(text_input:Width() * 0.3, text_input:Height())
    text_input:SetCanResizeWidth(false)

    left_button:SetDockingPoint(4)
    text_input:SetDockingPoint(5)
    right_button:SetDockingPoint(6)

    left_button:SetDockOffset(0,0)
    right_button:SetDockOffset(0,0)

    self:set_uics(new_uic)

    return new_uic
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

    local values = self:get_values()
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
    local uic = self:get_uics()[1]
    if is_uicomponent(uic) then
        local current_val = self:get_selected_setting()

        if current_val > max then
            self:set_selected_setting(max)
        elseif current_val < min then
            self:set_selected_setting(min)
        else
            self:set_selected_setting(current_val)
        end
    end
end

---- UI selected listeners & stuff
core:add_listener(
    "mct_slider_left_or_right_pressed",
    "ComponentLClickUp",
    function(context)
        local uic = UIComponent(context.component)
        return (uic:Id() == "left_button" or uic:Id() == "right_button") and uicomponent_descended_from(uic, "mct_slider")
    end,
    function(context)
        local ok, err = pcall(function()
        local step = context.string
        local uic = UIComponent(context.component)

        local slider = UIComponent(uic:Parent())
        local dummy_option = UIComponent(slider:Parent())

        local option_key = dummy_option:Id()
        local mod_obj = mct:get_selected_mod()
        mct:log("getting mod "..mod_obj:get_key())
        mct:log("finding option with key "..option_key)

        local option_obj = mod_obj:get_option_by_key(option_key)

        local values = option_obj:get_values()
        local step_size = values.step_size

        if step == "right_button" then
            mct:log("changing val from "..option_obj:get_selected_setting().. " to "..option_obj:get_selected_setting() + step_size)
            option_obj:set_selected_setting(option_obj:get_selected_setting() + step_size)
        elseif step == "left_button" then
            option_obj:set_selected_setting(option_obj:get_selected_setting() - step_size)
        end
    end) if not ok then mct:error(err) end
    end,
    true
)

return type
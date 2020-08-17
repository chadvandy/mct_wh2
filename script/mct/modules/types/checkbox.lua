local mct = mct

local template_type = mct._MCT_TYPES.template

local lua_type = type

local type = mct:create_class(template_type)

function type:__index(attempt)
    mct:log("start")
    mct:log("calling: "..attempt)
    --mct:log("key: "..self:get_key())
    --mct:log("calling "..attempt.." on mct option "..self:get_key())
    local field = rawget(getmetatable(self), attempt)
    local retval = nil

    if lua_type(field) == "nil" then
        mct:log("not found, checking template_type")
        local wrapped = rawget(getmetatable(self), "template_type")

        field = wrapped and wrapped[attempt]

        if lua_type(field) == "nil" then
            mct:log("not found, check mct_option")
            -- not found in mct_option, check template_type!
            local wrapped_boi = rawget(self, "option")

            field = wrapped_boi and wrapped_boi[attempt]

            if lua_type(field) == "function" then
                retval = function(obj, ...)
                    return field(wrapped_boi, ...)
                end
            else
                retval = field
            end
        else
            -- found in mct_option, woop
            if lua_type(field) == "function" then
                mct:log("func found")
                retval = function(obj, ...)
                    return field(wrapped, ...)
                end
            else
                mct:log("non-func found")
                retval = field
            end
        end
    else
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
    if not is_boolean(value) then
        return false
    end

    return true
end

function type:set_default()
    local option = self:get_option()

    -- if there's no default, set it to false.
    option._default_setting = false
end

function type:ui_select_value(val)

    local option_uic = self:get_uics()[1]
    -- grab the checkbox UI

    local state = "selected"

    if val == false then
        state = "active"
    end

    mct.ui:uic_SetState(option_uic, state)
end

function type:ui_change_state(val)
    local option = self:get_option()

    local option_uic = option:get_uics()[1]
    local text_uic = option:get_uic_with_key("text")

    local locked = option:get_uic_locked()
    local lock_reason = option:get_lock_reason()
    
    local value = option:get_selected_setting()

    local state = "active"
    local tt = option:get_tooltip_text()

    if locked then
        -- disable the checkbox, set it as checked if the finalized setting is true
        if value == true then
            state = "selected_inactive"
        else
            state = "inactive"
        end
        tt = lock_reason .. "\n" .. tt
    else
        if value == true then
            state = "selected"
        else
            state = "active"
        end
    end

    mct.ui:uic_SetState(option_uic, state)
    mct.ui:uic_SetTooltipText(text_uic, tt, true)
end

function type:ui_create_option(dummy_parent)
    local option = self:get_option()
    local template = option:get_uic_template()

    local new_uic = core:get_or_create_component("mct_checkbox_toggle", template, dummy_parent)
    new_uic:SetVisible(true)

    option:set_uics(new_uic)

    return new_uic
end

--------- UNIQUE SECTION -----------
-- These functions are unique for this type only. Be careful calling these!



--------- List'n'rs ----------
-- Unique listeners for just this type.
core:add_listener(
    "mct_checkbox_toggle_option_selected",
    "ComponentLClickUp",
    function(context)
        return context.string == "mct_checkbox_toggle"
    end,
    function(context)
        local uic = UIComponent(context.component)

        -- will tell us the name of the option
        local parent_id = UIComponent(uic:Parent()):Id()
        --mct:log("Checkbox Pressed - parent id ["..parent_id.."]")
        local mod_obj = mct:get_selected_mod()
        local option_obj = mod_obj:get_option_by_key(parent_id)

        if not mct:is_mct_option(option_obj) then
            mct:error("mct_checkbox_toggle_option_selected listener trigger, but the checkbox pressed ["..parent_id.."] doesn't have a valid mct_option attached. Returning false.")
            return false
        end

        option_obj:set_selected_setting(not option_obj:get_selected_setting())
    end,
    true
)

return type
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
        local wrapped = rawget(self, "template_type")

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

-- TODO this
function type:check_validity(value)
    if not is_string(value) then
        return false
    end


    return true
end

function type:set_default()
    local option = self:get_option()

    -- TODO do this better mebs?
    option._default_setting = ""
end

function type:ui_select_value(val)
    local option = self:get_option()

    local option_uic = option:get_uics()[1]

    -- auto-type the text
    mct.ui:uic_SetStateText(option_uic, val)
end

function type:ui_change_state()
    local option = self:get_option()

    local option_uic = option:get_uics()[1]
    local text_uic = option:get_uic_with_key("text")

    local locked = option:get_uic_locked()
    local lock_reason = option:get_lock_reason()

    local tt = option:get_tooltip_text()

    if locked then
        tt = lock_reason .. "\n" .. tt
    end

    option_uic:SetInteractive(not locked)
    mct.ui:uic_SetTooltipText(text_uic, tt, true)
end

function type:ui_create_option(dummy_parent)
    local option = self:get_option()

    local text_input_template = "ui/common ui/text_box"

    local new_uic = core:get_or_create_component("mct_text_input", text_input_template, dummy_parent)
    new_uic:SetVisible(true)
    new_uic:SetCanResizeWidth(true) new_uic:SetCanResizeHeight(true)
    new_uic:Resize(dummy_parent:Width() * 0.4, dummy_parent:Height() * 0.95)

    new_uic:SetInteractive(true)

    option:set_uics(new_uic)
    
    return new_uic
    --return self:override_error("ui_create_option")
end

--------- UNIQUE SECTION -----------
-- These functions are unique for this type only. Be careful calling these!


---------- List'n'rs -------------
--

core:add_listener(
    "mct_text_input",
    "ComponentLClickUp",
    function(context)
        return context.string == "mct_text_input"
    end,
    function(context)
        core:remove_listener("mct_text_input_unselected")

        local uic = UIComponent(context.component)

        -- will tell us the name of the option
        local parent_id = UIComponent(uic:Parent()):Id()

        local mod_obj = mct:get_selected_mod()
        local option_obj = mod_obj:get_option_by_key(parent_id)

        if not mct:is_mct_option(option_obj) then
            mct:error("mct_text_input listener trigger, but the text-input pressed ["..parent_id.."] doesn't have a valid mct_option attached. Returning false.")
            return false
        end

        core:add_listener(
            "mct_text_input_unselected",
            "ComponentLClickUp",
            function(context)
                return context.string ~= "mct_text_input"
            end,
            function(context)
                if not is_uicomponent(uic) then
                    return false
                end

                local test_string = uic:GetStateText()

                -- TODO do a test to see if this is a valid string
                -- Call a callback set by the modder to check it?
                -- Do nothing?

                option_obj:set_selected_setting(test_string)
            end,
            false
        )
    end,
    true
)

return type
local mct = mct

local template_type = mct._MCT_TYPES.template

local wrapped_type = {}

function wrapped_type:new(option_obj)
    local self = {}

    --[[for k,v in pairs(getmetatable(tt)) do
        mct:log("assigning ["..k.."] to checkbox_type from template_type.")
        self[k] = v
    end
]]
    setmetatable(self, wrapped_type)

    --[[for k,v in pairs(type) do
        mct:log("assigning ["..k.."] to checkbox_type from self!")
        self[k] = v
    end]]

    self.option = option_obj

    local tt = template_type:new(option_obj)

    self.template_type = tt

    return self
end

function wrapped_type:__index(attempt)
    --mct:log("start check in type:__index")
    --mct:log("calling: "..attempt)
    --mct:log("key: "..self:get_key())
    --mct:log("calling "..attempt.." on mct option "..self:get_key())
    local field = rawget(getmetatable(self), attempt)
    local retval = nil

    if type(field) == "nil" then
        --mct:log("not found, check mct_option")
        -- not found in mct_option, check template_type!
        local wrapped_boi = rawget(self, "option")

        field = wrapped_boi and wrapped_boi[attempt]

        if type(field) == "nil" then
            --mct:log("not found in wrapped_type or mct_option, check in template_type!")
            -- not found in mct_option or wrapped_type, check in template_type
            local wrapped_boi_boi = rawget(self, "template_type")
            
            field = wrapped_boi_boi and wrapped_boi_boi[attempt]
            if type(field) == "function" then
                retval = function(obj, ...)
                    return field(wrapped_boi_boi, ...)
                end
            else
                retval = field
            end
        else
            if type(field) == "function" then
                retval = function(obj, ...)
                    return field(wrapped_boi, ...)
                end
            else
                retval = field
            end
        end
    else
        --mct:log("found in wrapped_type")
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


--------- OVERRIDEN SECTION -------------
-- These functions exist for every type, and have to be overriden from the version defined in template_types.

function wrapped_type:check_validity(value)
    if not is_boolean(value) then
        return false
    end

    return true
end

function wrapped_type:set_default()

    -- if there's no default, set it to false.
    self:set_default_value(false)
end

function wrapped_type:ui_select_value(val)

    local option_uic = self:get_uic_with_key("option")
    if not is_uicomponent(option_uic) then
        mct:error("ui_select_value() triggered for mct_option with key ["..self:get_key().."], but no option_uic was found internally. Aborting!")
        return false
    end

    -- grab the checkbox UI

    local state = "selected"

    if val == false then
        state = "active"
    end

    mct.ui:SetState(option_uic, state)
end

function wrapped_type:ui_change_state(val)
    local option_uic = self:get_uic_with_key("option")
    local text_uic = self:get_uic_with_key("text")

    local locked = self:get_uic_locked()
    local lock_reason = self:get_lock_reason()
    
    local value = self:get_selected_setting()

    local state = "active"
    local tt = self:get_tooltip_text()

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

    mct.ui:SetState(option_uic, state)
    mct.ui:SetTooltipText(text_uic, tt, true)
end

function wrapped_type:ui_create_option(dummy_parent)
    local template = self:get_uic_template()

    local new_uic = core:get_or_create_component("mct_checkbox_toggle", template, dummy_parent)
    new_uic:SetVisible(true)

    self:set_uic_with_key("option", new_uic, true)

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

return wrapped_type
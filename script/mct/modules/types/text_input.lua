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

-- TODO this
function type:check_validity(value)
    if not is_string(value) then
        return false
    end


    return true
end

function type:set_default()

    -- TODO do this better mebs?
    self:set_default_value("")
    --self._default_setting = ""
end

function type:ui_select_value(val)
    local option_uic = self:get_uics()[1]
    if not is_uicomponent(option_uic) then
        mct:error("ui_select_value() triggered for mct_option with key ["..self:get_key().."], but no option_uic was found internally. Aborting!")
        return false
    end
    
    -- auto-type the text
    mct.ui:uic_SetStateText(option_uic, val)
end

function type:ui_change_state()
    local option_uic = self:get_uics()[1]
    local text_uic = self:get_uic_with_key("text")

    local locked = self:get_uic_locked()
    local lock_reason = self:get_lock_reason()

    local tt = self:get_tooltip_text()

    if locked then
        tt = lock_reason .. "\n" .. tt
    end

    option_uic:SetInteractive(not locked)
    mct.ui:uic_SetTooltipText(text_uic, tt, true)
end

function type:ui_create_option(dummy_parent)
    local text_input_template = "ui/common ui/text_box"

    local new_uic = core:get_or_create_component("mct_text_input", text_input_template, dummy_parent)
    new_uic:SetVisible(true)
    new_uic:SetCanResizeWidth(true) new_uic:SetCanResizeHeight(true)
    new_uic:Resize(dummy_parent:Width() * 0.4, new_uic:Height())

    new_uic:SetInteractive(true)

    self:set_uics(new_uic)
    
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
        mct:log("mct_text_input_clickeded")
        core:remove_listener("mct_text_input_unselected")

        local uic = UIComponent(context.component)

        -- will tell us the name of the option
        local parent_id = UIComponent(uic:Parent()):Id()

        mct:log("Parent id: "..parent_id)

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
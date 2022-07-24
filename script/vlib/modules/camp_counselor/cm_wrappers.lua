---- This contains "wrappers" to the campaign manager, to prevent any crashing from calling "episodic_scripting" functions with the wrong arguments.

local function err(function_name, text, ...)
    text = string.format(text, ...)

    text = string.format("ERROR: %s() called but %s", function_name, text)

    script_error(text)

    return false
end

function campaign_manager:treasury_mod(faction_key, amount)
    if not is_string(faction_key) then
        script_error("ERROR: treasury_mod() called but the faction_key provided is not a string!")
        return false
    end
    if not is_number(amount) then
        script_error("ERROR: treasury_mod() called but the amount provided is not a number!")
        return false
    end
    self.game_interface:treasury_mod(faction_key, amount)
end

-- first arg is a "FAMILY_MEMBER_SCRIPT_INTERFACE", not a char obj
--[[function campaign_manager:add_agent_experience_through_family_member(char_obj, experience)
    if not is_character(char_obj) then
        -- errmsg
        return false 
    end
    if not is_number(experience) then
        -- errmsg
        return false
    end
    self.game_interface:add_agent_experience_through_family_member(char_obj, experience)
end]]

function campaign_manager:faction_add_pooled_resource(faction_key, resource_key, factor_key, value)
    if not is_string(faction_key) then
        return err("faction_add_pooled_resource", "the supplied faction key %q is not a valid string!", tostring(faction_key))
    end

    if not is_string(resource_key) then
        return err("faction_add_pooled_resource", "the supplied pooled resource key %q is not a valid string!", tostring(resource_key))
    end

    if not is_string(factor_key) then
        return err("faction_add_pooled_resource", "the supplied pooled resource factor key %q is not a valid string!", tostring(factor_key))
    end

    if not is_number(value) then
        return err("faction_add_pooled_resource", "the supplied value %q is not a valid number!", tostring(factor_key))
    end

    self.game_interface:faction_add_pooled_resource(faction_key, resource_key, factor_key, value)
end

function campaign_manager:force_confederation(confederation_key, faction_key)
    if not is_string(confederation_key) then
        return err("force_confederation", "the supplied confederation key %q is not a valid string!", tostring(confederation_key))
    end

    if not is_string(faction_key) then
        return err("force_confederation", "the supplied faction key %q is not a valid string!", tostring(faction_key))
    end

    self.game_interface:force_confederation(confederation_key, faction_key)
end
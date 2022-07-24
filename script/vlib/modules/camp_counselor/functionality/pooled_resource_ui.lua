--- TODO make adding new PR's work post-first-tick
--- TODO add functionality for setting visible/invisible
--- TODO create a bar UIC!
--- TODO make work before first tick

local vlib = get_vandy_lib()
local log,logf,errlog,errlogf = vlib:get_log_functions("[pr_ui]")

---@class vlib_pr_manager
local PR_Manager = {
    pr_path = "ui/vandy_lib/pooled_resources/dy_canopic_jars",
    negative_list_entry = "ui/vandy_lib/pooled_resources/negative_list_entry",
    positive_list_entry = "ui/vandy_lib/pooled_resources/positive_list_entry",

    tt_path = "{{tt:ui/campaign ui/tooltip_pooled_resource_breakdown}}",
    tt_key = "tooltip_pooled_resource_breakdown",
    
    resources = {},
}

---@class vlib_pr_obj
local PR_Obj = {
    _pr_key = "",
    _icon_path = "",
    _factions = {},
}

function PR_Obj:new(pr_key, icon_path, faction_table)
    ---@type vlib_pr_obj
    local o = table.deepcopy(PR_Obj)
    setmetatable(o, {__index = PR_Obj})

    o._pr_key = pr_key
    o._icon_path = icon_path

    o:set_factions(faction_table)

    return o
end

function PR_Obj:get_key()
    return self._pr_key
end

function PR_Obj:add_faction(faction_key)
    self._factions[faction_key] = true
end

function PR_Obj:set_factions(faction_table)
    self._factions = {}
    for i = 1, #faction_table do
        local faction_key = faction_table[i]
        self._factions[faction_key] = true
    end
end

function PR_Obj:is_faction_valid(faction_key)
    return self._factions[faction_key]
end

function PR_Obj:get_icon_path()
    return self._icon_path
end

function PR_Manager:create_new_pr(pooled_resource_key, pr_icon_path, filters)
    local o = PR_Obj:new(pooled_resource_key, pr_icon_path, filters)

    self.resources[#self.resources+1] = o

    return o
end

function PR_Manager:get_pr_with_key(key)
    if not is_string(key) then return false end
    for i = 1, #self.resources do
        local o = self.resources[i]
        if o:get_key() == key then
            return o
        end
    end

    return false
end

---Get the UIC for a PR, if any are on screen. Returns false if none are found!
---@param pr_key string
---@return UIComponent|boolean
function PR_Manager:get_uic(pr_key)
    local parent = find_uicomponent(core:get_ui_root(), "layout", "resources_bar", "topbar_list_parent")

    return find_uicomponent(parent, pr_key, "dy_canopic_jars")
end

--- Create the UIC on the top bar!
---@param pr_obj vlib_pr_obj
---@param faction_key string
function PR_Manager:create_uic(pr_obj, faction_key)
    local pr_key = pr_obj:get_key()
    log("Adding ["..pr_key.."] UI to faction ["..faction_key.."].")
    local parent = find_uicomponent(core:get_ui_root(), "layout", "resources_bar", "topbar_list_parent")

    if not parent then return errlogf("Parent not found!!!!") end

    local test = self:get_uic(pr_key)
    if test then
        return
    end
        
    local canopic = find_uicomponent(parent, "canopic_jars_holder")
    local uic = UIComponent(canopic:CopyComponent(pr_key))

    if not uic then return errlogf("Failed to create component") end
    local pos = 1

    -- remove all other children of the parent bar, except for the treasury, so the new PR will be to the right of the treasury holder
    for i = 0, parent:ChildCount() - 1 do
        local child = UIComponent(parent:Find(i))
        if child:Id() == "treasury_holder" then
            -- dummy:Adopt(child:Address())
            pos = i
            break
        end
    end

    -- add the PR component!
    parent:Adopt(uic:Address(), pos+1)

    uic:SetInteractive(true)
    uic:SetVisible(true)
    
    local uic_icon = find_uicomponent(uic, "icon")
    uic_icon:SetImagePath(pr_obj:get_icon_path(), 0)
    
    uic:SetTooltipText(self.tt_path, true)
    
    self:check_value(pr_key, faction_key)
end

function PR_Manager:check_value(pooled_resource_key, faction_key)
    local uic = self:get_uic(pooled_resource_key)
    if uic then
        local pr_interface = cm:get_faction(faction_key):pooled_resource(pooled_resource_key)
        local val = pr_interface:value()
        uic:SetStateText(tostring(val))
    else
        -- TODO, err? create uic?
    end
end

function PR_Manager:adjust_tooltip(pooled_resource_key, faction_key)
    local ok, err = pcall(function()
    local tooltip = find_uicomponent(core:get_ui_root(), "tooltip_pooled_resource_breakdown")
    tooltip:SetVisible(true)

    local list_parent = find_uicomponent(tooltip, "list_parent")

    local title_uic = find_uicomponent(list_parent, "dy_heading_textbox")
    local desc_uic = find_uicomponent(list_parent, "instructions")

    local loc_header = "pooled_resources"
    title_uic:SetStateText(effect.get_localised_string(loc_header.."_display_name_"..pooled_resource_key))
    desc_uic:SetStateText(effect.get_localised_string(loc_header.."_description_"..pooled_resource_key))

    local positive_list = find_uicomponent(list_parent, "positive_list")
    positive_list:SetVisible(true)
    local positive_list_header = find_uicomponent(positive_list, "list_header")
    positive_list_header:SetVisible(true)
    positive_list_header:SetStateText(effect.get_localised_string(loc_header.."_positive_factors_display_name_"..pooled_resource_key))

    local negative_list = find_uicomponent(list_parent, "negative_list")
    negative_list:SetVisible(true)
    local negative_list_header = find_uicomponent(negative_list, "list_header")
    negative_list_header:SetVisible(true)
    negative_list_header:SetStateText(effect.get_localised_string(loc_header.."_negative_factors_display_name_"..pooled_resource_key))

    local faction_obj = cm:get_faction(faction_key)
    local pr_interface = faction_obj:pooled_resource(pooled_resource_key)

    if pr_interface:is_null_interface() then
        return errlogf("Trying to create Pooled Resource %q for %q, but the faction doesn't have access to this PR!", pooled_resource_key, faction_key)
    end

    logf("Moving through pr %q, building tooltips.", pooled_resource_key)

    local factors_list_obj = pr_interface:factors()

    local diff = 0

    -- clear out all existing stuff on each factor list (if there's any) ((sorry kids!))
    logf("before destroy")
    find_uicomponent(positive_list, "factor_list"):DestroyChildren()
    find_uicomponent(negative_list, "factor_list"):DestroyChildren()
    logf("post destroy")
    
    local function new_factor(key, value, state)
        local uic_path
        local parent

        logf("building new factor with key %s and state %s", key, state)

        if state == "positive" then
            parent = positive_list
            uic_path = self.positive_list_entry
        else
            parent = negative_list
            uic_path = self.negative_list_entry
        end

        local factor_list = find_uicomponent(parent, "factor_list")

        local factor_entry = core:get_or_create_component(pooled_resource_key..key, uic_path, factor_list)
        factor_list:Adopt(factor_entry:Address())

        -- factor_entry = title text
        factor_entry:SetStateText(effect.get_localised_string("pooled_resource_factors_display_name_"..state.."_"..key))

        local value_uic = find_uicomponent(factor_entry, "dy_value")

        if state == "positive" then
            -- defaults to grey
            value_uic:SetState('0')
            if value > 0 then
                value_uic:SetState('1') -- make green
            elseif value < 0 then
                value_uic:SetState('2') -- make red
            end
        elseif state == "negative" then
            value_uic:SetState('0')
        end

        value_uic:SetStateText(tostring(value))
    end

    logf("Looping in factors")
    for i = 0, factors_list_obj:num_items() - 1 do
        logf("Looping in factors, pos %d", i)
        local factor = factors_list_obj:item_at(i)
        
        local key = factor:key()
        local val = factor:value()

        logf("Factor [%s] has val %d", key, val)

        diff = diff + val -- adds/subtracts to set the "Change This turn" number

        local max = factor:maximum_value()
        local min = factor:minimum_value()

        -- check to see if the factor's maximum value is higher than the factor's minimum value - if it is, it's positive
        -- ie., min value of -10 and max of +100 is positive, min value of -21400000 is negative
        local positive = math.abs(max) > math.abs(min)

        if val == 0 then
            if positive then
                new_factor(key, val, "positive")
            else
                new_factor(key, val, "negative")
            end
        elseif val > 0 then
            new_factor(key, val, "positive")
        else
            new_factor(key, val, "negative")
        end
    end

    local total = find_child_uicomponent(list_parent, "total")
    local total_val = find_child_uicomponent(total, "dy_value")
    if diff < 0 then
        total_val:SetState('0')
    elseif diff == 0 then
        total_val:SetState('1')
    elseif diff > 0 then
        total_val:SetState('2')
    end

    total_val:SetStateText(tostring(diff)) end) if not ok then errlogf(err) end
end

function PR_Manager:get_resource_keys_for_faction(faction_obj)
    local faction_key = faction_obj:name()

    local ret = {}

    local resources = self.resources
    for i = 1, #resources do
        local pr = resources[i]
        if pr:is_faction_valid(faction_key) then
            ret[#ret+1] = pr:get_key()
        end
    end

    return ret
end

function PR_Manager:faction_has_resources(faction_obj)
    local res = self:get_resource_keys_for_faction(faction_obj)
    return #res >= 1
end

function PR_Manager:add_pr_uics_for_local_faction()
    local faction = cm:get_local_faction(true)
    local faction_key = faction:name()
    if self:faction_has_resources(faction) then
        local resource_keys = self:get_resource_keys_for_faction(faction)
        
        for i = 1, #resource_keys do
            local resource_key = resource_keys[i]
            local pr_obj = self:get_pr_with_key(resource_key)

            self:create_uic(pr_obj, faction_key)
        end
    end
end

function PR_Manager:init()
    log("init")
    self._initialized = true

    self:add_pr_uics_for_local_faction()
end

return PR_Manager
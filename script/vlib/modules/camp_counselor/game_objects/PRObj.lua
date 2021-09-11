--- TODO make adding new PR's work post-first-tick
--- TODO add functionality for setting visible/invisible
--- TODO create a bar UIC!

local vlib = get_vandy_lib()
local log,logf,errlog,errlogf = vlib:get_log_functions("[pr_ui]")

---@class vlib_pr_obj
local PRObj = {
    _uics = {
        pr = "ui/vandy_lib/pooled_resources/dy_canopic_jars",
        negative_list_entry = "ui/vandy_lib/pooled_resources/negative_list_entry",
        positive_list_entry = "ui/vandy_lib/pooled_resources/positive_list_entry",
    },

    _tt_path = "{{tt:ui/campaign ui/tooltip_pooled_resource_breakdown}}",
    _tt_key = "tooltip_pooled_resource_breakdown",

    _initialized = false,
    _pr_key = "",
    _icon_path = "",
    _factions = {},
}

local resources = {}

function PRObj.new(pr_key, icon_path, faction_table)
    ---@type vlib_pr_obj
    local o = table.deepcopy(PRObj)
    setmetatable(o, {__index = PRObj})

    o._pr_key = pr_key
    o._icon_path = icon_path

    o:set_factions(faction_table)

    return o
end

function PRObj:get_key()
    return self._pr_key
end

function PRObj:add_faction(faction_key)
    self._factions[faction_key] = true
end

function PRObj:set_factions(faction_table)
    self._factions = {}
    for _,faction_key in ipairs(faction_table) do
        self._factions[faction_key] = true
    end
end

function PRObj:is_faction_valid(faction_key)
    return self._factions[faction_key]
end

function PRObj:get_icon_path()
    return self._icon_path
end

function PRObj.create_new_pr(pooled_resource_key, pr_icon_path, filters)
    local o = PRObj.new(pooled_resource_key, pr_icon_path, filters)

    resources[#resources+1] = o

    return o
end

function PRObj.get_pr_with_key(key)
    if not is_string(key) then return false end
    for i = 1, #resources do
        local o = resources[i]
        if o:get_key() == key then
            return o
        end
    end

    return false
end

---Get the UIC for a PR, if any are on screen. Returns false if none are found!
---@param pr_key string
---@return UIComponent|boolean
function PRObj.get_uic(pr_key)
    local parent = find_uicomponent(core:get_ui_root(), "layout", "resources_bar", "topbar_list_parent")

    return find_uicomponent(parent, pr_key)
end

--- Create the UIC on the top bar!
---@param pr_obj vlib_pr_obj
---@param faction_key string
function PRObj.create_uic(pr_obj, faction_key)
    local pr_key = pr_obj:get_key()
    log("Adding ["..pr_key.."] UI to faction ["..faction_key.."].")
    local parent = find_uicomponent(core:get_ui_root(), "layout", "resources_bar", "topbar_list_parent")

    if not parent then return errlogf("Parent not found!!!!") end

    local test = PRObj.get_uic(pr_key)
    if test then
        return
    end
        
    local uic = UIComponent(core:get_ui_root():CreateComponent(pr_key, PRObj._uics.pr))

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
    uic_icon:SetImagePath(pr_obj:get_icon_path())
    
    uic:SetTooltipText(PRObj._tt_path, true)
    
    PRObj.check_value(pr_key, faction_key)
end

function PRObj.check_value(pooled_resource_key, faction_key)
    local uic = PRObj.get_uic(pooled_resource_key)
    if uic then
        local pr_interface = cm:get_faction(faction_key):pooled_resource(pooled_resource_key)
        local val = pr_interface:value()
        uic:SetStateText(tostring(val))
    else
        -- TODO, err? create uic?
    end
end

function PRObj.adjust_tooltip(pooled_resource_key, faction_key)
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
            uic_path = PRObj._uics.positive_list_entry
        else
            parent = negative_list
            uic_path = PRObj._uics.negative_list_entry
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

function PRObj.get_resource_keys_for_faction(faction_obj)
    local faction_key = faction_obj:name()

    local ret = {}

    for i = 1, #resources do
        local pr = resources[i]
        if pr:is_faction_valid(faction_key) then
            ret[#ret+1] = pr:get_key()
        end
    end

    return ret
end

function PRObj.faction_has_resources(faction_obj)
    local res = PRObj.get_resource_keys_for_faction(faction_obj)
    return #res >= 1
end

function PRObj.add_pr_uics_for_local_faction()
    local faction = cm:get_local_faction(true)
    local faction_key = faction:name()
    if PRObj.faction_has_resources(faction) then
        local resource_keys = PRObj.get_resource_keys_for_faction(faction)
        
        for i = 1, #resource_keys do
            local resource_key = resource_keys[i]
            local pr_obj = PRObj.get_pr_with_key(resource_key)

            PRObj.create_uic(pr_obj, faction_key)
        end
    end
end

function PRObj.init()
    PRObj._initialized = true
    PRObj.add_pr_uics_for_local_faction()

    -- initialize the listeners!
    core:add_listener(
        "PR_HoveredOn",
        "ComponentMouseOn",
        function(context)
            return PRObj.get_pr_with_key(context.string)
        end,
        function(context)
            local str = context.string
            vlib:callback(function()
                -- logf("Checking tooltip for PR %q", str)
                local ok, msg = pcall(function()
                    PRObj.adjust_tooltip(str, cm:get_local_faction_name(true))
                end) if not ok then errlog(msg) end
            end, 5, "pr_hovered")
        end,
        true
    )

    core:add_listener(
        "PR_ValueChanged",
        "PooledResourceEffectChangedEvent",
        function(context)
            return context:faction():name() == cm:get_local_faction_name(true) and PRObj.get_pr_with_key(context:resource():key())
        end,
        function(context)
            PRObj.check_value(context:resource():key(), cm:get_local_faction_name(true))
        end,
        true
    )

    core:add_lookup_listener_callback(
        "faction_turn_start_listeners_by_name", "PR_TurnStart", cm:get_local_faction_name(true),
        function(context)
            local faction = context:faction()
            local faction_key = faction:name()
            if PRObj.faction_has_resources(faction) then
                local resource_keys = PRObj.get_resource_keys_for_faction(faction)
                for i = 1, #resource_keys do
                    local resource_key = resource_keys[i]

                    if not PRObj.get_uic(resource_key) then
                        -- create UIC, if it doesn't exist already
                        PRObj.create_uic(PRObj.get_pr_with_key(resource_key), faction_key)
                    else -- check value if it does
                        PRObj.check_value(resource_key, faction_key)
                    end
                end
            end
        end,
        true
    )
end

return PRObj
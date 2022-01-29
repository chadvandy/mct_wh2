--- TODO add
--- TODO clear up the States stuff, make it more usable.

local vlib = get_vandy_lib()

---@type vlib_camp_counselor
local cc = vlib:get_module("camp_counselor")
local log,logf,err,errf = vlib:get_log_functions("[unit]")

local function is_tech(obj)
    return tostring(obj):match("^TechObj")
end

---@param key string
---@return tech_class
local function get_tech(key)
    if not is_string(key) then return false end

    return cc:get_object("TechObj", key)
end

---@class tech_class : Class
local TechObj = vlib:new_class("TechObj")
TechObj.__index = TechObj

---@class tech_class_state
local TechObjState = {
    ---@type string The relevant faction key.
    _faction_key = "",

    ---@type lock_state
    _lock_state = 0,

    ---@type string Tooltip to display for why this unit is locked.
    _lock_reason = "",
    
    _exclusive_techs = {},
    
    --- TODO change to "_unlocks", hold ANY go reference?
    _units = {},
}

function TechObj:__tostring()
    return "TechObj ["..self.__name.."]"
end

function TechObj.instantiate(o)
    return setmetatable(o, TechObj)
end

function TechObj.new(key, filters)
    ---@type tech_class
    local o = {
        _key = key,

        ---@type table<string, tech_class_state>
        _states = {},

        ---@type table<number, string>
        _child_techs = {},
        
        _parent_key = nil,
    }
    o = TechObj.instantiate(o)

    o:new_states(filters)
    return o
end

function TechObj:new_states(filters)
    for i,faction_key in ipairs(filters) do
        local state = setmetatable(table.deepcopy(TechObjState), TechObjState)
        state._faction_key = faction_key

        self._states[faction_key] = state
    end
end

--- TODO hook up w/ unit objs!
---@param unit_table any
---@param is_unlock any
---@param faction_key any
function TechObj:set_unit_table(unit_table, is_unlock, faction_key)
    local state = self:get_state(faction_key, true)

    local key = is_unlock and "unlock" or "lock"
    state._units[key] = unit_table
end

function TechObj:get_unit_table(faction_key)
    local state = self:get_state(faction_key, true)

    return state and state._units or {}
end

function TechObj:has_units(faction_key)
    local state = self:get_state(faction_key)

    return state and is_table(state._units)
end

function TechObj:set_child_techs(children, filters)
    if not is_table(children) then
        return errf("Trying to set children for technology w/ key [%s] but the child_techs arg provided [%s] is not a table!", self:get_key(), tostring(children))
    end

    for i = 1, #children do
        local child_key = children[i]
        local tech = cc:new_object("TechObj", child_key, filters)

        self:add_child_tech(tech)
    end
end

---@param child_tech tech_class
---@return boolean
function TechObj:add_child_tech(child_tech)
    if not is_tech(child_tech) then
        return errf("Trying to add child tech to tech %q, but the child tech provided [%s] isn't a valid technology!", self:get_key(), tostring(child_tech))
    end

    logf("Adding tech %q as parent to %q", self:get_key(), child_tech:get_key())

    self._child_techs[#self._child_techs+1] = child_tech:get_key()
    child_tech:set_parent(self:get_key())
end

function TechObj:get_child_techs()
    local ret = {}
    local keys = self:get_child_tech_keys()

    for i = 1, #keys do
        local tech = get_tech(keys[i])
        ret[#ret+1] = tech
    end

    return ret
end

function TechObj:get_child_tech_keys()
    return self._child_techs
end

function TechObj:set_parent(tech_key)
    if not is_string(tech_key) then
        return false
    end

    self._parent_key = tech_key
end

function TechObj:set_exclusive_techs(tech_table, faction_key)
    local state = self:get_state(faction_key, true)

    local t = {}
    for i = 1, #tech_table do
        if tech_table[i] ~= self:get_key() then
            t[#t+1] = tech_table[i]
        end
    end

    state:set_exclusive_techs(t)
end

function TechObj:get_exclusive_techs(faction_key)
    local state = self:get_state(faction_key)

    return state and state:get_exclusive_techs()
end

function TechObj:add_exclusive_tech(tech_key, faction_key)
    local state = self:get_state(faction_key, true)

    return state and state:add_exclusive_tech(tech_key)
end

---@return tech_class_state
function TechObj:get_state(faction_key, is_set)
    local state = self._states[faction_key]
    -- if not state and is_set then
    --     state = self:new_state(faction_key)
    -- end

    return state
end

function TechObj:has_parent()
    return is_string(self._parent_key)
end

function TechObj:get_parent()
    return is_string(self._parent_key) and get_tech(self._parent_key)
end

function TechObj:has_children()
    return is_table(self._child_techs) and #self._child_techs >= 1
end

function TechObj:is_exclusive_with_tech(tech_key, faction_key)
    local state = self:get_state(faction_key)

    if not state then return false end

    local exclusives = state:get_exclusive_techs()
    for i = 1, #exclusives do
        if exclusives[i] == tech_key then
            return true
        end
    end

    return false
end

function TechObj:has_exclusive_techs(faction_key)
    local state = self:get_state(faction_key)
    return state and is_table(state._exclusive_techs) and #state._exclusive_techs >= 1
end

function TechObjState:set_exclusive_techs(tech_table)
    self._exclusive_techs = tech_table
end

function TechObjState:get_exclusive_techs()
    return self._exclusive_techs
end

function TechObjState:add_exclusive_tech(tech_key)
    self._exclusive_techs[#self._exclusive_techs+1] = tech_key
end

function TechObjState:set_lock_state(lock_state, lock_reason)
    -- TODO err check?

    self._lock_state = lock_state
    self._lock_reason = lock_reason
end

function TechObjState:get_lock_state()
    return self._lock_state
end

function TechObjState:get_lock_reason()
    return self._lock_reason
end

-- TODO have a version where this can handle a table of faction keys?
function TechObj:set_lock_state(lock_state, lock_reason, faction_key)
    local state = self:get_state(faction_key, true)
    state:set_lock_state(lock_state, lock_reason)
end

function TechObj:get_lock_state(faction_key)
    local state = self:get_state(faction_key)

    return state and state:get_lock_state() or 0
end

function TechObj:get_lock_reason(faction_key)
    local state = self:get_state(faction_key)

    return state and state:get_lock_reason() or ""
end

function TechObj:is_perma_locked(faction_key)
    local state = self:get_state(faction_key)

    return state and state:get_lock_state() == 3
end

function TechObj:is_disabled(faction_key)
    local state = self:get_state(faction_key)

    return state and state:get_lock_state() == 1
end

local _techs = {}
local _researched_or_researching = {}
local _currently_hovered = nil
local _slot_parent = nil

local _faction_key

---@param tech_obj tech_class
---@param is_lock boolean
---@param affect_children boolean
---@return boolean
function TechObj.set_tech_node_state(tech_obj, is_lock, affect_children)
    if not is_boolean(is_lock) then is_lock = true end
    if not is_boolean(affect_children) then affect_children = true end

    -- prevent unlocking any perma-locked!
    if tech_obj:is_perma_locked() then is_lock = true end
    
    local tech_key = tech_obj:get_key()

    logf("Setting %s for tech %q", tostring(is_lock and "locked" or "unlocked"), tech_key)

    local uic = TechObj.get_uic_with_key(tech_key)
    if not is_uicomponent(uic) then
        errf("Can't find a tech UIC w/ key %q", tech_key)
        return false
    end

    if uic:CurrentState() == "researching" then return logf("This tech is being researched, can't do stuff!") end
    if is_lock and uic:CurrentState() == "locked_rank" then return logf("This tech is already locked visually!") end

    local time = UIComponent(uic:Find("dy_time"))
    local icons = UIComponent(uic:Find("icon_list"))

    -- local id = uic:Id()
    if is_lock == true then
        _techs[tech_key] = {
            current_state = "locked_rank",
            previous_states = {uic:CurrentState(), time:Visible(), icons:Visible()},
            is_removed = nil,
        }

        uic:SetState("locked_rank")
        time:SetVisible(false)
        icons:SetVisible(false)
    else
        local previous_states = _techs[tech_key].previous_states
        _techs[tech_key] = nil

        if previous_states[1] then
            local state = previous_states[1]
            local t_visible = previous_states[2]
            local i_visible = previous_states[3]

            logf("Returning tech w/ key %q to state [%s]", tech_key, state)
    
            uic:SetState(state)
            time:SetVisible(t_visible)
            icons:SetVisible(i_visible)
        end
    end

    if affect_children then
        local children = tech_obj:get_child_techs()
        for i = 1, #children do
            logf("Setting child of %q with key %q as locked", tech_key, children[i]:get_key())
            TechObj.set_tech_node_state(children[i], is_lock, false)
        end
    end
end

function TechObj.get_uic_with_key(key)
    if not is_string(key) then return false end

    local slot = _slot_parent
    if slot then
        return UIComponent(slot:Find(key)) or false
    end
end

function TechObj.remove(tech_key)
    local uic = TechObj.get_uic_with_key(tech_key)

    if uic then
       uic:SetVisible(false)

       _techs[tech_key] = {is_removed = true}
    end
end

-- TODO if a tech is being researched, and then you click on another, both show as visually researching. Gotta fix!!!!!!!!!!!!!
-- TODO figure out how to refresh the techs after a tech node is pressed, so the locks and tooltips get re-applied
-- do the check on all exclusive techs and their states and shit
function TechObj.refresh()
    local faction_obj = cm:get_local_faction(true)

    local vlib = get_vlib()
    local cc = vlib:get_module("camp_counselor")

    -- first, check the panel for any nodes that SHOULD be locked on the screen :)

    local active_techs = cc:get_active_techs_for_faction(faction_obj)

    for i = 1, #active_techs do
        -- local active_tech_key = active_tech_keys[i]
        local active_tech = active_techs[i]
        local active_tech_key = active_tech:get_key()

        if not active_tech then
            logf("Can't find any tech with key %q", tostring(active_tech_key))
        else
            if active_tech:is_disabled(_faction_key) and not _techs[active_tech_key].is_removed then
                TechObj.remove(active_tech_key)
            end
    
            if faction_obj:has_technology(active_tech_key) then
                _researched_or_researching[active_tech_key] = active_tech
            end
        end
    end

    for tech_key, tech in pairs(_researched_or_researching) do
        local exclusives = tech:get_exclusive_techs()
        for j = 1, #exclusives do
            local exclusive_tech_key = exclusives[j]
            local exclusive_tech = cc:get_object("TechObj", exclusive_tech_key)

            if not exclusive_tech:is_perma_locked() then
                local str = effect.get_localised_string("vlib_technology_locked")
                str = str .. "\n - " .. effect.get_localised_string("technologies_onscreen_name_"..tech_key)
                str = str .. effect.get_localised_string("vlib_colour_end")

                -- TODO, the UI shouldn't change state, right?
                exclusive_tech:set_lock_state(3, str, _faction_key)
                -- exclusive_tech:set_perma_locked(true, str)
            end

            TechObj.set_tech_node_state(exclusive_tech, true, true)
        end
    end
end

function TechObj.open()
    local faction_key = cm:get_local_faction_name(true)

    _faction_key = faction_key

    _slot_parent = find_uicomponent("technology_panel", "listview", "list_clip", "list_box", "emp_civ_reworkd", "tree_parent", "slot_parent")

    vlib:repeat_callback(function() TechObj.refresh() end, 25, "vlib_tech_ui_refresh")

    -- second, do a listener for hovering over any tech nodes that are in the list of techs here, and then lock the exclusive tech stuffs

    -- TODO don't do the locks if the hovered tech is already researched!
    -- TODO don't do anything if the hovered tech is perma locked!

    core:remove_listener("VLIB_TechHovered")
    core:add_listener(
        "VLIB_TechHovered",
        "ComponentMouseOn",
        true,
        function(context)
            TechObj.set_tech_as_hovered(context.string)
        end,
        true
    )
end

function TechObj.close()
    core:remove_listener("VLIB_TechHovered")

    vlib:remove_callback("vlib_tech_ui_refresh")

    _faction_key = nil
    _researched_or_researching = {}
    _currently_hovered = nil
    _slot_parent = nil
    _techs = {}
end

---comment
---@param tech_key string
function TechObj.set_tech_as_hovered(tech_key)
    local ok, er = pcall(function()
    local faction_obj = cm:get_local_faction(true)

    local tech = cc:get_object("TechObj", tech_key)

    if _currently_hovered and _currently_hovered ~= tech_key or not _currently_hovered then
        local affected = _techs
        logf("Removing any currently-affected tech locks, visually.")

        for key, status in pairs(affected) do
            local affected_tech = cc:get_object("TechObj", key)
            logf("Removing tech lock for %q", key)
            TechObj.set_tech_node_state(affected_tech, false, false)
        end
    end
    
    if not tech then
        _currently_hovered = nil
        return
    end

    logf("Setting %q as hovered!", tech_key)
    _currently_hovered = tech_key

    -- currently hovered tech is locked somehow; set its tooltip but don't mess with any other techs.
    if tech:get_lock_state(_faction_key) >= 2 then
        vlib:callback(function()
            local tt = find_uicomponent("TechTooltipPopup")
            if tt then
                local list_parent = UIComponent(tt:Find("list_parent"))

                local add = UIComponent(list_parent:Find("additional_info"))
                add:SetVisible(true)

                local str = tech:get_lock_reason(_faction_key)

                add:SetStateText(str)
            end
        end, 5)

        return
    end

    local has_tech = faction_obj:has_technology(tech_key)

    -- TODO clean up the exclusives text!
    vlib:callback(function()
        local tt = find_uicomponent("TechTooltipPopup")
        if tt then
            local list_parent = UIComponent(tt:Find("list_parent"))

            local add = UIComponent(list_parent:Find("additional_info"))
            add:SetVisible(true)

            local str = ""

            local exclusives = tech:get_exclusive_techs(_faction_key)

            ---@param mah_str string
            ---@return string
            local function add_linebreak(mah_str)
                if mah_str == "" then return "\n" end
                if not mah_str:ends_with("\n\n") then
                    if mah_str:ends_with("\n") then
                        mah_str = mah_str .. "\n"
                    else
                        mah_str = mah_str .. "\n\n"
                    end
                end

                return mah_str
            end

            if #exclusives >= 1 then
                str = add_linebreak(str)
                if has_tech then
                    str = str .. effect.get_localised_string("vlib_technology_locking")
                else
                    str = str .. effect.get_localised_string("vlib_technology_will_lock")
                end

                if #exclusives > 1 then
                    str = string.format(str, effect.get_localised_string("vlib_lock"), effect.get_localised_string("vlib_technologies"))
                else 
                    str = string.format(str, effect.get_localised_string("vlib_lock"), effect.get_localised_string("vlib_technology"))
                end
    
                -- str = str .. effect.get_localised_string("vlib_colour_red")
                local colour = effect.get_localised_string("vlib_colour_red")
                local colour_end = effect.get_localised_string("vlib_colour_end")
    
                for i = 1, #exclusives do
                    local tech_text = effect.get_localised_string("technologies_onscreen_name_" .. exclusives[i])
                    if tech_text == "" then tech_text = "TECH TEXT FOR [".. exclusives[i] .."] NOT FOUND" end
                    str = str .. "\n    - " .. colour .. tech_text .. colour_end
                end

                -- str = str .. effect.get_localised_string("vlib_colour_end")
            end

            local unit_table = tech:get_unit_table(_faction_key)
            if unit_table.unlock then
                str = add_linebreak(str)

                if has_tech then
                    str = str .. effect.get_localised_string("vlib_technology_units_locking")
                else
                    str = str .. effect.get_localised_string("vlib_technology_units_will_lock")
                end

                local lock_str = effect.get_localised_string("vlib_unlock")

                local units = unit_table.unlock

                if #units > 1 then
                    str = string.format(str, lock_str, effect.get_localised_string("vlib_units"))
                else
                    str = string.format(str, lock_str, effect.get_localised_string("vlib_unit"))
                end

                local colour = effect.get_localised_string("vlib_colour_green")
                local colour_end = effect.get_localised_string("vlib_colour_end")

                for i = 1, #units do
                    local unit_text = effect.get_localised_string("land_units_onscreen_name_"..units[i])
                    if unit_text == "" then unit_text = "UNIT TEXT FOR ["..units[i].."] NOT FOUND!" end
                    str = str .. "\n\t  - " .. colour .. unit_text .. colour_end
                end
            end

            if unit_table.lock then
                str = add_linebreak(str)

                if has_tech then
                    str = str .. effect.get_localised_string("vlib_technology_units_locking")
                else
                    str = str .. effect.get_localised_string("vlib_technology_units_will_lock")
                end

                local lock_str =  effect.get_localised_string("vlib_lock")

                local units = unit_table.lock

                if #units > 1 then
                    str = string.format(str, lock_str, effect.get_localised_string("vlib_units"))
                else
                    str = string.format(str, lock_str, effect.get_localised_string("vlib_unit"))
                end

                local colour = effect.get_localised_string("vlib_colour_red")
                local colour_end = effect.get_localised_string("vlib_colour_end")

                for i = 1, #units do
                    local unit_text = effect.get_localised_string("land_units_onscreen_name_"..units[i])
                    if unit_text == "" then unit_text = "UNIT TEXT FOR ["..units[i].."] NOT FOUND!" end
                    str = str .. "\n\t  - " .. colour .. unit_text .. colour_end
                end
            end

            add:SetStateText(str)
        end
    end, 5)

    -- We don't need to do anything with the below because they're already locked :)
    -- if has_tech then return end
    -- if tech:get_uic():CurrentState() == "researching" then return end

    logf("Disabling techs visually that are excluded by %q", tech_key)

    local exclusive_techs = tech:get_exclusive_techs(_faction_key)
    for i = 1, #exclusive_techs do
        local exclusive_tech_key = exclusive_techs[i]
        logf("Hiding tech with key %q", exclusive_tech_key)

        local exclusive_tech = cc:get_object("TechObj", exclusive_tech_key)
        TechObj.set_tech_node_state(exclusive_tech, true, true)
    end end) if not ok then logf(er) end
end

function TechObj.init()
    -- delay these calls by 10ms so UI can catch up
    local function f(callback, key)
        vlib:callback(callback, 10, key)
    end

    --- Hookup all the necessary listeners to do shtuff
	core:add_lookup_listener_callback(
		"panel_opened", "TechObjPanelOpened", "technology_panel",
		function(context)
			f(TechObj.open, "TechObjPanelOpened")
		end,
		true
	)

	core:add_lookup_listener_callback(
		"panel_closed", "TechObjPanelClosed", "technology_panel",
		function(context)
			f(TechObj.close, "TechObjPanelClosed")
		end,
		true
	)
end

return TechObj
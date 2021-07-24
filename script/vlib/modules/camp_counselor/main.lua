--- TODO for now, this entire module is disabled.
-- do return end

--- Campaign Counselor (because CA already took the Campaign Manager).

--- TODO move Counselor into its own file, keep main.lua for purely init/listeners
--- TODO move each "object" into its own files - techproto and stuff.
--- TODO move "filters" into own file.
--- TODO Create "requirements"
--- TODO make it easy to use all of this shit (:

--- This manager handles a lot of the fun stuff that can happen within a campaign - unit disabling, mutually exclusive techs, scripted building and agent stuff.
-- This will specifically handle stuff that can happen at any point in the campaign; first-turn exclusive things like changing starting units belong elsewhere.
---@module CampCounselor
---@see vlib_camp_counselor

if __game_mode ~= __lib_type_campaign then return end

local vlib = get_vandy_lib()
local log,logf,errlog,errlogf = vlib:get_log_functions("[camp]")

log("HELLO")

--- load in wrappers and stuff
vlib:load_module("cm_additions", "script/vlib/modules/camp_counselor/")
log("HELLO")
vlib:load_module("cm_wrappers", "script/vlib/modules/camp_counselor/")
log("HELLO")

--- TODO fix this error by moving the new_manager() function into vlib_init. Also fuck you sumneko
---@class vlib_camp_counselor : manager_prototype
local Counselor = vlib:new_manager("camp_counselor")

local functionality_path = "script/vlib/modules/camp_counselor/functionality/"

---@type vlib_pr_manager
local pr_ui = vlib:load_module("pooled_resource_ui", functionality_path)

Counselor._filters = {}

local function is_tech(obj)
    return string.sub(tostring(obj), 1, 7) == "TechObj"
end

local function is_unit(obj)
    return string.sub(tostring(obj), 1, 7) == "UnitObj"
end

---@return vlib_TechObj
local function get_tech(key)
    if not is_string(key) then return false end

    return Counselor:get_obj(key, "TechObj")
end

---@return vlib_UnitObj
local function get_unit(key)
    if not is_string(key) then return false end

    return Counselor:get_obj(key, "UnitObj")
end

local function get_all(class_key)
    if not is_string(class_key) then return false end
    if not Counselor:get_class(class_key) then return false end

    return Counselor._objects[class_key]
end

---@return table<string, vlib_TechObj>
local function get_all_techs()
    return get_all("TechObj")
end

---@return table<number, vlib_TechObj>
local function get_techs_for_faction(faction_key)
    local all = get_all_techs()
    local ret = {}

    for tech_key, tech_obj in pairs(all) do
        if tech_obj:get_state(faction_key) then
            ret[#ret+1] = tech_obj
        end
    end

    return ret
end

---@return table<string, vlib_UnitObj>
local function get_all_units()
    return get_all("UnitObj")
end

---@return table<number, vlib_UnitObj>
local function get_units_for_faction(faction_key)
    local all = get_all_units()
    local ret = {}

    for _, unit_obj in pairs(all) do
        if unit_obj:get_state(faction_key) then
            ret[#ret+1] = unit_obj
        end
    end

    return ret
end

local function get_units_for_building(building_key, faction_key)
    local all
    local ret = {}
    if faction_key then
        all = get_units_for_faction(faction_key)

        for i = 1, #all do
            local unit_obj = all[i]
            if unit_obj:get_building_key() == building_key then
                ret[#ret+1] = unit_obj
            end
        end
    else
        all = get_all_units()

        for _, unit_obj in pairs(all) do
            if unit_obj:get_building_key() == building_key then
                ret[#ret+1] = unit_obj
            end
        end
    end

    return ret
end

-- TODO handle filters! If it's a subculture, make a single obj instance for every faction in that boi.

local function new_tech(key, filters)
    if not is_string(key) then return false end

    ---@type vlib_TechObj
    local obj = Counselor:new_object(key, "TechObj")

    for i = 1, #filters do
        local faction_key = filters[i]
        obj:new_state(faction_key)
    end

    return obj
end

local function new_unit(key, filters)
    if not is_string(key) then return false end

    ---@type vlib_UnitObj
    local obj = Counselor:new_object(key, "UnitObj")

    for i = 1, #filters do
        local faction_key = filters[i]
        obj:new_state(faction_key)
    end

    return obj
end

---@class vlib_TechState : object_prototype
local TechStateProto = {
    _faction_key = "",

    -- 0 is unlocked; 1 is invisible; 2 is locked w/ reason; 3 is permalocked w/ reason
    _lock_state = 0,
    _lock_reason = "",
    
    _exclusive_techs = {},
    _units = {},
}

---@class vlib_UnitState : object_prototype
local UnitStateProto = {
    _faction_key = "",

    -- 0 is unlocked; 1 is locked w/ reason; 2 is invisible.
    _lock_state = 0,
    _lock_reason = "",
}

---@class vlib_TechObj : object_prototype
local TechProto = {
    ---@type table<string, vlib_TechState>
    _states = {},

    ---@type table<number, string>
    _child_techs = {},
    
    _parent_key = nil,
}

---@class vlib_UnitObj : object_prototype
local UnitProto = {
    ---@type table<string, vlib_UnitState>
    _states = {},

    --- TODO decide if this needs to be a table?
    ---@type string Building that this unit can be found within.
    _building_key = "",

    ---@type string The localised name of this unit, for the currently played language.
    _localised_name = "",
}

--[[
    ====== Technology Objects ======
    
    This section contains all of the methods and stuff for the technology objects within the VLib.

    "TechObj" is the main object for a technology. It internally tracks global things, like children of this technology, any localised text for this technology - but, mostly, it holds information about the various states of this technology.

    "TechState"s are individual states of a technology, for different factions. This enables features, so faction A might have tech1 unlocked, but faction B would have tech1 locked with the reason "You have to be faction A to use this technology!" States drive the majority of this system.

    There should be no reason for outside moddeurs to handle tech objects or states directly, and can make all their necessary edits from within the camp counselor, but you can use these for querying states - seeing if tech_a is locked for faction_a, for instance.

    ======
--]]

--- TODO hook up w/ unit objs!
---@param unit_table any
---@param is_unlock any
---@param faction_key any
function TechProto:set_unit_table(unit_table, is_unlock, faction_key)
    local state = self:get_state(faction_key, true)

    local key = is_unlock and "unlock" or "lock"
    state._units[key] = unit_table
end

function TechProto:get_unit_table(faction_key)
    local state = self:get_state(faction_key, true)

    return state and state._units or {}
end

function TechProto:has_units(faction_key)
    local state = self:get_state(faction_key)

    return state and is_table(state._units)
end

function TechProto:set_child_techs(children, filters)
    if not is_table(children) then
        return errlogf("Trying to set children for technology w/ key [%s] but the child_techs arg provided [%s] is not a table!", self:get_key(), tostring(children))
    end

    for i = 1, #children do
        local child_key = children[i]
        local tech = new_tech(child_key, filters)

        self:add_child_tech(tech)
    end
end

---@param child_tech vlib_TechObj
---@return boolean
function TechProto:add_child_tech(child_tech)
    if not is_tech(child_tech) then
        return errlogf("Trying to add child tech to tech %q, but the child tech provided [%s] isn't a valid technology!", self:get_key(), tostring(child_tech))
    end

    logf("Adding tech %q as parent to %q", self:get_key(), child_tech:get_key())

    self._child_techs[#self._child_techs+1] = child_tech:get_key()
    child_tech:set_parent(self:get_key())
end

function TechProto:get_child_techs()
    local ret = {}
    local keys = self:get_child_tech_keys()

    for i = 1, #keys do
        local tech = get_tech(keys[i])
        ret[#ret+1] = tech
    end

    return ret
end

function TechProto:get_child_tech_keys()
    return self._child_techs
end

function TechProto:set_parent(tech_key)
    if not is_string(tech_key) then
        return false
    end

    self._parent_key = tech_key
end

function TechProto:set_exclusive_techs(tech_table, faction_key)
    local state = self:get_state(faction_key, true)

    local t = {}
    for i = 1, #tech_table do
        if tech_table[i] ~= self:get_key() then
            t[#t+1] = tech_table[i]
        end
    end

    state:set_exclusive_techs(t)
end

function TechProto:get_exclusive_techs(faction_key)
    local state = self:get_state(faction_key)

    return state and state:get_exclusive_techs()
end

function TechProto:add_exclusive_tech(tech_key, faction_key)
    local state = self:get_state(faction_key, true)

    return state and state:add_exclusive_tech(tech_key)
end

-- TODO query if there's already a state, also errmsg's
function TechProto:new_state(faction_key)
    if self._states[faction_key] then return self._states[faction_key] end

    local obj = TechStateProto:new(faction_key)
    obj._faction_key = faction_key

    self._states[faction_key] = obj
    return obj
end

---@return vlib_TechState
function TechProto:get_state(faction_key, is_set)
    local state = self._states[faction_key]
    if not state and is_set then
        state = self:new_state(faction_key)
    end

    return state
end

function TechProto:has_parent()
    return is_string(self._parent_key)
end

function TechProto:get_parent()
    return is_string(self._parent_key) and get_tech(self._parent_key)
end

function TechProto:has_children()
    return is_table(self._child_techs) and #self._child_techs >= 1
end

function TechProto:is_exclusive_with_tech(tech_key, faction_key)
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

function TechProto:has_exclusive_techs(faction_key)
    local state = self:get_state(faction_key)
    return state and is_table(state._exclusive_techs) and #state._exclusive_techs >= 1
end

function TechStateProto:set_exclusive_techs(tech_table)
    self._exclusive_techs = tech_table
end

function TechStateProto:get_exclusive_techs()
    return self._exclusive_techs
end

function TechStateProto:add_exclusive_tech(tech_key)
    self._exclusive_techs[#self._exclusive_techs+1] = tech_key
end

function TechStateProto:set_lock_state(lock_state, lock_reason)
    -- TODO err check?

    self._lock_state = lock_state
    self._lock_reason = lock_reason
end

function TechStateProto:get_lock_state()
    return self._lock_state
end

function TechStateProto:get_lock_reason()
    return self._lock_reason
end

-- TODO have a version where this can handle a table of faction keys?
function TechProto:set_lock_state(lock_state, lock_reason, faction_key)
    local state = self:get_state(faction_key, true)
    state:set_lock_state(lock_state, lock_reason)
end

function TechProto:get_lock_state(faction_key)
    local state = self:get_state(faction_key)

    return state and state:get_lock_state() or 0
end

function TechProto:get_lock_reason(faction_key)
    local state = self:get_state(faction_key)

    return state and state:get_lock_reason() or ""
end

function TechProto:is_perma_locked(faction_key)
    local state = self:get_state(faction_key)

    return state and state:get_lock_state() == 3
end

function TechProto:is_disabled(faction_key)
    local state = self:get_state(faction_key)

    return state and state:get_lock_state() == 1
end

--[[ TODO fill dis out
    ====== Unit Objects ======



    ======
--]]

---@return vlib_UnitState
function UnitProto:new_state(faction_key)
    if self._states[faction_key] then 
        logf("Wanted to create a new state for unit %q, for faction %s, but a state already exists!", self:get_key(), faction_key)
        return self._states[faction_key] 
    end

    local obj = UnitStateProto:new(faction_key)
    obj._faction_key = faction_key

    self._states[faction_key] = obj
    return obj
end

---comment
---@param faction_key any
---@return vlib_UnitState
function UnitProto:get_state(faction_key, is_set)
    local state = self._states[faction_key]

    if not state and is_set then
        state = self:new_state(faction_key)
    end

    return state
end

function UnitProto:set_lock_state(lock_state, lock_reason, faction_key)
    local state = self:get_state(faction_key, true)

    logf("Setting unit key [%q] to state [%s] w/ reason [%s] for faction %q", self:get_key(), lock_state, tostring(lock_reason), faction_key)

    return state and state:set_lock_state(lock_state, lock_reason)
end

function UnitProto:get_lock_state(faction_key)
    local state = self:get_state(faction_key)

    if not state then logf("In unit w/ key %q, can't find any state for faction %s???", self:get_key(), faction_key) end

    return state and state:get_lock_state()
end

function UnitProto:get_lock_reason(faction_key)
    local state = self:get_state(faction_key)
    
    return state and state:get_lock_reason()
end

function UnitProto:set_building_key(building_key)
    self._building_key = building_key

    -- TODO?
    -- if not unit_manager.building_key_to_units[building_key] then
	-- 	unit_manager.building_key_to_units[building_key] = {self}
	-- else
	-- 	unit_manager.building_key_to_units[building_key][#unit_manager.building_key_to_units[building_key]+1] = self
	-- end
end

function UnitProto:get_building_key()
    return self._building_key
end

-- TODO, needed for the building_key_to_units thingy?
-- function unit_obj:instantiate(o)
-- 	setmetatable(o, {__index = unit_obj})
-- 	-- TODO make it a bit prettier?
-- 	-- This is entirely needed so unit manager gets update with building_key_to_units. (Save the building key to units table stuff?)
-- 	o:set_building_key(o._building_key)

-- 	logf("Instantiating unit obj %q. Building key %q", o:get_key(), tostring(o:get_building_key()))
-- end

function UnitProto:set_localised_name(name)
    if self:get_localised_name() ~= "" then return end
    if not is_string(name) then return end

    self._localised_name = name
end

function UnitProto:get_localised_name()
	return self._localised_name
end

function UnitStateProto:set_lock_state(lock_state, lock_reason)
    -- TODO err check?
    logf("Doing UnitState lock state change!")

    self._lock_state = lock_state
    self._lock_reason = lock_reason
end

function UnitStateProto:get_lock_state()
    return self._lock_state
end

function UnitStateProto:get_lock_reason()
    return self._lock_reason
end

-- TODO, an individual STATE object, for within a tech. This will go in a tech._states[faction_key].
-- A TechState should hold whatever individual state stuff exists therein; it should hold query methods and what not.

-- Add everything to the Counselor!
---@type vlib_TechState
TechStateProto = Counselor:new_class("TechState", TechStateProto)
-- vlib._prototypes.CLASS.new("TechState", TechStateProto)

-- Uh, ditto on UnitState, lmao.
---@type vlib_UnitState
UnitStateProto = Counselor:new_class("UnitState", UnitStateProto)

---@type vlib_TechObj
TechProto = Counselor:new_class("TechObj", TechProto)

---@type vlib_UnitObj
UnitProto = Counselor:new_class("UnitObj", UnitProto)

---comment
---@param o vlib_UnitObj
---@return table
function UnitProto:instantiate(o)
    logf("Instantiating object w/ key %q of type %s", o._key, self._type)

    setmetatable(o, {
        __index = self._prototype,
        __tostring = function(t) return t._type .. " [" .. t._key .. "]" end,
    })

    for key, state in pairs(o._states) do
        o._states[key] = UnitStateProto:instantiate(state)
    end
    
    return o
end

---@param o vlib_TechObj
function TechProto:instantiate(o)
    logf("Instantiating object w/ key %q of type %s", o._key, self._type)

    setmetatable(o, {
        __index = self._prototype,
        __tostring = function(t) return t._type .. " [" .. t._key .. "]" end,
    })

    for key, state in pairs(o._states) do
        o._states[key] = TechStateProto:instantiate(state)
    end
    
    return o
end


--- TODO Handles a table of any filters, and returns a single table with a list of faction keys to use as filters.
function Counselor:handle_filters(filters)
    if is_string(filters) then filters = {faction = filters} end
    if not is_table(filters) then
        return errlogf("Attempting to call Counselor:handle_filters(), but the filters table passed isn't actually a table!")
    end

    local ret = {}

    local function handle_culture(key, is_sub)
        if not is_string(key) then
            return errlogf("Trying to run Counselor:handle_filters(), but the key for handle_culture isn't a string!")
        end

        local first_faction
        if is_sub then
            first_faction = cm:get_faction_of_subculture(key)
        else
            first_faction = cm:get_faction_of_culture(key)
        end

        if not first_faction then
            return errlogf("Running Counselor:handle_filters(), but the culture key [%s] passed to handle_culture doesn't have any valid factions in the game!", key)
        end

        local list = first_faction:factions_of_same_culture()
        if is_sub then
            list = first_faction:factions_of_same_subculture()
        end

        for i = 0, list:num_items() -1 do
            local fact = list:item_at(i)
            local faction_key = fact:name()

            ret[#ret+1] = faction_key
        end
    end

    local function handle_faction(key)
        if not is_string(key) then
            return errlogf("Running Counselor:handle_filters(), but the faction key [%s] passed isn't a valid string", tostring(key))
        end

        local test = cm:get_faction(key)
        if not test then
            return errlogf("Running Counselor:handle_filters(), but the faction key [%s] passed to handle_faction doesn't have any valid faction in the game!", key)
        end

        ret[#ret+1] = key
    end

    if filters.subculture then
        if is_string(filters.subculture) then
            handle_culture(filters.subculture, true)
        elseif is_table(filters.subculture) and is_string(filters.subculture[1]) then
            for i = 1, #filters.subculture do
                handle_culture(filters.subculture[i], true)
            end
        end
    end

    if filters.culture then
        if is_string(filters.culture) then
            handle_culture(filters.culture, false)
        elseif is_table(filters.culture) and is_string(filters.culture[1]) then
            for i = 1, #filters.culture do
                handle_culture(filters.culture[i], false)
            end
        end
    end

    if filters.faction then
        if is_string(filters.faction) then
            handle_faction(filters.faction)
        elseif is_table(filters.faction) and is_string(filters.faction[1]) then
            for i = 1, #filters.faction do
                handle_faction(filters.faction[i])
            end
        end
    end

    return ret
end

---comment
---@param faction_obj userdata
---@return table<number, vlib_TechObj>
function Counselor:get_active_techs_for_faction(faction_obj)
    local faction_key = faction_obj:name()

    local found_techs = {}

    local all_techs = get_all_techs()

    for _, tech in pairs(all_techs) do
        if tech:get_state(faction_key) then
            found_techs[#found_techs+1] = tech
        end
    end

    return found_techs
end

---comment
---@param tech_keys table<number, string>
---@param filters any
---@return table<number, vlib_TechObj>
function Counselor:new_techs_from_table(tech_keys, filters)
    local techs = {}
    
    for i = 1, #tech_keys do
        local tech_key = tech_keys[i]

        local test = get_tech(tech_key)
        if test then
            techs[#techs+1] = test
        else
            techs[#techs+1] = new_tech(tech_key, filters)
        end
    end

    return techs
end

---comment
---@param unit_keys table<number, string>
---@param filters any
---@return table<number, vlib_UnitObj>
function Counselor:new_units_from_table(unit_keys, filters)
    local units = {}
    
    for i = 1, #unit_keys do
        local unit_key = unit_keys[i]

        local test = get_unit(unit_key)
        if test then
            units[#units+1] = test
        else
            units[#units+1] = new_unit(unit_key, filters)
        end
    end

    return units
end

--[[

    ====== UI Stuff ======
    This section has all of my UI-specific functions!

--]]

---@class vlib_TechUI
local tech_ui = {
    _faction_key = nil,
    _slot_parent = nil,
    _currently_hovered = nil,

    ---@type table<string, vlib_TechObj>
    _researched_or_researching = {},

    ---@type table<string, table>
    _techs = {},
}

---@param tech_obj vlib_TechObj
---@param is_lock boolean
---@param affect_children boolean
---@return boolean
function tech_ui:set_tech_node_state(tech_obj, is_lock, affect_children)
    if not is_boolean(is_lock) then is_lock = true end
    if not is_boolean(affect_children) then affect_children = true end

    -- prevent unlocking any perma-locked!
    if tech_obj:is_perma_locked() then is_lock = true end
    
    local tech_key = tech_obj:get_key()

    logf("Setting %s for tech %q", tostring(is_lock and "locked" or "unlocked"), tech_key)

    local uic = self:get_uic_with_key(tech_key)
    if not is_uicomponent(uic) then
        errlogf("Can't find a tech UIC w/ key %q", tech_key)
        return false
    end

    if uic:CurrentState() == "researching" then return logf("This tech is being researched, can't do stuff!") end
    if is_lock and uic:CurrentState() == "locked_rank" then return logf("This tech is already locked visually!") end

    local time = UIComponent(uic:Find("dy_time"))
    local icons = UIComponent(uic:Find("icon_list"))

    -- local id = uic:Id()
    if is_lock == true then
        self._techs[tech_key] = {
            current_state = "locked_rank",
            previous_states = {uic:CurrentState(), time:Visible(), icons:Visible()},
            is_removed = nil,
        }

        uic:SetState("locked_rank")
        time:SetVisible(false)
        icons:SetVisible(false)
    else
        local previous_states = self._techs[tech_key].previous_states
        self._techs[tech_key] = nil

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
            self:set_tech_node_state(children[i], is_lock, false)
        end
    end
end

function tech_ui:get_uic_with_key(key)
    if not is_string(key) then return false end

    local slot = self._slot_parent
    if slot then
        return UIComponent(slot:Find(key)) or false
    end
end

function tech_ui:remove(tech_key)
    local uic = self:get_uic_with_key(tech_key)

    if uic then
       uic:SetVisible(false)

       self._techs[tech_key] = {is_removed = true}
    end
end

-- TODO if a tech is being researched, and then you click on another, both show as visually researching. Gotta fix!!!!!!!!!!!!!
-- TODO figure out how to refresh the techs after a tech node is pressed, so the locks and tooltips get re-applied
-- do the check on all exclusive techs and their states and shit
function tech_ui:refresh()
    local faction_obj = cm:get_local_faction(true)

    -- first, check the panel for any nodes that SHOULD be locked on the screen :)

    local active_techs = Counselor:get_active_techs_for_faction(faction_obj)

    for i = 1, #active_techs do
        -- local active_tech_key = active_tech_keys[i]
        local active_tech = active_techs[i]
        local active_tech_key = active_tech:get_key()

        if not active_tech then
            logf("Can't find any tech with key %q", tostring(active_tech_key))
        else
            if active_tech:is_disabled(self._faction_key) and not self._techs[active_tech_key].is_removed then
                self:remove(active_tech_key)
            end
    
            if faction_obj:has_technology(active_tech_key) then
                self._researched_or_researching[active_tech_key] = active_tech
            end
        end
    end

    for tech_key, tech in pairs(self._researched_or_researching) do
        local exclusives = tech:get_exclusive_techs()
        for j = 1, #exclusives do
            local exclusive_tech_key = exclusives[j]
            local exclusive_tech = get_tech(exclusive_tech_key)

            if not exclusive_tech:is_perma_locked() then
                local str = effect.get_localised_string("vlib_technology_locked")
                str = str .. "\n - " .. effect.get_localised_string("technologies_onscreen_name_"..tech_key)
                str = str .. effect.get_localised_string("vlib_colour_end")

                -- TODO, the UI shouldn't change state, right?
                exclusive_tech:set_lock_state(3, str, self._faction_key)
                -- exclusive_tech:set_perma_locked(true, str)
            end

            self:set_tech_node_state(exclusive_tech, true, true)
        end
    end
end

function tech_ui:open()
    local faction_key = cm:get_local_faction_name(true)

    self._faction_key = faction_key

    self._slot_parent = find_uicomponent("technology_panel", "listview", "list_clip", "list_box", "emp_civ_reworkd", "tree_parent", "slot_parent")

    vlib:repeat_callback(function() self:refresh() end, 25, "vlib_tech_ui_refresh")

    -- second, do a listener for hovering over any tech nodes that are in the list of techs here, and then lock the exclusive tech stuffs

    -- TODO don't do the locks if the hovered tech is already researched!
    -- TODO don't do anything if the hovered tech is perma locked!

    core:remove_listener("VLIB_TechHovered")
    core:add_listener(
        "VLIB_TechHovered",
        "ComponentMouseOn",
        true,
        function(context)
            self:set_tech_as_hovered(context.string)
        end,
        true
    )
end

function tech_ui:close()
    core:remove_listener("VLIB_TechHovered")

    vlib:remove_callback("vlib_tech_ui_refresh")

    self._researched_or_researching = {}
    self._currently_hovered = nil
    self._slot_parent = nil
    self._techs = {}
end

---comment
---@param tech_key string
function tech_ui:set_tech_as_hovered(tech_key)
    local ok, er = pcall(function()
    local faction_obj = cm:get_local_faction(true)

    local tech = get_tech(tech_key)

    if self._currently_hovered and self._currently_hovered ~= tech_key or not self._currently_hovered then
        local affected = self._techs
        logf("Removing any currently-affected tech locks, visually.")

        for key, status in pairs(affected) do
            local affected_tech = get_tech(key)
            logf("Removing tech lock for %q", key)
            self:set_tech_node_state(affected_tech, false, false)
        end
    end
    
    if not tech then
        self._currently_hovered = nil
        return
    end

    logf("Setting %q as hovered!", tech_key)
    self._currently_hovered = tech_key

    -- currently hovered tech is locked somehow; set its tooltip but don't mess with any other techs.
    if tech:get_lock_state(self._faction_key) >= 2 then
        vlib:callback(function()
            local tt = find_uicomponent("TechTooltipPopup")
            if tt then
                local list_parent = UIComponent(tt:Find("list_parent"))

                local add = UIComponent(list_parent:Find("additional_info"))
                add:SetVisible(true)

                local str = tech:get_lock_reason(self._faction_key)

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

            local exclusives = tech:get_exclusive_techs(self._faction_key)

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

            local unit_table = tech:get_unit_table(self._faction_key)
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

    local exclusive_techs = tech:get_exclusive_techs(self._faction_key)
    for i = 1, #exclusive_techs do
        local exclusive_tech_key = exclusive_techs[i]
        logf("Hiding tech with key %q", exclusive_tech_key)

        local exclusive_tech = get_tech(exclusive_tech_key)
        self:set_tech_node_state(exclusive_tech, true, true)
    end end) if not ok then logf(er) end
end

---@class vlib_UnitUI
local unit_ui = {
    ---@type string The currently hovered upon building in a building browser!
    _building_hovered = nil,

}

function unit_ui:get_cp()
	local construction_popups = {"construction_popup", "second_construction_popup"}
	for i = 1, #construction_popups do
		local cp = find_uicomponent(construction_popups[i])
		if cp then
			return cp
		end
	end

    return errlogf("Trying to get the Construction Popup within the Unit UI, but can't find any!")
end

function unit_ui:get_bip(is_settlement_panel)
	local bip

	-- if an arg is passed, just test that one BIP
	if is_boolean(is_settlement_panel) then
		if is_settlement_panel == true then
			return find_uicomponent("layout", "info_panel_holder", "secondary_info_panel_holder", "info_panel_background", "BuildingInfoPopup")
		else
			return find_uicomponent("building_browser", "info_panel_background", "BuildingInfoPopup")
		end
	end

	-- no arg is passed; we don't know which direction the BIP is coming from, so test both!
	bip = find_uicomponent("layout", "info_panel_holder", "secondary_info_panel_holder", "info_panel_background", "BuildingInfoPopup")

	if not bip then
		bip = find_uicomponent("building_browser", "info_panel_background", "BuildingInfoPopup")
	end

	return bip
end

function unit_ui:edit_building_info_panel(bip_uic)
	if is_nil(bip_uic) then bip_uic = self:get_bip() end
	if not bip_uic then return end
	if not self._building_hovered then return end

	local building_key = self._building_hovered

	local faction_key = cm:get_local_faction_name(true)
    local units = get_units_for_building(building_key, faction_key)

	logf("Hovering over building %q that has unit key stuff!", building_key)

	local unit_names = {}
	for i = 1, #units do
		local unit = units[i]

        local name = unit:get_localised_name()
        local lock_state = unit:get_lock_state(faction_key)

		-- only if they're hidden entirely, not locked with visual stuff
		if lock_state == 1 then
			unit_names[name] = 1
        elseif lock_state >= 2 then
            unit_names[name] = 2
		end
	end

	logf("Checking BIP for effects and shit")

	local entry_parent = find_uicomponent(bip_uic, "effects_list", "building_info_recruitment_effects", "entry_parent")

	if not entry_parent then return end

	local all = entry_parent:ChildCount()
	local total = 0

	for i = 0, all-1 do
		local child = UIComponent(entry_parent:Find(i))
		local unit_name_uic = UIComponent(child:Find("unit_name"))
		local unit_name_text = unit_name_uic:GetStateText()

		logf("Seeing if %q is a unit to hide", unit_name_text)

        local state = unit_names[unit_name_text]
        if state then
            if state == 1 then
                child:SetVisible(false)
				total = total + 1
            elseif state == 2 then
                unit_name_text = "[[col:red]]"..unit_name_text.."[[/col]]"
                unit_name_uic:SetStateText(unit_name_text)
            end
        end
	end

	if total == all then
		UIComponent(entry_parent:Parent()):SetVisible(false)
	end
end

--- Handles the "slot parent" component, which is used within the Building Browser and within Construction Popups. Goes through all of the building slots, checks their unit lists, and handles shit appropriately.
---@param slot_parent userdata
function unit_ui:handle_slot_parent(slot_parent)
	logf("Handling the slot parent component! Locking unit cards visibly and shtuff.")
	-- local slot_parent

	if not is_uicomponent(slot_parent) then
		return logf("Trying to handle the slot parent shtuff, but the slot parent provided wasn't valid!")
	end

    local faction_key = cm:get_local_faction_name(true)

	-- loop through all of the "slots" within the building tree. Order here goes Slot Parent -> Slot # -> Building UIC
	logf("Pre-loop, num children is %d", slot_parent:ChildCount())
	for i = 0, slot_parent:ChildCount() -1 do
		-- logf("Getting slot address, child num %d", i)
		logf("Getting slot UIC at child index %d", i)
		local slot = UIComponent(slot_parent:Find(i))
        if not is_uicomponent(slot) then logf("No UIC found?") end

        if is_uicomponent(slot) and slot:ChildCount() > 0 and slot:Find(0) then
            logf("Retrieved slot w/ key %s", slot:Id())
            logf("Getting building UIC")
            local building_uic = UIComponent(slot:Find(0))
            logf("Gotten building w/ key %s", building_uic:Id())

            -- holder for floating unit cards!
            local unit_list_uic = UIComponent(building_uic:Find("units_list"))

            logf("Gotten units list")

            -- loop through all floating unit cards
            for j = 0, unit_list_uic:ChildCount() -1 do
                logf("Looping through unit list, at index %d", j)
                local unit_entry = UIComponent(unit_list_uic:Find(j))
                logf("Unit entry founded")
                local unit_key = unit_entry:Id()
                logf("Unit key is %q", unit_key)

                -- ignore template unit cards
                if unit_key ~= "unit_entry" and unit_key ~= "agent_entry" then
                    -- check if there's a unit in the manager with this key!
                    local unit = get_unit(unit_key)

                    if unit then
                        -- save the localised name for other parts of the manager.
                        unit:set_localised_name(unit_entry:GetTooltipText())
                        unit:set_building_key(building_uic:Id())

                        -- if this unit is locked, hide it
                        local lock_state = unit:get_lock_state(faction_key)
                        if lock_state == 1 then
                            -- hide it entirely from the UI
                            unit_entry:SetVisible(false)
                        elseif lock_state >= 2 then
                            -- set locked, visually, and set the tooltip
                            local tt = unit_entry:GetTooltipText()
                            local lock_reason = unit:get_lock_reason(faction_key)
                            if not tt:find(lock_reason) then
                                tt = tt .. "\n\n [[col:red]]" .. lock_reason .. "[[/col]]"

                                unit_entry:SetState("active_red")
                                unit_entry:SetTooltipText(tt, true)
                            end
                        end
                    end
                end
            end
		end
	end
end

--- TODO this has to be removed w/ a panel closed listener!
function unit_ui:building_hover_listener(is_settlement_panel)
	local parent
	
	-- they have a different structure based on the spot!
	if is_settlement_panel then
		parent = find_uicomponent("settlement_panel", "main_settlement_panel")
	else
		parent = find_uicomponent("building_browser", "main_settlement_panel")
	end
	
	-- no main settlement panel found; err!
	if not parent then
		return errlogf("In unit_ui:building_hover_listener(), but there's no main_settlement_panel found!")
	end

	logf("Starting the building hover listener!")

	-- TODO listen for a hover over a construction slot within a settlement panel
		-- there's a "Construction_Slot" UIC type that can exist, only within settlement_panel->main_settlement_panel
		-- within that, a construction_popup triggers with each building set UIC within. once you hover over a building set UIC, a second_construction_popup triggers
		-- within THAT, the second_cp, we need to trigger the handle_slot_parent function again!


	--[ui] <531.5s>   path from root:		root > settlement_panel > main_settlement_panel > capital > settlement_capital > building_slot_3 > Slot2_Construction_Site > frame_expand_slot > button_expand_slot
		-- settlement_capital
		-- player
		-- button_expand_slot
		-- hover

	-- Listen for a hover over a "construction slot" that's available within the UI, to adjust the available buildings that popup within the construction dialogs.
    local is_hovered = false
	core:remove_listener("VLIB_ConstructionHovered")
	core:add_listener(
		"VLIB_ConstructionHovered",
		"ComponentMouseOn",
		function(context)
			local uic = UIComponent(context.component)
			if not uicomponent_descended_from(uic, "main_settlement_panel") then return false end

			-- Make sure it's a button expand slot, and make sure it's being hovered (otherwise, it's another faction's/it's locked/etc)
            logf("Hovering over UIC in main settlement panel w/ key %q", context.string)
			return context.string == "button_expand_slot" and uic:CurrentState() == "hover" and is_hovered == false
		end,
		function(context)
            logf("Hovering upon an expand slot, checking for Second Construction Popup!")
			-- while this button is hovered, we're gonna do a repeated check!
			local handled = false
            is_hovered = true

			vlib:repeat_callback(
				function()

                    logf("Checking for SCP repeat call!")

					-- first, test if the construction_popup is on screen. If it isn't, we've moved on!
					local cp = find_uicomponent("construction_popup")
					if not cp or cp and not cp:Visible() then
                        logf("No Construction Popup is found; aborting the SCP check!")
                        is_hovered = false
						return vlib:remove_callback("VLIB_ConstructionHovered")
                    end

					-- grab the "second_construction_popup", if there's one. this is the panel with all of the building icons to construct!
					local scp = find_uicomponent("second_construction_popup")
					if not scp then
						handled = false
						return
					end

					logf("At SCP, handled is: "..tostring(handled))

					-- if not handled then
						local slot_parent = find_uicomponent(scp, "list_holder", "building_tree", "slot_parent")

                        if is_uicomponent(slot_parent) and slot_parent:Visible() and slot_parent:ChildCount() > 0 then
    						self:handle_slot_parent(slot_parent)
                            handled = true
                        end
					-- end
				end,
				10, -- every ms to check
				"VLIB_ConstructionHovered"
			)
		end,
		true
	)


	core:remove_listener("VLIB_BuildingHovered")
	core:add_listener(
		"VLIB_BuildingHovered",
		"ComponentMouseOn",
		function(context)
			local uic = UIComponent(context.component)
			local p = UIComponent(uic:Parent())

			return 
                (string.find(p:Id(), "building_slot_") and 
                uicomponent_descended_from(uic, "main_settlement_panel")) or 
                uicomponent_descended_from(uic, "slot_parent")
		end,
		function(context)
			local uic = UIComponent(context.component)
			self._building_hovered = context.string

			logf("Hovered over building w/ key %q", context.string)

			local ok, er = pcall(function()
			
			vlib:callback(
				function()
					logf("trying to get the BIP!")
					local bip = self:get_bip(is_settlement_panel)
					if not bip or not bip:Visible() then return end

					if not uicomponent_descended_from(uic, "construction_popup") then
						local construction_popup = self:get_cp()
						if not construction_popup then return end
						if not self._building_hovered then return end
					
						local slot_parent = find_uicomponent(construction_popup, "list_holder", "building_tree", "slot_parent")
						self:handle_slot_parent(slot_parent)
					end

					self:edit_building_info_panel(bip)
				end,
				5,
				"VLIB_BuildingHovered"
			) end) if not ok then errlogf(er) end
		end,
		true
	)
end

--- Hide/remove all of the units in the recruitment pool that should be removed!
function unit_ui:open_recruitment_panel()
	logf("Hiding units from recruitment pool!")

	local ok, er = pcall(function()
	local recruitment_listbox = find_uicomponent("units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox")

	local faction_key = cm:get_local_faction_name(true)
    local units = get_units_for_faction(faction_key)

	if units and #units >= 1 then
		for _, intermediate_id in ipairs({"global", "local1", "local2"}) do
			local intermediate_parent = find_uicomponent(recruitment_listbox, intermediate_id)
			if intermediate_parent then
				for i = 1, #units do
                    local unit = units[i]
					local unit_key = unit:get_key()
                    logf("Checking %s within the recruitment panel", unit_key)
					local unit_uic = find_uicomponent(intermediate_parent, "unit_list", "listview", "list_clip", "list_box", unit_key.."_recruitable")
					if unit_uic then
                        local lock_state = unit:get_lock_state(faction_key)
                        logf("Lock state for unit [%s] in faction %q is [%s]", unit_key, faction_key, tostring(lock_state))
						if lock_state == 1 then
                            logf("%q is disabled, setting invisible!", unit_key)
							unit_uic:SetVisible(false)
						elseif lock_state >= 2 then
                            logf("%q is locked, setting visible w/ special tooltip.", unit_key)
							-- get rid of a silly white square!
							local lock = find_uicomponent(unit_uic, "disabled_script")
							lock:SetVisible(false)

							-- change the unit icon state to "locked", which shows that padlock over the unit card.
							local icon = find_uicomponent(unit_uic, "unit_icon")
							icon:SetState("locked")

							-- grab the existing tooltip, to edit.
							local tt = unit_uic:GetTooltipText()
							
							-- we're grabbing the `[[col:red]]Cannot recruit unit.[[/col]]` bit and replacing it on our own.
							local str = effect.get_localised_string("random_localisation_strings_string_StratHudbutton_Cannot_Recruit_Unit0")

							-- get rid of the col bits. the % are needed because string.gsub treats [ as a special character, so these are being "escaped"
							str = string.gsub(str, "%[%[col:red]]", "")
							str = string.gsub(str, "%[%[/col]]", "")

							-- this replaces the remaining bit, "Cannot recruit unit.", with whatever the provided lock reason is.
							local lock_reason = unit:get_lock_reason(faction_key)
							tt = string.gsub(tt, str, lock_reason, 1)

							-- cut off everything AFTER the lock reason. vanilla has trailing \n for no raisin.
							local _,y = string.find(tt, lock_reason)
							tt = string.sub(tt, 1, y)

							-- replace the tooltip!
							unit_uic:SetTooltipText(tt, true)
						end
					end
				end
			end
		end
	end
end) if not ok then errlogf(er) end
end

function unit_ui:open_building_browser()
	local building_browser = find_uicomponent("building_browser")
	if building_browser then
		local slot_parent = find_uicomponent(building_browser, "listview", "list_clip", "list_box", "building_tree", "slot_parent")
		self:handle_slot_parent(slot_parent)
	end

	self:building_hover_listener(false)
end

function unit_ui:open_settlement_panel()
	self:building_hover_listener(true)
end

--- TODO check if there needs to be any deets from unit_ui cleared out!
function unit_ui:close_building_browser()
    core:remove_listener("VLIB_ConstructionHovered")
    core:remove_listener("VLIB_BuildingHovered")
end

function unit_ui:close_settlement_panel()
    core:remove_listener("VLIB_ConstructionHovered")
    core:remove_listener("VLIB_BuildingHovered")
end

function unit_ui:handle_panel(panel_name, is_open)
    local name_to_func = {
        building_browser = self.open_building_browser,
        settlement_panel = self.open_settlement_panel,

        units_recruitment = self.open_recruitment_panel,
        mercenary_recruitment = self.open_recruitment_panel,
    }

    if not is_open then
        name_to_func = {
            building_browser = self.close_building_browser,
            settlement_panel = self.close_settlement_panel,
        }
    end

    local f = name_to_func[panel_name]
    if not f then return end

    return f(self) and true
end

local valid_panels_to_open = {
    --- Tech!
    technology_panel = true,

    -- Unit shit!
    units_recruitment = true,
    mercenary_recruitment = true,
    building_browser = true,
    settlement_panel = true,
}

local valid_panels_to_close = {
    --- Tech!
    technology_panel = true,

    building_browser = true,
    settlement_panel = true,
}

local function handle_panel(panel_name, is_open)
    logf("Handling panel %s that was "..tostring(is_open and "opened" or "closed"), panel_name)

    local ok, er = pcall(function()
    if panel_name == "technology_panel" then
        if is_open then 
            tech_ui:open()
        else
            tech_ui:close()
        end
    end

    local unit_handled = unit_ui:handle_panel(panel_name, is_open)

    -- for any other sections that might want to handle it!
    if not unit_handled then
        
    end
end) if not ok then errlogf(er) end
end

--[[ 

    ====== Listeners ======

    For cleanliness's sake, this section holds all of my top-level listeners!

--]]

local function init_listeners()

    -- TODO temp disbable
    -- core:add_listener(
    --     "VLIB_PanelOpened",
    --     "PanelOpenedCampaign",
    --     function(context)
    --         return valid_panels_to_open[context.string]
    --     end,
    --     function(context)
    --         local panel_name = context.string
    --         vlib:callback(function()
    --             handle_panel(panel_name, true)
    --         end, 10, "VLIB_PanelOpened")
    --     end,
    --     true
    -- )
    
    -- core:add_listener(
    --     "VLIB_PanelClosed",
    --     "PanelClosedCampaign",
    --     function(context)
    --         return valid_panels_to_close[context.string]
    --     end,
    --     function(context)
    --         local panel_name = context.string
    --         vlib:callback(function()
    --             handle_panel(panel_name, false)
    --         end, 10, "VLIB_PanelClosed")
    --     end,
    --     true
    -- )
    
    
    -- -- TODO finish this up!
    -- -- Locks the techs for a faction if they research any exclusive tech.
    -- core:add_listener(
    --     "TechResearched",
    --     "ResearchCompleted",
    --     true,
    --     function(context)
    --         local tech_key = context:technology()
    --         local faction = context:faction()
    --         local faction_key = faction:name()
    --         logf("Research %q completed by %q, checking if any exclusives are researched!", tech_key, faction_key)
    
    --         local tech = get_tech(tech_key)
    
    --         if not tech then
    --             logf("No tech found with key %q", tech_key)
    --             return
    --         end
    
    --         logf("Tech has exclusive techs: "..tostring(tech:has_exclusive_techs()))
    
    --         if tech:has_exclusive_techs() then
    --             logf("Tech %q has exclusive technologies, restricting for faction %q", tech_key, faction_key)
    --             -- tech_manager:restrict_tech_for_faction(tech:get_exclusive_techs(), faction_key, true)
    --             logf("techs restricted!")
    --         end
    
    --         -- TODO handle this with locks AND unlocks, needs to be dynamic so locked reasons and shit can be provided.
    --         if tech:has_units() then
    --             local unit_table = tech:get_unit_table(faction_key)
    
    --             for state,units in pairs(unit_table) do
    --                 Counselor:set_units_lock_state(unit_table[state], state, "TODO!", faction_key)
    --             end
    --         end
    --     end,
    --     true
    -- )

    core:add_listener(
        "PR_HoveredOn",
        "ComponentMouseOn",
        function(context)
            return pr_ui:get_pr_with_key(context.string)
        end,
        function(context)
            local str = context.string
            vlib:callback(function()
                -- logf("Checking tooltip for PR %q", str)
                local ok, msg = pcall(function()
                pr_ui:adjust_tooltip(str, cm:get_local_faction_name(true))
                end) if not ok then errlog(msg) end
            end, 5, "pr_hovered")
        end,
        true
    )

    core:add_listener(
        "PR_ValueChanged",
        "PooledResourceEffectChangedEvent",
        function(context)
            return context:faction():name() == cm:get_local_faction_name(true) and pr_ui:get_pr_with_key(context:resource():key())
        end,
        function(context)
            pr_ui:check_value(context:resource():key(), cm:get_local_faction_name(true))
        end,
        true
    )

    core:add_listener(
        "PR_TurnStart",
        "FactionTurnStart",
        function(context)
            return context:faction():name() == cm:get_local_faction_name(true)
        end,
        function(context)
            local faction = context:faction()
            local faction_key = faction:name()
            if pr_ui:faction_has_resources(faction) then
                local resource_keys = pr_ui:get_resource_keys_for_faction(faction)
                for i = 1, #resource_keys do
                    local resource_key = resource_keys[i]

                    if not pr_ui:get_uic(resource_key) then
                        -- create UIC, if it doesn't exist already
                        pr_ui:create_uic(pr_ui:get_pr_with_key(resource_key), faction_key)
                    else -- check value if it does
                        pr_ui:check_value(resource_key, faction_key)
                    end
                end
            end
        end,
        true
    )
end

--[[

    ====== CM Stuff ======

    This section is filled with the Counselor methods that handle communication between the CA Campaign Manager, and my own here. This is for stuff like functionally removing the ability to recruit a unit, or to remove the ability to research a technology.

    This section shouldn't need to be touched by outside mods - the API directly handles calls to this section. I separated it for cleanliness sake.
--]]

--- Public-facing API for this part of the Vandy Library. The "Camp Counselor" is my campaign manager, to be used for making any campaign methods or functions.
---@usage local vandy_lib = get_vandy_lib() 
-- local Counselor = vandy_lib:get_module("camp_counselor")
-- Counselor:add_pr_uic("pr_key", "ui.png", "wh_main_emp_empire")
---@class CounselorAPI


-- TODO write up methods to run through these via subculture/culture? or naw?
function Counselor:restrict_units_for_faction(unit_table, faction_key, is_disable)
    if is_string(unit_table) then unit_table = {unit_table} end
    if not is_boolean(is_disable) then is_disable = true end

    if not is_string(faction_key) then
        return errlogf("Calling restrict_units_for_faction, but the faction key provided [%s] isn't a string!", tostring(faction_key))
    end

    logf("%s units [%s] for faction %q", tostring(is_disable and "Restricting" or "Unlocking"), table.concat(unit_table, ", "), faction_key)

    local function func()
        local faction = cm:get_faction(faction_key)
        if not faction then
            return errlogf("Calling restrict_units_for_faction, but the faction provided [%s] doesn't exist in this game!", tostring(faction_key))
        end
    
        cm:restrict_units_for_faction(faction_key, unit_table, is_disable)
    end

    if cm.game_is_running then
        func()
    else
        cm:add_first_tick_callback(func)
    end
end

function Counselor:restrict_techs_for_faction(techs, faction_key, is_disable)
    if is_string(techs) then techs = {techs} end
    if not is_boolean(is_disable) then is_disable = true end

    if not is_string(faction_key) then
        return errlogf("Calling restrict_tech_for_faction, but the faction key provided [%s] isn't a string!", tostring(faction_key))
    end

    logf("%s techs [%s] for faction %q", tostring(is_disable and "Restricting" or "Unlocking"), table.concat(techs, ", "), faction_key)

    local function func()
        local faction = cm:get_faction(faction_key)
        if not faction then
            return errlogf("Calling restrict_tech_for_faction, but the faction provided [%s] doesn't exist in this game!", tostring(faction_key))
        end

        cm:restrict_technologies_for_faction(faction_key, techs, is_disable)
    end

    if cm.game_is_running then
        func()
    else
        cm:add_first_tick_callback(func)
    end
end

--[[

    ====== API ======

    The section below is the actual usable part of the script; everything above is just backend stuff.

    To grab the "Camp counselor" object, use:
    
        local vlib = get_vandy_lib()
        local counselor = vlib:get_module("camp_counselor")

    And from then on, simply call functions on the "counselor" object!

        counselor:set_mutually_exclusive_techs({tech_1={"child", "child"}})

    And so forth!

--]]

--- Add in-game UI for a Pooled Resource - similar to the UI for Canopic Jars, or the various Vortex Currencies, or otherwise. The Pooled Resource MUST be created already in data, and have valid factors, valid text, and be hooked up to each faction provided herein.
---@param pooled_resource_key string The key for your PR, from pooled_resources_tables.
---@param pr_icon_path string The image path for your PR icon. It should start from the root of a .pack file - so if your file is in mymod.pack/ui/icons/pr_icon.png, you would put in "ui/icons/pr_icon.png", including the file name (must be a .png).
---@param filters table|string Provide a filters table (or a single string, if you're just using one faction key). You can use {faction="faction_key"}, {subculture="subculture_key"}, {culture="culture_key"}, or any combination therein. Any three of those, likewise, can be tables, ie. {faction = {"faction1", "faction2"}}, and you can use all three filters at once, ie. {faction="faction1", subculture = {"subculture1", "subculture2"}}
---@usage Counselor:add_pr_uic("pr_key", "ui/skins/default/my_icon.png", "wh_main_emp_empire")
function Counselor:add_pr_uic(pooled_resource_key, pr_icon_path, filters)
    if not is_string(pooled_resource_key) then
        return errlogf("Calling add_pr_uic(), but the PR key provided [%s] isn't a valid string!", tostring(pooled_resource_key))
    end
    
    if not is_string(pr_icon_path) then
        return errlogf("Calling add_pr_uic(), but the PR icon path provided [%s] isn't a valid string!", tostring(pr_icon_path))
    end
    
    local proper_filters = self:handle_filters(filters)
    if not proper_filters then
        return errlogf("Calling add_pr_uic(), but the filters provided aren't valid!")
    end

    local new_pr = pr_ui:create_new_pr(pooled_resource_key, pr_icon_path, proper_filters)

    if pr_ui._initialized then
        local this_faction = cm:get_local_faction_name(true)
        if new_pr._factions[this_faction] then
            pr_ui:create_uic(new_pr, this_faction)
        end
    end
end

--- A system to create mutually exclusive technologies - if one is researched, the other[s] are locked, permanently. Handles the UI and the actual locking of the techs.
---@param tech_table table<string, table> A table of the relevant techs that are being mutually exclusive'd. Needs to be a table of techs, optionally linked to each techs child key. For instance, without child techs: {"tech_1", "tech_2", "tech_3"}; with child techs: {["tech_1"] = {"child_1", "child_2"}, ["tech_2"] = {"child_3", "child_4"}}
---@param filters table|string Provide a filters table (or a single string, if you're just using one faction key). You can use {faction="faction_key"}, {subculture="subculture_key"}, {culture="culture_key"}, or any combination therein. Any three of those, likewise, can be tables, ie. {faction = {"faction1", "faction2"}}, and you can use all three filters at once, ie. {faction="faction1", subculture = {"subculture1", "subculture2"}}
---@usage Counselor:set_mutually_exclusive_techs({"tech_1", "tech_2"}, "wh_main_emp_empire")
---@usage Counselor:set_mutually_exclusive_techs({["tech_1"] = {"child_1"}, ["tech_2"] = {"child_2"}}, "wh_main_emp_empire")
function Counselor:set_mutually_exclusive_techs(tech_table, filters)
    local ok, er = pcall(function()
    if not is_table(tech_table) then
        return errlogf("Calling set_mutually_exclusive_techs, but the tech table provided isn't actually a table!")
    end

    if next(tech_table) == nil then
        return errlogf("Calling set_mutually_exclusive_techs, but the tech table provided is empty!")
    end

    local proper_filters = self:handle_filters(filters)
    if not is_table(proper_filters) then
        return errlogf("Calling set_mutually_exclusive_techs, but the filters provided aren't valid!")
    end

    local is_array = tech_table[1] ~= nil

    local all_keys = {}
    if is_array then
        all_keys = tech_table
    else
        for k,_ in pairs(tech_table) do
            all_keys[#all_keys+1] = k
        end
    end

    logf("Setting techs [%s] as mutually exclusive for factions [%s].", table.concat(all_keys, ", "), table.concat(proper_filters, ", "))

    if is_array then
        for i = 1, #tech_table do
            local tech_key = tech_table[i]
            local tech = new_tech(tech_key, proper_filters)

            for j = 1, #proper_filters do
                tech:set_exclusive_techs(all_keys, proper_filters[j])
            end
        end
    else
        for tech_key, children in pairs(tech_table) do
            local tech = new_tech(tech_key, proper_filters)
    
            if is_table(children) then
                tech:set_child_techs(children, proper_filters)
            end
    
            for i = 1, #proper_filters do
                tech:set_exclusive_techs(all_keys, proper_filters[i])
            end
        end 
    end

    end) if not ok then errlogf(er) end
end

--- Provide a list of units to lock behind this tech, and to subsequently unlock upon research. Set the "is_unlock" bool to false, to handle the opposite interaction - unlock by default, and then LOCK upon research.
---@param tech_key string The tech behind which to lock your units. Must match the key in "technologies"
---@param unit_table string|table The unit[s] to attach to this tech. You can provide a single unit key `"unit_1"`, or a bunch of them using a table `{"unit_1", "unit_2"}`
---@param is_unlock boolean Set this to true to lock the units by default, and unlock through this tech being research; set this to false to have the reverse behaviour.
---@param filters table|string Provide a filters table (or a single string, if you're just using one faction key). You can use {faction="faction_key"}, {subculture="subculture_key"}, {culture="culture_key"}, or any combination therein. Any three of those, likewise, can be tables, ie. {faction = {"faction1", "faction2"}}, and you can use all three filters at once, ie. {faction="faction1", subculture = {"subculture1", "subculture2"}}
---@usage Counselor:set_tech_unit_unlock("tech_key", {"unit_1", "unit_2"}, true, "wh_main_emp_empire")
function Counselor:set_tech_unit_unlock(tech_key, unit_table, is_unlock, filters)
    local ok, er = pcall(function()
    if not is_string(tech_key) then
        return errlogf("Calling set_tech_unit_unlock(), but the tech key provided [%s] isn't a valid string!", tostring(tech_key))
    end

    if is_string(unit_table) then unit_table = {unit_table} end

    if not is_table(unit_table) then
        return false
    end

    if is_nil(is_unlock) then is_unlock = false end

    if not is_boolean(is_unlock) then
        return errlogf("Calling set_tech_unit_unlock(), but the is_unlock arg provided [%s] isn't a valid boolean!", tostring(is_unlock))
    end

    local proper_filters = self:handle_filters(filters)
    if not is_table(proper_filters) then
        return errlogf("Calling set_tech_unit_unlock(), but the filters table provided isn't actually a table!")
    end

    local tech = new_tech(tech_key, proper_filters)

    -- Lock reason - "This unit requires technology: %s", where %s is filled in by the tech's onscreen name.
    local str = effect.get_localised_string("vlib_restrict_unit_by_tech")
    str = string.format(str, effect.get_localised_string("technologies_onscreen_name_"..tech_key))

    -- If this operation unlocks the units via techs, then we have to set them to locked, and vice versa.
    local state = "unlocked"
    if is_unlock then state = "locked" end

    logf("Setting units [%s] as %s until tech [%s] is researched, for faction[s] [%s].", table.concat(unit_table, ", "), state, tech_key, table.concat(proper_filters, ", "))

    -- TODO I don't like doing this w/ the filters; think of some other way to handle it?
    self:set_units_lock_state(unit_table, state, str, {faction=proper_filters})

    for i = 1, #proper_filters do
        local faction_key = proper_filters[i]
        tech:set_unit_table(unit_table, is_unlock, faction_key)
    end
end) if not ok then errlogf(er) end
end

local states_to_numbers = {
    unlocked = 0,
    disabled = 1,
    locked = 2,
    permalocked = 3,
}

--- Used to set the lock state for a technology. This can unlock a previously locked tech, apply a lock to a tech, or completely remove and hide a tech from player and AI.
---@param tech_table string|table<number,string> A single technology key, or a table of them.
---@param lock_state string|"locked"|"unlocked"|"disabled" Set the state for these locks. Locked means it cannot be used, and has chains on it visually. Unlocked means business as usual. Disabled means it's hidden and unusable.
---@param lock_reason string|nil Provide the reason for the lock, if the lock_state is "locked". Otherwise, this parameter is ignored.
---@param filters table|string Provide a filters table (or a single string, if you're just using one faction key). You can use {faction="faction_key"}, {subculture="subculture_key"}, {culture="culture_key"}, or any combination therein. Any three of those, likewise, can be tables, ie. {faction = {"faction1", "faction2"}}, and you can use all three filters at once, ie. {faction="faction1", subculture = {"subculture1", "subculture2"}}
function Counselor:set_techs_lock_state(tech_table, lock_state, lock_reason, filters)
    local ok, er = pcall(function()
    if is_string(tech_table) then tech_table = {tech_table} end
    if not is_table(tech_table) and not is_string(tech_table[1]) then
        return errlogf("Calling set_techs_lock_state(), but the tech_table provided isn't a table, or doesn't have only strings (tech keys) within it.")
    end

    if not is_string(lock_state) then
        return errlogf("Calling set_techs_lock_state(), but the lock_state provided [%s] isn't a valid string!", lock_state)
    end

    if not states_to_numbers[lock_state] then
        return errlogf("Calling set_techs_lock_state(), but the lock_state provided [%s] isn't a valid state! Valid states are %q, %q, and %q.", lock_state, "unlocked", "locked", "disabled")
    end

    local new_state = states_to_numbers[lock_state]

    if new_state >= 2 and not is_string(lock_reason) then
        return errlogf("Calling set_techs_lock_state(), but the lock_state is [%s] and requires a lock_reason, but no lock_reason was provided or the one provided [%s] isn't a string!", lock_state, tostring(lock_reason))
    end

    local proper_filters = self:handle_filters(filters)
    if not is_table(proper_filters) then
        return errlogf("Calling set_techs_lock_state(), but the filters provided aren't valid!")
    end

    local new_techs = self:new_techs_from_table(tech_table, proper_filters)
    if not new_techs then
        -- errmsg
        return false
    end

    logf("Setting techs [%s] as %s for factions [%s].", table.concat(tech_table, ", "), lock_state, table.concat(proper_filters, ", "))

    for i = 1, #new_techs do
        local tech = new_techs[i]

        for j = 1, #proper_filters do
            local faction_key = proper_filters[j]
            tech:set_lock_state(new_state, lock_reason, faction_key)

            -- Functionally restrict the tech; lock_state >= 1 translates to "true" for disable.
            self:restrict_techs_for_faction(tech:get_key(), faction_key, new_state >= 1)
        end
    end end) if not ok then errlogf(er) end
end

--- Set the lock state for the units provided. 
---@param unit_keys string|table<number, string> The unit[s] to lock. Use "unit_key" or {"unit_key", "unit_key_2"}.
---@param lock_state string|"unlocked"|"locked"|"disabled" Set the lock state to unlocked to have the unit readily available; locked to have the unit restricted, but visible in the UI with an explanation (lock_reason) and a chain around it; or disabled, to have the unit restricted and invisible in the UI.
---@param lock_reason string|nil The reason to list in the UI for the lock. I recommend passing in text grabbed through effect.get_localised_string(). Only necessary if the lock_state is "locked".
---@param filters table|string Provide a filters table (or a single string, if you're just using one faction key). You can use {faction="faction_key"}, {subculture="subculture_key"}, {culture="culture_key"}, or any combination therein. Any three of those, likewise, can be tables, ie. {faction = {"faction1", "faction2"}}, and you can use all three filters at once, ie. {faction="faction1", subculture = {"subculture1", "subculture2"}}
function Counselor:set_units_lock_state(unit_keys, lock_state, lock_reason, filters)
    local ok, er = pcall(function()
    if is_string(unit_keys) then unit_keys = {unit_keys} end
    if not is_table(unit_keys) and not is_string(unit_keys[1]) then
        return errlogf("Calling set_units_lock_state(), but the unit_keys provided isn't a table, or doesn't have only strings (unit keys) within it.")
    end

    if not is_string(lock_state) then
        return errlogf("Calling set_units_lock_state(), but the lock_state provided [%s] isn't a valid string!", lock_state)
    end

    local state = states_to_numbers[lock_state]
    if not state then
        return errlogf("Calling set_units_lock_state(), but the lock_state provided [%s] isn't a valid state! Valid states are %q, %q, and %q.", lock_state, "unlocked", "locked", "disabled")
    end


    if state == 2 and not is_string(lock_reason) then
        return errlogf("Calling set_units_lock_state(), but the lock_state is [%s] and requires a lock_reason, but no lock_reason was provided or the one provided [%s] isn't a string!", lock_state, tostring(lock_reason))
    end

    local proper_filters = self:handle_filters(filters)
    if not proper_filters then
        return errlogf("Calling set_units_lock_state(), but the filters provided aren't valid!")
    end

    logf("Setting units [%s] as %s for factions [%s].", table.concat(unit_keys, ", "), lock_state, table.concat(proper_filters, ", "))

    local units = self:new_units_from_table(unit_keys, proper_filters)

    for i = 1, #units do
        local unit = units[i]

        for j = 1, #proper_filters do
            local faction_key = proper_filters[j]
            unit:set_lock_state(state, lock_reason, faction_key)

            self:restrict_units_for_faction(unit:get_key(), faction_key, state >= 1)
        end
    end end) if not ok then errlogf(er) end
end

vlib:add_module("camp_counselor", Counselor)

cm:add_first_tick_callback(function()
    init_listeners()
    pr_ui:init()
end)

cm:add_saving_game_callback(
    function(context)
        cm:save_named_value("vlib_campcounselor", Counselor._objects, context)
    end
)

cm:add_loading_game_callback(
    function(context)
        local ok, er = pcall(function()
        Counselor._objects = cm:load_named_value("vlib_campcounselor", Counselor._objects, context)

        for class_key, objects in pairs(Counselor._objects) do
            logf("Instantiating %s class within Counselor!", class_key)
            local class = Counselor:get_class(class_key)

            for object_key, object in pairs(objects) do
                logf("Instantiating %s of class %s", object_key, class_key)
                class:instantiate(object)

                logf("Object has states %s", tostring(object._states))
                do
                    for i = 1, #object._states do
                        local state = object._states[i]
                        logf("State at %d is %s", i, tostring(state))
                    end
                end
            end
        end end) if not ok then errlogf(er) end
    end
)
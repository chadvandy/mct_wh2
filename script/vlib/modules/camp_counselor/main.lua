--- This is a series of functionalities lumped into one singular manager. The name is partially erroneous because it has some functionality for the frontend as well as the campaign (and maybe eventually battle).

--- Campaign Counselor (because CA already took the Campaign Manager).

--- TODO move "filters" into own file.
--- TODO Create "requirements"
--- TODO make it easy to use all of this shit (:

--- Lock states are either 0 (unlocked), 1 (invisible), 2 (locked) or 3 (permanently locked)
---@alias lock_state "0"|"1"|"2"|"3"

--- 
---@alias lock_state_string "\"locked\""|"\"unlocked\""|"\"invisible\""

-- Campaign only!
if __game_mode ~= __lib_type_campaign then return end

local vlib = get_vandy_lib()
local log,logf,errlog,errlogf = vlib:get_log_functions("[camp]")

local this_path = "script/vlib/modules/camp_counselor/"
local functionality_path = this_path.."functionality/"
local go_path = this_path.."game_objects/"

---@class vlib_camp_counselor
local CounselorDefaults = {
    _classes = {
        ---@type unit_class
        UnitObj = vlib:load_module("UnitObj", go_path),

        ---@type tech_class
        TechObj = vlib:load_module("TechObj", go_path),

        ---@type vlib_pr_obj TODO swap to the custom class setup?
        PRObj = vlib:load_module("PRObj", go_path),
    },

    
    _objects = {},
}

---@class vlib_camp_counselor : Class
local Counselor = vlib:new_class("camp_counselor", CounselorDefaults)
vlib:add_module("camp_counselor", Counselor)

function Counselor:init()
    -- anything else needed on creation
    for k,_ in pairs(self._classes) do
        self._objects[k] = {}
    end

    --- load functionality here
    vlib:load_modules(functionality_path)
end

Counselor:init()

function Counselor:get_class(class_key)
    return self._classes[class_key]
end

--- TODO make sure new/get obj are valid, so it doesn't break on objects[class_key][object_key] if class is invalid
function Counselor:new_object(class_key, object_key, ...)
    local object = self:get_class(class_key).new(object_key, ...)

    self._objects[class_key][object_key] = object
    return object
end

function Counselor:get_object(class_key, object_key)
    return self._objects[class_key][object_key]
end

function Counselor:get_objects_of_class(class_key)
    return self._objects[class_key]
end


-- TODO set these all to CC

---comment
---@param key string
---@return unit_class
local function get_unit(key)
    if not is_string(key) then return false end

    return Counselor:get_object("UnitObj", key)
end

---comment
---@param key string
---@return tech_class
local function get_tech(key)
    if not is_string(key) then return false end

    return Counselor:get_object("TechObj", key)
end

---comment
---@param key any
---@param filters any
---@return tech_class
local function new_tech(key, filters)
    if not is_string(key) then return false end

    return Counselor:new_object("TechObj", key, filters)
end

---comment
---@param key any
---@param filters any
---@return unit_class
local function new_unit(key, filters)
    if not is_string(key) then return false end

    return Counselor:new_object("UnitObj", key, filters)
end

---@return table<string, tech_class>
local function get_all_techs()
    return Counselor:get_objects_of_class("TechObj")
end

---@return table<string, tech_class>
local function get_all_units()
    return Counselor:get_objects_of_class("UnitObj")
end

local function is_tech(obj)
    return tostring(obj):match("^TechObj")
end

local function is_unit(obj)
    return tostring(obj):match("^UnitObj")
end

---@return table<number, tech_class>
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

function Counselor:get_units_for_building(building_key, faction_key)
    local all
    local ret = {}
    if faction_key then
        all = self:get_units_for_faction(faction_key)

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

---@return table<number, unit_class>
function Counselor:get_units_for_faction(faction_key)
    if not is_string(faction_key) then
        -- errmsg
        return false
    end

    local all = get_all_units()
    local ret = {}

    for _, unit_obj in pairs(all) do
        if unit_obj:get_state(faction_key) then
            ret[#ret+1] = unit_obj
        end
    end

    return ret
end

--- TODO make Filter its own "object" that can be created and used on its own
--- ie., local filter = Counselor:new_filter({faction="faction_key"}) or whatever, and then you can keep that filter with its MT and all and use it for multiple functions at once
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
---@return table<number, tech_class>
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
---@return table<number, tech_class>
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
---@return table<number, unit_class>
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

    ---@type vlib_pr_obj
    local pr_ui = self:get_class("PRObj")
    
    local proper_filters = self:handle_filters(filters)
    if not proper_filters then
        return errlogf("Calling add_pr_uic(), but the filters provided aren't valid!")
    end

    local new_pr = pr_ui.create_new_pr(pooled_resource_key, pr_icon_path, proper_filters)

    if pr_ui._initialized then
        local this_faction = cm:get_local_faction_name(true)
        if new_pr._factions[this_faction] then
            pr_ui.create_uic(new_pr, this_faction)
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
---@param lock_state lock_state_string Set the state for these locks. Locked means it cannot be used, and has chains on it visually. Unlocked means business as usual. Disabled means it's hidden and unusable.
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

cm:add_first_tick_callback(function()
    -- call "init" on every class!
    local classes = Counselor._classes

    for k,class in pairs(classes) do
        if class.init then
            class.init()
        end
    end
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
                class.instantiate(object)

                logf("Object has states %s", tostring(object._states))
                do
                    for i = 1, #object._states do
                        local state = object._states[i]
                        logf("State at %d is %s", i, tostring(state))

                        -- TODO instantiate state?
                    end
                end
            end
        end end) if not ok then errlogf(er) end
    end
)
---- Mod Configuration Tool Manager
--- @class mct
-- Define the manager that will be used for the majority of all these operations
---@type mct
local mod_configuration_tool = {
    _settings_path = "/script/mct/settings/",
    _self_path = "script/vlib/modules/mod_configuration_tool/",

    ---@type mct_settings
    settings = nil,

    -- default to false
    _finalized = false,
    _initialized = false,
    _first_load = false,

    write_to_log = true,

    _registered_mods = {},
    _selected_mod = nil,

    ui_created_callbacks = {},
}

setmetatable(
    mod_configuration_tool, 
    {__tostring = function(self) return "MOD_CONFIGURATION_TOOL" end,}
)

local vlib = get_vlib()
local log,logf,errlog,errlogf = vlib:get_log_functions("[mct]")

function mod_configuration_tool:log(text)
    return log(text)
end

function mod_configuration_tool:logf(text, ...)
    return logf(text, ...)
end

function mod_configuration_tool:err(text)
    return errlog(text)
end

function mod_configuration_tool:errf(text, ...)
    return errlogf(text, ...)
end

function mod_configuration_tool:warn(text)
    return log("WARNING: " .. text)
end

--- triggers the listeners for MP communication events!
function mod_configuration_tool:mp_prep()
    ClMultiplayerEvents.registerForEvent(
        "MctMpFinalized","MctMpFinalized",
        function(mct_data)
            -- mct_data = {mod_key = {option_key = {setting = xxx, read_only = true}, option_key_2 = {setting = yyy, read_only = false}}, mod_key2 = {etc}}
            for mod_key, options in pairs(mct_data) do
                local mod_obj = self:get_mod_by_key(mod_key)

                for option_key, option_data in pairs(options) do
                    local option_obj = mod_obj:get_option_by_key(option_key)

                    local setting = option_data._setting

                    option_obj:set_finalized_setting(setting)
                end
            end

            --core:trigger_custom_event("MctFinalized", {["mct"] = self, ["mp_sent"] = true})
        end
    )

end

function mod_configuration_tool:load_and_start(loading_game_context, is_mp)
    self._initialized = true

    core:add_listener(
        "who_is_the_host_tell_me_now_please",
        "UITrigger",
        function(context)
            return context:trigger():starts_with("mct_host|")
        end,
        function(context)
            local str = context:trigger()
            local faction_key = string.gsub(str, "mct_host|", "")

            cm:set_saved_value("mct_host", faction_key)

            self.settings:mp_load()
        end,
        false
    )
    
    local function trigger(is_multi)
        core:trigger_custom_event("MctInitialized", {["mct"] = self, ["is_multiplayer"] = is_multi})
    end

    if __game_mode == __lib_type_campaign then
        if is_mp then
            
            cm:add_pre_first_tick_callback(function()
                if not cm:get_saved_value("mct_mp_init") then
                    --if cm:is_new_game() then
                        local my_faction = cm:get_local_faction_name(true)
                        --[[local their_faction = ""
                        local faction_keys = cm:get_human_factions()
                        if faction_keys[1] == my_faction then
                            their_faction = faction_keys[2]
                        else
                            their_faction = faction_keys[1]
                        end]]
        
                        local is_host = core:svr_load_bool("local_is_host")
                        if is_host then
                            CampaignUI.TriggerCampaignScriptEvent(0, "mct_host|"..my_faction)
                        end

                        cm:set_saved_value("mct_mp_init", true)
                        --self.settings:mp_load()

                    --trigger()
                else
                    -- trigger during pre-first-tick-callback to prevent time fuckery
                    trigger(true)
                end
            end)
            self.settings:load_game_callback(loading_game_context)
            --trigger(true)
            

            self:mp_prep()


            cm:add_saving_game_callback(function(context) self.settings:save_game_callback(context) end)
        else
            -- if it's a new game, read the settings file and save that into the save file
            if cm:is_new_game() then
                self.settings:load()
            else
                self.settings:load_game_callback(loading_game_context)
            end

            cm:add_saving_game_callback(function(context) self.settings:save_game_callback(context) end)

            trigger(false)
        end
    else
        --log("frontend?")
        -- read the settings file
        local ok, msg = pcall(function()
            self.settings:load()

            trigger(false)
        end) if not ok then errlog(msg) end
    end
end

--- For internal use, loads specific mod files located in `script/mct/settings/`. 
--- Any .lua file found in here is given the MCT manager as the variable `mct` within the full scope of the file.
--- @param filename string The filename being required and loaded.
--- @param filename_for_out string The original filename with the full directory path still included; used for outputs.
function mod_configuration_tool:load_mod(filename, filename_for_out)
    log("Loading MCT module with name [" .. filename_for_out .."]")

    local loaded_file, load_error = loadfile(filename)

    if loaded_file then
        local global_env = core:get_env()

        local attach_env = {}
        setmetatable(attach_env, {__index = global_env})
        
        attach_env.mct = self
        attach_env.core = core

        setfenv(loaded_file, attach_env)

        -- run the file!
        local ok, msg = pcall(loaded_file)

        -- if it didn't work
        if not ok then
            errlog("Failed to execute loaded MCT file [" .. filename_for_out .. "], error is: " .. tostring(msg))
            return false
        end
    else          
        errlog("\tFailed to load MCT file [" .. filename_for_out .. "], error is: " .. tostring(load_error) .. ". Will attempt to require() this file to generate a more meaningful error message:")

        local require_result, require_error = pcall(require, filename)

        if require_result then
            errlog("require() seemed to be able to load file [" .. filename .. "] with filename [" .. filename_for_out .. "], where loadfile failed? Maybe the file is loaded, maybe it isn't - proceed with caution!")
            --return true
        else
            -- strip tab and newline characters from error string
            log("\t\t" .. string.gsub(string.gsub(require_error, "\t", ""), "\n", ""))
            return false
        end
    end

    -- finalize all mods found in this module
    local mods = self:get_mods_from_file(filename_for_out)
    for _, mod in pairs(mods) do
        mod:finalize()
    end
end

function mod_configuration_tool:load_mods()
    log("********")
    log("LOADING SETTINGS SCRIPTS")
    log("********")

    package.path = self._settings_path .. "?.lua;" .. package.path

    local file_str = effect.filesystem_lookup(self._settings_path, "*.lua")
    for filename in string.gmatch(file_str, '([^,]+)') do
        local filename_for_out = filename

        local pointer = 1
        while true do
            local next_sep = string.find(filename, "\\", pointer) or string.find(filename, "/", pointer)

            if next_sep then
                pointer = next_sep + 1
            else
                if pointer > 1 then
                    filename = string.sub(filename, pointer)
                end
                break
            end
        end

        local suffix = string.sub(filename, string.len(filename) - 3)

        if string.lower(suffix) == ".lua" then
            filename = string.sub(filename, 1, string.len(filename) -4)
        end

        --[[if package.loaded[filename] then
            log("yes!")
            return false
        end]]

        self:load_mod(filename, filename_for_out)
    end

    log("********")
    log("FINISHED LOADING SETTINGS")
    log("********")
end

function mod_configuration_tool:set_selected_mod(mod_name)
    self._selected_mod = mod_name
end

function mod_configuration_tool:get_selected_mod_name()
    return self._selected_mod
end

---@return mct_mod
function mod_configuration_tool:get_selected_mod()
    return is_string(self:get_selected_mod_name()) and self:get_mod_by_key(self:get_selected_mod_name())
end

function mod_configuration_tool:has_mod_with_name_been_registered(mod_name)
    return not not self._registered_mods[mod_name]
end

function mod_configuration_tool:get_mod_with_name(mod_name)
    return self:get_mod_by_key(mod_name)
end

--- Internal use only. Triggers all the functionality for "Finalize Settings!"
function mod_configuration_tool:finalize(specific_mod)
    local ok, msg = pcall(function()
    if __game_mode == __lib_type_campaign then
        -- check if it's MP!
        if cm.game_interface:model():is_multiplayer() then
            -- check if it's the host
            if cm:get_local_faction_name(true) == cm:get_saved_value("mct_host") then
                log("Finalizing settings mid-campaign for MP.")
                self.settings:finalize(false, specific_mod)

                self._finalized = true
                self.ui.locally_edited = false

                -- communicate to both clients that this is happening!
                local mct_data = {}
                local all_mods = self:get_mods()
                for mod_key, mod_obj in pairs(all_mods) do
                    log("Looping through mod obj ["..mod_key.."]")
                    mct_data[mod_key] = {}
                    local all_options = mod_obj:get_options()

                    for option_key, option_obj in pairs(all_options) do
                        if not option_obj:get_local_only() then
                            log("Looping through option obj ["..option_key.."]")
                            mct_data[mod_key][option_key] = {}

                            log("Setting: "..tostring(option_obj:get_finalized_setting()))

                            mct_data[mod_key][option_key]._setting = option_obj:get_finalized_setting()
                        else
                            --?
                        end
                    end
                end
                ClMultiplayerEvents.notifyEvent("MctMpFinalized", 0, mct_data)

                self.settings:local_only_finalize(true)
            else
                self._finalized = true
                self.ui.locally_edited = false
                
                self.settings:local_only_finalize(false)
            end
        else
            -- it's SP, do regular stuff
            self.settings:finalize(false, specific_mod)

            self._finalized = true
    
            -- remove the "locally_edited" field
            self.ui.locally_edited = false
    
            core:trigger_custom_event("MctFinalized", {["mct"] = self, ["mp_sent"] = false})
        end
    else
        self.settings:finalize(false, specific_mod)

        self._finalized = true

        -- remove the "locally_edited" field
        self.ui.locally_edited = false

        core:trigger_custom_event("MctFinalized", {["mct"] = self, ["mp_sent"] = false})
    end
     end) if not ok then errlog(msg) end
end

--- Getter for the @{mct_mod} with the supplied key.
---@param mod_name string Unique identifier for the desired mct_mod.
---@return mct_mod
function mod_configuration_tool:get_mod_by_key(mod_name)
    if not is_string(mod_name) then
        errlog("get_mod_by_key() called, but the mod_name provided ["..tostring(mod_name).."] is not a string!")
        return nil
    end
    
    local test = self._registered_mods[mod_name]
    if type(test) == "nil" then
        errlog("Trying to get mod with name ["..mod_name.."] but none is found! Returning nil.")
        return nil
    end
        
    return self._registered_mods[mod_name]
end

---@return mct_mod[]
function mod_configuration_tool:get_mods()
    return self._registered_mods
end

function mod_configuration_tool:get_mods_from_file(filepath)
    local mod_list = self._registered_mods
    local retval = {}
    for key, mod in pairs(mod_list) do
        local compare_path = mod._FILEPATH

        if compare_path == filepath then
            retval[key] = mod
        end
    end

    return retval
end

--- Primary function to begin adding settings to a "mod".
--- Calls the internal function @{mct_mod.new}.
--- @param mod_name string The identifier for this mod.
--- @see mct_mod.new
---@return mct_mod
function mod_configuration_tool:register_mod(mod_name)
    -- get info about where this function was called from, to save that Lua file as a part of the mod obj
    local info = debug.getinfo(2, "S")
    local filepath = info.source
    if self:has_mod_with_name_been_registered(mod_name) then
        errlog("Loading mod with name ["..mod_name.."], but it's already been registered. Only use `mct:register_mod()` once. Returning the previous version.")
        return self:get_mod_by_key(mod_name)
    end

    if mod_name == "mct_cached_settings" then
        errlog("mct:register_mod() called with key \"mct_cached_settings\". Why have you tried to do this? Use a different key.")
        return false
    end

    local new_mod = self._MCT_MOD.new(mod_name)
    new_mod._FILEPATH = filepath
    self._registered_mods[mod_name] = new_mod

    return new_mod
end

--- Type-checker for @{mct_mod}s
--- @param obj any Tested value.
--- @return boolean Whether it passes.
function mod_configuration_tool:is_mct_mod(obj)
    return tostring(obj):find("MCT_MOD [")
end

--- Type-checker for @{mct_option}s
--- @param obj any Tested value.
--- @return boolean Whether it passes.
function mod_configuration_tool:is_mct_option(obj)
    return tostring(obj):find("MCT_OPTION [")
end

--- Type-checker for @{mct_section}s
--- @param obj any Tested value.
--- @return boolean Whether it passes.
function mod_configuration_tool:is_mct_section(obj)
    return tostring(obj):find("MCT_SECTION [")
end

--- Type-checker for @{mct_option} types.
--- @param val any Tested value.
--- @return boolean Whether it passes.
function mod_configuration_tool:is_valid_option_type(val)
    return self._MCT_TYPES[val] ~= nil
end

function mod_configuration_tool:get_valid_option_types()
    local retval = {}
    for k,_ in pairs(self._MCT_TYPES) do
        if k ~= "template" then
            retval[#retval+1] = k
        end
    end

    return retval
end

function mod_configuration_tool:get_valid_option_types_table()
    local types = self:get_valid_option_types()
    local o = {}

    for i = 1, #types do
        local type = types[i]
        o[type] = {}
    end

    return o
end

return mod_configuration_tool
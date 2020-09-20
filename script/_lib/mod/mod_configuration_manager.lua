---- Mod Configuration Tool Manager
--- @class mct
--- @alias mod_configuration_tool mct

-- Define the manager that will be used for the majority of all these operations
local mod_configuration_tool = {
    __tostring = "MOD_CONFIGURATION_TOOL",

    _filepath = "/script/mct/settings/",
    _logpath = "mct_log.txt",

    -- default to false
    _finalized = false,
    _initialized = false,
    _first_load = false,

    write_to_log = true,

    _registered_mods = {},
    _selected_mod = nil,

    ui_created_callbacks = {},

    callback_int = 0,
}


--- startup function
function mod_configuration_tool:init()
    -- initialize the log
    self:log_init()

    -- load modules!
    --local ok, err = pcall(function()
        self:log("********")
        self:log("LOADING INTERNAL MODULES")
        self:log("********")

        -- add the modules and modules/extern/ paths to the Lua field
        local path = "script/mct/modules/?.lua;"
        package.path = path .. package.path

        -- load vandy-lib stuff
        self:load_module("uic_mixins", "script/mct/modules/")

        self._MCT_TYPES = {}
        local ok, err = pcall(function()
        self._MCT_TYPES.template = self:load_module("zzz_template", "script/mct/modules/types/")
        self._MCT_TYPES.slider = self:load_module("slider", "script/mct/modules/types/")
        self._MCT_TYPES.dropdown = self:load_module("dropdown", "script/mct/modules/types/")
        self._MCT_TYPES.checkbox = self:load_module("checkbox", "script/mct/modules/types/")
        self._MCT_TYPES.text_input = self:load_module("text_input", "script/mct/modules/types/")
        --self._MCT_TYPES.multibox = self:load_module("multibox", "script/mct/modules/types/")
        self._MCT_TYPES.dummy = self:load_module("dummy", "script/mct/modules/types/")


        -- load MCT object modules
        self._MCT_OPTION = self:load_module("option_obj", "script/mct/modules/")
        self._MCT_MOD = self:load_module("mod_obj", "script/mct/modules/")
        self._MCT_SECTION = self:load_module("section_obj", "script/mct/modules/")

        end) if not ok then self:error(err) end

        -- load the settings and UI files last
        self.settings = self:load_module("settings", "script/mct/modules/")
        self.ui = self:load_module("ui", "script/mct/modules/")

        -- load mods in mct/settings/!
        self:load_mods()

        --self:load_and_start(loading_game_context, is_mp)
    --end)
    --if not ok then self:log(err) end
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
    --local ok, err = pcall(function()
    self:init()

    core:add_listener(
        "who_is_the_host_tell_me_now_please",
        "UITriggerScriptEvent",
        function(context)
            self:log("test uitriggerscroptevent")
            self:log(context:trigger())
            return context:trigger():starts_with("mct_host|")
        end,
        function(context)
            self:log('does this trigger pls')
            local str = context:trigger()
            local faction_key = string.gsub(str, "mct_host|", "")

            cm:set_saved_value("mct_host", faction_key)

            self:log('yes hey cool ['..faction_key..']')

            self.settings:mp_load()
        end,
        false
    )

    
    local function trigger(is_multi)
        self:log("Triggering MctInitialized, enjoy")
        core:trigger_custom_event("MctInitialized", {["mct"] = self, ["is_multiplayer"] = is_multi})
    end

    -- TODO offload this elsewhere?
    self:log("load and start!")
    if __game_mode == __lib_type_campaign then
        self:log("is campaign yes yes")
        if is_mp then
            self:log("is mp yerp")
            
            cm:add_pre_first_tick_callback(function()
                if not cm:get_saved_value("mct_mp_init") then
                    self:log("MP init")
                    --if cm:is_new_game() then
                        local my_faction = cm:get_local_faction(true)
                        --[[local their_faction = ""
                        local faction_keys = cm:get_human_factions()
                        if faction_keys[1] == my_faction then
                            their_faction = faction_keys[2]
                        else
                            their_faction = faction_keys[1]
                        end]]
        
                        local is_host = core:svr_load_bool("local_is_host")
                        self:log("local faction: "..my_faction)
                        self:log("is_host: "..tostring(is_host))
                        if is_host then
                            self:log("triggering scropt event")
                            CampaignUI.TriggerCampaignScriptEvent(0, "mct_host|"..my_faction)
                            self:log("mp scropt event sent")
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
            self:log("someone's playing alone :(")
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
        --self:log("frontend?")
        -- read the settings file
        local ok, err = pcall(function()
            self:log("LOADING SETTINGS")
            self.settings:load()
            self:log("END - MctInitializing!")

            trigger(false)
        end) if not ok then self:error(err) end
    end

    local new_options_added = {}
    local booly = false

    local function start_delay()
        core:add_listener(
            "do_stuff",
            "RealTimeTrigger",
            function(context)
                return context.string == "mct_new_option_created"
            end,
            function(context)
                local mod_keys = {}

                for k,_ in pairs(new_options_added) do
                    self:log("Adding mod key: "..k)
                    mod_keys[#mod_keys+1] = k
                end

                local key = context.string
                local text = effect.get_localised_string("mct_new_settings_created_start") .. "\n\n" .. effect.get_localised_string("mct_new_settings_created_mid") .. "\n"

                for i = 1, #mod_keys do
                    local mod_obj = self:get_mod_by_key(mod_keys[i])
                    local mod_title = mod_obj:get_title()

                    if 1 == #mod_keys then
                        text = text .. "\"" .. mod_title .. "\"" .. ". "
                    else

                        if i == #mod_keys then
                            text = text .. "and \"" .. mod_title .. "\"" .. ". "
                        else
                            text = text .. "\"" .. mod_title .. "\"" .. ", "
                        end
                    end

                end

                local function highlight_stuffs()
                    local currently_selected_mod = self:get_selected_mod()
                    local mod_key = currently_selected_mod:key()

                    -- highlight all new options in currently selected mod
                    if not is_nil(new_options_added[mod_key]) then
                        local options_added = new_options_added[mod_key]
                        for i = 1, #options_added do
                            local option_key = options_added[i]
                            local option_obj = currently_selected_mod:get_option_by_key(option_key)
                            if not self:is_mct_option(option_obj) then
                                -- errmsg
                            else
                                option_obj:highlight_in_ui()
                            end
                        end
                    end

                    -- highlight all unselected mods (and stash the options they have to higlight)
                    for stashed_mod_key, options in pairs(new_options_added) do
                        if stashed_mod_key == mod_key then
                            -- skip
                        else
                            local mod_obj = self:get_mod_by_key(stashed_mod_key)
                            if not self:is_mct_mod(mod_obj) then
                                -- errmsg
                            else
                                mod_obj:highlight_in_ui(options)
                            end
                        end
                    end 
                end

                self.ui:create_popup(
                    key,
                    function()
                        if not self.ui.opened then
                            return text .. "\n" .. effect.get_localised_string("mct_new_settings_created_end")
                        else
                            return text
                        end
                    end,
                    function()
                        if not self.ui.opened then
                            return true
                        else
                            return false
                        end
                    end,
                    function()
                        if self.ui.opened then
                            self:callback(highlight_stuffs, 5)
                        else
                            -- open the frame and then do the same higlight thing as above
                            self.ui:open_frame()
                            
                            -- do a 5ms callback to make sure the panel opens up and all in time
                            self:callback(highlight_stuffs, 5)
                        end
                    end,
                    function()
                        -- do nothing?
                    end
                )

                booly = false
                new_options_added = {}
            end,
            false
        )

        -- trigger above listener in 0.1s
        real_timer.register_singleshot("mct_new_option_created", 100)
    end

    self:log("check new options post")

    self._initialized = true

    -- check for new options created after MCT has been started and loaded.
    -- ~2s after a new option has been created, trigger a popup. This'll prevent triggering like 60 popups if 60 new options are added within a tick or two.
    core:add_listener(
        "mct_new_option_created",
        "MctNewOptionCreated",
        true,
        function(context)
            if not booly then
                -- in 2.5s, trigger the popup
                booly = true
                start_delay()
                
            end

            local mod_key = context:mod():get_key()
            local option_key = context:option():get_key()

            if is_nil(new_options_added[mod_key]) then
                new_options_added[mod_key] = {}
            end

            self:log("New option added for mod: "..option_key)

            local tab = new_options_added[mod_key]

            tab[#tab+1] = option_key
        end,
        true
    )
--end) if not ok then self:error(err) end
end

function mod_configuration_tool:callback(callback_function, time_delay)
    if not is_function(callback_function) then
        -- errmsg
        return false
    end

    if not is_number(time_delay) then
        -- errmsg
        return false
    end

    self.callback_int = self.callback_int +1

    core:add_listener(
        "do_stuff",
        "RealTimeTrigger",
        function(context)
            return context.string == "do_stuff"..tostring(self.callback_int)
        end,
        function(context)
            callback_function()
        end,
        false
    )

    real_timer.register_singleshot("do_stuff"..tostring(self.callback_int), time_delay)
end

function mod_configuration_tool:log_init()
    --[[local num = 1
    local log = "mct_log"..num..".txt"
    if io.open(log, "r") ~= nil then
        ModLog("MCT_LOG1 EXISTS")
        num = 2
        log = "mct_log"..num..".txt"
    else
        ModLog("NO MCT_LOG1 EXISTS")
    end]]

    ModLog("mct:log_init() started")
    local first_load = true --core:svr_load_persistent_bool("mct_init") ~= true

    if first_load then
        --core:svr_save_persistent_bool("mct_init", true)

        local file = io.open(self._logpath, "w+")
        file:write("NEW LOG INITIALIZED \n")
        local time_stamp = os.date("%d, %m %Y %X")
        file:write("[" .. time_stamp .. "]\n")
        file:close()
    else
        local i_to_game_mode = {
            [0] = "BATTLE",
            [1] = "CAMPAIGN",
            [2] = "FRONTEND",
        }

        local game_mode = i_to_game_mode[__game_mode]

        local file = io.open(self._logpath, "a+")
        file:write("**********\nNEW GAME MODE: "..game_mode)
        local time_stamp = os.date("%d, %m %Y %X")
        file:write("[" .. time_stamp .. "]\n")
        file:close()
    end

    --self._logpath = log

    --return num
end

--- Basic logging function for outputting text into the MCT log file.
--- @tparam string text The string used for output
function mod_configuration_tool:log(text)
    if not is_string(text) and not is_number(text) then
        return false
    end

    if not self.write_to_log then
        return false
    end

    local file = io.open(self._logpath, "a+")

    local timestamp = get_timestamp()
    file:write(tostring(timestamp) .. "\t" .. text .. "\n")
    file:close()
end

--- Basic warning logging function for outputting text into the MCT log file.
--- @tparam string text The string used for output
function mod_configuration_tool:warn(text)
    if not is_string(text) and not is_number(text) then
        return false
    end

    if not self.write_to_log then
        return false
    end

    local file = io.open(self._logpath, "a+")

    local timestamp = get_timestamp()
    file:write(tostring(timestamp).."\tWARNING: " .. text .. "\n")
    --file:write(debug.traceback("", 2) .. "\n")
    file:close()
end

--- Basic error logging function for outputting text into the MCT log file.
--- @tparam string text The string used for output
function mod_configuration_tool:error(text)
    if not is_string(text) and not is_number(text) then
        return false
    end

    if not self.write_to_log then
        return false
    end

    local file = io.open(self._logpath, "a+")

    local timestamp = get_timestamp()

    file:write(tostring(timestamp).."\tERROR: " .. text .. "\n")
    file:write(debug.traceback("", 2) .. "\n")
    file:close()
end

--- For internal use, loads specific mod files located in `script/mct/settings/`. 
--- Any .lua file found in here is given the MCT manager as the variable `mct` within the full scope of the file.
--- @tparam string filename The filename being required and loaded.
--- @tparam string filename_for_out The original filename with the full directory path still included; used for outputs.
function mod_configuration_tool:load_mod(filename, filename_for_out)
    self:log("Loading MCT module with name [" .. filename_for_out .."]")

    local loaded_file, load_error = loadfile(filename)

    if loaded_file then
        local global_env = core:get_env()

        local attach_env = {}
        setmetatable(attach_env, {__index = global_env})
        
        attach_env.mct = self
        attach_env.core = core

        setfenv(loaded_file, attach_env)

        package.loaded[filename] = true

        -- run the file!
        local ok, err = pcall(loaded_file)

        -- if it didn't work, 
        if not ok then
            self:error("Failed to execute loaded MCT file [" .. filename_for_out .. "], error is: " .. tostring(err))
            return false
        end
    else          
        self:error("\tFailed to load MCT file [" .. filename_for_out .. "], error is: " .. tostring(load_error) .. ". Will attempt to require() this file to generate a more meaningful error message:")

        local require_result, require_error = pcall(require, filename)

        if require_result then
            self:warn("require() seemed to be able to load file [" .. filename .. "] with filename [" .. filename_for_out .. "], where loadfile failed? Maybe the file is loaded, maybe it isn't - proceed with caution!")
            --return true
        else
            -- strip tab and newline characters from error string
            self:log("\t\t" .. string.gsub(string.gsub(require_error, "\t", ""), "\n", ""))
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
    self:log("********")
    self:log("LOADING SETTINGS SCRIPTS")
    self:log("********")

    package.path = self._filepath .. "?.lua;" .. package.path

    local file_str = effect.filesystem_lookup(self._filepath, "*.lua")
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
            self:log("yes!")
            return false
        end]]

        self:load_mod(filename, filename_for_out)
    end

    self:log("********")
    self:log("FINISHED LOADING SETTINGS")
    self:log("********")
end

--- Internal loader for scripts located in `script/mct/modules/`.
--- @tparam string module_name The .lua file name. Exclude the ".lua" part of it!
--- @tparam string path The path to find this .lua file. Make sure package.path has been editing before this function is called!
function mod_configuration_tool:load_module(module_name, path)
    --[[if package.loaded[module_name] then
        return 
    end]]

    local full_file_name = path .. module_name .. ".lua"

    local file, load_error = loadfile(full_file_name)

    if not file then
        self:error("Attempted to load module with name ["..module_name.."], but loadfile had an error: ".. load_error .."")
        --return
    else
        self:log("Loading module with name [" .. module_name .. ".lua]")

        local global_env = core:get_env()
        local attach_env = {}
        setmetatable(attach_env, {__index = global_env})

        -- pass valuable stuff to the modules
        attach_env.mct = self
        --attach_env.core = core

        setfenv(file, attach_env)
        local lua_module = file(module_name)
        package.loaded[module_name] = lua_module or true

        self:log("[" .. module_name .. ".lua] loaded successfully!")

        --if module_name == "mod_obj" then
        --    self.mod_obj = lua_module
        --end

        --self[module_name] = lua_module

        return lua_module
    end

    local ok, err = pcall(function() require(module_name) end)

    --if not ok then
        self:error("Tried to load module with name [" .. module_name .. ".lua], failed on runtime. Error below:")
        self:error(err)
        return false
    --end
end

function mod_configuration_tool:set_selected_mod(mod_name)
    self._selected_mod = mod_name
end

function mod_configuration_tool:get_selected_mod_name()
    return self._selected_mod
end

function mod_configuration_tool:get_selected_mod()
    return self:get_mod_by_key(self:get_selected_mod_name())
end

function mod_configuration_tool:has_mod_with_name_been_registered(mod_name)
    return not not self._registered_mods[mod_name]
end

function mod_configuration_tool:get_mod_with_name(mod_name)
    return self:get_mod_by_key(mod_name)
end

--- Internal use only. Triggers all the functionality for "Finalize Settings!"
function mod_configuration_tool:finalize(specific_mod)
    local ok, err = pcall(function()
    if __game_mode == __lib_type_campaign then
        -- check if it's MP!
        if cm.game_interface:model():is_multiplayer() then
            -- check if it's the host
            if cm:get_local_faction(true) == cm:get_saved_value("mct_host") then
                self:log("Finalizing settings mid-campaign for MP.")
                self.settings:finalize(false, specific_mod)

                self._finalized = true
                self.ui.locally_edited = false

                -- communicate to both clients that this is happening!
                local mct_data = {}
                local all_mods = self:get_mods()
                for mod_key, mod_obj in pairs(all_mods) do
                    self:log("Looping through mod obj ["..mod_key.."]")
                    mct_data[mod_key] = {}
                    local all_options = mod_obj:get_options()

                    for option_key, option_obj in pairs(all_options) do
                        if not option_obj:get_local_only() then
                            self:log("Looping through option obj ["..option_key.."]")
                            mct_data[mod_key][option_key] = {}

                            self:log("Setting: "..tostring(option_obj:get_finalized_setting()))

                            mct_data[mod_key][option_key]._setting = option_obj:get_finalized_setting()
                        else
                            --?
                        end
                    end
                end
                ClMultiplayerEvents.notifyEvent("MctMpFinalized", 0, mct_data)

                self.settings:local_only_finalize(true)
            else
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
     end) if not ok then self:error(err) end
end

--- Getter for the @{mct_mod} with the supplied key.
--- @tparam string mod_name Unique identifier for the desired mct_mod.
--- @treturn mct_mod
function mod_configuration_tool:get_mod_by_key(mod_name)
    if not is_string(mod_name) then
        self:error("get_mod_by_key() called, but the mod_name provided ["..tostring(mod_name).."] is not a string!")
        return nil
    end
    
    local test = self._registered_mods[mod_name]
    if type(test) == "nil" then
        self:warn("Trying to get mod with name ["..mod_name.."] but none is found! Returning nil.")
        return nil
    end
        
    return self._registered_mods[mod_name]
end

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
--- @tparam string mod_name The identifier for this mod.
--- @see mct_mod.new
function mod_configuration_tool:register_mod(mod_name)
    -- get info about where this function was called from, to save that Lua file as a part of the mod obj
    local info = debug.getinfo(2, "S")
    local filepath = info.source
    if self:has_mod_with_name_been_registered(mod_name) then
        self:log("Loading mod with name ["..mod_name.."], but it's already been registered. Only use `mct:register_mod()` once. Returning the previous version.")
        return self:get_mod_by_key(mod_name)
    end

    local new_mod = self._MCT_MOD.new(mod_name)
    new_mod._FILEPATH = filepath
    self._registered_mods[mod_name] = new_mod

    return new_mod
end

--- Type-checker for @{mct_mod}s
--- @tparam any obj Tested value.
--- @treturn boolean Whether it passes.
function mod_configuration_tool:is_mct_mod(obj)
    return tostring(obj) == "MCT_MOD"
end

--- Type-checker for @{mct_option}s
--- @tparam any obj Tested value.
--- @treturn boolean Whether it passes.
function mod_configuration_tool:is_mct_option(obj)
    return tostring(obj) == "MCT_OPTION"
end

--- Type-checker for @{mct_section}s
--- @tparam any obj Tested value.
--- @treturn boolean Whether it passes.
function mod_configuration_tool:is_mct_section(obj)
    return tostring(obj) == "MCT_SECTION"
end

--- Type-checker for @{mct_option} types.
--- @tparam any val Tested value.
--- @treturn boolean If this is a valid option type.
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


--- This is just `get_mct()`, the documentation program is being stupid.
--- Global getter for the mct object.
--- @static
--- @function get_mct
--- @treturn mct
--- @within API
function get_mct()
    return core:get_static_object("mod_configuration_tool")
    --return mod_configuration_tool
end

core:add_static_object("mod_configuration_tool", mod_configuration_tool, false)

--mod_configuration_tool:init()

_G.get_mct = get_mct

-- REMOVE THIS
core:add_listener(
    "a",
    "ShortcutPressed",
    true,
    function(context)
        ModLog("ShortcutPressed:")
        ModLog(context.string)
    end,
    true
)

core:add_listener(
    "b",
    "ShortcutTriggered",
    true,
    function(context)
        ModLog("ShortcutTriggered:")
        ModLog(context.string)
    end,
    true
)
--- Mod Configuration Tool Manager
-- @classmod mct
-- @alias mod_configuration_tool

-- Define the manager that will be used for the majority of all these operations
---@class mct
local mod_configuration_tool = {
    __tostring = "MOD_CONFIGURATION_TOOL",

    _filepath = "/script/mct/settings/",
    _logpath = "mct_log.txt",


    write_to_log = true,

    _registered_mods = {},
    _selected_mod = nil
}

-- startup function
function mod_configuration_tool:init(loading_game_context)
    -- initialize the log
    self:log_init()

    -- load modules!
    local ok, err = pcall(function()
        self:log("********\nLOADING INTERNAL MODULES\n********")

        -- add the modules and modules/extern/ paths to the Lua field
        local path = "script/mct/modules/?.lua;script/mct/modules/extern/?.lua;"
        package.path = path .. package.path

        -- load external vendors, not my work at all, all rights reserved, copyright in these files stands
        --self.json = self:load_module("json", "script/mct/modules/extern/") 
        --self.inspect = self:load_module("inspect", "script/mct/modules/extern/")

        -- load vandy-lib stuff
        self:load_module("uic_mixins", "script/mct/modules/")

        -- load MCT object modules
        self._MCT_OPTION = self:load_module("option_obj", "script/mct/modules/")
        self._MCT_MOD = self:load_module("mod_obj", "script/mct/modules/")

        -- load the settings and UI files last
        self.settings = self:load_module("settings", "script/mct/modules/")
        self.ui = self:load_module("ui", "script/mct/modules/")

        -- load mods in mct/settings/!
        self:load_mods()

        if __game_mode == __lib_type_campaign then
            -- if it's a new game, read the settings file and save that into the save file
            if cm:is_new_game() then
                self.settings:load()
            else
                self.settings:load_game_callback(loading_game_context)
            end

            cm:add_saving_game_callback(function(context) self.settings:save_game_callback(context) end)
            --cm:add_loading_game_callback(function(context)
                
            --end)
        else
            -- read the settings file
            self.settings:load()
        end
    end)
    if not ok then self:log(err) end

    core:add_static_object("mod_configuration_tool", self, false)

    core:trigger_custom_event("MctInitialized", {["mct"] = self})
end

function mod_configuration_tool:log_init()
    local file = io.open(self._logpath, "w+")
    file:write("NEW LOG INITIALIZED \n")
    local time_stamp = os.date("%d, %m %Y %X")
    file:write("[" .. time_stamp .. "]\n")
    file:close()
end

--- Basic logging function for outputting text into the MCT log file.
-- @tparam string text The string used for output
function mod_configuration_tool:log(text)
    if not is_string(text) and not is_number(text) then
        return false
    end

    if not self.write_to_log then
        return false
    end

    local file = io.open(self._logpath, "a+")
    file:write(text .. "\n")
    file:close()
end

--- Basic error logging function for outputting text into the MCT log file.
-- @tparam string text The string used for output
function mod_configuration_tool:error(text)
    if not is_string(text) and not is_number(text) then
        return false
    end

    if not self.write_to_log then
        return false
    end

    local file = io.open(self._logpath, "a+")
    file:write("ERROR: " .. text .. "\n")
    file:write(debug.traceback("", 2) .. "\n")
    file:close()
end

--- For internal use, loads specific mod files located in `script/mct/settings/`. 
-- Any .lua file found in here is given the MCT manager as the variable `mct` within the full scope of the file.
-- @tparam string filename The filename being required and loaded.
-- @tparam string filename_for_out The original filename with the full directory path still included; used for outputs.
function mod_configuration_tool:load_mod(filename, filename_for_out)
    self:log("Loading MCT module with name [" .. filename_for_out .."]")

    local loaded_file, load_error = loadfile(filename)

    if loaded_file then
        local env = core:get_env()
        env.mct = self
        env.core = core

        setfenv(loaded_file, env)

        package.loaded[filename] = true

        -- run the file!
        local ok, err = pcall(loaded_file)

        -- if it didn't work, 
        if not ok then
            self:error("Failed to execute loaded mod file [" .. filename_for_out .. "], error is: " .. tostring(err))
            return false
        end
    else          
        self:error("\tFailed to load mod file [" .. filename_for_out .. "], error is: " .. tostring(load_error) .. ". Will attempt to require() this file to generate a more meaningful error message:")

        local require_result, require_error = pcall(require, filename)

        if require_result then
            self:log("\tWARNING: require() seemed to be able to load file [" .. filename .. "] with filename [" .. filename_for_out .. "], where loadfile failed? Maybe the mod is loaded, maybe it isn't - proceed with caution!")
            --return true
        else
            -- strip tab and newline characters from error string
            self:log("\t\t" .. string.gsub(string.gsub(require_error, "\t", ""), "\n", ""))
            return false
        end
    end

    -- finalize all mods found in this module
    local mods = self:get_mods_from_file(filename_for_out)
    for key, mod in pairs(mods) do
        mod:finalize()
    end
end

function mod_configuration_tool:load_mods()
    self:log("********\nLOADING SETTINGS SCRIPTS\n********")
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

    self:log("********\nFINISHED LOADING SETTINGS\n********")
end

--- Internal loader for scripts located in `script/mct/modules/`.
-- @tparam string module_name The .lua file name. Exclude the ".lua" part of it!
-- @tparam string path The path to find this .lua file. Make sure package.path has been editing before this function is called!
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

--- Getter for the @{mct_mod} with the supplied key.
-- @tparam string mod_name Unique identifier for the desired mct_mod.
-- @return @{mct_mod}
function mod_configuration_tool:get_mod_by_key(mod_name)
    local test = self._registered_mods[mod_name]
    if type(test) == "nil" then
        self:error("Trying to get mod with name ["..mod_name.."] but none is found! Returning nil.")
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

--- Primary function to begin adding settings to a "mod"
-- Calls the internal function "mct_mod.new()"
-- @tparam string mod_name The identifier for this mod.
-- @see mct_mod.new
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

function mod_configuration_tool:is_mct_mod(obj)
    return tostring(obj) == "MCT_MOD"
end

function mod_configuration_tool:is_mct_option(obj)
    return tostring(obj) == "MCT_OPTION"
end

function get_mct()
    return core:get_static_object("mod_configuration_tool")
    --return mod_configuration_tool
end

_G.get_mct = get_mct

-- check if the game mode is campaign - if aye, make the button
-- needed to create the button on the top left corner of the screen

if __game_mode == __lib_type_campaign then
    local function create_campaign_button()
        -- parent for the buttons on the top-left bar
        local button_group = find_uicomponent(core:get_ui_root(), "menu_bar", "buttongroup")
        local new_button = UIComponent(button_group:CreateComponent("button_mct_options", "ui/templates/round_small_button"))

        -- set the tooltip to the one on the frontend button
        new_button:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069"), true)
        new_button:SetImagePath("ui/skins/warhammer2/icon_options.png")

        -- make sure it's on the button group, and set its z-priority to be as high as its parents
        new_button:PropagatePriority(button_group:Priority())
        button_group:Adopt(new_button:Address())
    end

    core:add_ui_created_callback(function() ModLog("Create campaign button") create_campaign_button() ModLog("button end") end)

    core:add_listener(
        "MCT_Init", 
        "LoadingGame", 
        true, 
        function(context) 
            mod_configuration_tool:init(context) 
        end, 
        true
    )
else
    mod_configuration_tool:init()
end
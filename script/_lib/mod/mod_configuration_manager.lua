-- enables more varied usages of the "custom_context" object, so you can supply the function name as well as the object
-- ie., `custom_context:add_data("testing string", "blorp")` will enable you to use `conext:blorp()` to output "testing string". 
function custom_context:add_data_with_key(value, key)
    -- make index optional
    if not is_string(key) then
        script_error("ERROR: adding data to custom context, but the key provided is not a string!")
        return false
    end

    self[key.."_data"] = val
    self[key] = function() return self[key.."_data"] end
end


function core_object:trigger_custom_event(event, data_items)

    -- build an event context
    local context = custom_context:new();

    if not is_string(event) then
        script_error("ERROR: triggering custom event, but the event key provided is not a string!")
        return false
    end

    if not is_table(data_items) then
        -- issue
        script_error("ERROR: triggering custom event, but the data_items arg provided is not a table!")
        return false
    end

    for key, value in pairs(data_items) do
        context:add_data_with_key(value, key)
    end

    local event_table = events[event]
    if event_table then
        for i = 1, #event_table do
            event_table[i](context)
        end
    end
end






-- Define the manager that will be used for the majority of all these operations
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
        -- load vendors first
        self:log("********\nLOADING INTERNAL MODULES\n********")
        self:load_module("json") 
        self:load_module("inspect")

        -- load vandy-lib stuff
        self:load_module("uic_mixins")

        -- load self-made modules
        self:load_module("option_obj")
        self:load_module("mod_obj")

        self:load_module("settings")
        self:load_module("ui")

        -- load mods in mct/settings/!
        self:load_mods() 

        if __game_mode == __lib_type_campaign then
            -- if it's a new game, read the settings file and save that into the save file
            if cm:is_new_game() then
                cm:add_saving_game_callback(function(context) self.settings:save_game_callback(context) end)
            end
                
            self.settings:load_game_callback(loading_game_context)
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

function mod_configuration_tool:error(text)
    if not is_string(text) and not is_number(text) then
        return false
    end

    if not self.write_to_log then
        return false
    end

    local file = io.open(self._logpath, "a+")
    file:write("ERROR: " .. text .. "\n")
    file:close()
end

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

function mod_configuration_tool:load_module(module_name)
    if package.loaded[module_name] then
        return 
    end

    local path = "script/mct/modules/"
    package.path = path .. "?.lua;".. package.path

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
        attach_env.core = core

        setfenv(file, attach_env)
        local lua_module = file(module_name)
        package.loaded[module_name] = lua_module or true

        self:log("[" .. module_name .. ".lua] loaded successfully!")

        --if module_name == "mod_obj" then
        --    self.mod_obj = lua_module
        --end

        --self[module_name] = lua_module

        return
    end

    local ok, err = pcall(function() require(module_name) end)

    if not ok then
        self:error("Tried to load module with name [" .. module_name .. ".lua], failed on runtime. Error below:")
        self:error(err)
        return false
    end
end

function mod_configuration_tool:set_selected_mod(mod_name)
    self._selected_mod = mod_name
end

function mod_configuration_tool:get_selected_mod_name()
    return self._selected_mod
end

function mod_configuration_tool:get_selected_mod()
    return self:get_mod_with_name(self:get_selected_mod_name())
end

function mod_configuration_tool:has_mod_with_name_been_registered(mod_name)
    return not not self._registered_mods[mod_name]
end

function mod_configuration_tool:get_mod_with_name(mod_name)
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

function mod_configuration_tool:register_mod(mod_name)
    -- get info about where this function was called from, to save that Lua file as a part of the mod obj
    local info = debug.getinfo(2, "S")
    local filepath = info.source
    if self:has_mod_with_name_been_registered(mod_name) then
        self:log("Loading mod with name ["..mod_name.."], but it's already been registered. Only use `mct:register_mod()` once. Returning the previous version.")
        return self:get_mod_with_name(mod_name)
    end

    local new_mod = self._MCT_MOD.new(mod_name)
    new_mod._FILEPATH = filepath
    self._registered_mods[mod_name] = new_mod

    return new_mod
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
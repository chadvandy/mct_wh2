--- Settings Object. INTERNAL USE ONLY.
-- @classmod mct_settings

-- TODO multiplayer shit

local mct = mct

local settings = {
    settings_file = "mct_settings.lua",
    tab = 0
}

local tab = 0

local function run_through_table(tabul, str)
    if not is_table(tabul) then
        mct:log("run_through_table() called but the table supplied isn't actually a table!")
		-- issue
		return str
    end

    tab = tab + 1
    
    --[[local excluded_indices = {
        --_FILEPATH = true,
        _uics = true,
        _mod = true,
        -- _template = true,
    }]]

    for k,v in pairs(tabul) do
        local t = ""
        for i = 1, tab do t = t .. "\t" end
        if is_string(k) then
            str = str .. t.."[\""..k.."\"] = "
        elseif is_number(k) then
            str = str .. t.. "["..k.."] = "
        end
        

        if is_table(v) then
            -- if it's an empty table, just do "{},"
            if next(v) == nil then 
                str = str .. "{},\n" 
            else
                str = str .. "{\n"
                str = run_through_table(v, str)
                str = str .. t .. "},\n"
            end
        else
            if is_string(v) then
                str = str .. "\"" .. v .. "\"" .. ",\n"
            elseif is_number(v) or is_boolean(v) then
                str = str .. tostring(v) .. ",\n"
            end
        end
    end

	tab = tab - 1

	--str = str .. "}"

	return str
end

function settings:save_mct_settings(data)
    local file = io.open(self.settings_file, "w+")

    local str = "return {\n"

    --mct:log("starting run through table")
    str = run_through_table(data, str)
    --mct:log("ending run through table")

    str = str .. "}"

    file:write(str)
    file:close()
end

function settings:finalize()
    --mct:log("Finalizing Settings!")
    local ret = {}
    local mods = mct:get_mods()

    -- don't save specific indices that will absolutely break shit or waste space if they're saved to Lua
    --[[local excluded_indices = {
        _FILEPATH = true,
        _uics = true,
        _mod = true,
        _template = true,
    }]]

    for key, mod in pairs(mods) do
        mct:log("Finalized mod ["..key.."]")
        mod:finalize_settings()

        local data = {}

        local options = mod:get_options()
        for option_key, option_obj in pairs(options) do
            data[option_key] = {}
            data[option_key]._setting = option_obj:get_finalized_setting()
            data[option_key]._read_only = option_obj:get_read_only()
        end

        ret[key] = data
    end

    self:save_mct_settings(ret)
end

function settings:load()
    local file = io.open(self.settings_file, "r")
    if not file then
        -- first time load, no settings file exists!
    else

        mct:log("Loading settings file!")
        local content = loadfile(self.settings_file)
        content = content()

        --local content = table.load(self.settings_file)
        for mod_key, data in pairs(content) do
            mct:log("Loading settings for mod ["..mod_key.."].")

            local mod_obj = mct:get_mod_by_key(mod_key)

            if not mct:is_mct_mod(mod_obj) then
                mct:error("Running settings:load(), but a mct_mod in the mct_data with key ["..mod_key.."] is not a valid mct_mod! Skipping!")
            else
            --mod_obj._finalized_setings = data

                for option_key, option_data in pairs(data) do
                    local option_obj = mod_obj:get_option_by_key(option_key)

                    if not mct:is_mct_option(option_obj) then
                        mct:error("Running settings:load(), but an option in the mct_data ["..option_key.."] is not a valid option for mct_mod ["..mod_key.."]. Skipping!")
                    else
                        mct:log("Finalizing option ["..option_key.."] with setting ["..tostring(option_data._setting).."]")

                        local setting = option_data._setting
                        if is_nil(setting) then
                            setting = option_obj:get_finalized_setting()
                        end

                        local read_only = option_data._read_only
                        if is_nil(read_only) then
                            read_only = option_obj:get_read_only()
                        end

                        option_obj:set_finalized_setting_event_free(setting)
                        option_obj:set_read_only(read_only)
                    end
                end
                
                mod_obj:load_finalized_settings()
            end
        end
    end
end

-- load saved details for all mods 
function settings:load_game_callback(context)
    local retval = {}

    local mods = mct:get_mods()

    for mod_key, mod_obj in pairs(mods) do
        local saved_data = cm:load_named_value("mct_"..mod_key, {}, context)
        
        -- check if there's anything actually saved for this mod key
        if is_table(saved_data) then
            for option_key, option_data in pairs(saved_data) do
                local option_obj = mod_obj:get_option_by_key(option_key)
                if option_obj then
                    -- save the option details in Lua-state
                    option_obj:set_finalized_setting_event_free(option_data._setting)
                    option_obj:set_read_only(option_data.read_only)
                end
            end
        end
    end
end

--[[ TODO improve this so it
        A) triggers immediately on a new game, hard-locks settings right away
        B) triggers on all other saves, and checks if there have been any *local* edits (not on the settings.lua file, through the mods themselves!) to non-read-only settings
--]]

-- called whenever saving
function settings:save_game_callback(context)
    local file = io.open(self.settings_file, "r")
    if not file then
        -- ISSUE
    else
        mct:log("Saving settings to the save file.")

        -- read the settings file
        local content = loadfile(self.settings_file)
        mct_data = content()

        -- go through each mod in the settings file, and save a table with all the info into it
        for mod_key, mod_data in pairs(mct_data) do
            local mod_obj = mct:get_mod_by_key(mod_key)
            local mod_table = {}

            for option_key, settings_val in pairs(mod_data) do
                local option_obj = mod_obj:get_option_by_key(option_key)
                if option_obj --[[and option_obj:get_read_only()]] then
                    mod_table[option_key] = {
                        _setting = settings_val._setting,
                        _read_only = settings_val._read_only
                    }
                end
            end

            cm:save_named_value("mct_"..mod_key, mod_table, context)
        end
    end
end

return settings
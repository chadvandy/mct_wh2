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

function settings:finalize(force)
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

    if __game_mode ~= __lib_type_campaign or (__game_mode == __lib_type_campaign and force) then
        self:save_mct_settings(ret)
    end
end

-- only used for new games in MP
function settings:mp_load()
    mct:log("mp_load() start")
    -- first up: set up the events to respond to the MP stuff
    ClMultiplayerEvents.registerForEvent(
        "MctMpInitialLoad","MctMpInitialLoad",
        function(mct_data)
            -- mct_data = {mod_key = {option_key = {setting = xxx, read_only = true}, option_key_2 = {setting = yyy, read_only = false}}, mod_key2 = {etc}}
            mct:log("MctMpInitialLoad begun!")
            for mod_key, options in pairs(mct_data) do
                local mod_obj = mct:get_mod_by_key(mod_key)
                mct:log("Looping through mod obj ["..mod_key.."].")

                for option_key, option_data in pairs(options) do
                    mct:log("At object ["..option_key.."]")
                    local option_obj = mod_obj:get_option_by_key(option_key)

                    local setting = option_data._setting
                    local read_only = option_data._read_only

                    mct:log("Setting: "..tostring(setting))
                    mct:log("Read only: "..tostring(read_only))

                    option_obj:set_finalized_setting_event_free(setting)
                    option_obj:set_read_only(read_only)
                end
            end

            mct:log("MctMpInitialLoad end!")

            mct:log("Triggering MctInitializedMp, enjoy")
            core:trigger_custom_event("MctInitialized", {["mct"] = mct, ["is_multiplayer"] = true})
        end
    )

    mct:log("Is this being called too early?")
    local test_faction = cm:get_saved_value("mct_host")
    mct:log("Host faction key is: "..test_faction)

    --mct:log("Local faction is: "..local_faction)

    mct:log("Is THIS?")
    --if cm.game_interface:model():faction_is_local(test_faction) then
    if core:svr_load_bool("local_is_host") then
        mct:log("mct_host found!")
        self:load()

        local tab = {}

        local all_mods = mct:get_mods()
        for mod_key, mod_obj in pairs(all_mods) do
            tab[mod_key] = {}

            local options = mod_obj:get_options()

            for option_key, option_obj in pairs(options) do
                tab[mod_key][option_key] = {}

                tab[mod_key][option_key]._setting = option_obj:get_finalized_setting()
                tab[mod_key][option_key]._read_only = option_obj:get_read_only()

            end
        end

        mct:log("Triggering MctMpInitialLoad")

        ClMultiplayerEvents.notifyEvent("MctMpInitialLoad", 0, tab)
    end
end

function settings:load()
    local file = io.open(self.settings_file, "r")
    if not file then
        -- create a file with all the defaults!
        mct:log("First time load - creating settings file! Using defaults for every option.")
        self:finalize(true)
        mct:log("Settings file created, all defaults applied!")
    else
        mct:log("Loading settings file!")
        local content = loadfile(self.settings_file)
        content = content()

        --local content = table.load(self.settings_file)
        local all_mods = mct:get_mods()

        for mod_key, mod_obj in pairs(all_mods) do
            mct:log("Loading settings for mod ["..mod_key.."].")

            -- check if there's any saved data for this mod obj
            local data = content[mod_key]

            if not mct:is_mct_mod(mod_obj) then
                mct:error("Running settings:load(), but a mct_mod in the mct_data with key ["..mod_key.."] is not a valid mct_mod! Skipping!")
            else
            --mod_obj._finalized_setings = data

                -- loop through all of the actual options available in the mct_mod, not only ones in the settings file
                local all_options = mod_obj:get_options()

                for option_key, option_obj in pairs(all_options) do
                    local setting = nil
                    local read_only = nil

                    -- grab data attached to this option key in the .lua settings file
                    if not is_nil(data) then
                        local saved_data = data[option_key]

                        -- grab the saved data in the .lua file for this option!
                        if not is_nil(saved_data) then
                            setting = saved_data._setting
                            read_only = saved_data._read_only
                        end
                    end

                    -- if no setting was found, default to whatever the default_value is
                    if is_nil(setting) then
                        -- this returns the default value
                        setting = option_obj:get_finalized_setting()
                    end

                    -- ditto
                    if is_nil(read_only) then
                        -- ditto
                        read_only = option_obj:get_read_only()
                    end

                    -- set the finalized setting and read only stuffs
                    option_obj:set_finalized_setting_event_free(setting)
                    option_obj:set_read_only(read_only)

                    mct:log("Finalizing option ["..option_key.."] with setting ["..tostring(setting).."] and read_only value ["..tostring(read_only).."]")
                end
                
                mod_obj:load_finalized_settings()
            end
        end

        self:finalize()
    end
end

-- load saved details for all mods 
function settings:load_game_callback(context)
    local retval = {}

    mct:log("Loading settings from the save file!")

    local mods = mct:get_mods()

    for mod_key, mod_obj in pairs(mods) do
        local saved_data = cm:load_named_value("mct_"..mod_key, {}, context)

        mct:log("Testing for mod ["..mod_key.."]")

        -- check if there's anything actually saved for this mod key
        if is_table(saved_data) then
            mct:log("Saved data found; checking through options saved!")

            for option_key, option_data in pairs(saved_data) do
                mct:log("Testing for option ["..option_key.."].")
                local option_obj = mod_obj:get_option_by_key(option_key)
                if option_obj then
                    -- save the option details in Lua-state
                    option_obj:set_finalized_setting_event_free(option_data._setting)
                    option_obj:set_read_only(option_data._read_only)

                    mct:log("Setting: "..tostring(option_data._setting))
                    mct:log("Read only: "..tostring(option_data._read_only))
                end
            end
            mod_obj:load_finalized_settings()
        end
    end
end

--[[ TODO improve this so it
        A) triggers immediately on a new game, hard-locks settings right away
        B) triggers on all other saves, and checks if there have been any *local* edits (not on the settings.lua file, through the mods themselves!) to non-read-only settings
--]]

-- called whenever saving
function settings:save_game_callback(context)
    --local file = io.open(self.settings_file, "r")
    --if not file then
        -- ISSUE
    --else
        mct:log("Saving settings to the save file.")

        -- DO NOT read the settings file
        --[[run_through_tableocal content = loadfile(self.settings_file)
        mct_data = content()]]

        local all_mods = mct:get_mods()


        -- go through each mod in the settings file, and save a table with all the info into it
        for mod_key, mod_obj in pairs(all_mods) do
            --local mod_obj = mct:get_mod_by_key(mod_key)
            local mod_table = {}

            local options = mod_obj:get_options()

            for option_key, option_obj in pairs(options) do
                --local option_obj = mod_obj:get_option_by_key(option_key)
                if option_obj --[[and option_obj:get_read_only()]] then
                    mod_table[option_key] = {
                        _setting = option_obj:get_finalized_setting(),
                        _read_only = option_obj:get_read_only(),
                    }
                end
            end

            cm:save_named_value("mct_"..mod_key, mod_table, context)
        end
    --end
end

return settings
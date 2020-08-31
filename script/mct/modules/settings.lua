---- Settings Object. INTERNAL USE ONLY.
--- @class mct_settings

local mct = mct

local settings = {
    settings_file = "mct_settings.lua",
    tab = 0,

    new_settings = {},
    
    -- this is a table of mod keys to tables of options keys to their options
    -- cached on reading mct_settings.lua. When reading *extant* mct_mods, the cache is cleared for that mod key
    -- This lets a user/modder disable a mod, finalize settings, and load up that old mod again without losing settings
    cached_settings = {},

    profiles_file = "mct_profiles.lua",

    -- k/v table of profile keys to the standard settings memory - mod-key to option-key to option-setting.
    profiles = {},
    selected_profile = "",
}

function settings:get_profiles()
    return self.profiles
end

function settings:get_selected_profile()
    return self.selected_profile
end

function settings:delete_profile_with_key(key)
    if not is_string(key) then
        mct:error("delete_profile_with_key() called, but the key provided ["..tostring(key).."] is not a string!")
        return false
    end

    if not self.profiles[key] then
        mct:error("delete_profile_with_key() called, but the profile with key ["..key.."] doesn't exist!")
        return false
    end

    self.profiles[key] = nil
    self.selected_profile = ""

    -- refresh the dropdown UI
    mct.ui:populate_profiles_dropdown_box()
end

function settings:set_selected_profile(key)
    if not is_string(key) then
        mct:error("set_selected_profile() called, but the key provided ["..tostring(key).."] is not a string!")
        return false
    end

    if not self.profiles[key] then
        mct:error("set_selected_profile() called, but there's not profile found with the key ["..key.."]")
        return false
    end

    -- get the former selected profile, and un-save it as saved
    local former = self.profiles[self.selected_profile]
    if is_table(former) then
        former.selected = false
    end

    -- save the new one as saved
    self.selected_profile = key
    self.profiles[key].selected = true

    mct.ui:populate_profiles_dropdown_box()
end

function settings:get_all_profile_keys()
    local ret = {}
    for k,_ in pairs(self.profiles) do
        ret[#ret+1] = k
    end

    return ret
end

function settings:read_profiles_file()
    local ok, err = pcall(function()
    local file = io.open(self.profiles_file, "r")
    
    -- if no file exists, skip operation
    if not file then
        return false
    end

    file:close()

    local content = loadfile(self.profiles_file)
    
    if not content then
        mct:error("read_profiles_file() called, but there is no valid profiles found in the profiles_file!")
        return false
    end

    -- clear out old profiles data
    self.profiles = {}
    self.selected_profile = ""

    content = content()

    for profile_key, profile_data in pairs(content) do
        -- profile_data has ["selected"], a bool
        -- profile_data has ["settings"], the k/v table of mod-key to option-key to option-setting

        self.profiles[profile_key] = profile_data

        -- TODO temporarily disable this - start with no prof's selected!
        if profile_data.selected then
            --self:set_selected_profile(profile_key)
        end
    end
end) if not ok then mct:error(err) end end

function settings:save_profiles_file()
    local file = io.open(self.profiles_file, "w")

    if not file then
        mct:error("save_profiles_file() called, but there's no profiles_file found!")
        return false
    end

    local str = "return {\n"

    for profile_key, profile_data in pairs(self.profiles) do
        str = str .. "\t[\""..profile_key.."\"] = {\n"

        local selected = profile_data.selected
        
        str = str .. "\t\t[\"selected\"] = " .. tostring(selected) .. ",\n"

        str = str .. "\t\t[\"settings\"] = {\n"

        local settings = profile_data.settings

        for mod_key, mod_data in pairs(settings) do
            str = str .. "\t\t\t[\""..tostring(mod_key).."\"] = {\n"

            for option_key, selected_setting in pairs(mod_data) do
                str = str .. "\t\t\t\t[\"" .. tostring(option_key) .. "\"] = "

                if is_string(selected_setting) then
                    str = str .. "\"" .. selected_setting .. "\"" .. ",\n"
                elseif is_boolean(selected_setting) then
                    str = str .. tostring(selected_setting) .. ",\n"
                elseif is_number(selected_setting) then
                    -- TODO make this work for precision points!!!!!!
                    str = str .. tostring(selected_setting) .. ",\n"
                end
            end
            str = str .. "\t\t\t},\n"
        end
        str = str .. "\t\t},\n"
        str = str .. "\t},\n"
        --str = str .. 
    end
    str = str .. "}"

    file:write(str)
    file:close()
end

-- make sure nothing is being erased here - only overwritten
-- not erasing the tables makes cached settings work
function settings:save_profile_with_key(key)
    if not is_string(key) then
        return "bad_key"
    end

    if not self.profiles[key] then
        return "none_found"
    end

    -- if the table doesn't exist, make one!
    if not is_table(self.profiles[key].settings) then
        self.profiles[key].settings = {}
    end

    local mods = mct:get_mods()

    for mod_key, mod_obj in pairs(mods) do
        -- ditto
        if not is_table(self.profiles[key]["settings"][mod_key]) then
            self.profiles[key]["settings"][mod_key] = {}
        end

        local options = mod_obj:get_options()

        for option_key, option_obj in pairs(options) do
            local setting = option_obj:get_selected_setting()

            -- one final ditto
            self.profiles[key]["settings"][mod_key][option_key] = setting
        end
    end

    self:save_profiles_file()
end

function settings:apply_profile_with_key(key)
    if not is_string(key) then
        return "bad_key"
    end

    if not self.profiles[key] then
        return "none_found"
    end

    local profile_settings = self.profiles[key].settings

    mct:log("applying profile with key ["..key.."].")

    for mod_key, mod_data in pairs(profile_settings) do
        mct:log("in mct_mod ["..mod_key.."]")
        local mod_obj = mct:get_mod_by_key(mod_key)

        if mod_obj then
            for option_key, selected_setting in pairs(mod_data) do
                local option_obj = mod_obj:get_option_by_key(option_key)

                if selected_setting ~= option_obj:get_finalized_setting() then
                    option_obj:set_selected_setting(selected_setting)
                end
            end
        end
    end
end

function settings:test_profile_with_key(key)
    if not is_string(key) then
        return "bad_key"
    end

    if key == "" then
        return "blank_key"
    end

    -- make sure the string isn't going to have some bad escape key or something
    -- TODO this

    -- test if one exists already
    if self.profiles[key] ~= nil then
        return "exists"
    end

    return true
end

function settings:add_profile_with_key(key)
    local test = self:test_profile_with_key(key)

    if test ~= true then
        return test
    end

    self.profiles[key] = {}

    -- loop through all current settings, and save them!
    local mods = mct:get_mods()

    self.profiles[key]["settings"] = {}

    for mod_key, mod_obj in pairs(mods) do
        self.profiles[key]["settings"][mod_key] = {}

        local options = mod_obj:get_options()

        for option_key, option_obj in pairs(options) do
            local setting = option_obj:get_selected_setting()

            self.profiles[key]["settings"][mod_key][option_key] = setting
        end
    end

    self.profiles[key]["selected"] = true

    self.selected_profile = key

    mct.ui:populate_profiles_dropdown_box()

    return true
end

--- Add a new cached_settings object for a specific mod key, or adds new option keys if one exists already.
function settings:add_cached_settings(mod_key, option_data)
    if not is_string(mod_key) then
        -- errmsg
        return nil
    end

    if not is_table(option_data) then
        -- errmsg
        return nil
    end

    local test_mod = self.cached_settings[mod_key]
    if is_nil(test_mod) then
        self.cached_settings[mod_key] = {}
    end

    for k,v in pairs(option_data) do
        self.cached_settings[mod_key][k] = v
    end
end

--- Check the cached_settings object for a specific mod key, and a single (or multiple) option.
-- Will return a table of settings keys in the order the option keys were presented. Nil if none are found.
function settings:get_cached_settings(mod_key, option_keys)
    if not is_string(mod_key) then
        mct:error("get_cached_settings() called, but the mod_key provided ["..tostring(mod_key).."] is not a string!")
        return nil
    end

    if is_string(option_keys) then
        option_keys = {option_keys}
    end

    if is_nil(option_keys) then
        -- return the entire cached mod
        return self.cached_settings[mod_key]
    end

    if not is_table(option_keys) then
        mct:error("get_cached_settings() called for mod_key ["..mod_key.."], but the option_keys arg provided wasn't a single option key, a table of option keys, or nil. Returning nil!")
        return nil
    end

    local test_mod = self.cached_settings[mod_key]

    -- no mod with this key was found in cached settings
    if is_nil(test_mod) then
        return nil
    end

    local retval = {}

    for i = 1, #option_keys do
        local option_key = option_keys[i]
        local test = test_mod[option_key]

        if not is_nil(test) then
            retval[option_key] = test
        end
    end

    return retval
end

--- Remove any cached settings within the mod-key provided with the option keys provided. 
-- If no option keys are provided, the entire mod's cached settings will be axed.
function settings:remove_cached_setting(mod_key, option_keys)
    if not is_string(mod_key) then
        mct:error("remove_cached_setting() called but the mod_key provided ["..tostring(mod_key).."] is not a string.")
        return false
    end

    if is_string(option_keys) then
        option_keys = {option_keys}
    end

    -- no "option_keys" were passed - just remove the mod from memory!
    if is_nil(option_keys) then
        self.cached_settings[mod_key] = nil
        return
    end

    if not is_table(option_keys) then
        mct:error("remove_cached_settings() called for mod_key ["..mod_key.."], but the option_keys argument provided is not a single option key, a table of option keys, or nil. Returning false!")
        return false
    end

    -- check if the mod is cached in memory
    local test_mod = self.cached_settings[mod_key]

    if is_nil(test_mod) then
        -- this mod was already removed from cached settings - cancel!
        return false
    end

    -- loop through all option keys, and remove them from the cached settings
    for i = 1, #option_keys do
        local option_key = option_keys[i]

        -- kill the cached setting for this option key
        test_mod[option_key] = nil
    end
end

function settings:save_mct_settings()
    local file, err = io.open(self.settings_file, "w+")

    if not file then
        mct:error("Could not load settings file: "..err)
        return false
    end

    self.tab = 0

    local str = "return {\n"

    local mods = mct:get_mods()
    for mod_key, mod_obj in pairs(mods) do
        local addendum = mod_obj:save_mct_settings()

        str = str .. addendum
    end

    local t = ""

    -- append a loop for the cached mods
    for mod_key, mod_data in pairs(self.cached_settings) do
        t = "\t[\""..mod_key.."\"] = {\n"

        -- loop through the k/v table of "mod_data", which is `["option_key"] = "setting",`
        for option_key, option_data in pairs(mod_data) do
            t = t .. "\t\t[\""..option_key.."\"] = {\n"

            for _,saved_setting in pairs(option_data) do
                t = t .. "\t\t\t[\"_setting\"] = "
                if is_string(saved_setting) then
                    t = t .. "\"" .. saved_setting .. "\",\n"
                elseif is_number(saved_setting) then
                    t = t .. tostring(saved_setting) .. ",\n"
                elseif is_boolean(saved_setting) then
                    t = t .. tostring(saved_setting) .. ",\n"
                else
                    --mct:log("not a string number or boolean?")
                    --mct:log(tostring(saved_setting))
                    t = t .. "nil" .. ",\n"
                end

                --t = t .. "\t\t\t},\n"
            end


            t = t .. "\t\t},\n"

        end

        t = t .. "\t},\n"
    end

    str = str .. t

    --mct:log("starting run through table")
    --str = run_through_table(data, str)
    --mct:log("ending run through table")

    str = str .. "}"

    self.tab = 0

    file:write(str)
    file:close()
end

function settings:local_only_finalize(sent_by_host)
    -- it's the client; only finalize local-only stuff
    mct:log("Finalizing settings mid-campaign for MP, local-only.")
    local all_mods = mct:get_mods()

    for mod_key, mod_obj in pairs(all_mods) do
        local fin = mod_obj:get_settings()

        mct:log("Looping through mct_mod ["..mod_key.."]")
        local all_options = mod_obj:get_options()

        for option_key, option_obj in pairs(all_options) do
            if option_obj:get_local_only() then
                mct:log("Editing mct_option ["..option_key.."]")

                -- only trigger the option-changed event if it's actually changing setting
                local selected = option_obj:get_selected_setting()

                if option_obj:get_finalized_setting() ~= selected then
                    option_obj:set_finalized_setting(selected)
                    fin[option_key] = selected
                end
            end
        end

        mod_obj._finalized_settings = fin
    end

    mct._finalized = true
    
    mct.ui.locally_edited = false

    core:trigger_custom_event("MctFinalized", {["mct"] = mct, ["mp_sent"] = sent_by_host})
end

function settings:finalize_first_time(force)
    local mods = mct:get_mods()

    for key, mod in pairs(mods) do
        mod:load_finalized_settings()
    end

    self:save_mct_settings()
end

function settings:finalize(force, specific_mod)
    --mct:log("Finalizing Settings!")
    --local ret = {}
    local mods = mct:get_mods()

    -- don't save specific indices that will absolutely break shit or waste space if they're saved to Lua
    --[[local excluded_indices = {
        _FILEPATH = true,
        _uics = true,
        _mod = true,
        _template = true,
    }]]

    if specific_mod then
        local mod_obj = mct:get_mod_by_key(specific_mod)

        if mct:is_mct_mod(mod_obj) then
            mod_obj:finalize_settings()
        else
            mct:error("Finalize called for specific mod ["..specific_mod.."], but no mct_mod was found with that key!")
        end
    else
        for key, mod in pairs(mods) do
            mct:log("Finalized mod ["..key.."]")
            mod:finalize_settings()
        end
    end

    if __game_mode ~= __lib_type_campaign or (__game_mode == __lib_type_campaign and force) then
        self:save_mct_settings()
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

                    mct:log("Setting: "..tostring(setting))

                    option_obj:set_finalized_setting(setting, true)
                end
            end

            mct:log("MctMpInitialLoad end!")

            mct:log("Triggering MctInitializedMp, enjoy")
            core:trigger_custom_event("MctInitialized", {["mct"] = mct, ["is_multiplayer"] = true})
        end
    )

    --mct:log("Is this being called too early?")
    local test_faction = cm:get_saved_value("mct_host")
    mct:log("Host faction key is: "..test_faction)

    --mct:log("Local faction is: "..local_faction)

    --mct:log("Is THIS?")
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
                -- don't send local-only settings to both
                if option_obj:get_local_only() == false then
                    tab[mod_key][option_key] = {}

                    tab[mod_key][option_key]._setting = option_obj:get_finalized_setting()
                end
            end
        end

        mct:log("Triggering MctMpInitialLoad")

        ClMultiplayerEvents.notifyEvent("MctMpInitialLoad", 0, tab)
    end
end

--- This is the function that reads the mct_settings.lua file and loads up all the necessary components from it.
-- If no file is found, or the file has some sort of script break, MCT will make a new one using all defaults.
-- This is also where settings are "cached" for any mct_mods that aren't currently enabled but are in the mct_settings.lua file
function settings:load()
    local file, err = io.open(self.settings_file, "r")
    if not file then
        -- create a file with all the defaults!
        mct:log("First time load - creating settings file! Using defaults for every option.")
        mct._first_load = true
        self:finalize_first_time(true)
        mct:log("Settings file created, all defaults applied!")
    else
        mct:log("Loading settings file!")
        mct._first_load = false
        local content = loadfile(self.settings_file)

        if not pcall(function() content() end) then
            mct:error("The mct_settings.lua file had a script error in it and couldn't be loaded. Investigate!")
            self:finalize_first_time(true)
            return
        end

        content = content()

        if not content then
            self:finalize_first_time(true)
            return
        end

        local any_added = false

        --local content = table.load(self.settings_file)
        local all_mods = mct:get_mods()

        for mod_key, mod_obj in pairs(all_mods) do
            --mct:log("Loading settings for mod ["..mod_key.."].")

            -- check if there's any saved data for this mod obj
            local data = content[mod_key]
            

            -- loop through all of the actual options available in the mct_mod, not only ones in the settings file
            local all_options = mod_obj:get_options()

            for option_key, option_obj in pairs(all_options) do
                local setting = nil

                -- grab data attached to this option key in the .lua settings file
                if not is_nil(data) then
                    local saved_data = data[option_key]

                    -- grab the saved data in the .lua file for this option!
                    if not is_nil(saved_data) then
                        setting = saved_data._setting
                    else -- this is a new setting!
                        --mct:log("New setting found! ["..option_key.."]")
                        if is_nil(self.new_settings[mod_key]) then
                            --mct:log("?")
                            self.new_settings[mod_key] = {}
                            --mct:log("??")
                        end

                        --mct:log("???")

                        -- save the option key in the new_settings table, so we can look back later and see that it's new!
                        -- skip this process if the option is a dummy!
                        if option_obj:get_type() ~= "dummy" then
                            self.new_settings[mod_key][#self.new_settings[mod_key]+1] = option_key
                            any_added = true
                        end

                        --mct:log("????")

                        --mct:log("?????")
                    end
                end

                -- if no setting was found, default to whatever the default_value is
                if is_nil(setting) then
                    -- this returns the default value
                    setting = option_obj:get_finalized_setting()
                end

                --- TODO Make this ignore the "read_only" status
                -- set the finalized setting and read only stuffs
                option_obj:set_finalized_setting(setting, true)

                --mct:log("Finalizing option ["..option_key.."] with setting ["..tostring(setting).."]")

                -- remove this from `data`, so non-existent settings will be cached
                if is_table(data) then
                    data[option_key] = nil
                end
            end
            
            mod_obj:load_finalized_settings()

            local next = next

            -- only clear out this mod from content (from an empty table {} to nil) if it's completely empty from the previous operation
            if content[mod_key] and next(content[mod_key]) == nil then
                content[mod_key] = nil
            end
        end

        -- loop through the rest of "content", which is either empty entirely or has
        -- any bits of information that need to be cached due to a disabled mct_mod
        for mod_key, mod_data in pairs(content) do
            mct:log("Caching settings for mct_mod with key ["..mod_key.."]")
            self.cached_settings[mod_key] = mod_data
        end

        --self:finalize()

        --mct:log(tostring(any_added))
        if any_added then
            --mct:log("does this exist")
            mct.ui:add_ui_created_callback(function()
                local mod_keys = {}
                for k, _ in pairs(self.new_settings) do
                    mod_keys[#mod_keys+1] = k
                end

                local key = "mct_new_settings"
                local text = effect.get_localised_string("mct_new_settings_start") .. "\n\n" .. effect.get_localised_string("mct_new_settings_mid")

                for i = 1, #mod_keys do
                    local mod_obj = mct:get_mod_by_key(mod_keys[i])
                    local title = mod_obj:get_title()

                    -- there's only one changed mod
                    if 1 == #mod_keys then
                        text = text .. "\"" .. title .. "\"" .. ". "
                    else
                        if i == #mod_keys then
                            text = text .. "and \"" .. title .. "\"" .. ". "
                        else
                            text = text .. "\"" .. title .. "\"" .. ", "
                        end
                    end
                end

                text = text .. "\n" .. effect.get_localised_string("mct_new_settings_end")

                mct.ui:create_popup(
                    key,
                    text,
                    true, -- this uses two buttons
                    function() -- the "ok" button was triggered - show the MCT panel
                        mct.ui:open_frame()
                    end,
                    function()  -- the "cancel" button was triggered - do nuffin, really
                    end
                )
            end)
        end
    end
end

-- load saved details for all mods 
function settings:load_game_callback(context)
    --local retval = {}

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
                    option_obj:set_finalized_setting(option_data._setting, true)
                    option_obj:set_read_only(option_data._read_only)

                    mct:log("Setting: "..tostring(option_data._setting))
                    mct:log("Read only: "..tostring(option_data._read_only))
                end
            end
            mod_obj:load_finalized_settings()
        end
    end
end


-- called whenever saving
function settings:save_game_callback(context)
    --local file = io.open(self.settings_file, "r")
    --if not file then
        -- ISSUE
    --else
        mct:log("Saving settings to the save file.")

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
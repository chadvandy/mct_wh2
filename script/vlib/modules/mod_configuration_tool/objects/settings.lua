---- Settings Object. INTERNAL USE ONLY.
--- @class mct_settings

local mct = get_mct()
local vlib = get_vlib()
local log,logf,err,errf = vlib:get_log_functions "[mct_settings]"

---@type mct_settings
local settings = {
    ---@type string Path to the profile save file.
    profiles_file = "mct_profiles.lua",

    ---@type string Path to the settings save file.
    settings_file = "mct_settings.lua",

    __new_settings = {},
    
    --- this is a table of mod keys to tables of options keys to their options.
    --- cached on reading mct_settings.lua. When reading *extant* mct_mods, the cache is cleared for that mod key.
    --- This lets a user/modder disable a mod, finalize settings, and load up that old mod again without losing settings.
    ---@type table<string, table<string, any>>
    __cached_settings = {},
    
    __profiles = setmetatable({},{
        __index = function(self, k)
            return rawget(self, k)
        end,
        __newindex = function(self, k, v)
            if k:match("^__") then
                -- you can't make a profile that starts with "__"
                return
            end

            return rawset(self, k, v)
        end,
    }),
    __used_profile = "",
}

function settings:clear_profile_cache()
    self.__profiles = setmetatable({},{
        __index = function(o, k)
            return rawget(o, k)
        end,
        __newindex = function(o, k, v)
            if k:match("^__") then
                -- todo errmsg
                -- you can't make a profile that starts with "__"
                return
            end

            return rawset(o, k, v)
        end,
    })
end

--[[ TODO this should:
    1) load up the mct_settings and mct_profiles files, store them
    2) create a new "main" profile, using the currently loaded settings. If there's a profile currently loaded, use that.
    3) if there are other profiles, reorganize them (remove the .selected and .settings fields, and only save DIFFERENCES from "main" instead of all settings)
    4) delete mct_profiles.lua
    5) save everything in mct_settings.lua
]]
function settings:setup_default_profile()
    self:read_profiles_file()

    --- clear out the old fields in all profiles
    for key,profile in pairs(self.__profiles) do
        self.__profiles[key].selected = nil
        self.__profiles[key].__settings = self.__profiles[key].settings
        self.__profiles[key].settings = nil
    end

    self.__used_profile = "main"
    -- self:add_profile_with_key("main")
    self.__profiles["main"] = {}

    ---@param mod_key string
    ---@param mod_obj mct_mod
    for mod_key,mod_obj in pairs(mct:get_mods()) do
        self.__profiles["main"][mod_key] = {
            __patch = 0,
            __settings = {},
        }

        for option_key, option_obj in pairs(mod_obj:get_options()) do
            self.__profiles["main"][mod_key]["__settings"][option_key] = option_obj:get_finalized_setting()
        end
    end
end

--- Load the shit from the profiles file.
function settings:load_new()
    local content = loadfile(self.settings_file)
    if not content then
        -- errmsg!
    end

    content = content()

    self.__selected_profile = content.__selected_profile
    self.__profiles = content.__profiles
    self.__cached_settings = content.__cached_settings
end

--- Save the shit into the profiles file.
function settings:save_new()
    local t = {}

    t.__selected_profile = self.__selected_profile
    t.__profiles = self:get_profiles()
    t.__cached_settings = self.__cached_settings

    local str = table_printer:print(t)

    local file = io.open(self.settings_file, "w+")
    file:write(str)
    file:close()
end

--- TODO a function to save an option w/ a new value in the profiles table
--- Needs to grab the current profile:
    --- if main, just change the new value in main
    --- otherwise, change the new value in this profile and set the value to old in main

function settings:get_profiles()
    return self.__profiles
end

function settings:get_selected_profile()
    return self.__selected_profile
end

function settings:get_profile(key)
    if not is_string(key) then return end
    
    return self:get_profiles()[key]
end

function settings:delete_profile_with_key(key)
    if not is_string(key) then
        err("delete_profile_with_key() called, but the key provided ["..tostring(key).."] is not a string!")
        return false
    end

    if not self:get_profile(key) then
        err("delete_profile_with_key() called, but the profile with key ["..key.."] doesn't exist!")
        return false
    end

    self.__profiles[key] = nil

    -- TODO never none selected!
    self.__selected_profile = ""

    -- refresh the dropdown UI
    mct.ui:populate_profiles_dropdown_box()
end

function settings:set_selected_profile(key)
    if not is_string(key) then
        err("set_selected_profile() called, but the key provided ["..tostring(key).."] is not a string!")
        return false
    end

    if not self:get_profile(key) then
        err("set_selected_profile() called, but there's not profile found with the key ["..key.."]")
        return false
    end

    -- save the new one as saved
    self.__selected_profile = key
end

function settings:get_all_profile_keys()
    local ret = {}
    for k,_ in pairs(self.__profiles) do
        ret[#ret+1] = k
    end

    return ret
end

function settings:read_profiles_file()
    local ok, msg = pcall(function()
    local file = io.open(self.profiles_file, "r")
    
    -- if no file exists, skip operation
    if not file then
        return false
    end

    file:close()

    local content = loadfile(self.profiles_file)
    
    if not content then
        err("read_profiles_file() called, but there is no valid profiles found in the profiles_file!")
        return false
    end

    -- TODO don't clear it out? or make sure it's reinstated the same way w/ MT?
    -- clear out old profiles data
    self.__profiles = {}
    self.__selected_profile = ""

    content = content()

    for profile_key, profile_data in pairs(content) do
        -- TODO, move "selected" to the max-level table? mct_profiles = {__selected = "profile key"}?
        -- profile_data has ["selected"], a bool
        -- profile_data has ["settings"], the k/v table of mod-key to option-key to option-setting

        self.__profiles[profile_key] = profile_data

        -- -- TODO temporarily disable this - start with no prof's selected!
        -- if profile_data.selected then
        --     self:set_selected_profile(profile_key)
        -- end
    end
end) if not ok then err(msg) end end

function settings:save_profiles_file()
    local file = io.open(self.profiles_file, "w")

    if not file then
        err("save_profiles_file() called, but there's no profiles_file found!")
        return false
    end

    local str = "return {\n"

    for profile_key, profile_data in pairs(self.__profiles) do
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

    if not self.__profiles[key] then
        return "none_found"
    end

    -- -- if the table doesn't exist, make one!
    -- if not is_table(self.__profiles[key].settings) then
    --     self.__profiles[key].settings = {}
    -- end

    local mods = mct:get_mods()

    for mod_key, mod_obj in pairs(mods) do
        -- ditto
        if not is_table(self.__profiles[key][mod_key]) then
            self.__profiles[key][mod_key] = {}
        end

        local options = mod_obj:get_options()

        for option_key, option_obj in pairs(options) do
            local setting = option_obj:get_selected_setting()

            -- one final ditto
            self.__profiles[key][mod_key][option_key] = setting
        end
    end

    self:save_profiles_file()
end

function settings:apply_profile_with_key(key)
    if not is_string(key) then
        return "bad_key"
    end

    if not self.__profiles[key] then
        return "none_found"
    end

    local profile_settings = self.__profiles[key]

    log("applying profile with key ["..key.."].")

    for mod_key, mod_data in pairs(profile_settings) do
        log("in mct_mod ["..mod_key.."]")
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

    if key == "main" then
        return "restricted"
    end

    -- make sure the string isn't going to have some bad escape key or something
    -- TODO this

    -- test if one exists already
    if self.__profiles[key] ~= nil then
        return "exists"
    end

    return true
end

function settings:add_profile_with_key(key)
    local test = self:test_profile_with_key(key)

    if test ~= true then
        return test
    end

    self.__profiles[key] = {}

    -- loop through all current settings, and save them!
    local mods = mct:get_mods()

    for mod_key, mod_obj in pairs(mods) do
        self.__profiles[key][mod_key] = {}

        local options = mod_obj:get_options()

        for option_key, option_obj in pairs(options) do
            local setting = option_obj:get_selected_setting()

            self.__profiles[key][mod_key][option_key] = setting
        end
    end

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

    local test_mod = self.__cached_settings[mod_key]
    if is_nil(test_mod) then
        self.__cached_settings[mod_key] = {}
    end

    for k,v in pairs(option_data) do
        self.__cached_settings[mod_key][k] = v
    end
end

--- Check the cached_settings object for a specific mod key, and a single (or multiple) option.
--- Will return a table of settings keys in the order the option keys were presented. Nil if none are found.
function settings:get_cached_settings(mod_key, option_keys)
    if not is_string(mod_key) then
        err("get_cached_settings() called, but the mod_key provided ["..tostring(mod_key).."] is not a string!")
        return nil
    end

    if is_string(option_keys) then
        option_keys = {option_keys}
    end

    if is_nil(option_keys) then
        -- return the entire cached mod
        return self.__cached_settings[mod_key]
    end

    if not is_table(option_keys) then
        err("get_cached_settings() called for mod_key ["..mod_key.."], but the option_keys arg provided wasn't a single option key, a table of option keys, or nil. Returning nil!")
        return nil
    end

    local test_mod = self.__cached_settings[mod_key]

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
--- If no option keys are provided, the entire mod's cached settings will be axed.
function settings:remove_cached_setting(mod_key, option_keys)
    if not is_string(mod_key) then
        err("remove_cached_setting() called but the mod_key provided ["..tostring(mod_key).."] is not a string.")
        return false
    end

    if is_string(option_keys) then
        option_keys = {option_keys}
    end

    -- no "option_keys" were passed - just remove the mod from memory!
    if is_nil(option_keys) then
        self.__cached_settings[mod_key] = nil
        return
    end

    if not is_table(option_keys) then
        err("remove_cached_settings() called for mod_key ["..mod_key.."], but the option_keys argument provided is not a single option key, a table of option keys, or nil. Returning false!")
        return false
    end

    -- check if the mod is cached in memory
    local test_mod = self.__cached_settings[mod_key]

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



--- 
--- TODO consolidate mct_settings.lua and mct_profiles.lua
function settings:save_mct_settings()
    local file, load_err  = io.open(self.settings_file, "w+")

    if not file then
        err("Could not load settings file: "..load_err)
        return false
    end

    self.tab = 0

    local str = "return {\n"

    local mods = mct:get_mods()
    for _, mod_obj in pairs(mods) do
        local addendum = mod_obj:save_mct_settings()

        str = str .. addendum
    end

    local t = ""

    -- append a loop for the cached mods
    if self.__cached_settings and not is_nil(next(self.__cached_settings)) then
        t = "\t[\"mct_cached_settings\"] = {\n"
        for mod_key, mod_data in pairs(self.__cached_settings) do
            t = t .. "\t\t[\""..mod_key.."\"] = {\n"

            -- loop through the k/v table of "mod_data", which is `["option_key"] = "setting",`
            for option_key, option_data in pairs(mod_data) do
                if not option_key:starts_with("__") then
                    t = t .. "\t\t\t[\""..option_key.."\"] = {\n"

                    for _,saved_setting in pairs(option_data) do
                        t = t .. "\t\t\t\t[\"_setting\"] = "
                        if is_string(saved_setting) then
                            t = t .. "\"" .. saved_setting .. "\",\n"
                        elseif is_number(saved_setting) then
                            t = t .. tostring(saved_setting) .. ",\n"
                        elseif is_boolean(saved_setting) then
                            t = t .. tostring(saved_setting) .. ",\n"
                        else
                            --log("not a string number or boolean?")
                            --log(tostring(saved_setting))
                            t = t .. "nil" .. ",\n"
                        end

                        --t = t .. "\t\t\t},\n"
                    end

                    t = t .. "\t\t\t},\n"
                end
            end

            t = t .. "\t\t},\n"
        end

        t = t .. "\t},\n"
    end

    str = str .. t

    --log("starting run through table")
    --str = run_through_table(data, str)
    --log("ending run through table")

    str = str .. "}"

    self.tab = 0

    file:write(str)
    file:close()
end

function settings:local_only_finalize(sent_by_host)
    -- it's the client; only finalize local-only stuff
    log("Finalizing settings mid-campaign for MP, local-only.")
    local all_mods = mct:get_mods()

    for mod_key, mod_obj in pairs(all_mods) do
        local fin = mod_obj:get_settings()

        log("Looping through mct_mod ["..mod_key.."]")
        local all_options = mod_obj:get_options()

        for option_key, option_obj in pairs(all_options) do
            if option_obj:get_local_only() then
                log("Editing mct_option ["..option_key.."]")

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

    if not sent_by_host then
        mct.ui.changed_settings = {}
    end

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
    local mods = mct:get_mods()

    if specific_mod then
        local mod_obj = mct:get_mod_by_key(specific_mod)

        if mct:is_mct_mod(mod_obj) then
            mod_obj:finalize_settings()
        else
            err("Finalize called for specific mod ["..specific_mod.."], but no mct_mod was found with that key!")
        end
    else
        for key, mod in pairs(mods) do
            log("Finalized mod ["..key.."]")
            mod:finalize_settings()
        end
    end

    if __game_mode ~= __lib_type_campaign or (__game_mode == __lib_type_campaign and force) then
        self:save_mct_settings()
    end
end

-- only used for new games in MP
function settings:mp_load()
    log("mp_load() start")
    -- first up: set up the events to respond to the MP stuff
    ClMultiplayerEvents.registerForEvent(
        "MctMpInitialLoad","MctMpInitialLoad",
        function(mct_data)
            -- mct_data = {mod_key = {option_key = {setting = xxx, read_only = true}, option_key_2 = {setting = yyy, read_only = false}}, mod_key2 = {etc}}
            log("MctMpInitialLoad begun!")
            for mod_key, options in pairs(mct_data) do
                local mod_obj = mct:get_mod_by_key(mod_key)
                log("Looping through mod obj ["..mod_key.."].")

                for option_key, option_data in pairs(options) do
                    
                    log("At object ["..option_key.."]")
                    local option_obj = mod_obj:get_option_by_key(option_key)

                    local setting = option_data._setting

                    log("Setting: "..tostring(setting))

                    option_obj:set_finalized_setting(setting, true)
                end
            end

            log("MctMpInitialLoad end!")

            log("Triggering MctInitializedMp, enjoy")
            core:trigger_custom_event("MctInitialized", {["mct"] = mct, ["is_multiplayer"] = true})
        end
    )

    --log("Is this being called too early?")
    local test_faction = cm:get_saved_value("mct_host")
    log("Host faction key is: "..test_faction)

    --log("Local faction is: "..local_faction)

    --log("Is THIS?")
    --if cm.game_interface:model():faction_is_local(test_faction) then
    if core:svr_load_bool("local_is_host") then
        log("mct_host found!")
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

        log("Triggering MctMpInitialLoad")

        ClMultiplayerEvents.notifyEvent("MctMpInitialLoad", 0, tab)
    end
end

--- This is the function that reads the mct_settings.lua file and loads up all the necessary components from it.
-- If no file is found, or the file has some sort of script break, MCT will make a new one using all defaults.
-- This is also where settings are "cached" for any mct_mods that aren't currently enabled but are in the mct_settings.lua file
function settings:load()
    -- if we're in the campaign, save the "mct_init" value as true
    if __game_mode == __lib_type_campaign then
        cm:set_saved_value("mct_init", true)
    end

    local file, _ = io.open(self.settings_file, "r")
    if not file then
        -- create a file with all the defaults!
        log("First time load - creating settings file! Using defaults for every option.")
        mct._first_load = true
        self:finalize_first_time(true)
        log("Settings file created, all defaults applied!")
    else
        log("Loading settings file!")
        mct._first_load = false
        local content = loadfile(self.settings_file)

        local ok,content = pcall(function() return content() end)

        if not ok then
            err("The mct_settings.lua file had a script error in it and couldn't be loaded. Investigate!")
            err(content)
            self:finalize_first_time(true)
            return
        end 

        if not content then
            self:finalize_first_time(true)
            return
        end

        --self:finalize_first_time()

        local any_added = false

        --local content = table.load(self.settings_file)
        local all_mods = mct:get_mods()

        local cached_settings = content["mct_cached_settings"]
        content["mct_cached_settings"] = nil

        for mod_key, mod_obj in pairs(all_mods) do
            --log("Loading settings for mod ["..mod_key.."].")

            -- check if there's any saved data for this mod obj
            local data = content[mod_key]
            
            if is_table(data) then
                local last_patch = data.__patch
                if last_patch then
                    mod_obj:set_last_viewed_patch(last_patch)
                    data.__patch = nil
                end
            end

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
                        --log("New setting found! ["..option_key.."]")

                        --log("???")

                        -- save the option key in the new_settings table, so we can look back later and see that it's new!
                        -- skip this process if the option is a dummy!
                        if option_obj:get_type() ~= "dummy" then
                            if is_nil(self.__new_settings[mod_key]) then
                                --log("?")
                                self.__new_settings[mod_key] = {}
                                --log("??")
                            end

                            self.__new_settings[mod_key][#self.__new_settings[mod_key]+1] = option_key
                            any_added = true
                        end
                    end
                end

                -- if no setting was found, default to whatever the default_value is
                if is_nil(setting) then
                    -- this returns the default value
                    setting = option_obj:get_finalized_setting()
                end

                -- if any setting is found in `mct_cached_settings`, check that for this mod key, for this option key, and then apply it over
                if cached_settings then
                    if cached_settings[mod_key] then
                        if cached_settings[mod_key][option_key] then
                            -- apply the new setting, and clear out the index in cached settings
                            setting = cached_settings[mod_key][option_key]["_setting"]
                            cached_settings[mod_key][option_key] = nil

                            -- if that was the last cached setting in this mct_mod, then remove the mod from cached settings
                            if cached_settings[mod_key] and next(cached_settings[mod_key]) == nil then
                                cached_settings[mod_key] = nil

                                -- if that was the last cached setting in any mct_mod, then just delete the table
                                if cached_settings and next(cached_settings) == nil then
                                    cached_settings = nil
                                end
                            end
                        end
                    end
                end
                
                -- set the finalized setting and read only stuffs
                option_obj:set_finalized_setting(setting, true)

                --log("Finalizing option ["..option_key.."] with setting ["..tostring(setting).."]")

                -- remove this from `data`, so non-existent settings will be cached
                if is_table(data) then
                    data[option_key] = nil
                end
            end
            
            mod_obj:load_finalized_settings()

            -- only clear out this mod from content (from an empty table {} to nil) if it's completely empty from the previous operation
            if content[mod_key] and next(content[mod_key]) == nil then
                content[mod_key] = nil
            end
        end

        -- loop through the "mct_cached_settings", if it exists, and add all of the stuff into the cached_settings table
        if cached_settings then
            for mod_key, mod_data in pairs(cached_settings) do
                log("Re-caching settings for mct_mod with key ["..mod_key.."]")

                if not self.__cached_settings[mod_key] then
                    self.__cached_settings[mod_key] = {}
                end

                for k,v in pairs(mod_data) do
                    self.__cached_settings[mod_key][k] = v
                end
            end
        end

        -- loop through the rest of "content", which is either empty entirely or has
        -- any bits of information that need to be cached due to a disabled mct_mod
        for mod_key, mod_data in pairs(content) do
            
            log("Caching settings for mct_mod with key ["..mod_key.."]")

            if not self.__cached_settings[mod_key] then
                self.__cached_settings[mod_key] = {}
            end

            for k,v in pairs(mod_data) do
                self.__cached_settings[mod_key][k] = v
            end
        end

        --self:finalize()

        -- log("Any new settings added?: "..tostring(any_added))
        if any_added then
            --log("does this exist")
            mct.ui:add_ui_created_callback(function()
                local mod_keys = {}
                for k, _ in pairs(self.__new_settings) do
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

                --text = text .. "\n" .. effect.get_localised_string("mct_new_settings_end")

                mct.ui:create_popup(
                    key,
                    function()
                        if not mct.ui.opened then 
                            return text .. "\n" .. effect.get_localised_string("mct_new_settings_created_end")
                        else 
                            return text
                        end
                    end,
                    function()
                        if not mct.ui.opened then
                            return true
                        else
                            return false
                        end
                    end,
                    function()
                        if mct.ui.opened then
                            -- do nothing
                        else
                            mct.ui:open_frame()
                        end
                    end,
                    function()
                        -- do nothing?
                    end
                )
            end)
        end

        self:finalize_first_time()
    end

    --- trigger the create-new-profile "main" thing here
    if not self:get_profile("main") then
        -- first time setup, either for a completely new user or a pre-port user.
        self:setup_default_profile()
    end
end

-- load saved details for all mods 
function settings:load_game_callback(context)
    --local retval = {}

    log("Loading settings from the save file!")

    local mods = mct:get_mods()

    for mod_key, mod_obj in pairs(mods) do
        local saved_data = cm:load_named_value("mct_"..mod_key, {}, context)

        log("Testing for mod ["..mod_key.."]")

        -- check if there's anything actually saved for this mod key
        if is_table(saved_data) then
            log("Saved data found; checking through options saved!")

            for option_key, option_data in pairs(saved_data) do
                log("Testing for option ["..option_key.."].")
                local option_obj = mod_obj:get_option_by_key(option_key)
                if option_obj then
                    -- save the option details in Lua-state
                    option_obj:set_finalized_setting(option_data._setting, true)
                    option_obj:set_read_only(option_data._read_only)

                    log("Setting: "..tostring(option_data._setting))
                    log("Read only: "..tostring(option_data._read_only))
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
        log("Saving settings to the save file.")

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
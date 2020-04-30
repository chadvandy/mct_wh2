local settings = {
    settings_file = "mct_settings.json"
}

local json = mct.json

function settings:finalize()
    mct:log("Finalizing Settings!")
    local ret = {}
    local mods = mct:get_mods()

    for key, mod in pairs(mods) do
        mct:log("In mod ["..key.."].")

        ret[key] = {}
        local mod_data = mod:finalize_settings()
        ret[key] = mod_data
    end
    local json_string = ""
    local status, res = pcall(function() json_string = json.encode(ret) end)
    if not status then mct:log(res) end
    mct:log(json_string)
    mct:log(tostring(ret))
    mct:log(ret)
    local file = io.open(self.settings_file, "w")
    file:write(json_string, "\n")
    file:close()
    mct:log("is it this?")
end

function settings:load()
    local file = io.open(self.settings_file, "r")
    if not file then
        -- first time load, no settings file exists!
    else
        mct:log("Loading settings file!")
        local content = file:read("*all")
        local mod_data = json.decode(content)

        mct:log(content)
        --mct:log(mod_data)

        for key, settings in pairs(mod_data) do
            -- key = mod key
            -- settings = {option_key=val,option2=val2,etc}

            local mod_obj = mct:get_mod_with_name(key)
            --local options = mod_obj:get_options()
            
            -- grab option objs in the mod with each key, 
            for option_key, val in pairs(settings) do
                local option_obj = mod_obj:get_option_by_key(option_key)
                if option_obj then
                    mct:log("Setting finalized setting for option ["..option_key.."] with val ["..tostring(val).."].")

                    -- YIKES this sucks
                    option_obj:set_finalized_setting(val)
                    option_obj:set_default_value(val)
                end
            end
            mod_obj:load_finalized_settings()
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
            for option_key, settings_val in pairs(saved_data) do
                local option_obj = mod_obj:get_option_by_key(option_key)
                if option_obj --[[and option_obj:get_read_only()]] then
                    -- save the option details in Lua-state
                    option_obj:set_finalized_setting(settings_val)
                    option_obj:set_default_value(settings_val)
                end
            end
        end
    end
end


-- called once when starting a new campaign, locks the settings to the save file
function settings:save_game_callback(context)
    local file = io.open(self.settings_file, "r")
    if not file then
        -- ISSUE
    else
        mct:log("Saving settings to the save file.")

        -- read the settings file
        local content = file:read("*all")
        local mct_data = json.decode(content)

        -- go through each mod in the settings file, and save a table with all the info into it
        for mod_key, settings in pairs(mct_data) do
            local mod_obj = mct:get_mod_with_name(mod_key)
            local mod_table = {}

            for option_key, settings_val in pairs(settings) do
                local option_obj = mod_obj:get_option_by_key(option_key)
                if option_obj --[[and option_obj:get_read_only()]] then
                    mod_table[option_key] = settings_val
                end
            end

            cm:save_named_value("mct_"..mod_key, mod_table, context)
        end
    end
end

mct.settings = settings
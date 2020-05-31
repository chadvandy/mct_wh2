--- Settings Object. INTERNAL USE ONLY.
-- @module mct_settings

local mct = mct

local settings = {
    settings_file = "mct_settings.lua",
    tab = 0
}

local tab = 0

-- TODO multiplayer shit

local function run_through_table(tabul, str)
    if not is_table(tabul) then
        mct:log("run_through_table() called but the table supplied isn't actually a table!")
		-- issue
		return str
    end
    
    --mct:log("running through table!")
    --mct:log(str)

    tab = tab + 1
    
    local excluded_indices = {
        --_FILEPATH = true,
        _uics = true,
        _mod = true,
        -- _template = true,
    }

    local ok, err = pcall(function()
    for k,v in pairs(tabul) do
        -- skip excluded indices, no breaks or overflows pls
        if excluded_indices[k] or is_function(v) then
            -- skip
        else
            local t = ""
            for i = 1, tab do t = t .. "\t" end
            if is_string(k) then
                str = str .. t.."[\""..k.."\"] = "
            elseif is_number(k) then
                str = str .. t.. "["..k.."] = "
            end
            
            --mct:log("In value ["..tostring(k).."]")

            --str = str .. "\t[\""..k.."\"] = "

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
    end
    end) if not ok then mct:log(err) end

	tab = tab - 1

	--str = str .. "}"

	return str
end

function settings:save_mct_settings(data)
    local file = io.open(self.settings_file, "w+")

    local str = "return {\n"
    --file:write("return {\n")

    mct:log("starting run through table")
    str = run_through_table(data, str)
    mct:log("ending run through table")

    str = str .. "}"

    file:write(str)
    file:close()
end

-- instantiate a new "mod" object, loaded from the save file/json file
function settings:instantiate_mod(key, o)
    local mod_obj = mct:get_mod_with_name(key)
    --

    --mct._registered_mods[key] = o

    local options = o._options
    for key, option_data in pairs(options) do
        --local option_obj = self:instantiate_option(key, option_data)
        --
        local option_obj = o._options[key]
        --

        for i,v in pairs(option_data) do
            option_obj[i] = v
        end

        option_obj._mod = mod_obj
        
        --o._options[key] = option_obj

        setmetatable(option_obj, {__index = mct._MCT_OPTION})
    end

    do
        for i,v in pairs(o) do
            mod_obj[i] = v
        end
    end

    setmetatable(mod_obj, {__index = mct._MCT_MOD})

    return mod_obj
end

function settings:instantiate_option(key, o)
    setmetatable(o, {__index = mct._MCT_OPTION})

    return o
end

function settings:finalize()
    --mct:log("Finalizing Settings!")
    local ret = {}
    local mods = mct:get_mods()

    -- don't save specific indices that will absolutely break shit or waste space if they're saved to Lua
    local excluded_indices = {
        _FILEPATH = true,
        --[[_uics = true,
        _mod = true,
        _template = true,]]
    }

    for key, mod in pairs(mods) do
        mct:log("Finalized mod ["..key.."]")
        mod:finalize_settings()
        --mct:log("In mod ["..key.."].")
        local data = {}

        local options = mod:get_options()
        for option_key, option_obj in pairs(options) do
            data[option_key] = {}
            data[option_key]._setting = option_obj:get_finalized_setting()
            data[option_key]._read_only = option_obj:get_read_only()
        end

        --local options = mod:get_options()
        --for key, option_obj in pairs(options) do
            --data[key] = option_obj:get_finalized_setting()


        --end

        --for k,v in pairs(mod) do
            --mct:log(tostring(k)) mct:log(tostring(v))
            -- don't save functions!
            --if not is_function(v)  --[[and not k == "__index"]] then
                --[[if excluded_indices[k] then
                    -- do nothing
                    mct:log("EXCLUDED INDEX: ".. tostring(k))
                else
                    data[k] = v
                    mct:log(tostring(k)) mct:log(tostring(v))
                end]]


            --end
        --end
        ret[key] = data
        --local mod_data = mod:finalize_settings()
        --ret[key] = mod_data
    end

    self:save_mct_settings(ret)

    --[[for lk,lv in pairs(ret) do
        mct:log(tostring(lk)) mct:log(tostring(lv))

        if is_table(lv) then
            for ik,iv in pairs(lv) do
                mct:log(tostring(ik)) mct:log(tostring(iv))
            end
        --else
        --    mct:log(tostring(k)) mct:log(tostring(v))
        end
    end]]

    --[[mct:log(tostring(ret))
    local json_string = ""
    local status, res = pcall(function() json_string = json.encode(ret) end)
    if not status then mct:log(res)  end
    mct:log(json_string)
    --mct:log(tostring(ret))
    --mct:log(ret)

    local file = io.open(self.settings_file, "w")
    file:write(json_string, "\n")
    file:close()]]

    --table.save(ret, self.settings_file)

    --local t = table.load(self.settings_file)
    --mct:log(tostring(t))

    --mct:log("is it this?")
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

            local mod_obj = mct:get_mod_with_name(mod_key)

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

            -- local mod_obj = self:instantiate_mod(mod_key, data)
        end

        --[[mct:log("Loading settings file!")
        local content = file:read("*all")
        local mct_data = json.decode(content)

        mct:log(content)
        --mct:log(mod_data)

        for key, mod_data in pairs(mct_data) do
            -- key = mod key
            -- settings = {option_key=val,option2=val2,etc}

            local mod_obj = self:instantiate_mod(key, mod_data)
            --local mod_obj = mct:get_mod_with_name(key)
            local options = mod_obj:get_options()
            
            -- grab option objs in the mod with each key, 
            for option_key, option_obj in pairs(options) do
                local option_obj = mod_obj:get_option_by_key(option_key)
                if option_obj then
                    mct:log("Setting finalized setting for option ["..option_key.."] with val ["..tostring(val).."].")

                    -- YIKES this sucks
                    option_obj:set_finalized_setting(val)
                    option_obj:set_default_value(val)
                end
            end
            mod_obj:load_finalized_settings()
        end]]
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
        local content = loadfile(self.settings_file)
        mct_data = content()

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

return settings
--- MCT Mod Object
-- @module mct_mod

local mct = mct

local mct_mod = {
    _name = "",
    _title = "No Title Assigned",
    _author = "No Author Assigned",
    _description = "No Description Assigned",
    --_workshop_link = "",
    --_options = {},

    _valid_option_types = {
        slider = true,
        dropdown = true,
        checkbox = true
    }
}

--- For internal use, called by the MCT Manager.
-- @tparam string key The identifying key for this mod object.
-- @see mct.register_mod
function mct_mod.new(key)
    local self = {}
    setmetatable(self, {
        __index = mct_mod,
        __tostring = function() return "MCT_MOD" end
    })

    self._key = key
    self._options = {}
    self._options_by_type = {
        dropdown = {},
        checkbox = {},
        slider = {}
    }
    self._coords = {
        --["1,2"] = option_key,
        --["3,5"] = option_key
        -- etcetc
    } -- positions for all the options, individual tables ordered numerically by top left -> top right -> down

    self._finalized_settings = {
        -- ["option_key"] = value,
        -- etc
    } -- read from the .json file

    -- start with the default section, if none are specified this is what's used
    self._sections = {
        {key = "default", txt = "Default Category"},
        
    }

    --self._options_by_section = {}

    return self
end

--- Add a new section to the mod's settings view, to separate them into several categories.
-- When this function is called, it assumes all following options being defined are being assigned to this section, unless further specified with
-- mct_option.
-- @tparam string section_key The unique identifier for this section.
-- @tparam string localised_name The localised text for this section. You can provide a direct string - "My Section Name" - or a loc key - "loc_key_example_my_section_name". If a loc key is provided, it will check first at runtime to see if that localised text exists. If no localised_name is provided, it will default to "No Text Assigned" 
function mct_mod:add_new_section(section_key, localised_name)
    if not is_string(section_key) then
        mct:error("add_new_section() tried on mct_mod with key ["..self:get_key().."], but the section_key supplied was not a string! Returning false.")
        return false
    end

    local table = {
        key = section_key,
        txt = localised_name
    }

    -- put the section key at the bottom of the sections list - used to find the last-made section, which is what new options will default to
    self._sections[#self._sections+1] = table
end

--- Returns a k/v table of {option_key=option_obj} for options that are linked to this section.
-- Shouldn't need to be used externally.
-- @tparam string section_key The unique identifier for this section.
function mct_mod:get_options_by_section(section_key)
    local options = self:get_options()
    local retval = {}
    for option_key, option_obj in pairs(options) do
        if option_obj:get_assigned_section() == section_key then
            retval[option_key] = option_obj
        end
    end

    return retval
    --return self._options_by_section[section_key]
end

--- Returns a table of all "sections" within the mct_mod.
-- These are returned as an array of tables, and each table has two indexes - ["key"] and ["txt"], for internal key and localised name, in that order.
function mct_mod:get_sections()
    return self._sections
end


function mct_mod:get_section_by_key(section_key)
    local sections = self:get_sections()
    for i = 1, #sections do
        local section = sections[i]
        if section.key == section_key then
            return section
        end
    end

    return nil
end

function mct_mod:get_last_section()
    -- return the last index in the _sections table
    return self._sections[#self._sections] or ""
end

--- Getter for the mct_mod's key
-- @treturn string key The key for this mct_mod
function mct_mod:get_key()
    return self._key
end

--- The finalize function is used for all actions needed to be performmed when the mct_mod is done being created, like setting positions for all options.
-- Triggered once the file which housed this mod_obj is done loading
function mct_mod:finalize()
    --mct:log("porsting 1")
    self:set_positions_for_options()
    --mct:log("porsting end")
end

--- Loops through all sections, and checks all options within each section, to save the x/y coordinates of each option.
-- Order the options by key within each section, giving sliders a full row to their own self
function mct_mod:set_positions_for_options()
    --mct:log("porsting 2")
    local sections = self:get_sections()
    --mct:log("porsting 3")

    mct:log("setting positions for options in mod ["..self:get_key().."]")
    
    for i = 1, #sections do
        local section_key = sections[i].key
        local attached_options = self:get_options_by_section(section_key)

        mct:log("in section ["..section_key.."].")

        --mct:log("porsting 4")

        --local total = 0
        --local option_keys = {}

        local ordered_option_keys = {}

        for key,_ in pairs(attached_options) do
            mct:log("option with key ["..key.."] detected in section.")
            table.insert(ordered_option_keys, key)
            --total = total + 1
            --option_keys[#option_keys+1] = key
        end

        table.sort(ordered_option_keys)

        local total = #ordered_option_keys

        mct:log("total num = " .. tostring(total))
        --mct:log("total num =" ..tostring(total))

        --mct:log("porsting 5")

        --local num_remaining = total

        local x = 1
        local y = 1

        -- only put sliders on x == 2

        local valid = true
        local j = 1
        local any_added_on_current_row = false
        local slider_added_on_current_row = false

        --mct:log("porsting 6")

        local function valid_for_type(type, x,y)
            -- hard check for sliders, must be in center and can't have any other options on the same row
            if type == "slider" then
                if x == 2 and not any_added_on_current_row then return true end
                return false
            end

            -- only sliders!
            if slider_added_on_current_row then
                return false
            end
            
            -- everything else is fine (for now!!!!!!)
            return true
        end

        local function iterate(added)
            if x == 3 then
                x = 1
                y = y + 1

                -- new row, set to false
                any_added_on_current_row = false
                slider_added_on_current_row = false
            else
                x = x + 1

                -- same row
                if added then
                    any_added_on_current_row = true
                end
            end
            if added then j = j + 1 end
        end

        --mct:log("porsting 7")

        while valid do
            --mct:log("on loop "..tostring(j))
            if j > total then
                break
            end

            --mct:log("porsting 8")

            local option_key = ordered_option_keys[j]
            --mct:log("key ["..option_key.."]")
            local option_obj = self:get_option_by_key(option_key)

            if mct:is_mct_option(option_obj) then

                --mct:log("checking pos for ["..option_key.."], j ["..tostring(j).."].")

                --mct:log(tostring(option_key))
                --mct:log(tostring(x)..", "..tostring(y))
                
                -- check if it's a valid position for that option's type (sliders only on 2)
                if valid_for_type(option_obj:get_type(), x, y) then
                    if option_obj:get_type() == "slider" then slider_added_on_current_row = true end
                    mct:log("setting pos for ["..option_key.."] at ("..tostring(x)..", "..tostring(y)..").")
                    option_obj:override_position(x,y)

                    iterate(true)

                    --j = j + 1
                else
                    -- if the current one is invalid, we should check the next few options to see if any are valid.
                    local done = false
                    --[[for k = 1, 2 do
                        if not done then
                            local next_option_key = ordered_option_keys[j+k]
                            local next_option_obj = self:get_option_by_key(next_option_key)
                            if mct:is_mct_option(next_option_obj) then
                                if valid_for_type(next_option_obj:get_type(), x, y) then
                                    if next_option_obj:get_type() == "slider" then slider_added_on_current_row = true end
                                    mct:log("setting pos for ["..next_option_key.."] at ("..tostring(x)..", "..tostring(y)..").")
                                    next_option_obj:override_position(x,y)

                                    done = true

                                    -- swap the positions of the last two keys
                                    ordered_option_keys[j] = next_option_key
                                    ordered_option_keys[j+k] = option_key
                                    --j = j + 1

                                    --break
                                end
                            end
                        end
                    end]]

                    iterate(done)
                end
            end
        end
    end
end

--- Used when loading the mct_settings.lua file.
function mct_mod:load_finalized_settings()
    local options = self:get_options()

    local ret = {}
    for key, option in pairs(options) do
        --mct:log("In option ["..key.."].")
        ret[key] = {}
        --option:set_finalized_setting(option:get_selected_setting())
        --mct:log("Finalized setting: "..tostring(option:get_finalized_setting()))
        ret[key] = option:get_finalized_setting()
    end

    self._finalized_settings = ret

    --return ret
end

--- Used when finalizing the settings in MCT.
function mct_mod:finalize_settings()
    local options = self:get_options()

    local ret = {}
    for key, option in pairs(options) do
        --mct:log("In option ["..key.."].")
        ret[key] = {}
        option:set_finalized_setting(option:get_selected_setting())
        --mct:log("Finalized setting: "..tostring(option:get_finalized_setting()))
        ret[key] = option:get_finalized_setting()
    end

    self._finalized_settings = ret

    return ret
end

--- Returns the _finalized_settings field of this mct_mod.
function mct_mod:get_settings()
    --[[local options = self:get_options()
    local retval = {}

    for key, option in pairs(options) do
        retval[key] = option:get_finalized_setting()
    end]]

    return self._finalized_settings
end

function mct_mod:get_last_coord()
    local coords = self._coords
    local last_coord = coords[#coords]
    if last_coord then
        return #coords, last_coord.x, last_coord.y
    end
end

-- used when UI is populated
function mct_mod:get_option_key_for_coords(x,y)
    if not is_number(x) or not is_number(y) then
        mct:error("get_option_key_for_coords() called for mct_mod with key ["..self:get_key().."], but the x/y coordinates supplied are not numbers! Returning false.")
        return false
    end

    local index = tostring(x) .. "," .. tostring(y)
    local object_key = self._coords[index]
    return object_key or "NONE"
end

function mct_mod:set_title(title_text, is_localised)
    if is_string(title_text) then

        self._title = {
            text = title_text, 
            is_localised = is_localised
        }
    end
end

function mct_mod:set_author(author_text, is_localised)
    if is_string(author_text) then

        self._author = author_text
    end
end

function mct_mod:set_description(desc_text, is_localised)
    if is_string(desc_text) then

        self._description = {
            text = desc_text, 
            is_localised = is_localised
        }
    end
end

--[[function mct_mod:set_workshop_link(link_text)
    if is_string(link_text) then
        self._workshop_link = link_text
    end
end]]

function mct_mod:get_title()
    -- check if a title exists in the localised texts!
    local title = effect.get_localised_string("mct_"..self:get_key().."_title")
    if title ~= "" then
        return title
    end

    title = self._title
    if title.is_localised then
        local test = effect.get_localised_string(title.text)
        if test ~= "" then
            return test
        end
    end

    return self._title.text or "No title assigned"
end

function mct_mod:get_author()
    local author = effect.get_localised_string("mct_"..self:get_key().."_author")
    if author ~= "" then
        return author
    end

    return self._author
end

function mct_mod:get_description()
    local description = effect.get_localised_string("mct_"..self:get_key().."_description")
    if description ~= "" then
        return description
    end

    description = self._description
    if description.is_localised then
        local test = effect.get_localised_string(description.text)
        if test ~= "" then
            return test
        end
    end

    return self._description.text or "No description assigned"
end

--[[function mct_mod:get_workshop_link()
    return self._workshop_link
end]]

function mct_mod:get_localised_texts()
    return 
        self:get_title(),
        self:get_author(),
        self:get_description()
        --self:get_workshop_link()
end

function mct_mod:get_options()
    return self._options
end

function mct_mod:get_option_keys_by_type(option_type)
    if not is_string(option_type) then
        mct:error("Trying `get_option_keys_by_type` for mod ["..self:get_key().."], but type provided is not a string! Returning false.")
        return false
    end

    local valid_types = self._valid_option_types
    if not valid_types[option_type] then
        mct:error("Trying `get_option_keys_by_type` for mod ["..self:get_key().."], but type ["..option_type.."] is not a valid type! Returning false.")
        return false
    end

    return self._options_by_type[option_type]
end

function mct_mod:get_option_by_key(option_key)
    if not is_string(option_key) then
        mct:error("Trying `get_option_by_key` for mod ["..self:get_key().."] but key provided ["..tostring(option_key).."] is not a string! Returning false.")
        return false
    end

    return self._options[option_key]
end

function mct_mod:add_new_option(option_key, option_type)
    -- check first to see if an option with this key already exists; if it does, return that one!

    mct:log("Adding option with key ["..option_key.."] to mod ["..self:get_key().."].")
    if not is_string(option_key) then
        mct:error("Trying `add_new_option()` for mod ["..self:get_key().."] but option key provided ["..tostring(option_key).."] is not a string! Returning false.")
        return false
    end

    if not is_string(option_type) then
        mct:error("Trying `add_new_option()` for mod ["..self:get_key().."] but option type provided ["..tostring(option_type).."] is not a string! Returning false.")
        return false
    end

    local valid_types = self._valid_option_types

    if not valid_types[option_type] then
        mct:error("Trying `add_new_option()` for mod ["..self:get_key().."] but option type provided ["..tostring(option_type).."] is not a valid type! Returning false.")
        return false
    end

    local mod = self

    local new_option = mct._MCT_OPTION.new(mod, option_key, option_type)

    self._options[option_key] = new_option
    self._options_by_type[option_type][#self._options_by_type[option_type]+1] = option_key

    mct:log("Assigned section: " .. tostring(new_option:get_assigned_section()))

    return new_option
end

function mct_mod:clear_uics_for_all_options()
    local opts = self:get_options()
    for _, option in pairs(opts) do
        option:clear_uics()
    end
end

return mct_mod
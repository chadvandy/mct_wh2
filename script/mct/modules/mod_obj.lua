--- MCT Mod Object
-- @module mct_mod

local mct_mod = {
    _name = "",
    _title = "No Title Assigned",
    _author = "No Author Assigned",
    _description = "No Description Assigned",
    _workshop_link = "",
    --_options = {},

    _valid_option_types = {
        slider = true,
        dropdown = true,
        checkbox = true
    }
}

mct._MCT_MOD = mct_mod

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

function mct_mod:add_new_section(section_key, localised_name)
    if not is_string(section_key) then
        -- errmsg
        return false
    end

    local table = {
        key = section_key,
        txt = localised_name
    }

    -- put the section key at the bottom of the sections list - used to find the last-made section, which is what new options will default to
    self._sections[#self._sections+1] = table
end

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

function mct_mod:get_sections()
    return self._sections
end

function mct_mod:get_last_section()
    -- return the last index in the _sections table
    return self._sections[#self._sections] or ""
end

function mct_mod:get_key()
    return self._key
end

-- triggered once the file which housed this mod_obj is done loading
function mct_mod:finalize()
    self:set_positions_for_options()
end

function mct_mod:set_positions_for_options()
    local settings = self:get_sections()
    
    for i = 1, #settings do
        local settings_key = settings[i].key
        local attached_options = self:get_options_by_section(settings_key)

        local total = 0
        local option_keys = {}

        for key,_ in pairs(attached_options) do
            total = total + 1
            option_keys[#option_keys+1] = key
        end

        local num_remaining = total

        local x = 1
        local y = 1

        for i = 1, #option_keys do
            local option_key = option_keys[i]
            local option_obj = self:get_option_by_key(option_key)

            option_obj:override_position(x,y)

            if x == 3 then
                x = 1 
                y = y + 1
            else
                x = x + 1
            end
        end

        --[[local valid = true
        while valid do
            if num_remaining <= 0 then
                break
            end

            -- grab the next option

        end]]
    end
end

function mct_mod:finalize_UNUSED_FUCK________()  
    mct:log("Beginning finalize for mod ["..self:get_key().."].")

    
    
    local dropdown_option_keys = self:get_option_keys_by_type("dropdown")
    local checkbox_option_keys = self:get_option_keys_by_type("checkbox")
    local slider_option_keys = self:get_option_keys_by_type("slider")

    -- loop indices for dropdown/checkbox/slider
    -- if all 3 grow over max size, kill the loop
    local di = 1
    local ci = 1
    local si = 1

    local di_max = #dropdown_option_keys
    local ci_max = #checkbox_option_keys
    local si_max = #slider_option_keys

    --mct:log("di,ci,si maxes: ("..tostring(di_max)..", "..tostring(ci_max)..", "..tostring(si_max).. ").")

    local x = 1
    local y = 1

    local valid = true
    while valid do
        -- no more options!
        if di > di_max and ci > ci_max and si > si_max then
            break
        end

        local option_key = ""
        local option_obj = nil

        -- untouched by the iterators within
        local curr_x = x
        local curr_y = y

        -- get the string for the index, ie. "1,2"
        local index = tostring(curr_x) .. "," .. tostring(curr_y)

        --mct:log("Current index being checked ["..index.."]")

        -- if we're in the first two rows
        if x < 3 then
            -- prioritize dropdowns
            if di <= di_max then
                option_key = dropdown_option_keys[di]
                di = di + 1
            -- check checkboxes next -- JK skip checkboxes for now
            --[[elseif ci <= ci_max then
                option_key = checkbox_option_keys[ci]
                ci = ci + 1]]
            -- check sliders next, but only put them on the second column
            elseif si <= si_max and x == 2 then
                option_key = slider_option_keys[si]
                si = si + 1
            end

            -- move to the next column next loop
            x = x + 1
        else
            -- prioritize checkboxes first
            if ci <= ci_max then
                option_key = checkbox_option_keys[ci]
                ci = ci + 1
            -- check dropdowns next
            --[[elseif di <= di_max then
                option_key = dropdown_option_keys[di]
                di = di + 1]]
            -- don't check for sliders
            end

            -- move to the first column of the next row, next loop
            x = 1
            y = y + 1
        end

        -- check if no option was determined for this coord
        if option_key == "" then
            -- save so that the loop in ui.lua can see that this is intentionally blank
            self._coords[index] = "MCT_BLANK"
        else
            -- get the option obj with this key
            option_obj = self:get_option_by_key(option_key)

            -- save the coords in the option & mod objects
            option_obj:override_position(curr_x, curr_y)
        end
    end



        -- if not - pick the next on the list
        --if not option_key then
            --local option = all_options[ordered_option_keys[i]]
            --option:override_position(x,y)
            --table.remove(ordered_option_keys, i)
            --i = i + 1
        
        -- if there is, grab that one and remove it from the table
        --[[else
            local option = all_options[option_key]

        end
    end]]
    --[[for key, option in pairs(all_options) do
        local index = tostring(x) .. "," .. tostring(y)
        local option_key = self._coords[index]
        if not option_key then

        end
    end]]
end

function mct_mod:load_finalized_settings()
    local options = self:get_options()

    local ret = {}
    for key, option in pairs(options) do
        mct:log("In option ["..key.."].")
        ret[key] = {}
        --option:set_finalized_setting(option:get_selected_setting())
        mct:log("Finalized setting: "..tostring(option:get_finalized_setting()))
        ret[key] = option:get_finalized_setting()
    end

    self._finalized_settings = ret

    --return ret
end

function mct_mod:finalize_settings()
    local options = self:get_options()

    local ret = {}
    for key, option in pairs(options) do
        mct:log("In option ["..key.."].")
        ret[key] = {}
        option:set_finalized_setting(option:get_selected_setting())
        mct:log("Finalized setting: "..tostring(option:get_finalized_setting()))
        ret[key] = option:get_finalized_setting()
    end

    self._finalized_settings = ret

    return ret
end

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
    if not is_number(x) then
        -- errmsg
        return false
    end

    if not is_number(y) then
        -- errmsg
        return false
    end

    local index = tostring(x) .. "," .. tostring(y)
    local object_key = self._coords[index]
    return object_key or "NONE"
end

--[[function mct_mod:set_title(title_text, is_localised)
    if is_string(title_text) then

        self._title = {title_text, is_localised}
    end
end]]

--[[function mct_mod:set_author(author_text)
    if is_string(author_text) then

        self._author = author_text
    end
end]]

--function mct_mod:set_description(desc_text, is_localised)
--    if is_string(desc_text) then
        --[[local t = desc_text
        if is_localised then
            t = effect.get_localised_string(t)
        end]]

--        self._description = {desc_text, is_localised}
--    end
--end

function mct_mod:set_workshop_link(link_text)
    if is_string(link_text) then
        self._workshop_link = link_text
    end
end

function mct_mod:get_title()
    -- check if a title exists in the localised texts!
    local title = effect.get_localised_string("mct_"..self:get_key().."_title")
    if title ~= "" then
        return title
    end

    return self._title

    -- _title is a table with {"text/key", is_localised_text}
    --[[local title_table = self._title
    
    local title_text = title_table[1]
    local is_localised = title_table[2]

    if is_localised then
        title_text = effect.get_localised_string(title_text)
    end

    return title_text]]
end

function mct_mod:get_author()
    local author = effect.get_localised_string("mct_"..self:get_key().."_author")
    if author ~= "" then
        return author
    end

    return self._author
    --return self._author --or "No author"
end

function mct_mod:get_description()
    local description = effect.get_localised_string("mct_"..self:get_key().."_description")
    if description ~= "" then
        return description
    end

    return self._description
    --[[local text_table = self._description

    local text = text_table[1]
    local is_localised = text_table[2]

    if is_localised then
        text = effect.get_localised_string(text)
    end

    return text]]
end

function mct_mod:get_workshop_link()
    return self._workshop_link --or ""
end

function mct_mod:get_localised_texts()
    return 
        self:get_title(),
        self:get_author(),
        self:get_description(),
        self:get_workshop_link()
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
    mct:log("Adding option with key ["..option_key.."] to mod ["..self:get_key().."].")
    if not is_string(option_key) then
        -- errmsg
        return
    end

    if not is_string(option_type) then
        -- errmsg
        return
    end

    --[[if not is_string(option_text) then
        -- errmsg
        return
    end

    if not is_string(option_tt) then
        -- that's actually fine
        option_tt = ""
    end]]

    local valid_types = self._valid_option_types

    if not valid_types[option_type] then
        -- errmsg
        return
    end

    local mod = self

    local new_option = mct._MCT_OPTION.new(mod, option_key, option_type)

    self._options[option_key] = new_option
    self._options_by_type[option_type][#self._options_by_type[option_type]+1] = option_key

    return new_option
end

function mct_mod:clear_uics_for_all_options()
    local opts = self:get_options()
    for key, option in pairs(opts) do
        option:clear_uics()
    end
end


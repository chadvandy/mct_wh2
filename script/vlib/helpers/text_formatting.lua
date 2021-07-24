local vlib = get_vandy_lib()

--- Testing testing
---@param text string
---@return string
function vlib_format_text(text)
    if not is_string(text) then
        return ""
    end

    -- check for wrapped {{loc:loc_key}} text. If there's any, automatically replace it with the localised string.
    local x,start = text:find("{{loc:")
    if x then
        local close,y = text:find("}}", start+1)
        if close then
            local loc_key = text:sub(start+1, close-1)

            local loc_text = effect.get_localised_string(loc_key)
            
            return table.concat({text:sub(1, x-1), loc_text, text:sub(y+1, -1)})
        end
    end

    return text
end
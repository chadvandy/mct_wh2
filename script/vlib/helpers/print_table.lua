--- TODO
--- Print a Lua table to a file, for many reasons.

-- Indentation
local tab = 0

--- Turns a Lua table into a formatted string, wrapped with "return {}". This is so the Lua table can be written to a file on disk, and loaded up later so information can be stored.
---@param t any
function print_table(t)
    local str = "return {\n"


end

--- Take a file on disk, and convert it back into a table!
function read_table()

end
-- this is the actual functionality that takes a table of hexadecimal fields, runs through them, and constructs some sort of meaningful shit out of it
-- it starts by creating a new UIC class, adding all of the hexadecimal fields into it, and then it runs through and constructs further objects within - creating a "state" object for each state, so on
-- each UIC class has its own fields for editing, tooltipping, and display

-- the layout_parser also is where all the internal versioning is, and if all goes well, is the only file that needs updating each CA patch (when a new UIC version is introduced).

---@type UIED
local uied = core:get_static_object("ui_editor_lib")

---@class UIED_Parser
local parser = {
    -- name = "blorp",
    data = nil,             -- this is the saved hex data, cleared on every call

    root_uic = nil,         -- this is the saved UIC object which contains every field and baby class, also cleared on every call
    location = 1,           -- used to jump through the hex bytes

    version = 0,
}

-- create a 4-byte hex code (ie. "AF 52 C4 DE"), randomly
function parser:regenerate_uiid()
    local hexes = {
        "0",
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
    }

    local bytes = {}

    math.randomseed(os.time())

    for i = 1,8 do
        local c = hexes[math.random(1, #hexes)]

        bytes[#bytes+1] = c
    end

    local str = table.concat(bytes, "")

    return str
end

function parser:bool_to_chunk(bool)
    if not is_boolean(bool) then
        -- errmsg
        return false
    end

    local hex_str = ""

    if bool == true then hex_str = "01" elseif bool == false then hex_str = "00" end

    return hex_str
end

function parser:utf16_to_chunk(str)
    -- first, grab the length
    local hex_str = ""

    local len = str:len()

    uied:log("Length of str: "..len)
    local hex_len = string.format("%02X", len)-- ..  "00"

    for _ = 1, 4-hex_len:len() do
        hex_len = hex_len .. "0"
    end

    uied:log("Hex len of str: "..hex_len)

    hex_str = hex_len

    -- loop through each char in the string
    for i = 1, len do
        local c = str:sub(i, i)
        -- print(c)
        uied:log(c)

        -- string.byte converts the character (ie. "r") to the binary data, and then string.format turns the binary byte into a hexadecimal value
        -- it's done this way so it can be one long, consistent hex string, then turned completely into a bin string
        c = string.format("%02X", string.byte(c)) .. "00"

        -- the "00" is added padding for utf8's

        hex_str = hex_str .. c
    end

    -- loops through every single hex byte (ie. everything with two hexa values, %x%x), then converts that byte into the relevant "char"
    -- for byte in hex_str:gmatch("%x%x") do
    --     -- print(byte)

    --     local bin_byte = string.char(tonumber(byte, 16))

    --     -- print(bin_byte)

    --     bin_str = bin_str .. bin_byte
    -- end

    -- uied:log(bin_str)

    return hex_str
end

-- parsers here (translate raw hex into actual data, and vice versa)
function parser:utf8_to_chunk(str)
    -- TODO errmsg if not a string or whatever?

    -- first, grab the length
    local hex_str = ""

    local len = str:len()

    uied:log("Length of str: "..len)
    local hex_len = string.format("%02X", len)-- ..  "00"

    for _ = 1, 4-hex_len:len() do
        hex_len = hex_len .. "0"
    end

    uied:log("Hex len of str: "..hex_len)

    hex_str = hex_len

    -- loop through each char in the string
    for i = 1, len do
        local c = str:sub(i, i)
        -- print(c)
        uied:log(c)

        -- string.byte converts the character (ie. "r") to the binary data, and then string.format turns the binary byte into a hexadecimal value
        -- it's done this way so it can be one long, consistent hex string, then turned completely into a bin string
        c = string.format("%02X", string.byte(c))

        hex_str = hex_str .. c
    end

    -- loops through every single hex byte (ie. everything with two hexa values, %x%x), then converts that byte into the relevant "char"
    -- for byte in hex_str:gmatch("%x%x") do
    --     -- print(byte)

    --     local bin_byte = string.char(tonumber(byte, 16))

    --     -- print(bin_byte)

    --     bin_str = bin_str .. bin_byte
    -- end

    -- uied:log(bin_str)

    return hex_str
end

function parser:int16_to_chunk(int)
    local hex = string.format("%X", int)
    
    if hex:len() < 4 then
        for _ = 1, 4 - hex:len() do
            hex = "0" .. hex
        end
    end

    local data = {}
    for i = 2,4,2 do
        local c = hex:sub(i-1, i)
        data[#data+1] = c
    end

    local str = ""
    for i = #data,1,-1 do
        str = str .. data[i]
    end

    return str
end

-- takes an integer and turns it into the relevant hex
function parser:int32_to_chunk(int)
    -- convert the integer into a hex right away.
    -- this converts "1920" into "780"
    local hex = string.format("%X", int)

    -- add in padding to get the number up to 4 total bytes
    -- becomes "00000780"
    if hex:len() < 8 then
        for _ = 1, 8 - hex:len() do
            hex = "0" .. hex
        end
    end

    -- split the full string into the 4 separate bytes
    -- ie., {00, 00, 07, 80}
    local data = {}
    for i = 2,8,2 do
        local c = hex:sub(i-1,i)
        data[#data+1] = c
    end

    -- recreate the string with little endian (so the smallest byte is first, largest byte is last)
    -- ie., "80070000" (the correct version!)
    local str = ""
    for i = #data,1,-1 do
        str = str .. data[i]
    end

    return str
end

-- https://stackoverflow.com/questions/18886447/convert-signed-ieee-754-float-to-hexadecimal-representation
-- thanks internet
local function float2hex (n)
    if n == 0.0 then return 0.0 end

    local sign = 0
    if n < 0.0 then
        sign = 0x80
        n = -n
    end

    local mant, expo = math.frexp(n)
    local hext = {}

    if mant ~= mant then
        hext[#hext+1] = string.char(0xFF, 0x88, 0x00, 0x00)

    elseif mant == math.huge or expo > 0x80 then
        if sign == 0 then
            hext[#hext+1] = string.char(0x7F, 0x80, 0x00, 0x00)
        else
            hext[#hext+1] = string.char(0xFF, 0x80, 0x00, 0x00)
        end

    elseif (mant == 0.0 and expo == 0) or expo < -0x7E then
        hext[#hext+1] = string.char(sign, 0x00, 0x00, 0x00)

    else
        expo = expo + 0x7E
        mant = (mant * 2.0 - 1.0) * math.ldexp(0.5, 24)
        hext[#hext+1] = string.char(sign + math.floor(expo / 0x2),
                                    (expo % 0x2) * 0x80 + math.floor(mant / 0x10000),
                                    math.floor(mant / 0x100) % 0x100,
                                    mant % 0x100)
    end

    return tonumber(string.gsub(table.concat(hext),"(.)",
                                function (c) return string.format("%02X%s",string.byte(c),"") end), 16)
end

local function hex2float (c)
    if c == 0 then return 0.0 end
    local c = string.gsub(string.format("%X", c),"(..)",function (x) return string.char(tonumber(x, 16)) end)
    local b1,b2,b3,b4 = string.byte(c, 1, 4)
    local sign = b1 > 0x7F
    local expo = (b1 % 0x80) * 0x2 + math.floor(b2 / 0x80)
    local mant = ((b2 % 0x80) * 0x100 + b3) * 0x100 + b4

    if sign then
        sign = -1
    else
        sign = 1
    end

    local n

    if mant == 0 and expo == 0 then
        n = sign * 0.0
    elseif expo == 0xFF then
        if mant == 0 then
            n = sign * math.huge
        else
            n = 0.0/0.0
        end
    else
        n = sign * math.ldexp(1.0 + mant / 0x800000, expo - 0x7F)
    end

    return n
end

local function intToHex(IN)
    local B,K,OUT,I=16,"0123456789ABCDEF","",0
    local D
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),math.mod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
    end


    OUT = "0x" .. OUT
    return OUT
end

function parser:float_to_hex(float)
    local int = float2hex(float)

    local hex = intToHex(int)

    return hex
end

function parser:grab_block(j, k)
    if not is_number(j) then j = self.location end
    if not is_number(k) then k = self.location end

    k = math.clamp(k, self.location, #self.data)

    local ret = {}
    for i = j, k do
        local data = self.data[i]
        if is_nil(data) then break end

        ret[#ret+1] = tostring(data)
    end

    return ret
end

-- little-endian, four-bytes number. 00 00 80 3F -> 1, 00 00 00 40 -> 2, 00 00 80 40 -> 3, no clue what the patter here is.
-- TODO make this!
function parser:chunk_to_float(j)
    local k = j + 3
    -- for now, just do int32, fuck it
    -- grab the relevant bytes

    -- for now, disbable it for int32
    do
        return self:chunk_to_int32(j, k)
    end

    local block = self:grab_block(j, k)

    -- flip the bytes! (changed 56 00 to 00 56, still a table)
    local flipped = {}
    for i = #block,1,-1 do -- loop backwards, starting at the end and going to the start by -1 each loop (ie. from 2 to 1, lol)
        flipped[#flipped+1] = tostring(block[i])
    end

    local str = "0x"..table.concat(flipped, "")
    uied:log("Hex for float at ["..j.."] ["..k.."] is ["..str.."].")

    local float = hex2float(str)
    local hex = self:chunk_to_hex(j, k)

    return float,hex,k
end

-- converts a series of hexadecimal bytes (between j and k) into a string
-- takes an original 2 bytes *before* the string as the "len" identifier.
function parser:chunk_to_utf8(j, k)
    if not k then k = -1 end
    -- local k = -1
    uied:log("chunk to str "..tostring(j) .. " & "..tostring(k))

    local start_j = j

    -- first two bytes are the length identifier
    if k == -1 then
        local len = (self:chunk_to_int16(j, j+1) or 0)
        uied:log("len is: "..tostring(len))

        -- if the len is 0, then just return a string of "" (for optional strings)
        if len == 0 then 
            uied:log(tostring(j)) 
            uied:log(tostring(j+1)) 
            return "\"\"", self:chunk_to_hex(j, j+1), j+1 
        end

        -- set k to the proper spot
        k = len + self.location -1

        -- move j and k up by 2 (for the length above)
        j = j + 2
        k = k + 2
    end


    -- adds each relevant hexadecimal byte into a table (only the string!)
    local block = self:grab_block(j, k)

    -- run through that table and convert the hex into formatted strings (\x56 from 56, for instance). Front-loaded so the first bit will also be converted!
    local str = "\\x" .. table.concat(block, "\\x")

    -- for i = 1, #block do
    --     str = str .. "\\x" .. (block[i] or "")
    -- end

    -- for each pattern of formatted strings (`\x56`), convert it into its char'd form
    -- tonumber(x,16) changes the number (56) to its place in binary (86) into the ASCII char (V)
    local ret = str:gsub("\\x(%x%x)", function(x) return string.char(tonumber(x,16)) end)
    local hex = self:chunk_to_hex(start_j, k) -- start at the BEGINNING of "len", end at the end of the string

    uied:logf("Deciphering a UTF8 string, undeciphered hex is %q, deciphered str is %q.", str, ret)

    return ret,hex,k
end

-- converts a length of text into a string-16 (which is, in hex, a string with empty 00 bytes between each character)
function parser:chunk_to_utf16(j)
    local k = -1
    -- first two bytes are the length identifier (tells the game how long the incoming string is)

    local start_j = j
    local len = self:chunk_to_int16(j, j+1)

    -- if the len is 0, then just return a string of "" (for optional strings)
    if len == 0 then return "\"\"", self:chunk_to_hex(j, j+1), j+1 end

    -- double "len", since it's counting every 2-byte chunk (ie. a length of 4 would be "56 00 12 00 53 00 12 00")
    len = len*2

    -- set k to the proper spot
    k = len + self.location -1

    -- move j and k up by 2 (offset them by the length identifier above)
    j = j + 2 k = k + 2

    local block = self:grab_block(j, k)
    -- for i = j,k do
    --     block[i] = self.data[i]
    -- end

    local str = ""
    for i = 1,#block,2 do -- the "2" iterates by 2 instead of 1, so it'll skip every unwanted 00
        str = str .. "\\x" .. block[i]
    end

    local ret = str:gsub("\\x(%x%x)", function(x) return string.char(tonumber(x,16)) end)
    local hex = self:chunk_to_hex(start_j, k)

    return ret,hex,k
end

-- turn the table of text into a single string (ie. {84, 03, 00 00} into "84 03 00 00")
function parser:chunk_to_hex(j, k)
    if not k then k = j + 1 end
    local block = self:grab_block(j, k)

    local ret = table.concat(block, " ")
    local hex = ret

    return ret,hex,k
end

function parser:chunk_to_int8(j)
    local k = j

    local block = self:grab_block(j, k)

    -- take the bytes and turn them into a string (ie. "0056")
    local str = table.concat(block, "")

    local ret = tonumber(str, 16)
    local hex = self:chunk_to_hex(j, k)

    -- turn the string into a number, using base-16 to convert it (which turns "0056" into 86, since tonumber drops excess 0's)
    return ret,hex,k
end

-- takes two bytes and turns them into a Lua number
-- always an unsigned int16, which means it's a hex byte converted into a number followed by an empty 00
-- this is "little endian", which means the hex is actually read backwards. ie., 56 00 is actually read as 00 56, which is translated to 00 86 in base-16
function parser:chunk_to_int16(j)
    local k = j + 1
    uied:log("chunk to int16 between "..tostring(j).." and " ..tostring(k))

    -- grab the relevant bytes
    local block = self:grab_block(j, k)
    -- for i = j,k do
    --     block[i] = self.data[i]
    -- end

    -- flip the bytes! (changed 56 00 to 00 56, still a table)
    local flipped = {}
    for i = #block,1,-1 do -- loop backwards, starting at the end and going to the start by -1 each loop (ie. from 2 to 1, lol)
        flipped[#flipped+1] = block[i]
    end

    -- take the bytes and turn them into a string (ie. "0056")
    local str = table.concat(flipped, "")

    local ret = tonumber(str, 16)
    local hex = self:chunk_to_hex(j, k)

    -- turn the string into a number, using base-16 to convert it (which turns "0056" into 86, since tonumber drops excess 0's)
    return ret,hex,k
end


-- convert a 4-byte hex section into an integer
-- this part is a little weird, since integers like this are actually read backwards in hex (little-endian). ie., 84 03 00 00 in hex is read as 00 00 03 84, which ends up being 03 84, which is converted into 900
function parser:chunk_to_int32(j)
    local k = j + 3

    local block = self:grab_block(j, k)
    -- for i = j,k do
    --     block[i] = self.data[i]
    -- end

    local str = ""

    for i = #block,1, -1 do
        str = str .. block[i]
    end

    local ret = tonumber(str, 16)
    local hex = self:chunk_to_hex(j, k)

    return ret,hex,k
end

-- convert a single byte into true or false. 00 for false, 01 for true
function parser:chunk_to_boolean(j)
    local k = j
    local hex = self:chunk_to_hex(j, k)

    local ret = false
    if hex == "01" then
        ret = true
    elseif hex == "00" then
        ret = false
    else 
        uied:logf("Chunk to boolean called at location %q, but the bit isn't a Bool!", tostring(j))
        ret = nil
    end

    return ret,hex,k
end

function parser:chunk_to_fraction(j)
    local k = j
    local int = self:chunk_to_int8(j)

    local ret = int / 256
    local hex = self:chunk_to_hex(j, k)

    return ret,hex,k
end

-- TODO make sure it's only the one type, and format it before. Ie., only "utf8", but format StringU8 to become "utf8"
parser.format_to_func = {
    ----- native types -----

    -- string types (hex is a string-ified set of hexadecimal bytes, ie "84 03 00 00")
    StringU8 = parser.chunk_to_utf8,
    utf8 = parser.chunk_to_utf8,
    
    StringU16 = parser.chunk_to_utf16,
    utf16 = parser.chunk_to_utf16,

    Hex = parser.chunk_to_hex,
    hex = parser.chunk_to_hex,

    -- number types!
    I16 = parser.chunk_to_int16,
    int16 = parser.chunk_to_int16,
    
    I32 = parser.chunk_to_int32,
    int32 = parser.chunk_to_int32,
    float = parser.chunk_to_float,

    -- boolean (with a pseudonym)
    bool = parser.chunk_to_boolean,
    boolean = parser.chunk_to_boolean,
    Boolean = parser.chunk_to_boolean,
}

parser.basic_types = {
    utf8 = parser.chunk_to_utf8,
    utf16 = parser.chunk_to_utf16,
    int8 = parser.chunk_to_int8,
    int16 = parser.chunk_to_int16,
    int32 = parser.chunk_to_int32,
    float = parser.chunk_to_float,
    boolean = parser.chunk_to_boolean,
    fraction = parser.chunk_to_fraction,
}

function parser:is_valid_type(t)
    return self.basic_types[t] or self.format_to_func[t]
end

function parser:decipher_chunk(format, j, k)
    if is_nil(j) then j = 1 end
    if is_nil(k) then k = -1 end
    j = j + self.location - 1
    if k ~= -1 then
        k = k + self.location - 1
        k = math.clamp(k, j, #self.data)
    end

    uied:log("deciphering chunk ["..tostring(j).." - "..tostring(k) .. "], with format ["..format.."]")

    local func = self.format_to_func[format]
    if not func then uied:log("func not found") return end

    -- this returns the *value* searched for, the string'd hex of the chunk, and the start and end indices (needed for types such as strings or tables with unknown lengths before deciphering)
    local value,hex,end_k = func(self, j, k)

    -- set location to k+1, for next decipher_chunk call
    self.location = end_k+1

    -- increase the internal field count

    uied:log("Deciphered hex is: \n\t" .. hex)

    -- if string.find(hex, "nil") then
    --     return
    -- end

    return value,hex
end

local formats_to_format_formation = {
    Hex = "hex",
    StringU8 = "utf8",
    StringU16 = "utf16",
    Boolean = "boolean",
    bool = "boolean",
    I16 = "int16",
    I32 = "int32",
}

---- TODO remove "override"; it's to prevent the "templatecomponent" check within a template component. SUCKS.
function parser:decipher_collection(collected_type, obj_to_add, override, ...)
    local keys
    local override_fields
    local my_len
    if is_table(collected_type) then
        local tab = collected_type
        keys = tab.keys

        if tab.type then
            collected_type = tab.type
        end

        if tab.override_fields then
            override_fields = tab.override_fields
        end

        if tab.length then
            my_len = tab.length
        end
        
        tab = nil
    end

    if not is_string(collected_type) then
        -- errmsg
        return false
    end

    -- turns it from "ComponentImage" to "ComponentImages", very simply
    local key = collected_type.."s"

    -- TODO I can do better than this
    if collected_type == "ComponentProperty" then
        key = "ComponentProperties"
    elseif collected_type == "ComponentTemplateChild" then
        key = "ComponentTemplateChildren"
    end

    uied:log("\ndeciphering "..key)

    -- every collection starts with an int32 (four bytes) to inform how much of that thing is within
    local len
    if is_string(override) and override == "I16" then
        len = self:decipher_chunk("int16")
    elseif is_number(override) then
        len = override
    elseif is_table(keys) then
        len = #keys
    elseif is_number(my_len) then
        len = my_len
    -- TODO FUCK clean this the fuck up.
    elseif collected_type == "ComponentTemplateChildState" then
        local template_key = obj_to_add._template_key
        if not template_key then
            uied:logf("Trying to create a template child state collection for obj %q, but the template key was not saved!", obj_to_add:get_key())

            return
        end

        -- template_key = template_key:get_value()

        local reg_template = uied._templates[template_key]
        if not reg_template then
            uied:logf("Trying to create a template child state collection for obj %q with template key %q, but there is no template saved with that key!", obj_to_add:get_key(), template_key)

            return
        end

        -- TODO absolute spaghetti, fix it.
        do
            local data = reg_template:get_data()
            uied:logf("Searching template %q for the number of states within the main UIC.", template_key)
            for j = 1, #data do
                ---@type UIC_BaseClass
                local datum = data[j]
                -- uied:logf("Found top-level data ")
                if datum:get_key() == "Components" then
                    local component_collection_data = datum:get_data()
                    uied:logf("Found main-level component collection, searching for the child component. Num children is %d", #component_collection_data)
                    for k = 1, #component_collection_data do
                        local component = component_collection_data[k]
                        uied:logf("Component found with key %q. Checking for States collection.", component:get_key())
                        local component_data = component:get_data()
    
                        for l = 1, #component_data do
                            local inner_data = component_data[l]
                            if inner_data:get_key() == "ComponentStates" then
                                len = #inner_data:get_data()
                                uied:logf("States collection found. Number of states is %d", len)
                            end
                        end
                    end
                end
            end
        end
    else
        len = self:decipher_chunk("int32")
    end

    --dec(collected_type.."len","int32", 4, obj_to_add):get_value()

    uied:log("len of "..key.." is "..tostring(len))

    -- local ret = {}

    local collection = uied:new_obj("Collection", key, nil, collected_type)

    -- collection.held_type = collected_type

    if override_fields then
        for i = 1, #override_fields do
            local field = override_fields[i]
            local my_key = field.key or key.."_override_"..i
            local format = field.type
            local my_len = field.length or -1

            self:dec(my_key, format, my_len, collection)

            -- collection:add_data(val)
        end
    end

    for i = 1, len do
        local val

        -- TODO templates and UIC's are really the same thing, don't treat them differently like this
        if collected_type == "Component" then
            local bits,bits_hex = self:decipher_chunk("hex", 1, 2)

            -- local bits = deciph("bits", "hex", 2):get_value() --parser:decipher_chunk("hex", 1, 2)
            if bits == "00 00" or override == true then
                local child = uied:new_obj("Component")
                if bits == "00 00" then
                    local new_field = uied._classes.Field:new("bits", bits, bits_hex)
                    child:add_data(new_field)
                else
                    self.location = self.location -2
                end
    
                uied:log("deciphering new component within "..obj_to_add:get_key())
                child:decipher()
    
                uied:log("component deciphered with key ["..child:get_key().."]")
    
                uied:log("adding them to the current obj, "..obj_to_add:get_key())

                val = child
            else
                self.location = self.location -2
    
                -- TODO this shouldn't be separate
                local template = uied:new_obj("ComponentTemplate")
                template:decipher()

                val = template
            end
        elseif collected_type == "ComponentTemplateChild" then
            local template_key = obj_to_add:get_data_with_key("template_key")

            local new_type = uied:new_obj(collected_type)
            
            new_type._template_key = template_key
            uied:logf("Deciphering Component Template Children, saving the template key as %q for template child.", template_key)
            
            val = new_type:decipher()
            --local val,new_hex,end_k = func(self)

            -- set the key as, example, "ComponentMouse1" (if there's no ui-id or name set!)
            val:set_key(collected_type..tostring(i), "index")
            uied:log("created "..collected_type.." with key "..val:get_key())
        else
            -- This makes collections work for native types! Why didn't I do this earlier!
            local format = formats_to_format_formation[collected_type] or collected_type
            if self.format_to_func[format] then
                -- if it's an array, use "Component1, Component2"
                -- if it's a map with predefined keys, use them, ie. "Width", "Height"
                local my_key = key..i
                if keys then
                    my_key = keys[i]
                end

                -- :dec() auto-adds the new field to the collection :)
                self:dec(my_key, format, -1, collection)
            else
                local new_type = uied:new_obj(collected_type)
                val = new_type:decipher(...)

                --local val,new_hex,end_k = func(self)

                -- set the key as, example, "ComponentMouse1" (if there's no ui-id or name set!)
                val:set_key(collected_type..tostring(i), "index")
                uied:log("created "..collected_type.." with key "..val:get_key())
            end
        end

        if val then
            val:set_parent(collection)

            collection:add_data(val)
            -- ret[#ret+1] = val
            --hex = hex .. new_hex
        end
    end

    -- collection.data = ret

    obj_to_add:add_data(collection)

    return collection--,hex
end

function parser:get_version()
    return self.root_uic and self.root_uic:get_version()
end

-- key here is a unique ID so the field can be saved into the root uic. key also references the relevant tooltip and text localisations
-- format is the type you're expecting - hex, str, int32, etc. Can also be the Lua object type - ie., "ComponentImage". If a native type is provided, a "Field" is returned
-- k is the end searched location. ie., if you're looking at a 4-byte field, k should be 4. k default to -1, for "unknown length". k can be a k/v table as well, for fields with multiple data inside (ie. offsets). it should be a k/v table with keys linked to lengths (ie. {x=4,y=4})
-- obj is the object it's being added to (ie. is this field in a specific state, or component, or WHAT). Defaults to the root uic obj
function parser:dec(key, format, k, obj)
    local j = 1 -- always start at the first byte!

    if is_nil(k) then     k = -1              end         -- assume k is -1 when undefined
    if is_nil(obj) then   obj = self.root_uic end         -- assume the referenced object is the root component

    if formats_to_format_formation[format] then
        format = formats_to_format_formation[format]
    end

    local new_field = nil

    -- if k is a table, decipher the chunks through a loop
    if is_table(k) then
        local val = {}
        local hex_boi = ""
        for i_key,v in pairs(k) do
            -- "v" is the end location here
            local ret,hex = self:decipher_chunk(format, j, v)
            val[i_key]=ret
            hex_boi=hex_boi.." "..hex
        end

        new_field = uied._classes.Field:new(key, val, hex_boi)
        uied:log("chunk deciphered with key ["..key.."], the hex was ["..hex_boi.."]")
    else -- k is not a table, decipher normally
        local ret,hex = self:decipher_chunk(format, j, k)

        new_field = uied._classes.Field:new(key, ret, hex)

        if is_nil(ret) then 
            new_field.value = "Error while decoding!"
            new_field:set_native_type("ERROR")
         end

        uied:log("chunk deciphered with key ["..key.."], the hex was ["..hex.."]")
    end

    new_field:set_native_type(format)

    return obj:add_data(new_field)
end

-- this function goes through the entire hexadecimal table, and translates each bit within into the relevant Lua object
-- this means the entire layout file is turned into a "root_uic" Lua object, which has methods to get all states, all children, all the children's states, etc., etc., as well as methods for display and getting specific fields
-- each Lua object holds other important data, such as the raw hex associated with that field
-- this function needs to be updated with any new UIC version created
-- function parser:decipher()
--     if is_nil(self.data) then
--         -- errmsg
--         return false
--     end

--     uied:log("decipher name: "..self.name)

--     local root_uic = self.root_uic

--     self:decipher_component(true)

--     return root_uic
-- end

setmetatable(parser, {
    __index = parser,
    ---comment
    ---@param self UIED_Parser
    ---@param hex_table any
    ---@return UIC_Component
    ---@return number
    __call = function(self, hex_table) -- called by using `parser(hex_table)`, where hex_table is an array with each hex byte set as a string in order ("t" here is a reference to the "parser" table itself)
        uied:log("yay")

        -- self.name = "new name"

        -- TODO verify the hex table first?

        self.data = nil
        self.root_uic = nil

        ---@type UIC_Component
        local root_uic = uied._classes.Component:new()
        root_uic:set_is_root(true)

        self.num_lines =  #hex_table
        self.data =       hex_table
        self.root_uic =   root_uic
        self.location =   1

        uied:log("Number of lines within the hex table: "..tostring(self.num_lines))

        return root_uic:decipher()
    end
})


return parser
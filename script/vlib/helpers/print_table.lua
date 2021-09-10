table_printer = {
    __tab = 0,
    __linebreak = "\n",
    __tabbreak = "\t",

    __str = "",
    __last = "",
}

local function is_table(o)
    return type(o) == "table"
end

local function is_number(o)
    return type(o) == "number"
end

local function is_boolean(o)
    return type(o) == "boolean"
end

local function is_string(o)
    return type(o) == "string"
end

function table_printer:newline(tab_i, override)
    self.__tab = self.__tab + tab_i

    if override then self.__tab = tab_i end

    local tab = ""
    for _ = 1, self.__tab do
        tab = tab .. self.__tabbreak
    end

    self:concat(self.__linebreak .. tab)
end

function table_printer:handle_key(key)
    if is_number(key) then
        self:concatf("[%d]", key)
    elseif is_string(key) then
        self:concatf("[%q]", key)
    else
        return false
    end

    return true
end

function table_printer:handle_value(value)
    if is_table(value) then
        self:concatf(" = ")
        self:handle_table(value)
    elseif is_number(value) then
        self:concatf(" = %d,", value)
    elseif is_string(value) then
        self:concatf(" = %q,", value)
    elseif is_boolean(value) then
        self:concatf(" = %s,", value and "true" or "false")
    else
        return false
    end

    return true
end

function table_printer:concatf(str, ...)
    str = string.format(str, ...)
    self:concat(str)
end

function table_printer:remove_last()
    local len = self.__last:len()

    self.__str = self.__str:sub(1, -len-1)
    self.__last = ""
end

function table_printer:concat(str)
    if not is_string(str) then print("Not a string! " .. tostring(str)) end
    self.__str = self.__str .. str

    self.__last = str
end

function table_printer:handle_table(t, is_first)
    if not is_table(t) then return end

    self:concat("{")
    self:newline(1)
    for k,v in pairs(t) do
        --- TODO if invalid value then don't save the key!!!
        if self:handle_key(k) then
            if self:handle_value(v) then
                self:newline(0)
            else
                print("Invalid value!")
                self:remove_last()
            end
        else
            print("Invalid key!")
        end
    end

    -- remove the last new line
    self:remove_last()
    
    if is_first then
        self:newline(0, true)
        self:concat("}")
    else
        self:newline(-1)
        self:concat("},")
    end
end

--- takes a table and returns the formatted text of its entirety
function table_printer:print(t)
    if not is_table(t) then return false end

    self.__str = ""
    self.__last = ""
    self.__tab = 0

    self:handle_table(t, true)

    return self.__str
end


local settings = {
    test = 5,
    my_test = {
        bloop = "17",
        [0] = 17,
    },
    blunderbuss = true,
    [{}] = "my test",
    cool_function = function() end,

    ["huge"] = "for me",
}

print("return " .. table_printer:print(settings))
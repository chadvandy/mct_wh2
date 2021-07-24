---@type UIED
local uied = core:get_static_object("ui_editor_lib")
local parser = uied.parser

---@class UIC_BaseClass
local obj = {
    type = "UI_BaseClass",

    key_type = "none",
}
obj.__index = obj

-- TODO better tostring?
obj.__tostring = function(self) return self:get_type() end

function obj:create(type_key)
    local o = obj:new()

    o.type = type_key

    return o
end

function obj:new(o)
    ---@type UIC_BaseClass
    o = o or {}
    setmetatable(o, self)

    o.data = o.data or {}
    o.key = o.key or nil

    o.uic_row_number = nil

    o.parent = o.parent or nil

    o.uic = nil
    o.state = "invisible"

    return o
end

function obj:get_parent()
    return self.parent
end

function obj:set_parent(p)
    self.parent = p
end

function obj:get_row_number()
    return self.uic_row_number
end

function obj:set_row_number(num)
    if not is_number(num) then return end

    self.uic_row_number = num 
end

function obj:filter_fields(key_filter, value_filter)
    local data = self.data

    for i = 1, #data do
        local inner = data[i]
        inner:filter_fields(key_filter, value_filter)
    end
end

function obj:get_type()
    return self.type
end

function obj:create_details()
    local new_state = "open"
    local data = self:get_data()

    local function is_field(o)
        return string.find(tostring(o), "UI_Field")
    end

    local function is_valid_collection(o)
        return string.find(tostring(o), "UI_Collection") and parser:is_valid_type(o:get_held_type())
    end

    for i = 1, #data do
        local datum = data[i]

        if is_field(datum) then
            uied.ui:create_details_row_for_field(datum)
        elseif is_valid_collection(datum) then
            uied.ui:create_details_row_for_collection(datum)
        end
    end
end

-- This is called whenever a header is pressed, which switches its state and triggers a change on all children fields and objects
function obj:switch_state()
    uied:log("Switching state for ["..self:get_key().."].")
    local state = self.state
    local new_state = ""
    local child_state = ""

    if state == "closed" then
        new_state = "open"
        child_state = "closed"
    elseif state == "open" then
        new_state = "closed"
        child_state = "invisible"
    end

    local ok, msg = pcall(function()

    -- self.state = new_state
    self:set_state(new_state)

    -- TODO error check
    -- local uic = self:get_uic()
    -- local parent = UIComponent(uic:Parent())
    -- local id = uic:Id()

    -- local canvas = UIComponent(parent:Find(id.."_canvas"))

    -- if new_state == "closed" then
    --     -- hide the listbox!
    --     -- resize it to puny so it fixes everything!
    --     canvas:SetVisible(false)
    --     canvas:Resize(canvas:Width(), 5)
    -- else
    --     canvas:SetVisible(true)
    -- end

end) if not ok then uied:err(msg) end
end

-- This is only called through switch_state(), which will trigger on self as well as on all children.
function obj:set_state(state)
    self.state = state

    uied:log("Setting state of ["..self:get_key().."] to ["..state.."].")

    -- set the state of the header (invisible if inner?)
    local uic = self:get_uic()
    if is_uicomponent(uic) then
        if state == "open" then
            uic:SetVisible(true)
            uic:SetState("selected")
        elseif state == "closed" then
            uic:SetVisible(true)
            uic:SetState("active")
        elseif state == "invisible" then
            -- TODO hide all canvas and shit
            uic:SetVisible(false)
            uic:SetState("active")
        end
    end
end

function obj:set_uic(uic)
    if not is_uicomponent(uic) then
        -- errmsg
        return false
    end
    
    self.uic = uic
end

function obj:get_uic()
    local uic = self.uic
    if not is_uicomponent(uic) then
        -- errmsg
        return false
    end

    return uic
end

function obj:get_key()
    return self.key or "No Key Found"
end

function obj:get_data()
    return self.data
end

-- when created, assign the key Type+Index, ie. "Component1"
-- then, assign the key through add_data if the field is "name" or "ui-id"
-- if ui-id is added but name was already added, keep name.
function obj:set_key(key, new_key_type)
    uied:log("set_key() called on obj with type "..self:get_type())
    local key_type = self.key_type
    local current_key = self:get_key()

    new_key_type = new_key_type or "none"

    if key_type == new_key_type or key == self.key then
        -- already added
        return
    end

    -- if there's no current key_type, anything assigned is valid
    if key_type == "none" then
        self.key = key
        self.key_type = new_key_type
    -- if the current key_type is index, anything but none is valid
    elseif key_type == "index" then
        if new_key_type ~= "none" then
            self.key = key
            self.key_type = new_key_type
        end
    -- if the current key_type is ui-id, only "name" is valid
    elseif key_type == "ui-id" then
        if new_key_type == "name" then
            self.key = key
            self.key_type = new_key_type
        end
    -- if the current key_type is name, nothing is valid
    elseif key_type == "name" then
        -- do nuffin?
    end

    uied:log("old key ["..current_key.."], new key ["..self.key.."].")
end

-- remove a field or object or collection from this object
function obj:remove_data(datum)
    uied:log("Remove data called! "..self:get_key().." is deleting data ["..datum:get_key().."].")
    local data = self:get_data()

    local new_table = {}

    for i = 1, #data do
        local inner = data[i]

        if inner == datum then
            uied:log("Inner found!")
        else
            new_table[#new_table+1] = inner
        end
    end

    -- replace the data field
    self.data = new_table
end

function obj:add_data(data)
    -- TODO confirm that it's a valid obj

    -- if a Field is being added, check if it's a name or ui-id, then add it as key
    if string.find(tostring(data), "UI_Field") then
        if data:get_key() == "name" then
            self:set_key(data:get_value(), "name")
        elseif data:get_key() == "ui-id" then
            self:set_key(data:get_value(), "ui-id")
        end
    end

    uied:log("Add Data called, ["..self:get_key().."] is getting a fresh new ["..tostring(data).."] with key ["..data:get_key().."].")

    -- if self:get_key() == "dy_txt" then
    --     uied:log("VANDY VANDY VANDY")
    --     uied:log("Adding data to dy_txt, data is: "..tostring(data))
    -- end

    self.data[#self.data+1] = data

    data:set_parent(self)

    return data
end

function obj:add_data_table(fields)
    for i = 1, #fields do
        self:add_data(fields[i])
    end
end

function obj:get_data_with_key(key)
    uied:logf("Checking %q for data with key %q", self:get_key(), key)

    local data = self:get_data()
    for i = 1, #data do
        if data[i]:get_key() == key then
            local value = data[i]:get_value()
            uied:logf("Found it! Value is %q.", tostring(value))
            return value
        end
    end

    return nil
end

local function dec(key, format, k, o)
    if is_table(format) then
        if format[1] == "Collection" then
            local override
            if is_table(format[2]) and #format[2] > 0 then
                override = #format[2]
            end
            
            return parser:decipher_collection(format[2], o, override)
        end
        if format[1] == "Collection16" then
            return parser:decipher_collection(format[2], o, "I16")
        end
    end

    uied:log("decoding field with key ["..key.."] and format ["..format.."]")
    return parser:dec(key, format, k, o)
end

function obj:decipher()
    local t = self:get_type()
    if t == "UIC_BaseClass" then 
        return uied:log("decipher called on "..self:get_key().." but the decipher method has not been overriden!")
    end

    local function deciph(key, format, k)
        return dec(key, format, k, self)
    end

    local schema = uied:get_schema_for_class(t)
    if not schema then
        return uied:logf("Trying to decipher object %q of type %q, but there's no schema for this bad boi!", self:get_key(), t)
    end

    local fields = schema.fields

    if t == "ComponentImageMetric" then
        uied:log("Deciphering a ComponentImageMetric, num fields is " .. tostring(#fields))
    end



    for i = 1, #fields do
        local field = fields[i]
        local name = field.name
        
        -- TODO swap over to type exclusively?
        local field_type = field.field_type or field.type
        -- uied:log("In field " .. name .. " with type " .. ((is_string(field_type) and field_type) or (is_table(field_type) and is_string(field_type[2]) and field_type[2])))
        
        -- Check if this field was deciphered properly; if not, throw EVERYTHING into a new collection of Hexes, called "Remaining", on the root uic.
        -- Put them in groups of 10 for readability
        local ok = deciph(name, field_type, field.length)
        if not ok then
            uied:log("Failed to decipher something. Throwing the rest of the file into a new collection called Remaining.")
            local root = parser.root_uic

            local new_collection = uied:new_obj("Collection", "Remaining")

            local any_left = true

            local k = 1

            while any_left do
                uied:logf("Looping through last bits. At location %d out of max lines %d", parser.location, #parser.data)
                if parser.location >= #parser.data then break end

                parser:dec("remaining_"..tostring(k), "hex", 10, new_collection)

                k = k + 1
            end

            root:add_data(new_collection)
            return
        end
    end

    return self
end

function obj:create_default()
    uied:log("create_default called on "..self:get_key().." but the create_default method has not been overriden!")
    return
end

return obj
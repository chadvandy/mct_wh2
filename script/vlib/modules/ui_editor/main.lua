---@class UIED
local ui_editor_lib = {
    loaded_uic = nil,
    loaded_uic_path = nil,

    testing_file_str = "TEST",
    testing_file_ind = 0,
    
    _schemas = {},
    _classes = {},

    _templates = {},
}

local vlib = get_vlib()
local log,logf,err,errf = vlib:get_log_functions("[uied]")

function ui_editor_lib:log(text)
    return log(text)
end

function ui_editor_lib:logf(text, ...)
    return logf(text, ...)
end

function ui_editor_lib:err(text)
    return err(text)
end

function ui_editor_lib:errf(text, ...)
    return errf(text, ...)
end

function ui_editor_lib:get_testing_file_string()
    local ret = self.testing_file_str..tostring(self.testing_file_ind)

    -- self.testing_file_ind = self.testing_file_ind+1

    return ret
end

function ui_editor_lib:get_schema_for_class(class_name)
    -- if not self:get_class(class_name) then
    --     return logf("Searching for a schema for %q, but that class doesn't exist!", class_name)
    -- end

    local s

    local ok, msg = pcall(function()

    local version = self.parser:get_version()

    local schemas = self._schemas[class_name]
    if not schemas then
        return logf("Checking for schemas for class %q, but none exist!", class_name)
    end

    logf("Trying to get schema for class %q within version %d", class_name, version)

    -- Loop through all available schemas for this class, and get the most recent one of that version or before.
    local closest = 0
    -- local s
    for i = 1, #schemas do
        local schema = schemas[i]
        local v = schema.version

        -- If no version is provided, this is a global schema, valid for all versions!
        -- That means it's valid for any version from 1-Current, unless there's another schema defined that exists with a specified version below current.
        -- This might be changed in the future; it's more of a duct-tape method to prevent having to codify EVERY VERSION CHANGE right now
        if not v then
            s = schema
        else
            -- logf("Checking schema with version %d against closest '%d' and target version '%d'", v, closest, version)

            if v > closest and v <= version then
                -- logf("Greater than previous '%d', and less than goal %d", closest, version)
                closest = v
                s = schema
            end
        end
    end
    
    logf("Schema for %q found, returning version %d", class_name, s.version or 0)
    
    end) if not ok then err(msg) end
    
    return s
end

function ui_editor_lib:load_template(filename)
    if not is_string(filename) then
        -- errmsg
        return false
    end

    logf("loading template with path %q", filename)

    local file = assert(io.open(filename, "rb+"))
    if not file then
        return log("file not found!")
    end

    -- cut the / and \\ from the file path
    local function trim(str)
        if not is_string(str) then return "" end

        local x = string.find(str, "/") or string.find(str, "\\")
        if not x then
            return str
        end

        str = string.sub(str, x+1)

        return trim(str)
    end

    local template_key = trim(filename)

    local data = {}

    local block_num = 10
    while true do
        local bytes = file:read(block_num)
        if not bytes then break end

        for b in string.gfind(bytes, ".") do
            local byte = string.format("%02X", string.byte(b))

            --data = data .. " " .. byte
            data[#data+1] = byte
        end
    end

    file:close()

    log("template file opened!")

    local ok, msg = pcall(function()
        ---@type UIC_BaseClass
        local uic = self.parser(data)

        logf("Saving template with key %q", template_key)
        self._templates[template_key] = uic
    end) if not ok then log(msg) end
end

function ui_editor_lib:load_templates()
    local path = "/ui/ui_editor/templates/"

    local templates_str = effect.filesystem_lookup(path, "*")
    for filename in string.gmatch(templates_str, '([^,]+)') do
        local filename_for_out = filename

        logf("Testing template with path %q", filename)

        if filename ~= path then
            filename = "data/"..filename

            self:load_template(filename)
        end
    end
end

function ui_editor_lib:init()
    local path = "script/vlib/modules/ui_editor/"

    ---@type UIED_Parser
    self.parser =              vlib:load_module("layout_parser", path) -- the manager for deciphering the hex and turning it into more accessible objects

    ---@type UIED_UI
    self.ui =                  vlib:load_module("ui_panel", path) -- the in-game UI panel manager

    local schema_path = path .. "schemas/"
    path = path .. "classes/"

    -- self.classes = {}
    local classes = self._classes
    local schemas = self._schemas

    --- TODO finish port to schemas.
    --- TODO load everything in schemas.

    ---@type UIC_BaseClass
    classes.BaseClass =                         vlib:load_module("BaseClass", path)

    ---@type UIC_Component
    classes.Component =                         vlib:load_module("Component", path)              -- the class def for the UIComponent type - main boy with names, events, offsets, states, images, children, etc
    ---@type UIC_Field
    classes.Field =                             vlib:load_module("Field", path)                  -- the class def for UIComponent fields - ie., "offset", "width", "is_interactive" are all fields
    ---@type UIC_Collection
    classes.Collection =                        vlib:load_module("Collection", path)              -- the class def for collections, which are just slightly involved tables (for lists of states, images, etc)

    schemas.ComponentImage =                    vlib:load_module("ComponentImage", schema_path)         -- ComponentImages, simple stuff, just controls image path / width / height /etc

    schemas.ComponentState =                    vlib:load_module("ComponentState", schema_path)         -- controls the different states a UIC can be - open, closed, etc., lots of fields within
    schemas.ComponentImageMetric =              vlib:load_module("ComponentImageMetric", schema_path)   -- controls the different fields on an image within a state - visible, tile, etc
    schemas.ComponentMouse =                    vlib:load_module("ComponentMouse", schema_path)
    schemas.ComponentMouseUndec =               vlib:load_module("ComponentMouseUndec", schema_path)
    schemas.ComponentProperty =                 vlib:load_module("ComponentProperty", schema_path)
    schemas.ComponentAnimation =                 vlib:load_module("ComponentAnimation", schema_path)
    schemas.ComponentAnimationFrame =        vlib:load_module("ComponentAnimationFrame", schema_path)
    schemas.ComponentAnimationTrigger = vlib:load_module("ComponentAnimationTrigger", schema_path)
    schemas.ComponentEvent =                    vlib:load_module("ComponentEvent", schema_path)

    -- classes.ComponentEventProperty =            vlib:load_module("ComponentEventProperty", path)
    schemas.ComponentEventProperty =            vlib:load_module("ComponentEventProperty", schema_path)

    classes.ComponentLayoutEngine =             vlib:load_module("ComponentLayoutEngine", path)

    schemas.ComponentTemplate =                 vlib:load_module("ComponentTemplate", schema_path)
    schemas.ComponentTemplateChild =            vlib:load_module("ComponentTemplateChild", schema_path)
    schemas.ComponentTemplateChildEvent =            vlib:load_module("ComponentTemplateChildEvent", schema_path)
    schemas.ComponentTemplateChildEventAlso =            vlib:load_module("ComponentTemplateChildEventAlso", schema_path)
    schemas.ComponentTemplateChildState =            vlib:load_module("ComponentTemplateChildState", schema_path)
    schemas.ComponentTemplateChildUndecOne =            vlib:load_module("ComponentTemplateChildUndecOne", schema_path)
    schemas.ComponentTemplateChildUndecTwo =            vlib:load_module("ComponentTemplateChildUndecTwo", schema_path)

    -- On game load, grab all of the templates!
    self:load_templates()
end

function ui_editor_lib:get_class(class_name)
    local base = self._classes.BaseClass
    if not is_string(class_name) then
        logf("Trying to get a class but the class name provided isn't a string! Returning BaseClass", tostring(class_name))
        return base
    end

    local ret = self._classes[class_name]

    if not ret then
        logf("Trying to get a class with the key %q but none found with that key! Returning BaseClass.", class_name)
        return base
    end

    return ret
end

-- -- TODO edit dis
-- -- check if a supplied object is an internal UI class
-- function ui_editor_lib:is_ui_class(obj)
--     local str = tostring(obj)
--     log("is ui class: "..str)
--     --ui_editor_lib:log(tostring(str.find("UIED_")))

--     return not not string.find(str, "UIED_")
-- end

function ui_editor_lib:new_obj(class_name, ...)
    if self._classes[class_name] then
        return self._classes[class_name]:new(...)
    end

    return self._classes.BaseClass:create(class_name)

    -- log("new_obj called, but no class was found with name ["..class_name.."].")
    
    -- return false
end

function ui_editor_lib:print_copied_uic()
    log("print copied UIC")
    local ok, msg = pcall(function()
    local uic = self.copied_uic

    -- loop through aaaaaall fields and print their hex

    local hex_str = ""
    local bin_str = ""

    local function iter(d)
        local data = d:get_data()

        for i = 1, #data do
            local datum = data[i]

            if tostring(datum) == "UI_Field" then
                hex_str = hex_str .. datum:get_hex()
            elseif tostring(datum) == "UI_Collection" then
                -- add the length hex and then iterate through all fields (read: objects)
                hex_str = hex_str .. datum:get_hex()
                iter(datum)
            else
                iter(datum)
            end
        end
    end

    iter(uic)

    log(hex_str)

    -- loops through every single hex byte (ie. everything with two hexa values, %x%x), then converts that byte into the relevant "char"
    for byte in hex_str:gmatch("%x%x") do
        -- print(byte)

        local bin_byte = string.char(tonumber(byte, 16))

        -- print(bin_byte)

        bin_str = bin_str .. bin_byte
    end

    log(bin_str)

    self.testing_file_ind=self.testing_file_ind+1
    local new_file = io.open("data/UI/ui_editor/"..self:get_testing_file_string(), "w+b")
    new_file:write(bin_str)
    new_file:close()

    -- ui_editor_lib.ui:create_loaded_uic_in_testing_ground(true)

end) if not ok then log(msg) end
end

function ui_editor_lib:load_uic_with_path(path)
    if not is_string(path) then
        -- errmsg
        return false
    end

    self.loaded_uic = nil
    self.loaded_uic_path = ""
    self.copied_uic = nil

    log("load uic with path: "..path)

    local file = assert(io.open(path, "rb+"))
    if not file then
        log("file not found!")
        return false
    end

    local data = {}
    --local nums = {}
    --local location = 1

    local block_num = 10
    while true do
        local bytes = file:read(block_num)
        if not bytes then break end

        for b in string.gfind(bytes, ".") do
            local byte = string.format("%02X", string.byte(b))

            --data = data .. " " .. byte
            data[#data+1] = byte
        end
    end

    file:close()

    log("file opened!")

    local ok, msg = pcall(function()
    local uic = self.parser(data)

    self.loaded_uic = uic
    self.loaded_uic_path = path

    -- make a "copy" of the UIC
    self.copied_uic = self:new_obj("Component", uic)


    self.ui:load_uic()
    end) if not ok then log(msg) self.ui:load_uic() end
end

core:add_static_object("ui_editor_lib", ui_editor_lib)

-- TODO reinstate.
-- ui_editor_lib:init()
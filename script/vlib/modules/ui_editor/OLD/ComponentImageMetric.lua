local uied = core:get_static_object("ui_editor_lib")
local BaseClass = uied:get_class("BaseClass")

local parser = uied.parser
local function dec(key, format, k, obj)
    uied:log("decoding field with key ["..key.."] and format ["..format.."]")
    return parser:dec(key, format, k, obj)
end

local ComponentImageMetric = {
    type = "ComponentImageMetric",
}


setmetatable(ComponentImageMetric, BaseClass)

ComponentImageMetric.__index = ComponentImageMetric
ComponentImageMetric.__tostring = BaseClass.__tostring


function ComponentImageMetric:new(o)
    o = BaseClass:new(o)
    setmetatable(o, self)


    return o
end

function ComponentImageMetric:decipher()
    local v = parser.root_uic:get_version()

    -- local obj = uied:new_obj("ComponentImageMetric")

    local function deciph(key, format, k)
        return dec(key, format, k, self)
    end

    deciph("ui-id", "hex", 4)

    if v >= 126 and v < 130 then
        deciph("b_sth", "hex", 16)
    end

    deciph("offset", "int32", {x=4,y=4})
    deciph("dimensions", "int32", {w=4,h=4})

    deciph("colour", "hex", 4)

    -- ui_colour_preset_type_key ?
    if v>=119 and v<130 then
        deciph("str_sth", "str")
    end

    -- bool, whether it's tiled or not
    deciph("tiled", "bool", 1)

    -- whether the image is flipped on the x/y axes
    deciph("x_flipped", "bool", 1)
    deciph("y_flipped", "bool", 1)

    deciph("docking_point", "int32", 4)

    deciph("dock_offset", "int32", {x=4,y=4})

    -- dock right/bottom; they seem to be bools?
    -- TODO this might be CanResizeWidth/Height
    deciph("dock", "bool", {right=1,left=1})

    deciph("rotation_angle", "hex", 4)
    deciph("pivot_point", "int32", {x=4,y=4})

    if v >= 103 then
        deciph("rotation_axis", "int32", {4,4,4})
        deciph("shader_name", "str")
    else
        deciph("shader_name", "str")
        deciph("rotation_axis", "int32", {4,4,4})
    end

    -- TOOD b4 is probably opacity!
    if v <= 102 then
        deciph("b4", "hex", 4)
    end

    -- TODO first 4 of the following are probably opacity!
    if v == 79 then
        deciph("b5", "hex", 8)
    elseif v >= 70 and v < 80 then
        deciph("b6", "hex", 9)
    elseif v >= 80 and v< 95 then
        if v == 92 or v == 93 then
            deciph("margin", "hex", {4,4,4,4})
        else
            deciph("margin", "hex", {4,4})
        end
    else
        if v >= 103 then
            deciph("shadertechnique_vars", "hex", {4,4,4,4})
        end
        
        deciph("margin", "hex", {4,4,4,4})

        if v >= 125 and v < 130 then
            deciph("b5", "hex", 1)
        end
    end

    return self
end

return ComponentImageMetric
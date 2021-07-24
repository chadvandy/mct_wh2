---@type UIED
local uied = core:get_static_object("ui_editor_lib")
local BaseClass = uied:get_class("BaseClass")

local parser = uied.parser
local function dec(key, format, k, obj)
    uied:log("decoding field with key ["..key.."] and format ["..format.."]")
    return parser:dec(key, format, k, obj)
end

---@class UIC_ComponentFunctionAnimation : UIC_BaseClass
local ComponentFunctionAnimation = {
    type = "ComponentFunctionAnimation",
}

setmetatable(ComponentFunctionAnimation, BaseClass)

ComponentFunctionAnimation.__index = ComponentFunctionAnimation
ComponentFunctionAnimation.__tostring = BaseClass.__tostring

function ComponentFunctionAnimation:new(o)
    o = BaseClass:new(o)
    setmetatable(o, self)

    return o
end

-- TODO do this later :)
function ComponentFunctionAnimation:decipher()
    local v = parser.root_uic:get_version()

    local function deciph(key, format, k)
        return dec(key, format, k, self)
    end

    -- TODO this sux
    local len = parser:decipher_chunk("int16", 1, 2) or 0
    uied:log("LEN1: "..tostring(len))

    parser.location = parser.location - 2

    if len == 0xFFFF then
        deciph("b_hex_0", "hex", 2)
        deciph("b_hex_1", "hex", 2)
    elseif v >= 122 and v < 130 then
        deciph("b_hex", "hex", 2)
        deciph("b_str", "utf8")
    else
        if len == 0 then
            deciph("b_hex_1", "hex", 2)
            deciph("b_hex_2", "hex", 2)
        else
            deciph("b_str", "utf8")

            local len = parser:decipher_chunk("int16", 1, 2) or 0
            uied:log("LEN2: "..tostring(len))

            parser.location = parser.location -2

            if len == 0 then 
                deciph("b_hex", "hex", 2)
            else
                deciph("b_str", "utf8")
            end
        end
    end

    deciph("offset_left", "float", 4)
    deciph("offset_top", "float", 4)

    deciph("targetmetrics_m_width", "int32", 4)
    deciph("targetmetrics_m_height", "int32", 4)

    deciph("targetmetrics_m_colour", "hex", 4)

    deciph("shader_vars", "float", {one=4,two=4,three=4,four=4})

    deciph("rotation_angle", "float", 4)

    deciph("imageindex1", "int32", 4)
    deciph("imageindex2", "int32", 4)

    if v >= 110 and v < 130 then
        deciph("m_font_scale", "int32", 4)
    end

    deciph("interpolationtime", "int32", 4)
    deciph("interpolationpropertymask", "int32", 4)

    deciph("easing_weight", "float", 4)
    deciph("easing_curve_type", "utf8", -1)

    parser:decipher_collection("ComponentFunctionAnimationTrigger", self)

    if v >= 90 and v < 100 then
        deciph("b2", "hex", 1)
    elseif v >= 100 and v < 110 then
        deciph("b2", "hex", 2)

        if v >= 106 then
            deciph("str_sth", "utf8")
        end

        if v >= 104 then
            deciph("b3", "utf8")
        else
            deciph("b3", "hex", 1)
        end
    elseif v >= 110 and v < 120 then
        deciph("b2", "hex", 2)
    elseif v >= 120 and v < 130 then
        deciph("b2", "hex", 2)

        if v >= 122 then
            deciph("b3", "utf8")
        end
    end

    return self
end

return ComponentFunctionAnimation
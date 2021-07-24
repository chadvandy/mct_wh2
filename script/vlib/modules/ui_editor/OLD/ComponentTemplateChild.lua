---@type UIED
local uied = core:get_static_object("ui_editor_lib")
local BaseClass = uied:get_class("BaseClass")

local parser = uied.parser
local function dec(key, format, k, obj)
    uied:log("decoding field with key ["..key.."] and format ["..format.."]")
    return parser:dec(key, format, k, obj)
end

---@class UIC_ComponentTemplateChild : UIC_BaseClass
local ComponentTemplateChild = {
    type = "ComponentTemplateChild",
}

setmetatable(ComponentTemplateChild, BaseClass)

ComponentTemplateChild.__index = ComponentTemplateChild
ComponentTemplateChild.__tostring = BaseClass.__tostring



function ComponentTemplateChild:new(o)
    o = BaseClass:new(o)
    setmetatable(o, self)

    return o
end

function ComponentTemplateChild:decipher(template_key)
    local v = parser.root_uic:get_version()

    local function deciph(key, format, k)
        return dec(key, format, k, self)
    end

    local reg_template = uied._templates[template_key]
    uied:logf("Checking UIED for a template with key %q. Any found: %q", template_key, tostring(not is_nil(reg_template)))

    deciph("undeciphered_1", "utf8")

    -- The name of the UIC as it's created
    deciph("name_dest", "utf8")

    -- uied:logf("Deciphering a template with the source name %q and the destination name %q", src:get_value(), des:get_value())

    if v >= 122 and v < 130 then
        deciph("b_sth", "hex", 16)

        local num_states = deciph("num_states", "int32", 4):get_value()

        for i = 1, num_states do
            deciph("state_"..i.."_str", "utf8")
            deciph("state_"..i.."_hex", "hex", 16)
        end
    end

    deciph("b0", "utf8")

    if v >= 100 and v < 110 then
        deciph("type", "utf8")
    elseif v >= 110 and v < 130 then
        local num_events = deciph("num_events", "int32", 4):get_value()
        for i = 1, num_events do
            deciph("event_str1_"..i, "utf8")
            deciph("event_str2_"..i, "utf8")
            deciph("event_str3_"..i, "utf8")

            if v >= 124 and v < 130 or v == 121 then
                local num_sth = deciph("num_sth", "int32", 4):get_value()

                for j = 1, num_sth do
                    deciph("sth_str1_"..j, "utf8")
                    deciph("sth_str2_"..j, "utf8")
                end
            end
        end
    end

    deciph("func_name", "utf8")

    deciph("b_floats", "float", {one=4,two=4,three=4,four=4})

    deciph("b_ints", "int32", {w=4,h=4})
    
    if v >= 122 and v < 130 then
        deciph("b1", "hex", 2)
    else
        deciph("b1", "hex", 1)
    end

    deciph("docking", "int32", 4)
    deciph("b2", "hex", 6)

    deciph("tooltip_id", "utf16")
    deciph("tooltip_text", "utf16")

    -- TODO some weird shit here
    -- if ($this->name_src){
    --     $ch = $uic_t->find($this->name_src);
    -- } else{ $ch = $uic_t; }

    if v >= 122 and v < 130 then
        deciph("b3", "hex", 3)
    end

    local i = 0

    -- TODO grab the number of states from the original template!
    local max_i



    while true do
        local num = {
            parser:decipher_chunk("int16", 1, 2),
            parser:decipher_chunk("int16", 1, 2),
        }

        parser.location = parser.location -4

        if num[1] == 0 or num[2] == 0 then
            break
        end

        --- TODO this shouldn't be hard'd, somehow read the OG template file to know how many states are expected
        deciph("state_"..i, "utf8")
        deciph("state_b1"..i, "utf16")
        deciph("state_b2"..i, "utf16")
        deciph("state_b3"..i, "utf16")
        deciph("state_b4"..i, "utf16")

        if v >= 122 and v < 130 then
            deciph("state_hex_"..i, "hex", 1)
        end

        i = i + 1

        -- Loop max_i times, which is the number of states found in the OG template
        if i == max_i then
            break
        end
    end

    local num_dynamic = deciph("num_dynamic", "int32", 4):get_value()

    for i = 1, num_dynamic do
        deciph("dynamic_"..i.."_key", "utf8")
        deciph("dynamic_"..i.."_value", "utf8")
    end

    local num_images = deciph("num_images", "int32", 4):get_value()

    for i = 1, num_images do
        deciph("image_"..i, "utf8")
    end

    if v >= 122 and v < 130 then
        deciph("b4", "hex", 4)

        local num_sth = deciph("num_sth", "int32", 4):get_value()

        for i = 1, num_sth do
            deciph("sth_"..i.."_str1", "utf8")
            deciph("sth_"..i.."_str2", "utf8")

            deciph("sth_"..i.."_hex1", "hex", 4)
            deciph("sth_"..i.."_hex2", "hex", 12)
        end

        local num_img = deciph("num_img", "int32", 4):get_value()

        for i = 1, num_img do
            deciph("img_"..i.."_str", "utf8")
            deciph("img_"..i.."_hex", "hex", 16)
        end
    end

    -- local children = parser:decipher_collection("Component", self)

    return self
end




return ComponentTemplateChild
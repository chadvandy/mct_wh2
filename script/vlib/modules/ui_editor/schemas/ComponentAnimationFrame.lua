-- TODO this, weirdness here

-- TODO I need to fix this up: right now, there's a starter two bits, "len", that don't actually exist in the object because they can vary in deciphering. There's more here that I'm not understanding, obvo.
return {
    {    
        version = 90,
        fields = {
            {
                name = "offset",
                type = {"Collection", {type = "I32", keys = {"x", "y"}}},
            },
            {
                name = "dimensions",
                type = {"Collection", {type = "I32", keys = {"width", "height"}}}
            },
            {
                name = "colour",
                type = "Hex",
                length = 4,
            },
            {
                name = "shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {
                name = "rotation_angle",
                type = "float",
            },
            {   -- TODO, this is actually type UI32
                name = "image_indices",
                type = {"Collection", {type = "I32", keys = {"one", "two"}}}
            },
            {   -- TODO maybe unsigned?
                name = "interpolation_time",
                type = "I32",
            },
            {   -- TOOD maybe unsigned?
                name = "interpolation_property_mask",
                type = "I32",
            },
            {
                name = "easing_weight",
                type = "float",
            },
            {
                name = "easing_curve_type",
                type = "StringU8",
            },
            {
                name = "triggers",
                type = {"Collection", "ComponentAnimationTrigger"},
            },
            {
                name = "is_movement_absolute",
                type = "Boolean",
            },
            {
                name = "is_resize_for_image",
                type = "Boolean",
            },
            {
                name = "sound_category",
                type = "StringU8",
            },
            {
                name = "sound_category_end",
                type = "StringU8"
            },
        },
    },
    {
        version = 119,
        fields = {
            {
                name = "offset",
                type = {"Collection", {type = "I32", keys = {"x", "y"}}},
            },
            {
                name = "dimensions",
                type = {"Collection", {type = "I32", keys = {"width", "height"}}}
            },
            {
                name = "colour",
                type = "Hex",
                length = 4,
            },
            {
                name = "shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {
                name = "rotation_angle",
                type = "float",
            },
            {   -- TODO, this is actually type UI32
                name = "image_indices",
                type = {"Collection", {type = "I32", keys = {"one", "two"}}}
            },
            {
                name = "font_scale",
                type = "float",
            },
            {   -- TODO maybe unsigned?
                name = "interpolation_time",
                type = "I32",
            },
            {   -- TOOD maybe unsigned?
                name = "interpolation_property_mask",
                type = "I32",
            },
            {
                name = "easing_weight",
                type = "float",
            },
            {
                name = "easing_curve_type",
                type = "StringU8",
            },
            {
                name = "triggers",
                type = {"Collection", "ComponentAnimationTrigger"},
            },
            {
                name = "is_movement_absolute",
                type = "Boolean",
            },
            {
                name = "is_resize_for_image",
                type = "Boolean",
            },
            {
                name = "sound_category",
                type = "StringU8",
            },
            {
                name = "sound_category_end",
                type = "StringU8"
            },
        }
    }
}
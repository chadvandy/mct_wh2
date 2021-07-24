return {
    {
        version = 100,
        fields = {
            {
                name = "undeciphered_1",
                field_type = "StringU8",
            },
            {
                name = "name_dest",
                field_type = "StringU8",
            },
            {
                name = "undeciphered_2",
                field_type = "StringU8",
            },
            {
                name = "type",
                field_type = "StringU8",
            },
            {
                name = "func_name",
                field_type = "StringU8",
            },
            {
                name = "undeciphered_floats",
                field_type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {
                name = "dimensions",
                field_type = {"Collection", {type = "I32", keys = {"width", "height"}}},
            },
            {
                name = "undeciphered_b1",
                field_type = "Hex",
                length = 1,
            },
            {
                name = "docking_point",
                field_type = "I32",
            },
            {
                name = "undeciphered_3",
                field_type = "Hex",
                length = 6,
            },
            {
                name = "tooltip_id",
                field_type = "StringU16",
            },
            {
                name = "tooltip_text",
                field_type = "StringU16",
            },
            {
                name = "states",
                field_type = {"Collection", "ComponentTemplateChildState"},
            },
            {
                name = "properties",
                field_type = {"Collection", "ComponentProperty"}
            },
            {
                name = "images",
                field_type = {"Collection", "StringU8"},
            }
        }
    },
    {
        version = 110,
        fields = {
            {
                name = "undeciphered_1",
                field_type = "StringU8",
            },
            {
                name = "name_dest",
                field_type = "StringU8",
            },
            {
                name = "undeciphered_2",
                field_type = "StringU8",
            },
            {
                name = "events",
                field_type = {"Collection", "ComponentTemplateChildEvent"},
            },
            {
                name = "func_name",
                field_type = "StringU8",
            },
            {
                name = "undeciphered_floats",
                field_type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {
                name = "dimensions",
                field_type = {"Collection", {type = "I32", keys = {"width", "height"}}},
            },
            {
                name = "undeciphered_b1",
                field_type = "Hex",
                length = 1,
            },
            {
                name = "docking_point",
                field_type = "I32",
            },
            {
                name = "undeciphered_3",
                field_type = "Hex",
                length = 6,
            },
            {
                name = "tooltip_id",
                field_type = "StringU16",
            },
            {
                name = "tooltip_text",
                field_type = "StringU16",
            },
            {
                name = "states",
                field_type = {"Collection", "ComponentTemplateChildState"},
            },
            {
                name = "properties",
                field_type = {"Collection", "ComponentProperty"}
            },
            {
                name = "images",
                field_type = {"Collection", "StringU8"},
            }
        }
    },
    {
        version = 122,
        fields = {
            {
                name = "undeciphered_1",
                field_type = "StringU8",
            },
            {
                name = "name_dest",
                field_type = "StringU8",
            },
            {
                name = "undeciphered_b_sth",
                field_type = "Hex",
                length = 16,
            },
            {
                name = "what?",
                field_type = {"Collection", "ComponentTemplateChildEventAlso"},
            },
            {
                name = "undeciphered_2",
                field_type = "StringU8",
            },
            {
                name = "events",
                field_type = {"Collection", "ComponentTemplateChildEvent"},
            },
            {
                name = "func_name",
                field_type = "StringU8",
            },
            {
                name = "undeciphered_floats",
                field_type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {
                name = "dimensions",
                field_type = {"Collection", {type = "I32", keys = {"width", "height"}}},
            },
            {
                name = "undeciphered_b1",
                field_type = "Hex",
                length = 2,
            },
            {
                name = "docking_point",
                field_type = "I32",
            },
            {
                name = "undeciphered_3",
                field_type = "Hex",
                length = 6,
            },
            {
                name = "tooltip_id",
                field_type = "StringU16",
            },
            {
                name = "tooltip_text",
                field_type = "StringU16",
            },
            {
                name = "unknown_again",
                field_type = "Hex",
                length = 3,
            },
            {
                name = "states",
                field_type = {"Collection", "ComponentTemplateChildState"},
            },
            {
                name = "properties",
                field_type = {"Collection", "ComponentProperty"}
            },
            {
                name = "images",
                field_type = {"Collection", "StringU8"},
            },
            {
                name = "unknown_b4",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "undec_1",
                field_type = {"Collection", "ComponentTemplateChildUndecOne"},
            },
            {
                name = "undec2",
                field_type = {"Collection", "ComponentTemplateChildUndecTwo"}
            }
        }
    },
}
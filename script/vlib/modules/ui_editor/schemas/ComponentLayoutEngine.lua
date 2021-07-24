return {
    {
        version = 119,
        fields = {
            {
                name = "type",
                type = "StringU8",
            },
            {
                name = "columns",
                type = {"Collection", "float"},
            },
            {
                name = "spacing",
                type = {"Collection", "float"},
            },
            {   -- These are likely all booleans :)
                name = "undec_bools",
                type = "Hex",
                length = 7,
            },
            {
                name = "margins",
                type = {"Collection", {type = "I32", keys = {"left", "top"}}},
            },
            {
                name = "secondary_margins",
                type = {"Collection", {type = "I32", keys = {"left", "top"}}},
            },
            {
                name = "max_length",
                type = "I32"
            },
            {
                name = "items_per_row",
                type = "I32"
            },
            {
                name = "min_size",
                type = "I32"
            },
            {
                name = "skew_angle",
                type = "I32",
            },
            {
                name = "equal_spacing_size",
                type = "I32",
            }
        }
    }
}
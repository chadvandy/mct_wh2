return {
    {
        version = 125,
        fields = {
            {
                name = "ui-id",
                field_type = "Hex",
                length = 4,
                is_key = true,
            },
            {
                name = "undeciphered",
                field_type = "Hex",
                length = 16,
            },
            {
                name = "animation",
                field_type = "StringU8",
            },
            {
                name = "state",
                field_type = "StringU8",
            },
            {
                name = "property",
                field_type = "StringU8",
            }
        }
    },
    {
        -- version = 125,
        fields = {
            {
                name = "ui-id",
                field_type = "Hex",
                length = 4,
                is_key = true,
            },
            {
                name = "animation",
                field_type = "StringU8",
            },
            {
                name = "state",
                field_type = "StringU8",
            },
            {
                name = "property",
                field_type = "StringU8",
            }
        }
    },
}
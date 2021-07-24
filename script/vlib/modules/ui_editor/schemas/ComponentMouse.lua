return {
    {
        version = 122,
        fields = {
            {
                name = "mouse_state",
                field_type = "Hex",
                length = 4,
            },
            {   -- TODO this should actually be a reference!
                name = "state_ui-id",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "undeciphered_0",
                field_type = "Hex",
                length = 16,
            },
            {
                name = "undeciphered_1",
                field_type = "Hex",
                length = 8,
            },
            {
                name = "undeciphered_2",
                field_type = {"Collection", "ComponentMouseUndec"}
            },
        }
    },
    {
        -- version = 122,
        fields = {
            {
                name = "mouse_state",
                field_type = "Hex",
                length = 4,
            },
            {   -- TODO this should actually be a reference!
                name = "state_ui-id",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "undeciphered_0",
                field_type = "Hex",
                length = 8,
            },
            {
                name = "undeciphered_1",
                field_type = {"Collection", "ComponentMouseUndec"}
            },
        }
    }
}
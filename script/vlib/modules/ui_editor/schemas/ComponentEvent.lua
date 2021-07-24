return {
    {
        version = 100,
        fields = {
            {
                name = "events",
                field_type = "StringU8",
            }
        }
    },
    {   -- TODO version 113 has events in a collection of just 1, while 110-129 have it in a collection with a Int32 leading up to it. This is handled elsewhere but I'm noting it here :)
        version = 110,
        fields = {
            {
                name = "callback_id",
                field_type = "StringU8",
            },
            {
                name = "context_object_id",
                field_type = "StringU8",
            },
            {
                name = "context_function_id",
                field_type = "StringU8",
            },
        }
    },
    {
        version = 121,
        fields = {
            {
                name = "callback_id",
                field_type = "StringU8",
            },
            {
                name = "context_object_id",
                field_type = "StringU8",
            },
            {
                name = "context_function_id",
                field_type = "StringU8",
            },
            {
                name = "properties",
                field_type = {"Collection", "ComponentEventProperty"},
            },
        }
    },
    {
        version = 122,
        fields = {
            {
                name = "callback_id",
                field_type = "StringU8",
            },
            {
                name = "context_object_id",
                field_type = "StringU8",
            },
            {
                name = "context_function_id",
                field_type = "StringU8",
            },
            -- {
            --     name = "properties",
            --     field_type = {"Collection", "ComponentEventProperty"},
            -- },
        }
    },
    {
        version = 124,
        fields = {
            {
                name = "callback_id",
                field_type = "StringU8",
            },
            {
                name = "context_object_id",
                field_type = "StringU8",
            },
            {
                name = "context_function_id",
                field_type = "StringU8",
            },
            {
                name = "properties",
                field_type = {"Collection", "ComponentEventProperty"},
            },
        }
    }
}
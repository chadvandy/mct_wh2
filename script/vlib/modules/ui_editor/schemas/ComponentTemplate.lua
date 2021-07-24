return {
    {
        version = 110,
        fields = {
            {
                name = "template_key",
                field_type = "StringU8",
                is_key = true,
            },
            {
                name = "ui-id",
                field_type = "Hex",
                length = 4,
                -- is_key = true,
            },
            {
                name = "TemplateChildren",
                field_type = {"Collection", "ComponentTemplateChild"},
            },
            {
                name = "Children",
                field_type = {"Collection", "Component"},
            },
        },
    },
    {
        version = 122,
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
                name = "TemplateChildren",
                field_type = {"Collection", "ComponentTemplateChild"},
            },
            {
                name = "Children",
                field_type = {"Collection", "Component"},
            },
        },
    }
}
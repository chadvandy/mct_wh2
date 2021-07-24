return {
    {
        -- version = 120,
        fields = {
            {
                name = "ui-id",
                field_type = "Hex",
                length = 4,
                is_key = true,
                default = "00 00 00 00"
            },
            {
                name = "img_path",
                field_type = "StringU8",
                is_key = false,
                default = ""
            },
            {
                name = "width",
                field_type = "I32",
                is_key = false,
                default = 0
            },
            {
                name =  "height",
                field_type =  "I32",
                is_key =  false,
                default =  0
            },
            {
                name = "unknown_bool",
                field_type = "Boolean",
                is_key = false,
                default = false
            }
        }
    },
}
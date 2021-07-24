-- IDK what this is versus the extant Events.lua shit, investigate
-- TODO ^^^^

return {
    {
        version = 122,
        fields = {
            {
                name = "str",
                field_type = "StringU8",
            },
            {
                name = "hex",
                field_type = "Hex",
                length = 16,
            },
        },
    }
}
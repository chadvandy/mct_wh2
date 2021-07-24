return {
    {
        version = 91,
        fields = {
            {
                name = "name",
                field_type = "StringU8",
                is_key = true,
            },
            {
                name = "propagate",
                field_type = "Boolean",
            },
            {
                name = "make_non_interactive",
                field_type = "Boolean",
            },
            {
                name = "frames",
                field_type = {"Collection", {type = "ComponentAnimationFrame",
                     override_fields = {[1] = {
                                key = "total_loops", 
                                type = "I32"
                            }
                        }
                    },
                },
            },
            {
                name = "undeciphered_1",
                field_type = "Hex",
                length = 2,
            }
        },
    },
    {
        version = 93,
        fields = {
            {
                name = "name",
                field_type = "StringU8",
                is_key = true,
            },
            {
                name = "propagate",
                field_type = "Boolean",
            },
            {
                name = "make_non_interactive",
                field_type = "Boolean",
            },
            {
                name = "frames",
                field_type = {"Collection", {type = "ComponentAnimationFrame", override_fields = {[1] = {key = "total_loops", type = "I32"}}},
            },
            },
        },
    },
    {
        version = 95,
        fields = {
            {
                name = "name",
                field_type = "StringU8",
                is_key = true,
            },
            {
                name = "propagate",
                field_type = "Boolean",
            },
            {
                name = "make_non_interactive",
                field_type = "Boolean",
            },
            {
                name = "frames",
                field_type = {"Collection", {type = "ComponentAnimationFrame", override_fields = {[1] = {key = "total_loops", type = "I32"}}},},
            },
            {
                name = "undeciphered_1",
                field_type = "Hex",
                length = 2,
            }
        },
    },
    {
        version = 97,
        fields = {
            {
                name = "name",
                field_type = "StringU8",
                is_key = true,
            },
            {
                name = "propagate",
                field_type = "Boolean",
            },
            {
                name = "make_non_interactive",
                field_type = "Boolean",
            },
            {
                name = "frames",
                field_type = {"Collection", {type = "ComponentAnimationFrame", override_fields = {[1] = {key = "total_loops", type = "I32"}}},},
            },
        },
    },
    {
        version = 100,
        fields = {
            {
                name = "name",
                field_type = "StringU8",
                is_key = true,
            },
            {
                name = "propagate",
                field_type = "Boolean",
            },
            {
                name = "make_non_interactive",
                field_type = "Boolean",
            },
            {
                name = "frames",
                field_type = {"Collection", {type = "ComponentAnimationFrame", override_fields = {[1] = {key = "total_loops", type = "I32"}}},},
            },
        },
    },
    {
        version = 110,
        fields = {
            {
                name = "name",
                field_type = "StringU8",
                is_key = true,
            },
            {
                name = "propagate",
                field_type = "Boolean",
            },
            {
                name = "make_non_interactive",
                field_type = "Boolean",
            },
            {
                name = "frames",
                field_type = {"Collection", {type = "ComponentAnimationFrame", override_fields = {[1] = {key = "total_loops", type = "I32"}}},},
            },
        },
    }
}
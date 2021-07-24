

return {
    {
        version = 119,
        fields = {
            {
                name = "environment_filepath",
                type = "utf8",
            },

            -- STUFF
            {
                name = "ambient_cube_top",
                type = {"Collection", {type = "fraction", length = 3}}
            },
            {
                name = "ambient_cube_bottom",
                type = {"Collection", {type = "fraction", length = 3}}
            },
            {
                name = "ambient_cube_front",
                type = {"Collection", {type = "fraction", length = 3}}
            },
            {
                name = "ambient_cube_back",
                type = {"Collection", {type = "fraction", length = 3}}
            },
            {
                name = "ambient_cube_left",
                type = {"Collection", {type = "fraction", length = 3}}
            },
            {
                name = "ambient_cube_right",
                type = {"Collection", {type = "fraction", length = 3}}
            },
            {
                name = "direction_light_direction",
                type = {"Collection", {type = "float", length = 3}},
            },
            {
                name = "direction_light_colour",
                type = {"Collection", {type = "fraction", length = 3}}
            },
            {
                name = "lighting",
                type = {"Collection", {type = "float", keys = {"colour_scale", "lighting_factor_selected", "lighting_factor_unselected"}}}
            },
            {
                name = "is_orthographic_camera",
                type = "Boolean"
            },
            {
                name = "camera_target",
                type = {"Collection", "float"}
            },
            {
                name = "camera",
                type = {"Collection", {type = "float", keys = {"distance", "theta", "phi", "fov"}}}
            },
            {
                name = "models",
                type = {"Collection", "ComponentModel"},
            },
        }
    }
}
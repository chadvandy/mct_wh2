return {
    {
        version = 70,
        fields = {
            {
                name = "ui-id",
                is_key = true,
                field_type = "Hex",
                length = 4,
            },
            {
                name = "offset_x",
                field_type = "I32",
            },
            {
                name = "offset_y",
                field_type = "I32",
            },
            {
                name = "width",
                field_type = "I32",
            },
            {
                name = "height",
                field_type = "I32",
            },
            {   -- TODO handle this another way, needs specific type
                name = "colour",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "image_tiled",
                field_type = "Boolean",
            },
            {
                name = "x_flipped",
                field_type = "Boolean",
            },
            {
                name = "y_flipped",
                field_type = "Boolean",
            },
            {
                name = "docking_point",
                field_type = "I32",
                enum_values = {} -- TODO This
            },
            {
                name = "dock_offset_x",
                field_type = "I32",
            },
            {
                name = "dock_offset_y",
                field_type = "I32",
            },
            {
                name = "can_resize_width",
                field_type = "Boolean",
            },
            {
                name = "can_resize_height",
                field_type = "Boolean",
            },
            {   -- TODO this
                name = "rotation_angle",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "pivot_point_x",
                field_type = "I32",
            },
            {
                name = "pivot_point_y",
                field_type = "I32",
            },
            {
                name = "shader_name",
                field_type = "StringU8",
            },
            {
                name = "rotation_axis_x",
                field_type = "I32",
            },
            {
                name = "rotation_axis_y",
                field_type = "I32",
            },
            {
                name = "rotation_axis_z",
                field_type = "I32",
            },
            {
                name = "probably_opacity",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "b5",
                field_type = "Hex",
                length = 9,
            },
        }
    },
    {
        version = 79,
        fields = {
            {
                name = "ui-id",
                is_key = true,
                field_type = "Hex",
                length = 4,
            },
            {
                name = "offset_x",
                field_type = "I32",
            },
            {
                name = "offset_y",
                field_type = "I32",
            },
            {
                name = "width",
                field_type = "I32",
            },
            {
                name = "height",
                field_type = "I32",
            },
            {   -- TODO handle this another way, needs specific type
                name = "colour",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "image_tiled",
                field_type = "Boolean",
            },
            {
                name = "x_flipped",
                field_type = "Boolean",
            },
            {
                name = "y_flipped",
                field_type = "Boolean",
            },
            {
                name = "docking_point",
                field_type = "I32",
                enum_values = {} -- TODO This
            },
            {
                name = "dock_offset_x",
                field_type = "I32",
            },
            {
                name = "dock_offset_y",
                field_type = "I32",
            },
            {
                name = "can_resize_width",
                field_type = "Boolean",
            },
            {
                name = "can_resize_height",
                field_type = "Boolean",
            },
            {   -- TODO this
                name = "rotation_angle",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "pivot_point_x",
                field_type = "I32",
            },
            {
                name = "pivot_point_y",
                field_type = "I32",
            },
            {
                name = "shader_name",
                field_type = "StringU8",
            },
            {
                name = "rotation_axis_x",
                field_type = "I32",
            },
            {
                name = "rotation_axis_y",
                field_type = "I32",
            },
            {
                name = "rotation_axis_z",
                field_type = "I32",
            },
            {
                name = "probably_opacity",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "b5",
                field_type = "Hex",
                length = 8,
            },
        }
    },
    {
        version = 80,
        fields = {
            {
                name = "ui-id",
                is_key = true,
                field_type = "Hex",
                length = 4,
            },
            {
                name = "offset_x",
                field_type = "I32",
            },
            {
                name = "offset_y",
                field_type = "I32",
            },
            {
                name = "width",
                field_type = "I32",
            },
            {
                name = "height",
                field_type = "I32",
            },
            {   -- TODO handle this another way, needs specific type
                name = "colour",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "image_tiled",
                field_type = "Boolean",
            },
            {
                name = "x_flipped",
                field_type = "Boolean",
            },
            {
                name = "y_flipped",
                field_type = "Boolean",
            },
            {
                name = "docking_point",
                field_type = "I32",
                enum_values = {} -- TODO This
            },
            {
                name = "dock_offset_x",
                field_type = "I32",
            },
            {
                name = "dock_offset_y",
                field_type = "I32",
            },
            {
                name = "can_resize_width",
                field_type = "Boolean",
            },
            {
                name = "can_resize_height",
                field_type = "Boolean",
            },
            {   -- TODO this
                name = "rotation_angle",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "pivot_point_x",
                field_type = "I32",
            },
            {
                name = "pivot_point_y",
                field_type = "I32",
            },
            {
                name = "shader_name",
                field_type = "StringU8",
            },
            {
                name = "rotation_axis_x",
                field_type = "I32",
            },
            {
                name = "rotation_axis_y",
                field_type = "I32",
            },
            {
                name = "rotation_axis_z",
                field_type = "I32",
            },
            {
                name = "probably_opacity",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_1",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_2",
                field_type = "Hex",
                length = 4,
            },
        }
    },
    {
        version = 92,
        fields = {
            {
                name = "ui-id",
                is_key = true,
                field_type = "Hex",
                length = 4,
            },
            {
                name = "offset_x",
                field_type = "I32",
            },
            {
                name = "offset_y",
                field_type = "I32",
            },
            {
                name = "width",
                field_type = "I32",
            },
            {
                name = "height",
                field_type = "I32",
            },
            {   -- TODO handle this another way, needs specific type
                name = "colour",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "image_tiled",
                field_type = "Boolean",
            },
            {
                name = "x_flipped",
                field_type = "Boolean",
            },
            {
                name = "y_flipped",
                field_type = "Boolean",
            },
            {
                name = "docking_point",
                field_type = "I32",
                enum_values = {} -- TODO This
            },
            {
                name = "dock_offset_x",
                field_type = "I32",
            },
            {
                name = "dock_offset_y",
                field_type = "I32",
            },
            {
                name = "can_resize_width",
                field_type = "Boolean",
            },
            {
                name = "can_resize_height",
                field_type = "Boolean",
            },
            {   -- TODO this
                name = "rotation_angle",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "pivot_point_x",
                field_type = "I32",
            },
            {
                name = "pivot_point_y",
                field_type = "I32",
            },
            {
                name = "shader_name",
                field_type = "StringU8",
            },
            {
                name = "rotation_axis_x",
                field_type = "I32",
            },
            {
                name = "rotation_axis_y",
                field_type = "I32",
            },
            {
                name = "rotation_axis_z",
                field_type = "I32",
            },
            {
                name = "probably_opacity",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_1",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_2",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_3",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_4",
                field_type = "Hex",
                length = 4,
            },
        }
    },
    {
        version = 94,
        fields = {
            {
                name = "ui-id",
                is_key = true,
                field_type = "Hex",
                length = 4,
            },
            {
                name = "offset_x",
                field_type = "I32",
            },
            {
                name = "offset_y",
                field_type = "I32",
            },
            {
                name = "width",
                field_type = "I32",
            },
            {
                name = "height",
                field_type = "I32",
            },
            {   -- TODO handle this another way, needs specific type
                name = "colour",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "image_tiled",
                field_type = "Boolean",
            },
            {
                name = "x_flipped",
                field_type = "Boolean",
            },
            {
                name = "y_flipped",
                field_type = "Boolean",
            },
            {
                name = "docking_point",
                field_type = "I32",
                enum_values = {} -- TODO This
            },
            {
                name = "dock_offset_x",
                field_type = "I32",
            },
            {
                name = "dock_offset_y",
                field_type = "I32",
            },
            {
                name = "can_resize_width",
                field_type = "Boolean",
            },
            {
                name = "can_resize_height",
                field_type = "Boolean",
            },
            {   -- TODO this
                name = "rotation_angle",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "pivot_point_x",
                field_type = "I32",
            },
            {
                name = "pivot_point_y",
                field_type = "I32",
            },
            {
                name = "shader_name",
                field_type = "StringU8",
            },
            {
                name = "rotation_axis_x",
                field_type = "I32",
            },
            {
                name = "rotation_axis_y",
                field_type = "I32",
            },
            {
                name = "rotation_axis_z",
                field_type = "I32",
            },
            {
                name = "probably_opacity",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_1",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_2",
                field_type = "Hex",
                length = 4,
            },
        }
    },
    {
        version = 103,
        fields = {
            {
                name = "ui-id",
                is_key = true,
                field_type = "Hex",
                length = 4,
            },
            {
                name = "offset_x",
                field_type = "I32",
            },
            {
                name = "offset_y",
                field_type = "I32",
            },
            {
                name = "width",
                field_type = "I32",
            },
            {
                name = "height",
                field_type = "I32",
            },
            {   -- TODO handle this another way, needs specific type
                name = "colour",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "image_tiled",
                field_type = "Boolean",
            },
            {
                name = "x_flipped",
                field_type = "Boolean",
            },
            {
                name = "y_flipped",
                field_type = "Boolean",
            },
            {
                name = "docking_point",
                field_type = "I32",
                enum_values = {} -- TODO This
            },
            {
                name = "dock_offset_x",
                field_type = "I32",
            },
            {
                name = "dock_offset_y",
                field_type = "I32",
            },
            {
                name = "can_resize_width",
                field_type = "Boolean",
            },
            {
                name = "can_resize_height",
                field_type = "Boolean",
            },
            {   -- TODO this
                name = "rotation_angle",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "pivot_point_x",
                field_type = "I32",
            },
            {
                name = "pivot_point_y",
                field_type = "I32",
            },
            {
                name = "rotation_axis_x",
                field_type = "I32",
            },
            {
                name = "rotation_axis_y",
                field_type = "I32",
            },
            {
                name = "rotation_axis_z",
                field_type = "I32",
            },
            {
                name = "shader_name",
                field_type = "StringU8",
            },
            {
                name = "shader_technique_vars_1",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "shader_technique_vars_2",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "shader_technique_vars_3",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "shader_technique_vars_4",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_1",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_2",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_3",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_4",
                field_type = "Hex",
                length = 4,
            },
        }
    },
    {
        version = 119,
        fields = {
            {
                name = "ui-id",
                is_key = true,
                field_type = "Hex",
                length = 4,
            },
            {
                name = "offset_x",
                field_type = "I32",
            },
            {
                name = "offset_y",
                field_type = "I32",
            },
            {
                name = "width",
                field_type = "I32",
            },
            {
                name = "height",
                field_type = "I32",
            },
            {   -- TODO handle this another way, needs specific type
                name = "colour",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "undeciphered_1",
                field_type = "StringU8",
            },
            {
                name = "image_tiled",
                field_type = "Boolean",
            },
            {
                name = "x_flipped",
                field_type = "Boolean",
            },
            {
                name = "y_flipped",
                field_type = "Boolean",
            },
            {
                name = "docking_point",
                field_type = "I32",
                enum_values = {} -- TODO This
            },
            {
                name = "dock_offset_x",
                field_type = "I32",
            },
            {
                name = "dock_offset_y",
                field_type = "I32",
            },
            {
                name = "can_resize_width",
                field_type = "Boolean",
            },
            {
                name = "can_resize_height",
                field_type = "Boolean",
            },
            {   -- TODO this
                name = "rotation_angle",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "pivot_point_x",
                field_type = "I32",
            },
            {
                name = "pivot_point_y",
                field_type = "I32",
            },
            {
                name = "rotation_axis_x",
                field_type = "I32",
            },
            {
                name = "rotation_axis_y",
                field_type = "I32",
            },
            {
                name = "rotation_axis_z",
                field_type = "I32",
            },
            {
                name = "shader_name",
                field_type = "StringU8",
            },
            {
                name = "shader_technique_vars_1",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "shader_technique_vars_2",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "shader_technique_vars_3",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "shader_technique_vars_4",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_1",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_2",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_3",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_4",
                field_type = "Hex",
                length = 4,
            },
        }
    },
    {
        version = 126,
        fields = {
            {
                name = "ui-id",
                is_key = true,
                field_type = "Hex",
                length = 4,
            },
            {
                name = "undeciphered_0",
                field_type = "Hex",
                length = 16,
            },
            {
                name = "offset_x",
                field_type = "I32",
            },
            {
                name = "offset_y",
                field_type = "I32",
            },
            {
                name = "width",
                field_type = "I32",
            },
            {
                name = "height",
                field_type = "I32",
            },
            {   -- TODO handle this another way, needs specific type
                name = "colour",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "undeciphered_1",
                field_type = "StringU8",
            },
            {
                name = "image_tiled",
                field_type = "Boolean",
            },
            {
                name = "x_flipped",
                field_type = "Boolean",
            },
            {
                name = "y_flipped",
                field_type = "Boolean",
            },
            {
                name = "docking_point",
                field_type = "I32",
                enum_values = {} -- TODO This
            },
            {
                name = "dock_offset_x",
                field_type = "I32",
            },
            {
                name = "dock_offset_y",
                field_type = "I32",
            },
            {
                name = "can_resize_width",
                field_type = "Boolean",
            },
            {
                name = "can_resize_height",
                field_type = "Boolean",
            },
            {   -- TODO this
                name = "rotation_angle",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "pivot_point_x",
                field_type = "I32",
            },
            {
                name = "pivot_point_y",
                field_type = "I32",
            },
            {
                name = "rotation_axis_x",
                field_type = "I32",
            },
            {
                name = "rotation_axis_y",
                field_type = "I32",
            },
            {
                name = "rotation_axis_z",
                field_type = "I32",
            },
            {
                name = "shader_name",
                field_type = "StringU8",
            },
            {
                name = "shader_technique_vars_1",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "shader_technique_vars_2",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "shader_technique_vars_3",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "shader_technique_vars_4",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_1",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_2",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_3",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "margin_4",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "b5",
                field_type = "Hex",
                length = 1,
            }
        }
    },
}
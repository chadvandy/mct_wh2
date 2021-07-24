return {
    {
        version = 70,
        fields = {
            {
                name = "ui-id",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "name",
                type = "StringU8",
            },
            {
                name = "dimensions",
                type = {"Collection", {type = "I32", keys = {"width", "height"}}},
            },
            {
                name = "text",
                type = "StringU16",
            },
            {
                name = "tooltip",
                type = "StringU16",
            },
            {
                name = "text_bounds",
                type = {"Collection", {type = "I32", keys = {"width", "heigh"}}},
            },
            {   -- TODO enumerate?
                name = "text_alignment",
                type = {"Collection", {type = "I32", keys = {"vertical", "horizontal"}}}
            },
            {   -- texthbehavior? TODO
                name = "b1",
                type = "Hex",
                length = 1,
            },
            {
                name = "text_label",
                type = "StringU16",
            },
            {
                name = "b3",
                type = "Hex",
                length = 2,
            },
            {
                name = "tooltip_localised",
                type = "StringU16",
            },
            {
                name = "tooltip_id",
                type = "StringU16",
            },
            {   -- TODO enumerate!
                name = "font_name",
                type = "StringU8",
            },
            {   -- Floats below?
                name = "font_size",
                type = "I32",
            },
            {
                name = "font_leading",
                type = "I32",
            },
            {
                name = "font_tracking", 
                type = "I32",
            },
            {   -- TODO colour type
                name = "font_colour",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enumerate!
                name = "font_category",
                type = "StringU8",
            },
            {
                name = "text_offset",
                type = {"Collection", {type = "I32", keys = {"x", "y"}}},
            },
            {
                name = "b7",
                type = "Hex",
                length = 7,
            },
            {   -- TODO enum
                name = "shader_name",
                type = "StringU8",
            },
            {
                name = "shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {   -- TODO enum
                name = "text_shader_name",
                type = "StringU8",
            },
            {
                name = "text_shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {
                name = "image_metrics",
                type = {"Collection", "ComponentImageMetric"}
            },
            {
                name = "before_mouse",
                type = "Hex",
                length = 8,
            },
            {
                name = "mouses",
                type = {"Collection", "ComponentMouse"},
            },
        }
    },
    {
        version = 80,
        fields = {
            {
                name = "ui-id",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "name",
                type = "StringU8",
            },
            {
                name = "dimensions",
                type = {"Collection", {type = "I32", keys = {"width", "height"}}},
            },
            {
                name = "text",
                type = "StringU16",
            },
            {
                name = "tooltip",
                type = "StringU16",
            },
            {
                name = "text_bounds",
                type = {"Collection", {type = "I32", keys = {"width", "heigh"}}},
            },
            {   -- TODO enumerate?
                name = "text_alignment",
                type = {"Collection", {type = "I32", keys = {"vertical", "horizontal"}}}
            },
            {   -- texthbehavior? TODO
                name = "b1",
                type = "Hex",
                length = 1,
            },
            {
                name = "text_label",
                type = "StringU16",
            },
            {
                name = "b3",
                type = "Hex",
                length = 2,
            },
            {
                name = "tooltip_localised",
                type = "StringU16",
            },
            {
                name = "tooltip_id",
                type = "StringU16",
            },
            {   -- TODO enumerate!
                name = "font_name",
                type = "StringU8",
            },
            {   -- Floats below?
                name = "font_size",
                type = "I32",
            },
            {
                name = "font_leading",
                type = "I32",
            },
            {
                name = "font_tracking", 
                type = "I32",
            },
            {   -- TODO colour type
                name = "font_colour",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enumerate!
                name = "font_category",
                type = "StringU8",
            },
            {
                name = "text_offset",
                type = {"Collection", {type = "I32", keys = {"l", "r", "t", "b"}}},
            },
            -- {    -- This doesn't exist for 80-89??
            --     name = "b7",
            --     type = "Hex",
            --     length = 7,
            -- },
            {   -- TODO enum
                name = "shader_name",
                type = "StringU8",
            },
            {
                name = "shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {   -- TODO enum
                name = "text_shader_name",
                type = "StringU8",
            },
            {
                name = "text_shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {
                name = "image_metrics",
                type = {"Collection", "ComponentImageMetric"}
            },
            {
                name = "before_mouse",
                type = "Hex",
                length = 8,
            },
            {
                name = "mouses",
                type = {"Collection", "ComponentMouse"},
            },
        }
    },
    {
        version = 90,
        fields = {
            {
                name = "ui-id",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "name",
                type = "StringU8",
            },
            {
                name = "dimensions",
                type = {"Collection", {type = "I32", keys = {"width", "height"}}},
            },
            {
                name = "text",
                type = "StringU16",
            },
            {
                name = "tooltip",
                type = "StringU16",
            },
            {
                name = "text_bounds",
                type = {"Collection", {type = "I32", keys = {"width", "heigh"}}},
            },
            {   -- TODO enumerate?
                name = "text_alignment",
                type = {"Collection", {type = "I32", keys = {"vertical", "horizontal"}}}
            },
            {   -- texthbehavior? TODO
                name = "b1",
                type = "Hex",
                length = 1,
            },
            {
                name = "text_label",
                type = "StringU16",
            },
            {
                name = "b3",
                type = "Hex",
                length = 2,
            },
            {
                name = "tooltip_localised",
                type = "StringU16",
            },
            {
                name = "tooltip_id",
                type = "StringU16",
            },
            {
                name = "b5",
                type = "StringU8",
            },
            {   -- TODO enumerate!
                name = "font_name",
                type = "StringU8",
            },
            {   -- Floats below?
                name = "font_size",
                type = "I32",
            },
            {
                name = "font_leading",
                type = "I32",
            },
            {
                name = "font_tracking", 
                type = "I32",
            },
            {   -- TODO colour type
                name = "font_colour",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enumerate!
                name = "font_category",
                type = "StringU8",
            },
            {
                name = "text_offset",
                type = {"Collection", {type = "I32", keys = {"l", "r", "t", "b"}}},
            },
            {   -- TODO second bit here is is_interactive!
                name = "b7",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enum
                name = "shader_name",
                type = "StringU8",
            },
            {
                name = "shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {   -- TODO enum
                name = "text_shader_name",
                type = "StringU8",
            },
            {
                name = "text_shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {
                name = "image_metrics",
                type = {"Collection", "ComponentImageMetric"}
            },
            {
                name = "before_mouse",
                type = "Hex",
                length = 8,
            },
            {
                name = "mouses",
                type = {"Collection", "ComponentMouse"},
            },
        }
    },
    {
        version = 110,
        fields = {
            {
                name = "ui-id",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "name",
                type = "StringU8",
            },
            {
                name = "dimensions",
                type = {"Collection", {type = "I32", keys = {"width", "height"}}},
            },
            {
                name = "text",
                type = "StringU16",
            },
            {
                name = "tooltip",
                type = "StringU16",
            },
            {
                name = "text_bounds",
                type = {"Collection", {type = "I32", keys = {"width", "heigh"}}},
            },
            {   -- TODO enumerate?
                name = "text_alignment",
                type = {"Collection", {type = "I32", keys = {"vertical", "horizontal"}}}
            },
            {   -- texthbehavior? TODO
                name = "b1",
                type = "Hex",
                length = 1,
            },
            {
                name = "text_label",
                type = "StringU16",
            },
            {
                name = "b3",
                type = "Hex",
                length = 2,
            },
            {
                name = "tooltip_localised",
                type = "StringU16",
            },
            {
                name = "tooltip_id",
                type = "StringU16",
            },
            {
                name = "b4",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enumerate!
                name = "font_name",
                type = "StringU8",
            },
            {   -- Floats below?
                name = "font_size",
                type = "I32",
            },
            {
                name = "font_leading",
                type = "I32",
            },
            {
                name = "font_tracking", 
                type = "I32",
            },
            {   -- TODO colour type
                name = "font_colour",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enumerate!
                name = "font_category",
                type = "StringU8",
            },
            {
                name = "text_offset",
                type = {"Collection", {type = "I32", keys = {"l", "r", "t", "b"}}},
            },
            {   -- TODO second bit here is is_interactive!
                name = "b7",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enum
                name = "shader_name",
                type = "StringU8",
            },
            {
                name = "shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {   -- TODO enum
                name = "text_shader_name",
                type = "StringU8",
            },
            {
                name = "text_shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {
                name = "image_metrics",
                type = {"Collection", "ComponentImageMetric"}
            },
            {
                name = "before_mouse",
                type = "Hex",
                length = 8,
            },
            {
                name = "mouses",
                type = {"Collection", "ComponentMouse"},
            },
        }
    },
    {
        version = 116,
        fields = {
            {
                name = "ui-id",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "name",
                type = "StringU8",
            },
            {
                name = "dimensions",
                type = {"Collection", {type = "I32", keys = {"width", "height"}}},
            },
            {
                name = "text",
                type = "StringU16",
            },
            {
                name = "tooltip",
                type = "StringU16",
            },
            {
                name = "text_bounds",
                type = {"Collection", {type = "I32", keys = {"width", "height"}}},
            },
            {   -- TODO enumerate?
                name = "text_alignment",
                type = {"Collection", {type = "I32", keys = {"vertical", "horizontal"}}}
            },
            {   -- texthbehavior? TODO
                name = "b1",
                type = "Hex",
                length = 1,
            },
            {
                name = "text_label",
                type = "StringU16",
            },
            {
                name = "tooltip_localised",
                type = "StringU16",
            },
            {   -- "b3" in Cpecific
                name = "tooltip_id",
                type = "StringU16",
            },
            -- {
            --     name = "b4",
            --     type = "Hex",
            --     length = 4,
            -- },
            {   -- TODO enumerate!
                name = "font_name",
                type = "StringU8",
            },
            {   -- Floats below?
                name = "font_size",
                type = "I32",
            },
            {
                name = "font_leading",
                type = "I32",
            },
            {
                name = "font_tracking", 
                type = "I32",
            },
            {   -- TODO colour type
                name = "font_colour",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enumerate!
                name = "font_category",
                type = "StringU8",
            },
            {
                name = "text_offset",
                type = {"Collection", {type = "I32", keys = {"l", "r", "t", "b"}}},
            },
            {   -- TODO second bit here is is_interactive!
                name = "b7",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enum
                name = "shader_name",
                type = "StringU8",
            },
            {
                name = "shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {   -- TODO enum
                name = "text_shader_name",
                type = "StringU8",
            },
            {
                name = "text_shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {
                name = "image_metrics",
                type = {"Collection", "ComponentImageMetric"}
            },
            {
                name = "before_mouse",
                type = "Hex",
                length = 8,
            },
            {
                name = "mouses",
                type = {"Collection", "ComponentMouse"},
            },
        }
    },
    {
        version = 121,
        fields = {
            {
                name = "ui-id",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "name",
                type = "StringU8",
            },
            {
                name = "dimensions",
                type = {"Collection", {type = "I32", keys = {"width", "height"}}},
            },
            {
                name = "text",
                type = "StringU16",
            },
            {
                name = "tooltip",
                type = "StringU16",
            },
            {
                name = "text_bounds",
                type = {"Collection", {type = "I32", keys = {"width", "heigh"}}},
            },
            {   -- TODO enumerate?
                name = "text_alignment",
                type = {"Collection", {type = "I32", keys = {"vertical", "horizontal"}}}
            },
            {   -- texthbehavior? TODO
                name = "b1",
                type = "Hex",
                length = 1,
            },
            {
                name = "text_label",
                type = "StringU16",
            },
            {
                name = "tooltip_localised",
                type = "StringU16",
            },
            {
                name = "tooltip_id",
                type = "StringU16",
            },
            {
                name = "unknown_str",
                type = "StringU8",
            },
            {   -- TODO enumerate!
                name = "font_name",
                type = "StringU8",
            },
            {   -- Floats below?
                name = "font_size",
                type = "I32",
            },
            {
                name = "font_leading",
                type = "I32",
            },
            {
                name = "font_tracking", 
                type = "I32",
            },
            {   -- TODO colour type
                name = "font_colour",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enumerate!
                name = "font_category",
                type = "StringU8",
            },
            {
                name = "text_offset",
                type = {"Collection", {type = "I32", keys = {"l", "r", "t", "b"}}},
            },
            {   -- TODO second bit here is is_interactive!
                name = "b7",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enum
                name = "shader_name",
                type = "StringU8",
            },
            {
                name = "shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {   -- TODO enum
                name = "text_shader_name",
                type = "StringU8",
            },
            {
                name = "text_shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {
                name = "image_metrics",
                type = {"Collection", "ComponentImageMetric"}
            },
            {
                name = "before_mouse",
                type = "Hex",
                length = 8,
            },
            {
                name = "mouses",
                type = {"Collection", "ComponentMouse"},
            },
        }
    },
    {
        version = 124,
        fields = {
            {
                name = "ui-id",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "name",
                type = "StringU8",
            },
            {
                name = "dimensions",
                type = {"Collection", {type = "I32", keys = {"width", "height"}}},
            },
            {
                name = "text",
                type = "StringU16",
            },
            {
                name = "tooltip",
                type = "StringU16",
            },
            {
                name = "text_bounds",
                type = {"Collection", {type = "I32", keys = {"width", "heigh"}}},
            },
            {   -- TODO enumerate?
                name = "text_alignment",
                type = {"Collection", {type = "I32", keys = {"vertical", "horizontal"}}}
            },
            {   -- texthbehavior? TODO
                name = "b1",
                type = "Hex",
                length = 1,
            },
            {
                name = "text_label",
                type = "StringU16",
            },
            {
                name = "tooltip_localised",
                type = "StringU16",
            },
            {
                name = "b3",
                type = "Hex",
                length = 2,
            },
            {
                name = "tooltip_id",
                type = "StringU16",
            },
            -- {
            --     name = "b5",
            --     type = "StringU8",
            -- },
            {   -- TODO enumerate!
                name = "font_name",
                type = "StringU8",
            },
            {   -- Floats below?
                name = "font_size",
                type = "I32",
            },
            {
                name = "font_leading",
                type = "I32",
            },
            {
                name = "font_tracking", 
                type = "I32",
            },
            {   -- TODO colour type
                name = "font_colour",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enumerate!
                name = "font_category",
                type = "StringU8",
            },
            {
                name = "text_offset",
                type = {"Collection", {type = "I32", keys = {"l", "r", "t", "b"}}},
            },
            {   -- TODO second bit here is is_interactive!
                name = "b7",
                type = "Hex",
                length = 4,
            },
            {   -- TODO enum
                name = "shader_name",
                type = "StringU8",
            },
            {
                name = "shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {   -- TODO enum
                name = "text_shader_name",
                type = "StringU8",
            },
            {
                name = "text_shader_vars",
                type = {"Collection", {type = "float", keys = {"one", "two", "three", "four"}}},
            },
            {
                name = "image_metrics",
                type = {"Collection", "ComponentImageMetric"}
            },
            {
                name = "before_mouse",
                type = "Hex",
                length = 8,
            },
            {
                name = "mouses",
                type = {"Collection", "ComponentMouse"},
            },
            -- {   -- TODO
            --     name = "state_undeciphered",
            --     type = {"Collection16", "ComponentStateStuff"},
            -- },
            --[[
                if ($v >= 124){
                    $a = read_string($h, 1, $my);
                    if (empty($a)){
                        $this->b8 = array($a);
                    } else{
                        $a = array($a);
                        
                        $num_sth = my_unpack_one($this, 'l', fread($h, 4));
                        $sth = array();
                        for ($i = 0; $i < $num_sth; ++$i){
                            $b = array();
                            $b[] = read_string($h, 1, $my);
                            $b[] = tohex(fread($h, 16));
                            $sth[] = $b;
                        }
                        $a[] = $sth;
                        
                        $num_sth = my_unpack_one($this, 'l', fread($h, 4));
                        $sth = array();
                        for ($i = 0; $i < $num_sth; ++$i){
                            $b = array();
                            $b[] = read_string($h, 1, $my);
                            $b[] = read_string($h, 1, $my);
                            $sth[] = $b;
                        }
                        $a[] = $sth;
                        
                        $this->b8 = $a;
                    }
                }
            ]]
        }
    }
}
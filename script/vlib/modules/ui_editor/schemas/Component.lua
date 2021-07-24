return {
    {
        version = 119,
        fields = {
            {
                name = "ui-id",
                type = "Hex",
                length = 4,
            },
            {
                name = 'name',
                type = "UTF8"
            },
            {
                name = 'template_key',
                type = 'utf8',
            },
            {
                name = 'events',
                type = {"Collection", "ComponentEvent"}
            },
            {
                name = 'offsets',
                type = {"Collection", {type = "I32", keys = {"x", "y"}}}
            },
            {
                name = "undeciphered_bools",
                type = "Hex",
                length = 12,
                --[[
                    allowhorizontalresize="false"
                    allowverticalresize="false"
                    visible="true"
                    clipchildren="false"
                    clipimagestocomponent="true"
                    useglobalclicks="false"
                    renderwhendragged="false"
                    renderifroot="false"
                    renderlastonfocused="false"
                    tooltipslocalised="true"
                    updatewhennotvisible="false"
                    isaspectratiolocked="false"
                    isrelativeresize="false"

                    PROBABLY NOT THESE:
                        locked="false"
			            marked_for_deletion="false"
                        part_of_template="false"
                ]]
            },
            {
                name = "tooltip_text",
                type = "utf16"
            },
            {
                name = "tooltip_id",
                type = "utf16"
            },
            {   -- TODO enum!
                name = "docking_point",
                type = "I32",
            },
            {
                name = "dock_offsets",
                type = {"Collection", {type = "I32", keys = {"x", "y"}}}
            },
            {
                name = "component_priority",
                type = "Hex",
                length = 1,
            },
            {   -- TODO reference!
                name = "default_state",
                type = "Hex",
                length = 4,
            },
            {
                name = "images",
                type = {"Collection", "ComponentImage"},
            },
            {   -- TODO reference!
                name = "mask_image",
                type = "Hex",
                length = 4,
            },
            {
                name = "states",
                type = {"Collection", "ComponentState"}
            },
            {
                name = "properties",
                type = {"Collection", "ComponentProperty"}
            },
            {   -- TODO unknown! Could be "current state"?
                name = "b6",
                type = "Hex",
                length = 4,
            },
            {
                name = "animations",
                type = {"Collection", "ComponentAnimation"}
            },
            {
                name = "children",
                type = {"Collection", "Component"}
            },
            {
                name = "has_layout",
                type = "Boolean",
            },
            {   -- TODO it's not a collection!
                name = "layout_engine",
                type = {"Collection", {type = "ComponentLayoutEngine", length = 1}},
            },

            -- There might be stuff between layout engine and this!
            {
                name = "has_model_view",
                type = "Boolean",
            },
            {   -- TODO it's not a collection!
                name = "model_view",
                type = {"Collection", {type = "ComponentModelView", length = 1}},
            }
        }
    }
}
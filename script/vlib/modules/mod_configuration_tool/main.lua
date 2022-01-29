local vlib = get_vlib()

local mct_path = "script/vlib/modules/mod_configuration_tool/"
local objects_path = mct_path .. "objects/"
local modules_path = mct_path.."modules/"
local types_path = mct_path.."types/"

---@type mct
local mct = vlib:load_module("mct", objects_path)

--- Global getter for the mct object.
---@return mct
function get_mct()
    return core:get_static_object("mod_configuration_tool")
end

_G.get_mct = get_mct

core:add_static_object("mod_configuration_tool", mct, false)

--- startup function
do
    mct:log("********")
    mct:log("LOADING INTERNAL MODULES")
    mct:log("********")
    
    -- load modules!

    -- load the settings and UI files first

    local settings = vlib:load_module("settings", objects_path)
    mct.settings = settings

    ---@type mct_ui
    local ui = vlib:load_module("ui_obj", objects_path)
    mct.ui = ui

    mct._MCT_TYPES = {}
    local ok, msg = pcall(function()
        -- TODO auto-load all types
        ---@type template_type
        mct._MCT_TYPES.template = vlib:load_module("zzz_template", types_path)
        ---@type mct_slider
        mct._MCT_TYPES.slider = vlib:load_module("slider", types_path)
        ---@type mct_dropdown
        mct._MCT_TYPES.dropdown = vlib:load_module("dropdown", types_path)
        ---@type mct_checkbox
        mct._MCT_TYPES.checkbox = vlib:load_module("checkbox", types_path)
        ---@type mct_text_input
        mct._MCT_TYPES.text_input = vlib:load_module("text_input", types_path)
        --self._MCT_TYPES.multibox = self:load_module("multibox", types_path)
        ---@type mct_dummy
        mct._MCT_TYPES.dummy = vlib:load_module("dummy", types_path)

        -- load MCT objects
        ---@type mct_option
        mct._MCT_OPTION = vlib:load_module("option_obj", objects_path)

        ---@type mct_mod
        mct._MCT_MOD = vlib:load_module("mod_obj", objects_path)

        ---@type mct_section
        mct._MCT_SECTION = vlib:load_module("section_obj", objects_path)

    end) if not ok then mct:err(msg) end

    mct:log("INIT 1")
    --- Load all internal modules!
    vlib:load_modules(modules_path)

    mct:log("INIT 2")
    -- load mods in script/mct/settings/!
    mct:load_mods()

    mct:log("INIT 3")
    
    if not core:is_campaign() then
        -- trigger load_and_start after all mod scripts are loaded!
        core:add_listener(
            "MCT_Init",
            "ScriptEventAllModsLoaded",
            true,
            function(context)
                mct:load_and_start()
            end,
            false
        )
    else
        mct:log("LISTENING FOR LOAD GAME")
        
        cm:add_loading_game_callback(function(context)
            mct:log("LOADING GAME CALBACK")
            if not cm.game_interface:model():is_multiplayer() then
                mct:load_and_start(context, false)
            else
                mct:load_and_start(context, true)
            end
        end)
    end
end
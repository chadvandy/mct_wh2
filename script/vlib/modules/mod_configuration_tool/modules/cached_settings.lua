--- All the stuff needed for the cached settings mechanic and display in UI

local mct = get_mct()
local vlib = get_vlib()

local log,logf,err,errf = vlib:get_log_functions("[mct_cache]")

---@type mct_ui
local ui = mct.ui

ui:new_tab("cached_settings", "icon_tech.png")

ui:set_tab_action(
    "cached_settings",
    function (ui_obj, mod, list_view)
        -- populate the tab based on cached settings

        -- First, a list of all of the mods (named if they are currently loaded, just a key otherwise) in cached settings
            -- Option to remove this from the cache entirely

        -- Second, click the mods to see a canvas of all of the options and their attached settings
            -- In each of these, an "X" to remove this from the cache entirely

        -- global option to clear the entire cache, using a text button & a popup (no popup for any other clear though)
    end
)
local def = false


local function init()
    if def then
        
        local x, y = cm:find_valid_spawn_location_for_character_from_settlement(
            "wh_main_dwf_dwarfs",
            "wh_main_the_silver_road_karaz_a_karak",
            false,
            true
        )

        cm:create_force(
            "wh_main_dwf_dwarfs",
            "wh_dlc06_dwf_inf_rangers_0,wh_dlc06_dwf_inf_rangers_0,wh_dlc06_dwf_inf_rangers_0,wh_dlc06_dwf_inf_rangers_0,wh_dlc06_dwf_inf_rangers_0,wh_dlc06_dwf_inf_rangers_0,wh_dlc06_dwf_inf_rangers_0,wh_dlc06_dwf_inf_rangers_0",
            "wh_main_the_silver_road_karaz_a_karak",
            x,
            y,
            true,
            nil        
        )
    end
end

cm:add_first_tick_callback(function()
    get_mct():log("first tick")
    if cm:is_new_game() and not cm:is_multiplayer() then
        init()
    end
end)


-- MctInitialized is called shortly after the Lua environment is safe to mess with
core:add_listener(
    "MctModInitialized",
    "MctInitialized",
    true,
    function(context)
        local mct = context:mct()
        mct:log("spawning fucks")

        local mod = mct:get_mod_by_key("mct_mod")

        local option = mod:get_option_by_key("mct2")
        local setting = option:get_finalized_setting()

        def = setting

        if context:is_multiplayer() then
            init()
        end
    end,
    true
)
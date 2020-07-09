-- _init.lua files are solely for controlling the initialization functions. Everything else belongs in another file.
local mct = get_mct()

core:add_listener(
    "MCT_Init_SP",
    "LoadingGame",
    true, 
    function(context)
        if not cm.game_interface:model():is_multiplayer() then
            ModLog("henk")
            mct:load_and_start(context, false)
        else
            -- save the host key into the save game
            if cm:is_new_game() then
                --local mp_file = loadfile("mct_mp")
                --if mp_file then
                    --local host_faction_key = mp_file().faction_key
                    local host_faction_key = core:svr_load_string("mct_mp_host")
            
                    cm:set_saved_value("mct_host", host_faction_key)
                --end
            end

            ModLog("MP: ferk")
            mct:load_and_start(context, true)
        end
    end,
    true
)
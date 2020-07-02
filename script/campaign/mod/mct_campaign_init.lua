-- _init.lua files are solely for controlling the initialization functions. Everything else belongs in another file.
local mct = get_mct()


core:add_listener(
    "MCT_Init_SP",
    "LoadingGame",
    true, 
    function(context)
        if not cm:is_multiplayer() then
            ModLog("henk")
            mct:init(context)
        else
            ModLog("ferk")
        end
    end, 
    true
)
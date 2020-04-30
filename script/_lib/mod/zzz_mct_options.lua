local function enable_logging(enable)
    if enable then
        __write_output_to_logfile = true

        if __logfile_path == "" then
            __logfile_path = "script_log_" .. os.date("%d".."".."%m".."".."%y".."_".."%H".."".."%M") .. ".txt"
        end
    else
        __write_output_to_logfile = false
    end
end

local function init(mct)
    local mod = mct:get_mod_by_key("mct_mod")
    local option = mod:get_option_by_key("enable_logging")

    enable_logging(option:get_finalized_setting())
end

core:add_listener(
    "MctModEnableLoggingChanged",
    "MctOptionSettingFinalized",
    function(context)
        out("TEST 1")
        out(tostring(context))
        out(tostring(context:mod()))
        out(tostring(context:mod():get_key()))
        out(context:mod():get_key())
        out(context:option():get_key())
        return context:mod():get_key() == "mct_mod" and context:option():get_key() == "enable_logging"
    end,
    function(context)
        out("TEST 2")
        out(tostring(context:setting()))
        enable_logging(context:setting())
    end,
    true
)

core:add_listener(
    "MctModInitialized",
    "MctInitialized",
    true,
    function(context)
        init(context:mct())
    end,
    true
)
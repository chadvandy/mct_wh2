-- edits the global environment to reenable out()'s
local function enable_logging(enable)
    if enable then
        __write_output_to_logfile = true

        if __logfile_path == "" then
            __logfile_path = "script_log_" .. os.date("%d".."".."%m".."".."%y".."_".."%H".."".."%M") .. ".txt"
            _G.logfile_path = __logfile_path
        end
    else
        __write_output_to_logfile = false
    end
end

-- first init - reads the mct_mod object, then the option "enable_logging", and checks its setting - true/false
local function init(mct)
    local mod = mct:get_mod_by_key("mct_mod")
    local option = mod:get_option_by_key("enable_logging")

    enable_logging(option:get_finalized_setting())
end

-- MctOptionSettingFinalized is called for each changed option when settings are finalized
core:add_listener(
    "MctModEnableLoggingChanged",
    "MctOptionSettingFinalized",
    function(context)
        return context:mod():get_key() == "mct_mod" and context:option():get_key() == "enable_logging"
    end,
    function(context)
        enable_logging(context:setting())
    end,
    true
)

-- MctInitialized is called shortly after the Lua environment is safe to mess with
core:add_listener(
    "MctModInitialized",
    "MctInitialized",
    true,
    function(context)
        init(context:mct())
    end,
    true
)
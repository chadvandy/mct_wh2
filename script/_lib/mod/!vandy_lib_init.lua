--- TODO come to an accord about how I need to handle all of these internal objects and libraries.


------ Vandy Library!
--- @class vandy_lib
local vandy_lib = {

    helpers_path = "script/vlib/helpers/",
    module_path = "script/vlib/modules/",
    _modules = {},
    _prototypes = {},
    
    logging = {},
    _logging = {
        path = "!vandy_lib_log.txt",
        init = false,
        line_break = "********************",
        timeout = 250,
        max_held = 1000,
        is_checking = false,
        print_immediately = false,
    },

    _callbacks = {},
}

--- Get all of the logging functions in one go. Optionally pass in a prefix so the log file will tell you where it's coming from
---@param prefix string The prefix to put before all logs in the log file - ie., "[vlib]" or "[mct]".
---@return fun(text:string) log Regular log function - takes in a single string.
---@return fun(text:string, arg: ...) logf Log with built in formatting support, ie. logf("My name is %s", "Sarah"). See documentation for string.format in http://www.lua.org/manual/5.1/manual.html#5.4
---@return fun(text:string) err Regular error function - takes in a single string. Will automatically print out an error stack trace, to show the last few functions involved before err() is called.
---@return fun(text:string, arg: ...) errf Error function with built-in formatting support, same as logf. Will automatically print out an error stack trace, to show the last few functions involved before err() is called.
function vandy_lib:get_log_functions(prefix)
    if not is_string(prefix) then prefix = "[lib]" end

    return --- Return log,logf,err,errf
        function(text) self:log(text, prefix) end,
        function(text, ...) self:logf(text, prefix, ...) end,
        function(text) self:error(text) end,
        function(text, ...) self:errorf(text, ...) end
end

local log,logf,errlog,errlogf = vandy_lib:get_log_functions("[lib]")

function vandy_lib:set_debug(is_debug)
    if is_debug then
        self._logging.print_immediately = true
    else
        self._logging.print_immediately = false
    end
end

function vandy_lib:init_log()
    local stamp = os.date("%d, %m %Y %X")
    local path = self._logging.path
    local linebreak = self._logging.line_break

    local t = "%s\nNEW LOG INITIALIZED\n[%s]\n%s"

    t = string.format(t, linebreak, stamp, linebreak)

    local file = io.open(path, "w+")
    if file then
        file:write(t)
        file:close()
        self._logging.init = true
    end
end

function vandy_lib:error(text)
    text = tostring(text)
    if not self._logging.init then
        self:init_log()
    end
    
    local t = "SCRIPT ERROR\n%s\n%s\n"
    
    text = string.format(t, text, debug.traceback("", 2))
    self:log(text, "[! ERR !]")
end

function vandy_lib:log(text, tag)
    text = tostring(text)
    if not is_string(text) then
        return
    end

    tag = tag or "[lib]"

    if not self._logging.init then
        self:init_log()
    end

    self.logging[#self.logging+1] = string.format("%s %s %s", tag, get_timestamp(), text)

    if self._logging.print_immediately then
        self:print_log()
    else
        self:check_logging()
    end
end

function vandy_lib:print_log()
    local log_file_path = self._logging.path
    local logging = self.logging

    local str = "\n"..table.concat(logging, "\n")

    local log_file = io.open(log_file_path, "a+")
    log_file:write(str)
    log_file:close()

    self.logging = {}
    self._logging.is_checking = false

    self:remove_callback("lib_check_logging")
end

function vandy_lib:check_logging()
    if self._logging.is_checking then
        if #self.logging >= self._logging.max_held then
            self:print_log()
        else
            -- do nothing?
        end
    else
        self._logging.is_checking = true

        self:callback(
            function()
                self:print_log()
            end,
            self._logging.timeout,
            "vlib_check_logging"
        )
    end
end

function vandy_lib:logf(text, tag, ...)
    if arg.n >= 1 then
        local ok, err = pcall(function()
            text = string.format(text, unpack(arg))
        end) if not ok then self:error(err) end
    end

    self:log(text, tag)
end

function vandy_lib:errorf(text, ...)
    text = string.format(text, unpack(arg))

    self:error(text)
end

function vandy_lib:repeat_callback(callback, delay, str)
    if not is_function(callback) then
        self:error("Calling repeat_callback(), but the function provided isn't actually a function!")
        return
    end
        
    if not is_number(delay) then
        self:error("Trying to call repeat_callback(), but the delay provided isn't a number!")
        return
    end

    if not is_string(str) then
        self:error("Trying to call repeat_callback(), but the ID provided isn't a string!")
        return
    end

    self._callbacks[str] = {
        key = str,
        callback = callback,
    }

    real_timer.register_repeating(str, delay)
end

function vandy_lib:callback(callback, delay, str)
    if not is_function(callback) then
        self:error("Trying to do a callback, but the function provided isn't actually a function!")
        return
    end
        
    if not is_number(delay) then
        self:error("Trying to call callback(), but the delay provided isn't a number!")
        return
    end

    if not is_string(str) then str = "VlibCallback" end

    self._callbacks[str] = {
        key = str,
        callback = callback,
    }

    real_timer.register_singleshot(str, delay)
end

function vandy_lib:remove_callback(str)
    if not is_string(str) then return end
    if not self._callbacks[str] then return end

    self._callbacks[str] = nil
    real_timer.unregister(str)
end

-- handles callbacks!
function vandy_lib:callback_handler()
    core:add_listener(
        "VLIB_CallbackHandler",
        "RealTimeTrigger",
        function(context)
            return self._callbacks[context.string]
        end,
        function(context)
            local callback = self._callbacks[context.string].callback
            local ok, er = pcall(function()
                callback()
            end) if not ok then self:error(er) end
        end,
        true
    )
end

--- Load every file, and return the Lua module, from within the folder specified, using the pattern specified.
---@param path string The path you're checking. Local to data, so if you're checking for any file within the script folder, use "script/" as the path.
---@param search_override string The file you're checking for. I believe it requires a wildcard somewhere, "*", but I haven't messed with it enough. Use "*" for any file, or "*.lua" for any lua file, or "*/main.lua" for any file within a subsequent folder with the name main.lua.
function vandy_lib:load_modules(path, search_override)
    if not search_override then search_override = "*.lua" end
    logf("Checking %s for all main.lua files!", path)

    local file_str = effect.filesystem_lookup(path, search_override)
    logf("Checking all module folders for main.lua, found: %s", file_str)
    for filename in string.gmatch(file_str, '([^,]+)') do
        local filename_for_out = filename

        local pointer = 1
        while true do
            local next_sep = string.find(filename, "\\", pointer) or string.find(filename, "/", pointer)

            if next_sep then
                pointer = next_sep + 1
            else
                if pointer > 1 then
                    filename = string.sub(filename, pointer)
                end
                break
            end
        end

        local suffix = string.sub(filename, string.len(filename) - 3)

        if string.lower(suffix) == ".lua" then
            filename = string.sub(filename, 1, string.len(filename) -4)
        end


        self:load_module(filename, string.gsub(filename_for_out, filename..".lua", ""))
    end
end

function vandy_lib:add_module(name, manager)
    if not is_string(name) then
        -- error_msg
        return false
    end

    if not is_table(manager) then
        -- err
        return false
    end

    self._modules[name] = manager
end

function vandy_lib:get_module(name)
    if not is_string(name) then
        -- error_msg
        return false
    end

    return self._modules[name]
end

function vandy_lib:load_module(module_name, path)
    local full_path = path .. module_name .. ".lua"
    logf("Loading module w/ full path %q", full_path)
    local file, load_error = loadfile(full_path)

    if not file then
        errlog("Attempted to load module with name ["..module_name.."], but loadfile had an error: ".. load_error .."")
        --return
    else
        log("Loading module with name [" .. module_name .. ".lua]")

        local global_env = core:get_env()
        setfenv(file, global_env)
        local lua_module = file(module_name)

        if lua_module ~= false then
            log("[" .. module_name .. ".lua] loaded successfully!")
        end

        return lua_module
    end

    local ok, msg = pcall(function() require(module_name) end)

    if not ok then
        errlog("Tried to load module with name [" .. module_name .. ".lua], failed on runtime. Error below:")
        errlog(msg)
        return false
    end
end

--- TODO move this to a ui helper!
function vandy_lib:trigger_popup(key, text, two_buttons, button_one_callback, button_two_callback)
    -- verify shit is alright
    if not is_string(key) then
        errlog("trigger_popup() called, but the key passed is not a string!")
        return false
    end

    if is_function(text) then
        text = text()
    end

    if not is_string(text) then
        errlog("trigger_popup() called, but the text passed is not a string!")
        return false
    end

    if is_function(two_buttons) then
        two_buttons = two_buttons()
    end

    if not is_boolean(two_buttons) then
        errlog("trigger_popup() called, but the two_buttons arg passed is not a boolean!")
        return false
    end

    if not two_buttons then button_two_callback = function() end end

    local popup = core:get_or_create_component(key, "ui/vandy_lib/dialogue_box")

    local function do_stuff()

        local both_group = UIComponent(popup:CreateComponent("both_group", "ui/campaign ui/script_dummy"))
        local ok_group = UIComponent(popup:CreateComponent("ok_group", "ui/campaign ui/script_dummy"))
        local DY_text = UIComponent(popup:CreateComponent("DY_text", "ui/vandy_lib/text/la_gioconda/center"))

        both_group:SetDockingPoint(8)
        both_group:SetDockOffset(0, 0)

        ok_group:SetDockingPoint(8)
        ok_group:SetDockOffset(0, 0)

        DY_text:SetDockingPoint(5)
        -- errlog("WHAT THE FUCK IS CALLING THIS")
        local ow, oh = popup:Width() * 0.9, popup:Height() * 0.8
        DY_text:Resize(ow, oh)
        DY_text:SetDockOffset(1, -35)
        DY_text:SetVisible(true)

        local cancel_img = effect.get_skinned_image_path("icon_cross.png")
        local tick_img = effect.get_skinned_image_path("icon_check.png")

        do
            local button_tick = UIComponent(both_group:CreateComponent("button_tick", "ui/templates/round_medium_button"))
            local button_cancel = UIComponent(both_group:CreateComponent("button_cancel", "ui/templates/round_medium_button"))

            button_tick:SetImagePath(tick_img)
            button_tick:SetDockingPoint(8)
            button_tick:SetDockOffset(-30, -10)
            button_tick:SetCanResizeWidth(false)
            button_tick:SetCanResizeHeight(false)

            button_cancel:SetImagePath(cancel_img)
            button_cancel:SetDockingPoint(8)
            button_cancel:SetDockOffset(30, -10)
            button_cancel:SetCanResizeWidth(false)
            button_cancel:SetCanResizeHeight(false)
        end

        do
            local button_tick = UIComponent(ok_group:CreateComponent("button_tick", "ui/templates/round_medium_button"))

            button_tick:SetImagePath(tick_img)
            button_tick:SetDockingPoint(8)
            button_tick:SetDockOffset(0, -10)
            button_tick:SetCanResizeWidth(false)
            button_tick:SetCanResizeHeight(false)
        end

        popup:PropagatePriority(1000)

        popup:LockPriority()

        -- grey out the rest of the world
        --popup:RegisterTopMost()

        if two_buttons then
            both_group:SetVisible(true)
            ok_group:SetVisible(false)
        else
            both_group:SetVisible(false)
            ok_group:SetVisible(true)
        end

        -- grab and set the text
        local tx = find_uicomponent(popup, "DY_text")

        local w,h = tx:TextDimensionsForText(text)
        tx:ResizeTextResizingComponentToInitialSize(w,h)

        tx:SetStateText(text)

        tx:Resize(ow,oh)
        --w,h = tx:TextDimensionsForText(text)
        tx:ResizeTextResizingComponentToInitialSize(ow,oh)

        core:add_listener(
            key.."_button_pressed",
            "ComponentLClickUp",
            function(context)
                local button = UIComponent(context.component)
                return (button:Id() == "button_tick" or button:Id() == "button_cancel") and UIComponent(UIComponent(button:Parent()):Parent()):Id() == key
            end,
            function(context)
                -- close the popup
				local ok, er = pcall(function() delete_component(popup) end) if not ok then self:error(er) end
                delete_component(find_uicomponent(key))

                if id == "button_tick" then
                    button_one_callback()
                else
                    button_two_callback()
                end
            end,
            false
        )
    end

    self:callback(do_stuff, 5, "do_stuff")
end

---@return vandy_lib
function get_vandy_lib()
    return core:get_static_object("vandy_lib")
end

function vandy_lib:setup_listeners()
    core:declare_lookup_listener(
        "panel_opened",
        "PanelOpenedCampaign",
        function(context) 
            return context.string 
        end
    )

    core:declare_lookup_listener(
        "panel_closed",
        "PanelClosedCampaign",
        function(context)
            return context.string
        end
    )

    core:declare_lookup_listener(
        "ui_clicked",
        "ComponentLClickUp",
        function(context)
            return context.string
        end
    )

    core:declare_lookup_listener(
        "ui_hovered",
        "ComponentMouseOn",
        function(context)
            return context.string
        end
    )
end

get_vlib = get_vandy_lib

function vandy_lib:init()
    core:add_static_object("vandy_lib", self)

    -- Load all helpers.
    self:load_modules(self.helpers_path)

    --- Load the Class constructor
    local f = self:load_module("class", "script/vlib/")

    --- Create a new class.
    ---@param name string The name of this new class.
    ---@param defaults table Default table to build this new class from.
    ---@return Class
    function vandy_lib:new_class(name, defaults)
        return f(name, defaults)
    end
    
    self:callback_handler()
    self:setup_listeners()

    -- Do debug stuffs.
    if vfs.exists("script/vlib/is_debug.txt") then
        self:set_debug(true)
    end

    logf("Loading all Vandy Lib modules!")
    
    local ok, msg = pcall(function()
        self:load_modules(self.module_path, "*/main.lua")
    end) if not ok then errlog(msg) return end

    self:logf(self._logging.line_break)
    self:logf("FINISHED LOADING Vandy Lib Modules!")
    self:logf(self._logging.line_break)

    self.VANDY_LIB_FOUND = vfs.exists("script/vlib/vandy_lib.txt")

    if __game_mode == __lib_type_frontend then
        core:add_ui_created_callback(function()
            if not self.VANDY_LIB_FOUND then
                self:trigger_popup(
                    "no_vlib_found",
                    "[[col:red]]One or more of your used mods now require the 'Vandy Library' mod from the workshop![[/col]]\nYou can find it on the workshop at [TODO link here] :)\n\nEnjoy!",
                    false,
                    function() end
                )
            end
        end)
    end
end

vandy_lib:init()
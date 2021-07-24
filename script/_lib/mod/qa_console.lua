-- --- Override the CA qa_console.lua file because it doesn't have the UIC Layout file to do anything.


-- out("qa_console.lua loaded");

-- local uic_console_name = "qa_console";
-- local layout_path = "UI/dev_ui/qa_console";
-- local shortcut_key = "script_ctrl_F3";

-- local uic_console = false;
-- local uic_console_persistent_checkbox = false;


-- local function qa_console_shortcut_pressed()
-- 	if uic_console then
-- 		if uic_console:Visible() then 	
-- 			uic_console:SetVisible(false);
-- 		else
-- 			uic_console:SetVisible(true);
-- 		end;
--     end
-- end


-- local function qa_console_execute_command()
--     local text = find_uicomponent(uic_console, "entry_box"):GetStateText();
--     local func, err = loadstring(text);
    
--     if not func then 
-- 		script_error("ERROR: qa console attempted to run a script command but an error was reported when loading the command string into a function. Command and error will follow this message.");
-- 		out("Command:");
-- 		out(text);
-- 		out("Error:");
-- 		out(err);
-- 		return;
-- 	end
	
--     setfenv(func, core:get_env());
    
--     local ok, result = pcall(func);

-- 	if not ok then 
-- 		script_error("ERROR: qa console attempted to run a script command but an error was reported when executing the function. Command and error will follow this message.");
-- 		out("Command:");
-- 		out(text);
-- 		out("Error:");
-- 		out(result);
-- 		return;
-- 	end;

-- 	if not string.find(uic_console_persistent_checkbox:CurrentState(), "selected") then
-- 		uic_console:SetVisible(false);
-- 	end;
-- end


-- core:add_ui_created_callback(
-- 	function()
-- 		-- create the console uicomponent
-- 		uic_console = core:get_or_create_component(uic_console_name, layout_path);
-- 		uic_console:SetVisible(false);

-- 		uic_console_persistent_checkbox = find_uicomponent(uic_console, "persist_checkbox");

-- 		core:add_listener(
-- 			"qa_console_listener",
-- 			"ShortcutPressed",
-- 			function(context)
-- 				out("ShortcutPressed event occurred, context.string is " .. context.string);
-- 				return context.string == shortcut_key
-- 			end,
-- 			function(context)
-- 				qa_console_shortcut_pressed()
-- 			end,
-- 			true
-- 		);

-- 		core:add_listener(
-- 			"qa_console_lclickup",
-- 			"ComponentLClickUp", 
-- 			function(context)
-- 				local uic = UIComponent(context.component);
-- 				return uic:Id() == "button_run" and uicomponent_descended_from(uic, uic_console_name);
-- 			end,
-- 			function()
-- 				qa_console_execute_command();
-- 			end,
-- 			true
-- 		);

-- 		core:add_listener(
-- 			"qa_console_lclickup_close",
-- 			"ComponentLClickUp", 
-- 			function(context)
-- 				local uic = UIComponent(context.component);
-- 				return uic:Id() == "button_close" and uicomponent_descended_from(uic, uic_console_name);
-- 			end,
-- 			function()
-- 				uic_console:SetVisible(false);
-- 			end,
-- 			true
-- 		);

-- 		core:add_listener(
-- 			"qa_console_lclickup_clear",
-- 			"ComponentLClickUp", 
-- 			function(context)
-- 				local uic = UIComponent(context.component);
-- 				return uic:Id() == "button_clear" and uicomponent_descended_from(uic, uic_console_name);
-- 			end,
-- 			function()
-- 				find_uicomponent(uic_console, "entry_box"):SetStateText("");
-- 			end,
-- 			true
-- 		);
-- 	end
-- );
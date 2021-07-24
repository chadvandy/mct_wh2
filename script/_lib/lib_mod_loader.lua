--- Edited by Vandy!
--- I'm coming in here to overwrite some stuff for this system. Specifically, the following two changes:
---- Incorporate vararg support for ModLog, and make ModLog not fail when something other than a string is passed.
---- Incorporate a new path - script/mod/ - which is loaded *after* _lib and all other game mode specific ones, but in every game mode. I don't like having to use _lib/mod for stuff that isn't necessarily a library, so I wanted this change!


-----------------------------------------------------------------------------------------------------------
-- MODULAR SCRIPTING FOR MODDERS
-----------------------------------------------------------------------------------------------------------
-- The following allows modders to load their own script files without editing any existing game scripts
-- This allows multiple scripted mods to work together without one preventing the execution of another
--
-- Issue: Two modders cannot use the same existing scripting file to execute their own scripts as one
-- version of the script would always overwrite the other preventing one mod from working
--
--
-- The following scripting loads all scripts within a "mod" folder of each campaign and then executes
-- a function of the same name as the file (if one such function is declared)
-- Onus is on the modder to ensure the function/file name is unique which is fine
--
-- Example: The file "data/script/campaign/wh2_main_great_vortex/mod/cool_mod.lua" would be loaded and
-- then any function by the name of "cool_mod" will be run if it exists (sort of like a constructor)
--
-- ~ Mitch 18/10/17
-----------------------------------------------------------------------------------------------------------


--- @loaded_in_battle
--- @loaded_in_campaign
--- @loaded_in_frontend


----------------------------------------------------------------------------
---	@section Mod Output
----------------------------------------------------------------------------
local logging = {
    made = false,
    path = "lua_mod_log.txt",
}

--- @function ModLog
--- @desc Writes output to the <code>lua_mod_log.txt</code> text file, and also to the game console.
--- @p @string output text
function ModLog(...)
    local text = ""
    for _,v in ipairs(arg) do
        text = text .. tostring(v) .. "\t"
    end

	out(text);
	if not logging.made then
		logging.made = true;
		local logInterface = io.open(logging.path, "w");
		logInterface:write(text.."\n");
		logInterface:flush();
		logInterface:close();
	else
		local logInterface = io.open(logging.path, "a");
		logInterface:write(text.."\n");
		logInterface:flush();
		logInterface:close();
	end;
end;


-- load mods here
if core:is_campaign() then
	-- LOADING CAMPAIGN MODS

	-- load mods on NewSession
	core:add_listener(
		"new_session_mod_scripting_loader",
		"NewSession",
		true,
		function(context)

			local all_mods_loaded_successfully = core:load_mods(
				"/script/_lib/mod/",								-- general script library mods
				"/script/campaign/mod/",							-- root campaign folder
				"/script/campaign/" .. CampaignName .. "/mod/",		-- campaign-specific folder
                "/script/mod/"                                      -- anywhere mod scripts
			);

			core:trigger_event("ScriptEventAllModsLoaded", all_mods_loaded_successfully);
		end,
		true
	);

	-- execute mods on first tick
	core:add_listener(
		"first_tick_after_world_created_mod_scripting_loader",
		"FirstTickAfterWorldCreated",
		true,
		function(context)
			core:execute_mods(context);
		end,
		false
	);


elseif core:is_battle() then
	-- LOADING BATTLE MODS
	
	local all_mods_loaded_successfully = core:load_mods(
		"/script/_lib/mod/",				-- general script library mods
		"/script/battle/mod/",				-- root battle folder
        "/script/mod/"                      -- anywhere mod scripts
	);

	core:trigger_event("ScriptEventAllModsLoaded", all_mods_loaded_successfully);

else
	-- LOADING FRONTEND MODS

	local all_mods_loaded_successfully = core:load_mods(
		"/script/_lib/mod/",				-- general script library mods
		"/script/frontend/mod/",			-- frontend-specific mods
        "/script/mod/"                      -- anywhere mod scripts
	);

	core:trigger_event("ScriptEventAllModsLoaded", all_mods_loaded_successfully);
end;
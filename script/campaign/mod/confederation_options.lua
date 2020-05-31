local confed_option_settings = {
    --["setting key"] = value
    ["wh_main_emp_empire"] = "no_tweak",
    ["wh_main_dwf_dwarfs"] = "no_tweak",
    ["wh_main_grn_greenskins"] = "no_tweak",
    ["wh_main_vmp_vampire_counts"] = "no_tweak",
    ["wh2_main_hef_high_elves"] = "no_tweak",
    ['wh2_main_def_dark_elves'] = "no_tweak",
    ["wh2_main_skv_skaven"] = "no_tweak",
    ['wh2_main_lzd_lizardmen'] = "no_tweak",
    ['wh_main_brt_bretonnia'] = "no_tweak",
    ['wh_dlc05_wef_wood_elves'] = "no_tweak",
    ['wh_main_sc_nor_norsca'] = "no_tweak",
    ['wh2_dlc09_tmb_tomb_kings'] = "no_tweak",
    ['wh2_dlc11_cst_vampire_coast'] = "no_tweak"
}

local valid_confed_settings = {
    --["setting key"] = value
    ["wh_main_emp_empire"] = true,
    ["wh_main_dwf_dwarfs"] = true,
    ["wh_main_grn_greenskins"] = true,
    ["wh_main_vmp_vampire_counts"] = true,
    ["wh2_main_hef_high_elves"] = true,
    ['wh2_main_def_dark_elves'] = true,
    ["wh2_main_skv_skaven"] = true,
    ['wh2_main_lzd_lizardmen'] = true,
    ['wh_main_brt_bretonnia'] = true,
    ['wh_dlc05_wef_wood_elves'] = true,
    ['wh_main_sc_nor_norsca'] = true,
    ['wh2_dlc09_tmb_tomb_kings'] = true,
    ['wh2_dlc11_cst_vampire_coast'] = true
}

core:add_listener(
    "ConfedOptionsMctCreated",
    "MctInitialized",
    true,
    function(context)
        local mct = core:get_static_object("mod_configuration_tool")
        --mct:log("CONFED OPTIONS LISTENER")
        local confed_options_mod = mct:get_mod_with_name("confederation_options")

        local settings_table = confed_options_mod:get_settings()

        -- overrides the settings table above, only if MCT exists
        confed_option_settings = settings_table
    end,
    false
)

local function do_other_function(culture, option)
    local mct = get_mct()
    mct:log("Do other function 1")

    if culture == "wh_dlc05_wef_wood_elves" then
        if option == "free_confed" then
            core:remove_listener("WoodElves_BuildingCompleted")
            cm:force_diplomacy("culture:wh_dlc05_wef_wood_elves", "culture:wh_dlc05_wef_wood_elves", "form confederation", true, false, false);
        elseif option == "player_only" then
            mct:log("PLAYER 1")
            core:remove_listener("WoodElves_BuildingCompleted")
            mct:log("PLAYER 2")
            local human_factions = cm:get_human_factions()
            for i = 1, #human_factions do
                local faction = cm:get_faction(human_factions[i])
                mct:log("PLAYER 3")
                if faction:culture() == "wh_dlc05_wef_wood_elves" then
                    mct:log("PLAYER 4")
                    cm:force_diplomacy("faction:"..faction:name(), "culture:wh_dlc05_wef_wood_elves", "form confederation", true, false, false);
                end
            end
        elseif option == "disabled" then
            core:remove_listener("WoodElves_BuildingCompleted")
        elseif option == "no_tweak" then
            -- do literally nothing!
        end
    elseif culture == "wh_main_brt_bretonnia" then
        if option == "free_confed" then
            core:remove_listener("BRT_Tech_FactionTurnStart")
            cm:force_diplomacy("culture:wh_main_brt_bretonnia", "culture:wh_main_brt_bretonnia", "form confederation", true, false, false)
        elseif option == "player_only" then
            mct:log("PLAYER 1")

            core:remove_listener("BRT_Tech_FactionTurnStart")
            local human_factions = cm:get_human_factions()
            mct:log("PLAYER 2")
            for i = 1, #human_factions do
                local faction = cm:get_faction(human_factions[i])
                mct:log("PLAYER 3")
                if faction:culture() == "wh_main_brt_bretonnia" then
                    mct:log("PLAYER 4")
                    cm:force_diplomacy("faction:"..faction:name(), "culture:wh_main_brt_bretonnia", "form confederation", true, false, false)
                end
            end
        elseif option == "disabled" then
            core:remove_listener("BRT_Tech_FactionTurnStart")
            cm:force_diplomacy("culture:wh_main_brt_bretonnia", "culture:wh_main_brt_bretonnia", "form confederation", false, false, true)
        elseif option == "no_tweak" then
            -- do literally nothing
        end
    elseif culture == "wh_main_sc_nor_norsca" then
        if option == "free_confed" then
            core:remove_listener("character_completed_battle_norsca_confederation_dilemma")
            core:remove_listener("VandyNorscaOverwriteListenerPartTwoForPlayerOnly")
            cm:force_diplomacy("subculture:wh_main_sc_nor_norsca", "subculture:wh_main_sc_nor_norsca", "form confederation", true, false, false)
        elseif option == "player_only" then
            mct:log("PLAYER 1")
            core:remove_listener("character_completed_battle_norsca_confederation_dilemma")
            mct:log("PLAYER 2")
        elseif option == "disabled" then
            core:remove_listener("character_completed_battle_norsca_confederation_dilemma")
            core:remove_listener("VandyNorscaOverwriteListenerPartTwoForPlayerOnly")
            cm:force_diplomacy("subculture:wh_main_sc_nor_norsca", "subculture:wh_main_sc_nor_norsca", "form confederation", false, false, true)
        elseif option == "force_diplomacy" then
            core:remove_listener("VandyNorscaOverwriteListenerPartTwoForPlayerOnly")
            -- do literally nothing!
        end
    end
end

local function set_confed_option(culture, option)
    local mct = get_mct()
    if option == "free_confed" then
        mct:log("FREE 1")
        -- enable confederation for this culture
        cm:force_diplomacy("culture:"..culture, "culture:"..culture, "form confederation", true, true, true)

        mct:log("FREE 2")

    elseif option == "player_only" then
        mct:log("PLAYER 1")
        -- disable confederation for AI
        cm:force_diplomacy("culture:"..culture, "culture:"..culture, "form confederation", false, false, true)
        mct:log("PLAYER 2")
        local human_factions = cm:get_human_factions()
        for i = 1, #human_factions do
            local faction_key = human_factions[i]
            local faction_obj = cm:get_faction(faction_key)
            if faction_obj:is_human() and faction_obj:culture() == culture then
                mct:log("PLAYER 3")
                mct:log(faction_obj:name())
                mct:log(faction_obj:culture())
                -- enable for human only
                cm:force_diplomacy("faction:"..faction_obj:name(), "culture:"..culture, "form confederation", true, false, false)
            end
        end

        mct:log("PLAYER 4")
    
    elseif option == "disabled" then
        mct:log("DISABLED 1")
        -- disable confederation for this culture
        cm:force_diplomacy("culture:"..culture, "culture:"..culture, "form confederation", false, false, true)
        mct:log("DISABLED 2")
    elseif option == "no_tweak" then
        --do nothing!
        mct:log("NO TWEAK 1")
    end
end

local function main()
    local mct = get_mct()
    get_mct():log("CONFED OPTIONS MAIN")
    local do_other = {
        ["wh_dlc05_wef_wood_elves"] = true,
        ["wh_main_brt_bretonnia"] = true,
        ["wh_main_sc_nor_norsca"] = true
    }

    for culture, option in pairs(confed_option_settings) do
        if valid_confed_settings[culture] then
            mct:log(tostring(culture))
            mct:log(tostring(option))
            if not do_other[culture] then
                mct:log("set confed option ["..option.."] for culture ["..culture.."].")
                set_confed_option(culture, option)
            else
                mct:log("set confed option ["..option.."] for culture ["..culture.."].")
                local ok, err = pcall(function()
                do_other_function(culture, option)
                end) if not ok then mct:log(err) end
            end
        end
    end
end

cm:add_first_tick_callback(function() main() end)

local NORSCA_SUBCULTURE = "wh_main_sc_nor_norsca"
local NORSCA_CONFEDERATION_DILEMMA = "wh2_dlc08_confederate_";
local norsca_info_text_confederation = {"war.camp.prelude.nor.confederation.info_001", "war.camp.prelude.nor.confederation.info_002", "war.camp.prelude.nor.confederation.info_003"};


-- the Norsca confed listener for player only
core:add_listener(
    "VandyNorscaOverwriteListenerPartTwoForPlayerOnly",
    "CharacterCompletedBattle",
    function(context)
        local character = context:character()
        return character:won_battle() == true and character:faction():subculture() == NORSCA_SUBCULTURE
    end,
    function(context)
        local character = context:character()
        local enemies = cm:pending_battle_cache_get_enemies_of_char(character);
		local enemy_count = #enemies;
		
		if context:pending_battle():night_battle() == true or context:pending_battle():ambush_battle() == true then
			enemy_count = 1;
		end
		
		for i = 1, enemy_count do
			local enemy = enemies[i];
			
			if enemy ~= nil and enemy:is_null_interface() == false and enemy:is_faction_leader() == true and enemy:faction():subculture() == NORSCA_SUBCULTURE then
				if enemy:has_military_force() == true and enemy:military_force():is_armed_citizenry() == false then
					if character:faction():is_human() == true and enemy:faction():is_human() == false and enemy:faction():is_dead() == false then
						-- Trigger dilemma to offer confederation
						local NORSCA_CONFEDERATION_PLAYER = character:faction():name();
						cm:trigger_dilemma(NORSCA_CONFEDERATION_PLAYER, NORSCA_CONFEDERATION_DILEMMA..enemy:faction():name(), true);
						Play_Norsca_Advice("dlc08.camp.advice.nor.confederation.001", norsca_info_text_confederation);
					--[[elseif character:faction():is_human() == false and enemy:faction():is_human() == false then
						-- AI confederation
						cm:force_confederation(character:faction():name(), enemy:faction():name());]]
					end
				end
			end
        end
    end,
    true
)
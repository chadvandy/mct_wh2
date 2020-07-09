local mct = get_mct()

real_timer.register_repeating("mct_button_highlight", 100)

core:add_listener(
    "check_for_button",
    "RealTimeTrigger",
    function(context) 
        return context.string == "mct_button_highlight" and
        is_uicomponent(find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar", "button_mct_options"))
    end,
    function(context)
        local uic = find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar", "button_mct_options")

        real_timer.unregister("mct_button_highlight")
        core:remove_listener("check_for_button")

        if not mct._finalized then

            uic:Highlight(true, false)
            uic:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069").."||"..effect.get_localised_string("mct_button_unfinalized"), true)
        end
    end,
    true
)

core:add_listener(
    "check_for_finalization",
    "MctFinalized",
    true,
    function(context)
        local uic = find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar", "button_mct_options")
        if is_uicomponent(uic) then

            -- turn off highlight!
            uic:Highlight(false, false)
            -- return tooltip to default
            uic:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069"), true)
        end
    end,
    false
)

local function init()
    local str_to_faction_key = {}
    local factions_to_index = {}

    local known = ""

    local function bloop()
        local uic = find_uicomponent(core:get_ui_root(), "mp_grand_campaign", "dock_area", "main_panel", "panel_player1", "player")
        if is_uicomponent(uic) then
            mct:log("bloop successed")
            -- stop looping

            local local_local = false

            -- go through the faction-dropdown and assign text to the faction keys, gleaned from mini_flag's path
            local list = find_uicomponent(uic, "popup_menu", "popup_list")
            if list:ChildCount() > 5 then
                mct:log("LOCAL IS HOST!")
                local_local = true
            end
            --[[if not is_uicomponent(list) then
                return
            end]]

            real_timer.unregister("bloopy")
            core:remove_listener("test_bloop")
            --mct:log("List found; bloop removed")
            
            --[[for i = 0, list:ChildCount() -1 do
                mct:log("Child loop ["..tostring(i).."]")
                local child = UIComponent(list:Find(i))

                local tx = UIComponent(child:Find("row_tx"))
                local flag = UIComponent(child:Find("mini_flag"))

                if not is_uicomponent(flag) then
                    -- err
                else
                    mct:log("Testing for flag path")
                    local flag_path = flag:GetImagePath()
                    if is_string(flag_path) then
                        local cut = string.sub(flag_path, 10, -12)
                        mct:log("Image path: "..flag_path)
                        mct:log("Cut path: "..cut)

                        if cut ~= "default" then
                            local str = tx:GetStateText()
                            mct:log("Linking text ["..str.."] to faction key ["..cut.."]")
                            str_to_faction_key[str] = cut
                        end
                    end
                end
            end]]

            --mct:log("List loop ended")

            local function write_to_file(faction_key)
                --[[mct:log("Writing to mp file: "..faction_key)
                local mp_file = io.open("mct_mp.lua", "w+")
                mp_file:write("return {faction_key=\""..faction_key.."\"}")
                mp_file:close()
                known=faction_key]]


                core:svr_save_bool("local_is_host", local_local)
                core:svr_save_string("mct_mp_host", faction_key)
            end

            core:add_listener(
                "check_player_1_key",
                "RealTimeTrigger",
                function(context)
                    return context.string == "check_p1_key"
                end,
                function(context)
                    local flag = find_uicomponent(core:get_ui_root(), "mp_grand_campaign", "dock_area", "main_panel", "panel_player1", "player", "singleplayer", "flag")
                    if not is_uicomponent(flag) then
                        --core:remove_listener("check_player_1_key")
                        return -- just wait a minute, damn chill
                    end

                    --mct:log("Testing flag on player1")

                    local flag_path = flag:GetImagePath()
                    if is_string(flag_path) then
                        --mct:log("test full path: "..flag_path)
                        local cut = string.sub(flag_path, 10, -13)

                        if cut ~= "default" then
                            if cut ~= known then
                                write_to_file(cut)
                            end
                        end
                    end
                end,
                true
            )

            real_timer.register_repeating("check_p1_key", 100)
        end
    end

    core:add_listener(
        "test_bloop",
        "RealTimeTrigger",
        function(context)
            return context.string == "bloopy"
        end,
        function(context)
            mct:log("triggered bloopy")
            bloop()
        end,
        true
    )

    real_timer.register_repeating("bloopy", 100)
end

core:add_listener(
    "screen_change",
    "FrontendScreenTransition",
    function(context)
        return context.string == "mp_grand_campaign"
    end,
    function(context)
        mct:log("FRONTEND TRANSITION: "..context.string)

        init()
    end,
    true
)

core:add_listener(
    "screen_change",
    "FrontendScreenTransition",
    function(context)
        return context.string ~= "mp_grand_campaign"
    end,
    function(context)
        core:remove_listener("test_bloop")     
        real_timer.unregister("bloopy")

        core:remove_listener("check_player_1_key")
        real_timer.unregister("check_p1_key")

        --mct:log("FRONTEND TRANSITION: "..context.string)

        --init()
    end,
    true
)
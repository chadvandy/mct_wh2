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
            --mct:log("bloop successed")
            -- stop looping

            local local_local = false

            local dropdown = find_uicomponent(uic, "faction_dropdown")
            if not is_uicomponent(dropdown) then
                --mct:log("faction dropdown unfounded")
                return
            end

            if not dropdown:Visible() then
                --mct:log("faction dropdown invis")
                return
            end

            if not uic:Visible() then
                --mct:log("player invisi")
                return
            end

            local parent = UIComponent(uic:Parent())
            if not parent:Visible() then
                --mct:log("panel_player1 invisi")
                return 
            end

            local grammie = UIComponent(parent:Parent())
            if not grammie:Visible() then
                --mct:log("main_panel invisib")
                return
            end

            local cus = UIComponent(grammie:Find("panel_player2"))
            if not cus:Visible() then
                --mct:log("panel_player2 invisible")
                return
            end

            local master = find_uicomponent("mp_grand_campaign")

            --[[local function loop_all(uic)
                if not is_uicomponent(uic) then
                    mct:log("Oof not a uic ["..tostring(uic).."].")
                    return
                end
                mct:log(uicomponent_to_str(uic))
                mct:log(uic:Id() .. " visibility: "..tostring(uic:Visible()))
                for i = 0, uic:ChildCount() -1 do
                    local child = UIComponent(uic:Find(i))
                    loop_all(child)
                end
            end

            loop_all(master)]]


            mct:log("Current state of dropdown: "..dropdown:CurrentState())

            if dropdown:CurrentState() == "inactive" then
                mct:log("LOCAL IS CLIENT")
                local_local = false
            else
                mct:log("LOCAL IS HOST")
                local_local = true
            end

            real_timer.unregister("bloopy")
            core:remove_listener("test_bloop")

            --mct:log("SETTING LOCAL TO HOST")
            core:svr_save_bool("local_is_host", local_local)

            -- TODO temp disabled because that means the client can't read any MP settings
            -- disable the MCT button while in the MP part
            --if not local_local then
                --local button = find_uicomponent("sp_frame", "menu_bar", "button_mct_options")
                --button:SetState("inactive")
                --button:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069").."||[[col:red]]Can't use MCT as a client user![[/col]]", true)
            --end

            -- trigger a UI popup once to say "hey, we're loading this person's settings"
            local popped = false
            local function popup()
                if popped then
                    -- do nothing
                    return
                end

                popped = true

                local popup_uic = core:get_or_create_component("mct_mp_host", "ui/common ui/dialogue_box")
                popup_uic:LockPriority()

                local str = ""

                local player_name = find_uicomponent(uic, "dy_player_name"):GetStateText()
                local is_host = local_local
                if is_host then
                    str = "[[col:red]]MCT: Loading Your Settings[[/col]]\n\nLoading your settings from MCT. Make sure the other player is cool with the settings you've chosen, if you care!"
                else
                    str = "[[col:red]]MCT: Loading "..player_name.."'s Settings[[/col]]\n\nLoading the Host's settings from MCT. Make sure you're cool with the settings they've picked.\n\nDo note - you can't see the host's settings until you load into the campaign, so you'll have to discuss it elsewhere."
                end

                local tx = find_uicomponent(popup_uic, "DY_text")
                tx:SetStateText(str)

                find_uicomponent(popup_uic, "both_group"):SetVisible(false)
                find_uicomponent(popup_uic, "ok_group"):SetVisible(true)


                core:add_listener(
                    "box_close",
                    "ComponentLClickUp",
                    function(context)
                        local button = UIComponent(context.component)
                        return (button:Id() == "button_tick" and UIComponent(UIComponent(button:Parent()):Parent()):Id() == "mct_mp_host")
                    end,
                    function(context)
                        mct.ui:delete_component(popup_uic)
                    end,
                    false
                )

            end

            popup()


            --[[core:add_listener(
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

                    popup()
                end,
                true
            )

            real_timer.register_repeating("check_p1_key", 100)]]
        end
    end

    core:add_listener(
        "test_bloop",
        "RealTimeTrigger",
        function(context)
            return context.string == "bloopy"
        end,
        function(context)
            --mct:log("triggered bloopy")
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

        -- reenable the button
        local button = find_uicomponent("sp_frame", "menu_bar", "button_mct_options")
        button:SetState("active")
        button:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069"), true)

        --mct:log("FRONTEND TRANSITION: "..context.string)

        --init()
    end,
    true
)
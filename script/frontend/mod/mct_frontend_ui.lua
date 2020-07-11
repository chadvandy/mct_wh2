local mct = get_mct()

local function check_highlight()
    local uic = find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar", "button_mct_options")

    if not mct._finalized then

        uic:Highlight(true, false)
        uic:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069").."||"..effect.get_localised_string("mct_button_unfinalized"), true)
    end
end

core:add_listener(
    "button_check!",
    "RealTimeTrigger",
    function(context)
        return context.string == "check_for_da_button" and is_uicomponent(find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar"))
    end,
    function(context)
        mct:log("button_check!")
        real_timer.unregister("check_for_da_button")
        core:remove_listener("button_check!")

        local parent = find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar")
        local button = UIComponent(parent:Find("button_mct_options"))

        --[[local button = UIComponent(parent:CreateComponent("button_mct_options", "ui/templates/round_small_button"))

        -- set the tooltip
        button:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069"), true)
        local img_path = effect.get_skinned_image_path("icon_options.png")
        button:SetImagePath(img_path)

        -- make sure it's on the button group, and set its z-priority to be as high as its parents
        button:PropagatePriority(parent:Priority())
        parent:Adopt(button:Address())

        for i = 0, parent:ChildCount() -1 do
            local child = UIComponent(parent:Find(i))
            if child:Id() == "button_mct_options" then
                local backwards = UIComponent(parent:Find(i-1))
                if not is_uicomponent(backwards) then
                    mct:log("???? da fuq")
                    return
                end

                local x,y = backwards:Position()
                local w,h = backwards:Dimensions()

                child:MoveTo(x+(w*1.1), y)
            end
        end]]

        mct:load_and_start()

        check_highlight()
    end,
    false
)

real_timer.register_repeating("check_for_da_button", 100)

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

local is_host = false

local function init()
    local str_to_faction_key = {}
    local factions_to_index = {}

    local known = ""

    local function bloop()
        local uic = find_uicomponent(core:get_ui_root(), "mp_grand_campaign", "dock_area", "main_panel", "panel_player1", "player")
        if is_uicomponent(uic) then
            --mct:log("bloop successed")
            -- stop looping

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

            local kick = find_uicomponent(cus, "button_kick")
            if kick:Visible() then
                core:svr_save_bool("local_is_host", true)
            else
                core:svr_save_bool("local_is_host", false)
            end

            local master = find_uicomponent("mp_grand_campaign")


            mct:log("Current state of dropdown: "..dropdown:CurrentState())

            local x_dropdown = find_uicomponent(grammie, "panel_player2", "player", "faction_dropdown")

            if dropdown:CurrentState() == "inactive" then
                --mct:log("LOCAL IS CLIENT")
                --local_local = false
            else
                --mct:log("LOCAL IS HOST")
                --local_local = true
            end

            real_timer.unregister("bloopy")
            core:remove_listener("test_bloop")

            --mct:log("SETTING LOCAL TO HOST")
            --core:svr_save_bool("local_is_host", local_local)

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

                local is_is_host_host = core:svr_load_bool("local_is_host")

                if is_is_host_host then
                    str = "[[col:red]]MCT: Loading Your Settings[[/col]]\n\nLoading your settings from MCT. Make sure the other player is cool with the settings you've chosen, if you care!\n\n[[col:fabulous_pink]]IF THIS IS WRONG - IF THE OTHER PLAYER IS ON THE LEFT SIDE OF THE SCREEN - PLEASE LOAD TO THE MAIN MENU AND LOAD BACK IN.[[/col]]"
                else
                    str = "[[col:red]]MCT: Loading "..player_name.."'s Settings[[/col]]\n\nLoading the Host's settings from MCT. Make sure you're cool with the settings they've picked. Do note - you can't see the host's settings until you load into the campaign, so you'll have to discuss it elsewhere.\n\n[[col:fabulous_pink]]IF THIS IS WRONG - IF YOU ARE ON THE LEFT SIDE OF THE SCREEN - PLEASE LOAD TO THE MAIN MENU AND LOAD BACK IN. ALSO REPORT THIS TO VANDY.[[/col]]"
                end

                local tx = find_uicomponent(popup_uic, "DY_text")
                tx:SetStateText(str)

                find_uicomponent(popup_uic, "both_group"):SetVisible(false)
                find_uicomponent(popup_uic, "ok_group"):SetVisible(true)

                core:remove_listener("box_close")

                core:add_listener(
                    "box_close",
                    "ComponentLClickUp",
                    function(context)
                        local button = UIComponent(context.component)
                        return (button:Id() == "button_tick" and UIComponent(UIComponent(button:Parent()):Parent()):Id() == "mct_mp_host")
                    end,
                    function(context)
                        mct:log("box_close")
                        local pressed = UIComponent(context.component)
                        if is_uicomponent(pressed) then
                            local parent = UIComponent(pressed:Parent())
                            if is_uicomponent(parent) then
                                local popup = UIComponent(parent:Parent())
                                if is_uicomponent(popup) then
                                    mct.ui:delete_component(popup)
                                end
                            end
                        end
                    end,
                    false
                )

            end

            popup()
        end
    end

    core:remove_listener("test_bloop")
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

    real_timer.unregister("bloopy")
    real_timer.register_repeating("bloopy", 100)
end

local function bloop()
    --[[mct:log("IS HOST: "..tostring(is_host))
    if is_host then
        core:svr_save_bool("local_is_host", is_host)
    end]]

    init()
end

local function start()
    core:remove_listener("grand_campaign_yay")
    core:add_listener(
        "grand_campaign_yay",
        "FrontendScreenTransition",
        function(context)
            return context.string == "mp_grand_campaign"
        end,
        function(context)
            mct:log("grand_campaign_yay triggered")
            bloop()
        end,
        true
    )
end

start()
--[[
-- first, listen for mp_games_list
core:add_listener(
    "mp_games_list_opened",
    "FrontendScreenTransition",
    function(context)
        return context.string == "mp_games_list"
    end,
    function(context)
        -- from here, listen for:
            -- the host buttons being pressed, for host
            -- the "mp_grand_campaign" transition being triggered, for client
            -- the "main" transition being triggered, for "cancel everything here and set to not host"

        -- host shit

        -- listen for MP Host Campaign -> Button Ok
        core:add_listener(
            "mp_host_new",
            "ComponentLClickUp",
            function(context)
                return context.string == "button_host_campaign"
            end,
            function(context)
                -- listen for button ok/button cancel

                core:add_listener(
                    "mp_host_new_yes_or_no",
                    "ComponentLClickUp",
                    function(context)
                        return context.string == "button_ok" or context.string == "button_cancel"
                    end,
                    function(context)
                        if context.string == "button_ok" then

                            --core:remove_listener("grand_campaign_yay")
                            core:remove_listener("mp_host_resume")
                            is_host = true

                            local trig = false

                            core:add_listener(
                                "grand_campaign_test",
                                "FrontendScreenTransition",
                                function(context)
                                    return context.string == "mp_grand_campaign"
                                end,
                                function(context)
                                    trig = true
                                end,
                                false
                            )

                            -- test in 5 seconds if the grand campaign was opened; if not, we can assume the host didn't go through
                            core:add_listener(
                                "check_time",
                                "RealTimeTrigger",
                                function(context)
                                    return context.string == "really?"
                                end,
                                function(context)
                                    if not trig then
                                        is_host = false
                                        core:remove_listener("grand_campaign_test")
                                    end
                                end,
                                false
                            )

                            real_timer.register_singleshot("really?", 5000)
                        else
                            is_host = false
                        end
                    end,
                    false
                )
            end,
            true
        )]]

        -- listen for MP Resume As Host -> Load
        --[[core:add_listener(
            "mp_host_resume",
            "FrontendScreenTransition",
            function(context)]]
                --[[local uic = UIComponent(context.component)

                return context.string == "button_load" and uicomponent_descended_from(uic, "mp_games_list")]]
                --[[return true
            end,
            function(context)
                mct:log("TRANSITION OUT OF MP_GAMES_LIST")
                core:remove_listener("mp_host_resume_transition")
                -- check if the transition was for the "Resume As Host" screen
                if context.string == "load_save_game" then
                    mct:log("Transitioned to load_save_game")
                    -- if it was, listen for a transition; if any transition occurs but "mp_grand_campaign", they are not the host; else they are
                    core:remove_listener("grand_campaign_yay")
                    core:add_listener(
                        "mp_host_resume_transition",
                        "FrontendScreenTransition",
                        true,
                        function(context)
                            if context.string == "mp_grand_campaign" then
                                mct:log("Transitioned from load_save_game to mp_grand_campaign, is_host!")
                                is_host = true

                                bloop()
                            else
                                mct:log("Transitioned from load_save_game to "..context.string .. ", we're client!")
                                is_host = false

                                start()
                            end
                        end,
                        false
                    )
                else
                    mct:log("Transitioned elsewhere, to "..context.string)
                    mct:log("We're client!")
                    -- we transitioned, we're the client
                    is_host = false
                end
            end,
            false
        )
    end,
    true
)

core:add_listener(
    "main_transition",
    "FrontendScreenTransition",
    function(context)
        return context.string == "main"
    end,
    function(context)
        is_host = false
        core:svr_save_bool("local_is_host", is_host)

        -- disable all listeners
        core:remove_listener("grand_campaign_yay")
        core:remove_listener("mp_host_new")
        core:remove_listener("mp_host_new_yes_or_no")
        core:remove_listener("mp_host_resume")
        core:remove_listener("mp_host_resume_transition")

        start()
    end,
    true
)

start()]]
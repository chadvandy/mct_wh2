local mct = get_mct()

local function check_highlight()
    local uic = find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar", "button_mct_options")

    mct.ui:set_mct_button(uic)

    -- if the mct_settings.lua file doesn't exist, do da highlight
    local first_load = mct._first_load

    if first_load then
        uic:Highlight(true, false)
        uic:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069").."||"..effect.get_localised_string("mct_button_unfinalized"), true)

        -- turn off the highlight when you press da button
        core:add_listener(
            "check_for_finalization",
            "ComponentLClickUp",
            function(context)
                return context.string == "button_mct_options"
            end,
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
        ModLog("button_check!")
        real_timer.unregister("check_for_da_button")
        core:remove_listener("button_check!")

        local button_group = find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar")

        local button = UIComponent(button_group:CreateComponent("button_mct_options", "ui/templates/round_small_button"))

        -- set the tooltip & img
        button:SetTooltipText(effect.get_localised_string("uied_component_texts_localised_string_button_mct_options_Tooltip_42069"), true)
        local img_path = effect.get_skinned_image_path("icon_options.png")
        button:SetImagePath(img_path)
    
        -- refresh the button group layout
        button_group:Layout()

        mct:load_and_start()

        check_highlight()

        mct.ui:ui_created()
    end,
    false
)

real_timer.register_singleshot("check_for_da_button", 0)

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

                local popup_uic = core:get_or_create_component("mct_mp_host", "ui/mct/mct_dialogue")
                popup_uic:SetCanResizeWidth(true) popup_uic:SetCanResizeHeight(true)
                popup_uic:Resize(popup_uic:Width() * 1.05, popup_uic:Height() * 1.10)
                popup_uic:SetCanResizeWidth(false) popup_uic:SetCanResizeHeight(false)

                mct:log("popup created")

                local both_group = UIComponent(popup_uic:CreateComponent("both_group", "ui/mct/script_dummy"))
                local ok_group = UIComponent(popup_uic:CreateComponent("ok_group", "ui/mct/script_dummy"))
                local DY_text = UIComponent(popup_uic:CreateComponent("DY_text", "ui/vandy_lib/text/la_gioconda/center"))

                mct:log("all dummies created")
        
                both_group:SetDockingPoint(8)
                both_group:SetDockOffset(0, 0)
        
                ok_group:SetDockingPoint(8)
                ok_group:SetDockOffset(0, 0)
        
                DY_text:SetVisible(true)
                DY_text:SetDockingPoint(5)
                local ow, oh = popup_uic:Width() * 0.9, popup_uic:Height() * 0.8
                DY_text:Resize(ow, oh)
                DY_text:SetDockOffset(1, -35)

                mct:log("Dummies set")
        
                local cancel_img = effect.get_skinned_image_path("icon_cross.png")
                local tick_img = effect.get_skinned_image_path("icon_check.png")
        
                do
                    local button_tick = UIComponent(both_group:CreateComponent("button_tick", "ui/templates/round_medium_button"))
                    local button_cancel = UIComponent(both_group:CreateComponent("button_cancel", "ui/templates/round_medium_button"))

                    mct:log("buttons created")
        
                    button_tick:SetImagePath(tick_img)
                    button_tick:SetDockingPoint(8)
                    button_tick:SetDockOffset(-30, -10)
        
                    button_cancel:SetImagePath(cancel_img)
                    button_cancel:SetDockingPoint(8)
                    button_cancel:SetDockOffset(30, -10)

                    mct:log("buttons moved")
                end
        
                do
                    local button_tick = UIComponent(ok_group:CreateComponent("button_tick", "ui/templates/round_medium_button"))

                    mct:log("single button created")
        
                    button_tick:SetImagePath(tick_img)
                    button_tick:SetDockingPoint(8)
                    button_tick:SetDockOffset(0, -10)

                    mct:log("button moved")
                end

                popup_uic:LockPriority()

                mct:log("prio lock")

                local str = ""

                local player_name = find_uicomponent(uic, "dy_player_name"):GetStateText()

                mct:log("player name is: "..player_name)

                local is_is_host_host = core:svr_load_bool("local_is_host")

                mct:log("is host is: "..tostring(is_is_host_host))

                if is_is_host_host then
                    str = effect.get_localised_string("mct_mp_is_host_start") .. "\n\n" .. effect.get_localised_string("mct_mp_is_host_mid") .. "\n\n" .. effect.get_localised_string("mct_mp_is_host_end") --"[[col:red]]MCT: Loading Your Settings[[/col]]\n\nLoading your settings from MCT. Make sure the other player is cool with the settings you've chosen, if you care!\n\n[[col:fabulous_pink]]IF THIS IS WRONG - IF THE OTHER PLAYER IS ON THE LEFT SIDE OF THE SCREEN - PLEASE LOAD TO THE MAIN MENU AND LOAD BACK IN.[[/col]]"
                else
                    str = effect.get_localised_string("mct_mp_not_host_start") .. player_name .. effect.get_localised_string("mct_mp_not_host_mid") .. "\n\n" .. effect.get_localised_string("mct_mp_not_host_end") .. "\n\n" .. effect.get_localised_string("mct_mp_not_host_end_actually") --"[[col:red]]MCT: Loading "..player_name.."'s Settings[[/col]]\n\nLoading the Host's settings from MCT. Make sure you're cool with the settings they've picked. Do note - you can't see the host's settings until you load into the campaign, so you'll have to discuss it elsewhere.\n\n[[col:fabulous_pink]]IF THIS IS WRONG - IF YOU ARE ON THE LEFT SIDE OF THE SCREEN - PLEASE LOAD TO THE MAIN MENU AND LOAD BACK IN. ALSO REPORT THIS TO VANDY.[[/col]]"
                end

                mct:log("str is: "..str)

       
                -- grab and set the text
                local tx = find_uicomponent(popup_uic, "DY_text")
        
                local w,h = tx:TextDimensionsForText(str)
                tx:ResizeTextResizingComponentToInitialSize(w,h)

                tx:SetStateText(str)
        
                tx:Resize(ow,oh)
                w,h = tx:TextDimensionsForText(str)
                tx:ResizeTextResizingComponentToInitialSize(ow,oh)

                mct:log("resizes and set the text")

                find_uicomponent(popup_uic, "both_group"):SetVisible(false)
                find_uicomponent(popup_uic, "ok_group"):SetVisible(true)

                mct:log("invisible")

                core:remove_listener("mct_mp_box_close")
                core:add_listener(
                    "mct_mp_box_close",
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
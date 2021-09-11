--- in-game patch notes for your mod.

local mct = get_mct()

local ui = mct.ui

ui:set_tab_action(
    "patch_notes",
    ---@param ui_obj mct_ui
    ---@param mod mct_mod
    ---@param list_view UIComponent
    function(ui_obj, mod, list_view)
        local patches = mod:get_patches()

        local list_box = find_uicomponent(list_view, "list_clip", "list_box")

        -- populate them on the listview! Start with the last first, so iterate backwards.
        for i = #patches, 1, -1 do
            local patch = patches[i]
            local name = patch.name
            local desc = patch.description
            
            -- TODO implement this in the UI somehow?
            local priority = patch.is_important

            --- TODO shorthand-creater for holder elements
            local patch_holder = core:get_or_create_component("patch_"..tostring(i), "ui/campaign ui/script_dummy", list_box)
            patch_holder:SetDockingPoint(2)
            patch_holder:SetDockOffset(0, 0)
            patch_holder:SetCanResizeHeight(true)
            patch_holder:SetCanResizeWidth(true)
            patch_holder:Resize(list_view:Width(), list_view:Height() * 1.5)
            patch_holder:SetCanResizeHeight(false)
            patch_holder:SetCanResizeWidth(false)

            --- TODO shorthand for creating text
            local name_uic = core:get_or_create_component("name", "ui/vandy_lib/text/fe_section_heading", patch_holder)
            name_uic:SetDockingPoint(2)
            name_uic:SetDockOffset(0, 10)

            resize_text(name_uic, name, patch_holder:Width() * 0.4, patch_holder:Height() * 0.1)

            local desc_uic = core:get_or_create_component("desc", "ui/vandy_lib/text/la_gioconda/unaligned", patch_holder)
            desc_uic:SetDockingPoint(2)
            desc_uic:SetDockOffset(0, name_uic:Height() + 15)

            resize_text(desc_uic, desc, patch_holder:Width() * 0.9, patch_holder:Height() * 0.8)

            --- Resize the patch holder so it doesn't get too large.
            local h = name_uic:Height() + desc_uic:Height() + 15

            _SetCanResize(patch_holder, true)
            patch_holder:Resize(patch_holder:Width(), h)
            _SetCanResize(patch_holder, false)
        end

        list_box:Layout()
    end
)

ui:set_tab_validity_check(
    "patch_notes",
    ---@param ui_obj mct_ui
    ---@param mod mct_mod
    function(ui_obj, mod)
        if is_table(mod:get_patches()) and #mod:get_patches() > 0 then
            return true
        end

        return false
    end
)

if core:is_frontend() then
    local pending_patches = {}

    -- check for new patches created!
    core:add_listener(
        "MctPatchCreated",
        "MctPatchCreated",
        true,
        function(context)
            pending_patches[#pending_patches+1] = {mod = context:mod(), patch = context:patch(), num = context:patch_number()}
        end,
        true
    )

    -- TODO what do if multiple patches?
    core:add_listener(
        "MctInitialized",
        "MctInitialized",
        true,
        function(context)
            core:remove_listener("MctPatchCreated")

            for i = 1, #pending_patches do
                local pending = pending_patches[i]
                ---@type mct_mod
                local mod = pending.mod

                local patch = pending.patch
                local num = pending.num
                if num > mod:get_last_viewed_patch() and patch.is_important then
                    local str = "[[col:dark_g]]New Patch for " .. mod:get_title() .. "[[/col]]\n"

                    ---@type string
                    local news = patch.description
                    news = news:format_with_linebreaks(60)
            
                    if news:len() > 180 then news = news:sub(1, 180-4) .. "[..]" end
            
                    str = str .. news .. "\n\nUse the check to view this patch note. Otherwise, close it."
            
                    mct.ui:create_popup(
                        "mct_patch_created_"..mod:get_key().."_".. num,
                        str,
                        true,
                        function()
                            -- "yes", open up the MCT panel
                            ui:open_frame()
                            ui:set_selected_mod(mod:get_key())
            
                            -- open up that tab!
                            ui:set_tab_active("patch_notes")
            
                            mod:set_last_viewed_patch(num)
            
                            -- needs to be saved immediately!
                            mct.settings:save_mct_settings()
                        end,
                        function()
                            -- "no", close.
            
                            mod:set_last_viewed_patch(num)
                            -- needs to be saved immediately!
                            mct.settings:save_mct_settings()
                        end
                    )
                end        
            end

            pending_patches = {}
        end,
        true
    )
end
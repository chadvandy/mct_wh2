--- in-game patch notes for your mod.

local mct = get_mct()

---@type mct_mod
local mct_mod = mct._MCT_MOD
local ui = mct.ui

--- Create a new patch. This allows you to slightly-better communicate with your users, by adding patches to a tab within the UI and potentially forcing a popup to inform your users of important stuff.
---@param patch_name string The name of your patch. Will display in larger text in the patch notes section.
---@param patch_description string Description for your patch. Accepts any existing localisation tags - [[col]] tags or whatever. Will get automatic linebreaks in it, to make it fit properly.
---@param patch_number number The order this patch should come in. Don't skip any numbers, and keep these to whole integers - ie., 1-2-3-4-5. Higher number means more recent, which means a higher placement; put your oldest at 1 and your highest at max.
---@param is_important boolean Set this to true to prioritize this patch by giving a popup to the user about a new patch (will only show once). Don't abuse pls!
function mct_mod:create_patch(patch_name, patch_description, patch_number, is_important)
    assert(is_string(patch_name), "You need to provide a patch name for the patch!")
    assert(is_string(patch_description), "You need to provide a patch description!")
    
    -- TODO somee way to make sure the number is valid?
    if not is_number(patch_number) then patch_number = #self._patches+1 end
    if not is_boolean(is_important) then is_important = false end

    patch_description = string.format_with_linebreaks(patch_description, 150)


    self._patches[patch_number] = 
    {
        name = patch_name,
        description = patch_description,
        is_important = is_important
    }

    core:trigger_custom_event(
        "MctPatchCreated", 
        {
            mct = mct,
            mod = self,
            patch = self._patches[patch_number],
            patch_number = patch_number,
        }
    )
end

function mct_mod:set_last_viewed_patch(index)
    if not is_number(index) or not self._patches[index] then return end

    self._last_viewed_patch = index
end

function mct_mod:get_last_viewed_patch()
    return self._last_viewed_patch
end

function mct_mod:get_patches()
    return self._patches
end

function mct_mod:get_patch(index)
    return self._patches[index]
end

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
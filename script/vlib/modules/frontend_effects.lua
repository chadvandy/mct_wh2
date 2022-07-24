if __game_mode ~= __lib_type_frontend then return false end

-- TODO refactor so this takes a lord's startpos ID
-- TODO refactor so it's a single lostener :)
-- TODO refactor so it uses internal callbacks not the current TM shit

local vandy_lib = get_vandy_lib()
-- local utility = vandy_lib:get_utility()

function vandy_lib:remove_frontend_effects(lord_loc_name, effect_text_or_position)
    local listener_name = "HideEffectsFor"..lord_loc_name

    -- listener needed to trigger after the lord's portrait is selected on the frontend
    core:add_listener(
        listener_name,
        "ComponentLClickUp",
        function(context)
            return context.string == lord_loc_name
        end,
        function(context)
            -- timer manager, to use a 0.05s callback
            local tm = get_tm()
            tm:callback(function()
                -- grab the root UIC, and the list box for the effects
                local root = core:get_ui_root()
                local parent = find_uicomponent(root, "sp_grand_campaign", "dockers", "centre_docker", "lord_details_panel", "faction", "faction_traits", "effects", "listview", "list_clip", "list_box")
                
                self:log(false, "Hiding effects for "..lord_loc_name, "[f_e]")

                if is_uicomponent(parent) then
                    for i = 1, #effect_text_or_position do
                        local criterion = effect_text_or_position[i]
                        if is_string(criterion) then
                            --# assume criterion: string
                            for j = 0, parent:ChildCount() - 1 do
                                local child = UIComponent(parent:Find(j))
                                if is_uicomponent(child) then
                                    local state_text = child:GetStateText()
                                    if string.find(state_text, criterion) then
                                        child:SetVisible(false)
                                        self:log(false, "Hiding effect with localised text ["..criterion.."] for lord ["..lord_loc_name.."]!", "[f_e]")
                                        break
                                    end
                                else
                                    self:log(true, "Child not found at index ["..i.."]. Should be impossible, investigate!", "[f_e]")
                                end
                            end
                        elseif is_number(criterion) then
                            local victim = find_uicomponent(parent, "lord_effect"..criterion)
                            victim:SetVisible(false)
                            self:log(false, "Hiding effect at position ["..criterion.."] for lord ["..lord_loc_name.."]!", "[f_e]")
                        end
                    end
                else
                    self:log(true, "List box not found upon listener with name ["..listener_name.."] being triggered. Investigate!", "[f_e]")
                end
            end, 50)
        end,
        true
    )
end
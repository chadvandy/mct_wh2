--- Testing a bunch of CC functions!
local faction = "wh2_main_hef_eataine"

local vlib = get_vlib()

---@type vlib_camp_counselor
local cc = vlib:get_module("camp_counselor")

-- TODO
local filter

cm:add_first_tick_callback(function()
    cc:add_pr_uic("wh2_main_ritual_currency", "ui/skins/default/bloodlines_skull.png", faction)

    cc:set_units_lock_state({"wh2_main_hef_inf_archers_0", "wh2_main_hef_inf_spearmen_0"}, "locked", "Locked because of raisins.", faction)

    cc:set_units_lock_state({"wh2_main_hef_inf_swordmasters_of_hoeth_0", "wh2_main_hef_inf_archers_1"}, "disabled", nil, faction)
end)
local mct = mct

local confed_options = mct:register_mod("confederation_options")

--[[confed_options:set_title("Confederation Options")
confed_options:set_author("Vandy")
confed_options:set_description("The following are the settings for the mod you're looking at right now. Try it out!")]]

local options_list = {
    "wh_main_emp_empire",
    "wh_main_dwf_dwarfs",
    "wh_main_grn_greenskins",
    "wh_main_vmp_vampire_counts",
    "wh2_main_hef_high_elves",
    "wh2_main_def_dark_elves",
    "wh2_main_skv_skaven",
    "wh2_main_lzd_lizardmen",
    "wh_main_brt_bretonnia",
    "wh_dlc05_wef_wood_elves",
    "wh_main_sc_nor_norsca",
    "wh2_dlc09_tmb_tomb_kings",
    "wh2_dlc11_cst_vampire_coast"
}

-- TODO incorporate a "preset" option

local enable = confed_options:add_new_option("enable_all", "checkbox")
enable:set_default_value(false)

-- when the "enable" button is checked on or off, all other options are set visible or invisible
enable:add_option_set_callback(
    function(option) 
        local val = option:get_selected_setting()
        local options = options_list

        for i = 1, #options do
            local i_option_key = options[i]
            local i_option = option:get_mod():get_option_by_key(i_option_key)
            i_option:set_uic_visibility(val)
        end
    end
)

local cult_loc_prefix = "cultures_name_"
local subcult_loc_prefix = "cultures_subcultures_name_"

local dropdown_options = {
    {
        key = "no_tweak",
        text = "confederation_options_no_tweak_text",
        tt = "confederation_options_no_tweak_tooltip",
        default = true
    },
    {
        key = "player_only", 
        text = "confederation_options_player_only_text",
        tt = "confederation_options_player_only_tooltip"
    }, 
    {
        key = "free_confed",
        text = "confederation_options_free_confed_text",
        tt = "confederation_options_free_confed_tooltip"
    },
    {
        key = "disabled",
        text = "confederation_options_disabled_text",
        tt = "confederation_options_disabled_tooltip"
    }
}

-- run through the 
for i = 1, #options_list do
    local option_key = options_list[i]
    local option_obj = confed_options:add_new_option(option_key, "dropdown")

    -- to set localised text, ie. "cultures_name_wh_main_brt_bretonnia"
    local text = cult_loc_prefix..option_key

    -- Norsca text has to be set using the subculture key
    if option_key == "wh_main_sc_nor_norsca" then
        text = subcult_loc_prefix..option_key
    end

    -- set the text for the option, displays on the left of the dropdown
    mct:log(text)
    option_obj:set_text(text, true)
    option_obj:set_tooltip_text("")

    -- default to invisible
    option_obj:set_uic_visibility(false)

    -- add the above table as dropdown values, providing "no_tweak" as the default
    option_obj:add_dropdown_values(dropdown_options)
end
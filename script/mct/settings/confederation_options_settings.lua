local confed_options = mct:register_mod("confederation_options")

--[[confed_options:set_title("Confederation Options")
confed_options:set_author("Vandy")
confed_options:set_description("The following are the settings for the mod you're looking at right now. Try it out!")]]
confed_options:set_workshop_link("https://steamcommunity.com/sharedfiles/filedetails/?id=1577217111")

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


--[[local emp = confed_options:add_new_option("wh_main_emp_empire", "dropdown")
emp:set_text(cult_loc_prefix..emp:get_key())
emp:add_dropdown_values(dropdown_options)

emp:set_uic_visibility(false)

local dwf = confed_options:add_new_option("wh_main_dwf_dwarfs", "dropdown")
dwf:set_text(cult_loc_prefix..dwf:get_key())
dwf:add_dropdown_values(dropdown_options)

dwf:set_uic_visibility(false)

local grn = confed_options:add_new_option("wh_main_grn_greenskins", "dropdown")
grn:set_text(cult_loc_prefix..grn:get_key())
grn:add_dropdown_values(dropdown_options)

grn:set_uic_visibility(false)

local vmp = confed_options:add_new_option("wh_main_vmp_vampire_counts", "dropdown")
vmp:set_text(cult_loc_prefix..vmp:get_key())
vmp:add_dropdown_values(dropdown_options)

vmp:set_uic_visibility(false)

local hef = confed_options:add_new_option("wh2_main_hef_high_elves", "dropdown")
hef:set_text(cult_loc_prefix..hef:get_key())
hef:add_dropdown_values(dropdown_options)

hef:set_uic_visibility(false)

local def = confed_options:add_new_option("wh2_main_def_dark_elves", "dropdown")
def:set_text(cult_loc_prefix..def:get_key())
def:add_dropdown_values(dropdown_options)

def:set_uic_visibility(false)

local lzd = confed_options:add_new_option("wh2_main_lzd_lizardmen", "dropdown")
lzd:set_text(cult_loc_prefix..lzd:get_key())
lzd:add_dropdown_values(dropdown_options)

lzd:set_uic_visibility(false)

local skv = confed_options:add_new_option("wh2_main_skv_skaven", "dropdown")
skv:set_text(cult_loc_prefix..skv:get_key())
skv:add_dropdown_values(dropdown_options)

skv:set_uic_visibility(false)

local brt = confed_options:add_new_option("wh_main_brt_bretonnia", "dropdown")
brt:set_text(cult_loc_prefix..brt:get_key())
brt:add_dropdown_values(dropdown_options)

brt:set_uic_visibility(false)

local wef = confed_options:add_new_option("wh_dlc05_wef_wood_elves", "dropdown")
wef:set_text(cult_loc_prefix..wef:get_key())
wef:add_dropdown_values(dropdown_options)

wef:set_uic_visibility(false)

local nor = confed_options:add_new_option("wh_main_sc_nor_norsca", "dropdown")
nor:set_text(subcult_loc_prefix..nor:get_key())
nor:add_dropdown_values(dropdown_options)

nor:set_uic_visibility(false)

local tmb = confed_options:add_new_option("wh2_dlc09_tmb_tomb_kings", "dropdown")
tmb:set_text(cult_loc_prefix..tmb:get_key())
tmb:add_dropdown_values(dropdown_options)

tmb:set_uic_visibility(false)

local cst = confed_options:add_new_option("wh2_dlc11_cst_vampire_coast", "dropdown")
cst:set_text(cult_loc_prefix..cst:get_key())
cst:add_dropdown_values(dropdown_options)

cst:set_uic_visibility(false)]]

--[[
    mct1:add_dropdown_value("option_1", "Option 1", "This is option1")
mct1:add_dropdown_value("option_2", "Option 2", "This is option2")
mct1:add_dropdown_value("option_3", "Option 3", "This is option3")
mct1:add_dropdown_value("option_4", "Option 4", "This is option4")
mct1:set_default_value("option_3")
]]
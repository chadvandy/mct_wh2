
local mct = mct

local mct_mod = mct:register_mod("my_cool_mod")

mct_mod:set_title("My Cool Mod")
mct_mod:set_author("Made By A Cool Guy")

local new_section = mct_mod:add_new_section("blorp", "This Is My Section")

local option_juan = mct_mod:add_new_option("option_1", "checkbox")
option_juan:set_default_value(true)

local option_two = mct_mod:add_new_option("option_2", "dummy")
option_two:set_uic_visibility(false, true)
option_two:set_border_visibility(false)

local option_three = mct_mod:add_new_option("option_3", "checkbox")
option_three:set_uic_visibility(true)

local option_four = mct_mod:add_new_option("option_4", "checkbox")
option_four:set_uic_visibility(false, false)

local option_five = mct_mod:add_new_option("option_5", "checkbox")
option_five:set_border_visibility(false)

local option_six = mct_mod:add_new_option("option_6", "dummy")
option_six:set_uic_visibility(false, true)
option_six:set_border_visibility(true)

local option_seven = mct_mod:add_new_option("option_7", "checkbox")
option_seven:set_uic_visibility(true)
option_seven:set_border_image_path("ui/skins/warhammer2/panel_back_border.png")

local option_eight = mct_mod:add_new_option("option_8", "dummy")
option_eight:set_text("This is my testing dummy.")

local mct = mct

local mct_mod = mct:register_mod("my_cool_mod")

mct_mod:set_title("My Cool Mod")
mct_mod:set_author("Made By A Cool Guy")

local new_section = mct_mod:add_new_section("blorp", "This Is My Section")

local option_juan = mct_mod:add_new_option("option_1", "checkbox")
option_juan:set_default_value(true)

local option_two = mct_mod:add_new_option("option_2", "checkbox")
option_two:set_uic_visibility(false, false)

local option_three = mct_mod:add_new_option("option_3", "checkbox")
option_three:set_uic_visibility(false, true)
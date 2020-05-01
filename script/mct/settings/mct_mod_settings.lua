local mct_mod = mct:register_mod("mct_mod")

--[[mct_mod:set_title("random_localisation_strings_string_mct_settings", true)
mct_mod:set_author("Vandy")
mct_mod:set_description("The following are the settings for the mod you're looking at right now. Try it out!")]]
mct_mod:set_workshop_link("https://steamcommunity.com/sharedfiles/filedetails/?id=1576253740")

local test = mct_mod:add_new_option("enable_logging", "checkbox")
test:set_default_value(false)
test:set_read_only(false)

--mct_mod:add_new_section("testing2")

local mct1 = mct_mod:add_new_option("mct1", "dropdown", "This is a test")
mct1:add_dropdown_value("option_1", "Option 1", "This is option1")
mct1:add_dropdown_value("option_2", "Option 2", "This is option2")
mct1:add_dropdown_value("option_3", "Option 3", "This is option3")
mct1:add_dropdown_value("option_4", "Option 4", "This is option4")
mct1:set_default_value("option_3")

local mct2 = mct_mod:add_new_option("mct2", "checkbox", "This is also a test")
mct2:set_default_value(true)

mct_mod:add_new_section("testing3")

local mct3 = mct_mod:add_new_option("mct3", "dropdown", "Further test")
mct3:add_dropdown_value("option_fuck", "Another Test", "This is option1")
mct3:add_dropdown_value("option_awef", "Florp", "This is option2")
mct3:add_dropdown_value("option_afe", "Option 3", "This is option3")
mct3:set_default_value("option_fuck")

local mct1 = mct_mod:add_new_option("135", "dropdown", "This is a test")
mct1:add_dropdown_value("option_1", "Option 1", "This is option1")
mct1:add_dropdown_value("option_2", "Option 2", "This is option2")
mct1:add_dropdown_value("option_3", "Option 3", "This is option3")
mct1:add_dropdown_value("option_4", "Option 4", "This is option4")
mct1:set_default_value("option_3")

local mct1 = mct_mod:add_new_option("afwe", "dropdown", "This is a test")
mct1:add_dropdown_value("option_1", "Option 1", "This is option1")
mct1:add_dropdown_value("option_2", "Option 2", "This is option2")
mct1:add_dropdown_value("option_3", "Option 3", "This is option3")
mct1:add_dropdown_value("option_4", "Option 4", "This is option4")
mct1:set_default_value("option_3")

local mct1 = mct_mod:add_new_option("awfeawec", "dropdown", "This is a test")
mct1:add_dropdown_value("option_1", "Option 1", "This is option1")
mct1:add_dropdown_value("option_2", "Option 2", "This is option2")
mct1:add_dropdown_value("option_3", "Option 3", "This is option3")
mct1:add_dropdown_value("option_4", "Option 4", "This is option4")
mct1:set_default_value("option_3")

--[[local mct4 = mct_mod:add_new_option("mct4", "slider", "Bloop")
mct4:slider_set_values(10, 800, 50)]]
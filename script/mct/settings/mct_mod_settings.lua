local mct = mct

local mct_mod = mct:register_mod("mct_mod")

local test = mct_mod:add_new_option("enable_logging", "checkbox")
test:set_default_value(false)
test:set_read_only(false)
test:set_text("Enable script logging")

--mct_mod:add_new_section("testing2")

local mct1 = mct_mod:add_new_option("mct1", "dropdown", "This is a test")
mct1:set_text("mct1")
mct1:add_dropdown_value("option_1", "Option 1", "This is option1")
mct1:add_dropdown_value("option_2", "Option 2", "This is option2")
mct1:add_dropdown_value("option_3", "Option 3", "This is option3")
mct1:add_dropdown_value("option_4", "Option 4", "This is option4")
--mct1:set_default_value("option_3")

local mct2 = mct_mod:add_new_option("mct2", "checkbox", "This is also a test")
--mct2:set_default_value(true)
mct2:set_text("mct2")

--local mct3 = mct_mod:add_new_option("mct3", "textbox", "ouaihybefiouaywbefouawyebyf")
--mct3:set_text("mct3")

--local mct4 = mct_mod:add_new_option("mct4", "slider", "baowefubawef")
--mct4:set_text("mct4")
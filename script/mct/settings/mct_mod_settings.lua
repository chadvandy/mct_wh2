local mct = mct

local mct_mod = mct:register_mod("mct_mod")

local test = mct_mod:add_new_option("enable_logging", "checkbox")
test:set_default_value(false)
test:set_read_only(false)
test:set_text("Enable script logging")
test:set_local_only(true)

--mct_mod:add_new_section("testing2")

local mct1 = mct_mod:add_new_option("mct1", "dropdown", "This is a test")
mct1:set_text("mct1")
mct1:add_dropdown_value("option_1", "Option 1", "This is option1")
mct1:add_dropdown_value("option_2", "Option 2", "This is option2")
mct1:add_dropdown_value("option_3", "Option 3", "This is option3")
mct1:add_dropdown_value("option_4", "Option 4", "This is option4")
--mct1:set_default_value("option_3")
mct1:set_read_only(true)

local mct2 = mct_mod:add_new_option("mct2", "checkbox", "This is also a test")
mct2:set_default_value(false)
mct2:set_text("mct2")
mct2:set_read_only(true)

--local mct3 = mct_mod:add_new_option("mct3", "textbox", "ouaihybefiouaywbefouawyebyf")
--mct3:set_text("mct3")

local mct4 = mct_mod:add_new_option("mct4", "slider", "baowefubawef")
mct4:set_text("mct4")

-- min/max/step size/default
mct4:slider_set_min_max(-6, 5)
mct4:slider_set_step_size(3)
mct4:set_default_value(0)
mct4:set_read_only(true)

local mct5 = mct_mod:add_new_option("mct5", "dropdown")
mct5:set_text("Local Only")
mct5:add_dropdown_value("option_1", "Option 1", "This is option1")
mct5:add_dropdown_value("option_2", "Option 2", "This is option2")
mct5:add_dropdown_value("option_3", "Option 3", "This is option3")
mct5:add_dropdown_value("option_4", "Option 4", "This is option4")
mct5:set_local_only(true)

local mct6 = mct_mod:add_new_option("mct6", "checkbox")
mct6:set_text("Mp Disabled")
mct6:set_default_value(true)
mct6:set_mp_disabled(true)
local mct = mct

local mct_mod = mct:register_mod("mct_mod")

mct_mod:set_log_file_path("mct_log.txt")

local test = mct_mod:add_new_option("enable_logging", "checkbox")
--test:set_default_value(false)
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
mct1:set_default_value("option_3")
mct1:set_uic_locked(true)

local mct2 = mct_mod:add_new_option("mct2", "checkbox", "This is also a test")
mct2:set_default_value(false)
mct2:set_text("Enable Test Section")

mct2:add_option_set_callback(
    function(option)
        --mct:log("trigger callback?")
        local setting = option:get_selected_setting()
        local show_section = setting == true

        mct_mod:set_section_visibility("section_test", show_section)
    end
)
--mct2:set_read_only(true)

--local mct3 = mct_mod:add_new_option("mct3", "textbox", "ouaihybefiouaywbefouawyebyf")
--mct3:set_text("mct3")

local mct4 = mct_mod:add_new_option("mct4", "slider", "baowefubawef")
mct4:set_text("mct4")

-- min/max/step size/default
mct4:slider_set_min_max(-6, 5)
mct4:slider_set_step_size(3)
mct4:slider_set_precision(0)
--mct4:set_default_value(0)
mct4:set_text("0-precision slider")
--mct4:set_read_only(true)

local section = mct_mod:add_new_section("section_test")
section:set_localised_text("This Is My Test Section")
section:set_visibility(false)

section:set_option_sort_function("index_sort")

-- change the "Enable Test Section" button when the section's visibility is changed manually
section:add_section_visibility_change_callback(
    function(section)
        local visibility = section:is_visible()
        
        -- TODO fix this infinite loop
        -- don't do this unless you want an infinite loop
        --mct2:set_selected_setting_event_free(visibility)
    end
)

local mct7 = mct_mod:add_new_option("mct7", "slider")
mct7:set_text("1-precision slider")
mct7:slider_set_min_max(0, 1)
mct7:slider_set_step_size(0.2, 1)
mct7:slider_set_precision(1)
mct7:set_default_value(0)

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

local mct8 = mct_mod:add_new_option("mct8", "text_input")
mct8:set_text("Text Input - Can't Be 'boyo'")
mct8:set_tooltip_text("I mean it. You cannot put the word 'boyo' as the option here. Don't try.")
mct8:set_default_value("My Text")

mct8:text_input_add_validity_test(
    function(text) 
        if text == "boyo" then
            return "I don't want the string 'boyo' in my mod."
        end

        return true    
    end
)

local mct9 = mct_mod:add_new_option("mct9", "slider")
mct9:set_text("2-precision slider")
mct9:slider_set_min_max(0, 10)
mct9:slider_set_step_size(0.01, 2)
mct9:slider_set_precision(2)
mct9:set_default_value(0)
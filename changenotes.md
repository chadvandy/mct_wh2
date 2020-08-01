## Change Notes

### MCT 2.1.6 - August 1, 2020

**Documentation**

- I've added new documentation. For instance, this page here.
- There will soon be a few more pages available, one for available events. I've also gotta get to fixing up some issues with the "classes" pages.

**Features**

- There is now much further control over the "sections" objects of an mct_mod. These can be read up at @{mct_section}.
- There is more control over positioning of objects, either through @{mct_mod:set_option_sort_function_for_all_sections} or @{mct_section:set_option_sort_function}. No more being confined to alphanumerical key sorting! (Though that's still the default :) )
- Beginning incorporation of a tabs system. Currently, there is one new available tab - Logging. This is just a long list of all the text found in a logging file, determined by @{mct_mod:set_log_file_path}. Useful when you don't want to alt-tab endlessly to read logging while the game is open.

**Changes and Fixes**

- The internal mct_log.txt will no longer start from scratch every time you change between frontend/campaign/battle game modes. There will now be a persisted log file through the entirety of one game session, making it easier for me to read the logs, yay.
- @{mct_option:set_uic_locked} will work to *unlock* an option as well as lock it, now.
- @{mct_option:ui_select_value} is set up to work for sliders now. This allows for easy auto-setting of sliders based on other callbacks.
- @{mct_mod:set_section_visibility} will properly work before the UI panel is opened.
- mct_options are properly disabled and unclickable in MP, battle, etc.,
- If you change a setting in Mod A, and move to Mod B without finalizing, and go back to Mod A - the changed setting will properly remain at the value you set before switching. If you leave and don't finalize, it will revert to its previous stance.
- @{mct_option:add_option_set_callback}'s are no longer called when the mct_option UI is first created, causing some unexpected issues.
- The section headers will no longer intersect with the scroll bar on the right side of the options panel.
- Slider values are properly saved into the mct_settings.lua file with the float precision desired.
- Slider default values are set in @{mct_option.new}. This probably means nothing to anybody, but that's fine.


**Known Issues**

- You can cause an infinite loop if you do something like [this](https://github.com/chadvandy/mod_configuration_tool/issues/35). Don't do that until I fix it, please. :)
- @{mct_option:set_assigned_section} doesn't work if you try to assign a not-created section. Ditto for @{mct_section:assign_option}, but backwards. https://github.com/chadvandy/mod_configuration_tool/issues/42
- I've tested it and it seems fine, but I changed how mct_settings.lua is built slightly, so it's more flexible on my end. If you have any issues with it not building properly, please let me know.

**Upcoming Features**

- My next focus is on fixing up some of the remaining UI issues - work on prettier fonts, work on crushed text, make the panels less ugly, fix spacing all over, try to get a more professional appearance across the board.
- Meanwhile, gonna be working on getting text input types to work (for text_input as well as sliders).
- And thirdly, working on Steam API integration - for stuff like automatically reading the mod title, mod description, change notes, similar.


### MCT 2.1.5 - July 11, 2020

**Features**

- Added more control for the slider options for modders: you can now set decimal-precision using a couple of new methods, `option_obj:slider_set_precision()`, and `option_obj:slider_set_step_size()` now has a second optional arg to set precision for the step sizes. This lets you lock numbers to a specific number of decimal places - defaulting to 0 decimal places if none are set.
- Added a couple of popups, sorry. There will be a popup if new options are found when first loading the game (ie., a mod has updated and added new MCT options that should be checked out), and another if new options are added mid-game (ie., a mod makes a new option only when you play as Dark Elves).
-- I'll probably add an mct default option to disable specific popups and notifications, but that'll come after I make popups more flexible on my end.
- `option_obj:set_uic_locked()` has been added, to change whether or not an option is interactive.
- Documentation has been edited to include the new methods and any alterations

**Fixes**

- `mod_obj:set_section_visibility()` has been fixed, it now actually works!
- the frontend button highlight will properly work on first-time-load or if the mct_settings.lua file is deleted from your disk
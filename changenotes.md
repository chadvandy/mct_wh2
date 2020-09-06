## Change Notes

### MCT 2.2.0 - September 6, 2020

This patch is fairly substantial, and as of this point, I'm consider MCT Reborn **no longer a beta**. It's fairly stable at this point, most major issues and break cases have been resolved (all that I know of!), and from this point forward the main focus is on improving the quality of the mod and making new features, rather than fixing old issues and resolving foundational errors.

**Features**

- Main feature here is the introduction of the "Profiles" mechanic. You can now save and apply profiles to quickly jump between various settings, similar to a "presets" mechanic in other programs, like mod managers (KMM).
- Popups are changed in favor of a "notification" system, that will be further expanded and exposed to modders in a future version. For now, popups trigger as normal in the frontend and while MCT panel is open; otherwise, if a popup message is triggered, the MCT button will begin highlighting to inform the user there's a message, and after opening the panel, the message will popup.
- New option type: text_input. This is much what it sounds like, a proper text-input option that users can edit to input whatever string. @{mct_option:text_input_add_validity_test} should be used to make verify the string that's input, if you want only specific text to be input there.
- Similar functionality applied to sliders, so users can edit the number to be what they want. Similar text validation applied here - tests for the number being within the decimal range, within min/max range, being a number proper, etc.
- New option type: dummy. This one is basically nothing, it's just an "mct_option" with no actual setting to it, so it's just text/tooltip or a space in the UI. Modders can make a dummy in column two row one, use `mct_option:set_uic_visibility(false, true)`, and `mct_option:set_border_visibility(false)`, and there will now be a blank space in the UI in that index. Can also be used for text or whatever you'd like.
- New "Actions Menu", with three actions (aside from profiles): "Revert to Defaults", which sets all settings for the selected mod to their default value; "Finalize Settings for Mod", which applies the settings for the selected mod; and "Finalize Settings for All Mods", which does the same but, well, for all mods! When Finalize Settings is pressed, there will now be an extra popup that will allow the user to go through and make sure they want to make the changes they're making, or revert them back to the previous value if they'd like.

**MODDER MUST CHANGES**

- I changed the order of operations in the backend for @{mct_option:set_selected_setting} and @{mct_option:ui_select_value}. Previously, it went ui-select-value -> set selected setting; now I'm preferring going the other way, which makes a lot more sense. There's backwards compatibility in place to prevent stuff from crashing and burning if you use it backwards, but please, if you have any calls to @{mct_option:ui_select_value}, switch them to @{mct_option:set_selected_setting}. I will be removing this backwards functionality in a few patches.

**Changes & Fixes**

- Some backend improvements; it's now way easier for me to create new "types" of options, and type-specific functions (like `mct_option:add_dropdown_value()`) will be caught better-er if used on the wrong type.
- Validation improvements all over the place. @{mct_option:is_val_valid_for_type} will now return a valid value if the one passed is invalid; the mct_settings.lua file goes through validation if, say, a user has a slider saved at value 100, but the modder edits that slider to be a max of 50, next time the user loads up the game the setting will decrease to 50; a broken `script/mct/settings/?.lua` file will not crash all of MCT anymore
- A lot of minor UI fixes and resizes and what not.
- UI is more responsive, with buttons greying out when they're not relevant, buttons highlighting when relevant, etc.
- UI is also more dynamic; `mct_option:slider_set_min_max`, `mct_option:add_dropdown_value`, and other commands will properly edit the UI (ie. add the new dropdown value to the dropdown list, change the slider buttons in UI) if need be.
- @{mct_mod:delete_option} was added. Have fun, lunatics.
- Better UX for locked options. @{mct_option:set_uic_locked} now has two extra parameters for a lock reason (and if that lock_reason string is localised), to inform the user why those options can't be interacted with.
- @{mct_option:set_uic_visibility} has a second parameter, `keep_in_ui`. Defaults to false. If set to true, an invisible option will still "show up" in the UI, but the option and text will be invisible.
- Added borders, and exposed some stuff for them. @{mct_option:set_border_image_path} to change the image of the border, @{mct_option:set_border_visibility} to show or hide the border.
- Lots o' stuff is localised (though I for sure missed some stuff), so it'll be easier if there's a translation mod to, well, translate!
- @{mct_option:set_selected_setting} and @{mct_option:set_finalized_setting} will not work if the mct_option is currently locked (via @{mct_option:set_uic_locked}).
- Added a new event: "MctOptionSelectedSettingSet". Sorry for the verbosity. This triggers whenever an option is clicked to change in the UI (or when @{mct_option:set_selected_setting}) is called). 
- Exposed a lot of the "cached settings" functionality for modder interaction. @{mct_settings:get_cached_settings}, @{mct_settings:remove_cached_setting}, and @{mct_settings:add_cached_settings} have all been added. This should allow for modders to add in dynamic options, remove them later, but still read those settings. They can also change option keys, and use delete-cached-settings to remove those old option keys from memory.
- mct_option's will now have a new auto-default value is the modder doesn't set one through @{mct_option:set_default_value}. These are used for "Revert to Defaults", and when the MCT panel is first loaded up.
- @{mct_mod:sort_sections_by_localised_text} and @{mct_section:sort_options_by_localised_text} have been added, enjoy.

**Known Issues**

- You'll see a bunch of new classes, for the specific types, in the documentation. You can ignore these for now and just reference @{mct_option}.
- There's one popup that says "press this to open the MCT panel" while you're already in the MCT panel in campaign. I'll change that later.

**Upcoming Features**

Next patch will have lots of QoL:

- Hoping to get out the final option type planned - "multibox", for AND|OR options (ie. have 4 checkboxes and have different behaviour between them, ie. you can only have 1+2 or 1+2+3 but 3 and 4 can't be used together).
- The "cached settings" functionality will be exposed to the user, so you can interact with them and delete any. They shouldn't take up too much space, all things considered, but it's still space that you can remove.
- There will be a "Change Notes" section that modders can opt into, so you can view change notes directly in-game.
- Notifications functionality expanded, as hinted above.
- First major usage of the notifs: an optional popup when you load the game that tells the player which mods have updated (even if they aren't MCT, probably). 
- Lots of UI clean-ups and prettifys are planned here.
- And lastly, a walkthrough in-game that will introduce new users to MCT and how it works. Also looking into the viability of incorporating some internal "help pages" mechanics.




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
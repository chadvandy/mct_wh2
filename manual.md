# MCT, the Mod Configuration Tool

## FOREWORD - BETA

**Keep in mind this is just a quick write-up for the beta testing version of MCT. The beta is not feature-complete, some stuff might be wrong, and everything is subject to change. If you find issues with MCT, have requests, or something isn’t clear - please just ping me and I’ll help you out!**

## Intro

Hallo. MCT stands for Mod Configuration Tool, an in-game tool that allows Lua modders to make some settings for their mods that can be decided within the UI created from MCT. It includes all functionality needed for making options, reading them, saving them, loading them, and so forth. All mods really need to do is define their options, settings, and then hook them into their code.

## How It Works

Before we go on, we've got to cover how MCT works at its core, so there's no confusion.

The MCT is designed to be fairly simple to use for others, as it does 70% of the heavy lifting - all the UI design, it reads text easily through localisation keys, it saves and reads and sends settings.

When the game is first loaded with MCT, it creates a local mct_settings.lua file on disk, in the same folder as the Warhammer2.exe. Don't touch that .lua file! It is the file used to read any settings that were set in the frontend UI, and "save" those settings into the campaign. When the UI is first "finalized", that .lua file is created, and will be edited by MCT as time goes whenever settings are changed.

That file is only used in frontend, and for the *first* load of a campaign. After the campaign is created, all the settings saved in the mct_settings.lua file are then saved into the campaign save file via `cm:set_saved_value()`, and they're read through `cm:get_saved_value()` internally from then on.

There is a separation internally for MCT. There is one file to *define* the settings you want for your mod in `script/mct/settings/?.lua`, and your .lua files elsewhere - ie., `script/campaign/mod/?.lua` - will be used to *read* the settings that the player has selected for your mod locally, using a handful of listeners and methods that let you easily read the current state of things.

## Create Settings File

To start off - make a file in `script/mct/settings/?.lua`. Give it a unique name, since two files of the same name in this folder will conflict.

The first line of your file should be:
```lua
local mct_mod = mct:register_mod("my_mod")
```
Wherein `mct_mod` can be replaced with whatever, it's just a local variable, and "my_mod" should be a unique indentifier for your specific mod. Once that single line is done, when you open up the Mod Configuration Tool, you'll see a new mod - that's yours!

![Blank Mod](./doc_img/00.png)

We'll cover @{manual.md.Localisation|localisation} for the mct_mod further down; for now, options!

The @{mct_option} object is the real bulk of the mod. They're the actual settings you can interact with and save to load up a game with changed settings and the like. There are currently only two types of options - checkbox & dropdown. As of writing, there are two mid-hookup: slider (a number-based slider) & text input. The documentation will be edited once those are incorporated.

To make a new mct_option, you use the following:

```lua
local mct_mod = mct:register_mod("my_mod")

local mct_option = mct_mod:add_new_option("option_key", "option_type")
```

Where, once more, `option_key` has to be unique (to your `mct_mod`). `option_type` is either "checkbox" or "dropdown".

First up, if you are using a dropdown, you'll want to use @{mct_option:add_dropdown_value} or @{mct_option:add_dropdown_values}, to add the separate dropdown values for the box. This'll create the actual values within the dropdown box. There isn't an upper limit, but I recommend not doing too much, it'll start looking potentially ugly above 6 or 8 or so, depending on resolution.

Next up, you'll want to set a default value.
```lua
local mct_mod = mct:register_mod("my_mod")

local mct_option = mct_mod:add_new_option("my_cool_option", "dropdown")
mct_option:add_dropdown_value("value1", "My Dropdown Value", "This dropdown value does this.", true)
mct_option:add_dropdown_value("value2", "Another Dropdown Value", "This dropdown value does something.", false)

mct_option:set_default_value("value2")

-- OR --
local mct_option = mct_mod:add_new_option("my_cool_checkbox", "checkbox")

mct_option:set_default_value(false)
```

There's not much beyond that that's needed to really expand functionality, though you can jump through the API to find any extra methods that you'd like. Before we get into reading the settings in-campaign, we're going to do localisation.

## Localisation

Localisation with MCT is fairly robust. There are three options available for you - automatically read localisation keys, script-applicable localisation keys, and script-applicable loose text (ie. "My Localisation").

For the `mct_mod` object, the auto-read keys are:
    - `mct_[mct_mod_key]_title`
    - `mct_[mct_mod_key]_author`
    - `mct_[mct_mod_key]_description`

Alternatively, you can use the following methods in script:
```lua
local mct_mod = mct:register_mod("my_mod")

mct_mod:set_title("My Title")
mct_mod:set_author("Vandy")
mct_mod:set_description("My cool mod is a very cool mod, thank you for asking.")
```

And, lastly, you can use the same methods to supply dynamic localisation keys instead:
```lua
local mct_mod = mct:register_mod("my_mod")

mct_mod:set_title("ui_text_replacements_localised_text_my_mod_title", true)
mct_mod:set_author("Vandy") -- doesn't accept localisation
mct_mod:set_description("ui_text_replacements_localised_text_my_mod_desc", true)
```

Supply those methods with `true` and they will check for a localised string with the loc key you supply.

For the `mct_option` object, the auto-read keys are:
    - `mct_[mct_mod_key]_[mct_option_key]_text`
    - `mct_[mct_mod_key]_[mct_option_key]_tooltip`

Alternatively, you can use the following methods in script:
```lua
local mct_mod = mct:register_mod("my_mod")

local my_option = mct_mod:add_new_option("test_option", "checkbox")

my_option:set_text("My Cool Option")
my_option:set_tooltip_text("My cool option does this specifically, enjoy!")
```

And likewise, you can supply localisation keys instead through script:
```lua
local mct_mod = mct:register_mod("my_mod")

local my_option = mct_mod:add_new_option("test_option", "checkbox")

my_option:set_text("ui_text_replacements_localised_text_my_option_text", true)
my_option:set_tooltip_text("ui_text_replacements_localised_text_my_option_tooltip_text", true)
```

## Hook Into Scripts

The above is enough to get the UI in the frontend and in the campaign to populate, have localisation, and do stuff, but the settings won't change anything on their own! We're gonna take a bit to look into hooking MCT into your scripts, making MCT an optional mod or a required one, and responding to new settings.

In your own .lua files - in `script/campaign/mod/` or wherever you've got them at - there's a couple functionalities and listeners you can set up to quickly and easily read the currently saved MCT settings.

A good quick example is the file `script/_lib/mod/zzz_mct_options.lua` in the MCT pack.

The first event that will help a lot is the "MctInitialized" event.

```lua
core:add_listener(
    "bloop",
    "MctInitialized",
    true,
    function(context)
        local mct = context:mct()
        local my_mod = mct:get_mod_by_key("my_cool_mod")
    end,
    true
)
```

MctInitialized is triggered *pretty* early on, fairly before FirstTickAfterWorldCreated, so **do not do model edits** off of this function! It's a great way to quickly read the settings from MCT and pass them locally, though.

```lua
-- default settings for the mod. If MCT is never enabled, or the player doesn't change settings, then do_thing_one and do_thing_two will remain true!
local settings = {
    do_thing_one = true,
    do_thing_two = true,
}

-- harmless listener, won't do anything if MCT isn't enabled. Triggered around LoadingGame, *do not to model edits here*
core:add_listener(
    "bloop",
    "MctInitialized",
    true,
    function(context)
        -- get the @{mct} object
        local mct = context:mct()

        -- get the @{mct_mod} object with the key "my_cool_mod"
        local my_mod = mct:get_mod_by_key("my_cool_mod")

        -- get the @{mct_option} object with the key "do_thing_one", and its finalized setting - reading from the mct_settings.lua file if it's a new game, or the save game file if it isn't
        local do_thing_one = my_mod:get_option_by_key("do_thing_one")
        local do_thing_one_setting = do_thing_one:get_finalized_setting()

        -- ditto
        local do_thing_two = my_mod:get_option_by_key("do_thing_two")
        local do_thing_two_setting = do_thing_two:get_finalized_setting()

        -- replace the default settings with the finalized settings through MCT
        settings.do_thing_one = do_thing_one_setting
        settings.do_thing_two = do_thing_two_setting
    end,
    true
)

-- do our model edits when it's safe, on first_tick!
cm:add_first_tick_callback(function()
    -- if the first setting is set to true ...
    if settings.do_thing_one then
        -- trigger a function for "do thing one", if it's set as true through MCT
    end

    -- ditto ...
    if settings.do_thing_two then
        -- ditto
    end
end)
```

Using the above should be enough for most mods. I recommend, if you don't want the settings to be changed mid-campaign, to use @{mct_option:set_read_only} after reading the finalized settings and then responding to them. That way, the user won't be able to edit the settings through MCT, only read them through the UI.

If you want settings changeable mid-campaign, there is one more listener provided for ease-of-use:

```lua
core:add_listener(
    "bloop",
    "MctOptionSettingFinalized",
    true,
    function(context)
        local mct = context:mct()
        local mct_mod = context:mod()
        local mct_option = context:option()
        local new_settings = context:setting()
    end,
    true
)
```

This event triggers any time an editable option (not-read-only) is changed through the "Finalize Settings" dialogue within MCT. That allows you to give users way more flexibility within a campaign, if you want that flexibility!

## Further Updates

As said - this is an early beta, releasing in the state so I can start getting feedback, requests, usage and the like. The program is mostly functional, but there may be bugs, unexpected responses, small things like that. I would very much like to get feedback on how it feels, how it works, and if there's anything I can do to help you make a better mod. If you have specific requests, reach out to me in the C&C Modding Den, in #just_vandy_things.

I have a lot of updates planned for this, but it's currently in a workable enough condition to be fine now.
- Work on better UX if you haven't pressed "Finalized Settings", or if you haven't used MCT in the frontend before loading a new campaign.
- Incorporate the new option types - sliders, text input, and multi-buttons (ie. four buttons in a row, give AND|OR operations to them, etc)
- Incorporate a "preset" type of option, which changes the setting for other options based on its setting. Y'know, a preset
- Multiplayer compatibility.
- 
project = 'MCT'
title='Mod Configuration Tool'
description='The full API for the Mod Configuration Tool, for use by modders giving their stuff some fun editablility.'
file = {'script/_lib/mod/mod_configuration_manager.lua', 'script/mct/modules'}
dir = './docs'
not_luadoc = true
no_lua_ref = true

topics = {"manual.md", "changenotes.md"}
custom_tags = { { 'example', hidden=false, title='Example'}}

format = 'markdown'

alias("class", "classmod")
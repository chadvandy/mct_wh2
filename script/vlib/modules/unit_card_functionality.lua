--- TODO figure out some table reading shit, PLEASE.
--- Disable completely for now :(
do return false end

if __game_mode ~= __lib_type_frontend then return false end

local vandy_lib =get_vandy_lib()
-- local utility = vandy_lib:get_utility()

local attributes = require("script/vandy_lib/tables/attributes")
local invalid_usage_flags = require("script/vandy_lib/tables/invalid_usage_flags")
local additional_ui_effects = require("script/vandy_lib/tables/additional_ui_effects")
local unit_ability_types = require("script/vandy_lib/tables/unit_ability_types")
local ui_unit_bullet_point_enums = require("script/vandy_lib/tables/ui_unit_bullet_point_enums")
local ui_unit_groupings = require("script/vandy_lib/tables/ui_unit_groupings")
local unit_ability_source_types = require("script/vandy_lib/tables/unit_ability_source_types")

local unit_card_manager = {} --# assume unit_card_manager: VANDY_UCM

--v function()
function unit_card_manager.init()
    local self = {}
    setmetatable(self, {__index = unit_card_manager})
    --# assume self: VANDY_UCM

    self._unit_cards = {} --: map<string, VANDY_UC>
    self._attributes = attributes
    self._invalid_usage_flags = invalid_usage_flags
    self._additional_ui_effects = additional_ui_effects
    self._unit_ability_types = unit_ability_types
    self._ui_unit_bullet_point_enums = ui_unit_bullet_point_enums
    self._ui_unit_groupings = ui_unit_groupings
    self._unit_ability_source_types = unit_ability_source_types

    self._abilities = {} --: map<string, VANDY_ABILITY>

    core:add_static_object("vandy_unit_card_manager", self)
end

local unit_card_obj = {} --# assume unit_card_obj: VANDY_UC

--v function(manager: VANDY_UCM, unit_key: string, loc_unit_name: string, unit_cat: string, loc_short_desc: string, loc_bullet_points: vector<string>, unit_card_image_path: string, num_models: number, is_large: boolean, upkeep_cost: number, health_total: number, stats: vector<number>, mod_icons: map<string, boolean> | nil) --> VANDY_UC
function unit_card_obj.new(manager, unit_key, loc_unit_name, unit_cat, loc_short_desc, loc_bullet_points, unit_card_image_path, num_models, is_large, upkeep_cost, health_total, stats, mod_icons)
    local self = {}
    setmetatable(self, {__index = unit_card_obj})
    --# assume self: VANDY_UC

    -- house the UC Manager within
    self._manager = manager

    -- used to get this object with the UC Manager
    self._unit_key = unit_key

    -- localisation details
    self._loc_unit_name = loc_unit_name
    self._unit_category = unit_cat
    self._loc_short_desc = loc_short_desc
    self._loc_bullet_points = loc_bullet_points

    -- image details
    self._unit_card_image_path = unit_card_image_path

    -- stats details
    self._num_models = num_models
    self._is_large = is_large
    self._upkeep_cost = upkeep_cost
    self._health_total = health_total
    self._stats = stats 
    self._mod_icons = mod_icons
    self._shield_value = 0 --: number

    self._ws_breakdown = {} --: vector<number>
    self._md_breakdown = {} --: vector<number>

    -- abilities details
    self._siege_attacker = false --: boolean
    self._phys_res = 0 --: number
    self._magic_res = 0 --: number
    self._missile_res = 0 --: number
    self._fire_res = 0 --: number
    self._ward_save = 0 --: number
    self._fire_weakness = 0 --: number

    self._attributes = {} --: vector<string>
    self._abilities = {} --: vector<VANDY_ABILITY>

    -- attached UIC's
    self._land_card_uic = nil --: CA_UIC
    self._land_card_uic_path = "ui/common ui/land_unit_card"

    self._stat_card_uic = nil --: CA_UIC
    self._stat_card_uic_path = "ui/common ui/unit_information"
    self._stat_card_docking_point = "" --: string

    self._uic_on_hover = nil --: CA_UIC


    -- aux. details
    self._highlight_on_hover = false --: boolean

    return self
end

--v method(unit_key: string, loc_unit_name: string, unit_category: string, loc_short_desc: string, loc_bullet_points: vector<string>, unit_card_image_path: string, num_models: number, is_large: boolean, upkeep_cost: number, health_total: number, stats: vector<number>, mod_icons: vector<string> | nil) --> (VANDY_UC | nil)
function unit_card_manager:new_unit_card(unit_key, loc_unit_name, unit_category, loc_short_desc, loc_bullet_points, unit_card_image_path, num_models, is_large, upkeep_cost, health_total, stats, mod_icons)
    --# assume self: VANDY_UCM
    -- check to make sure the passed args are of the right type
    if not          is_string(unit_key)                 then            script_error("[unit_key] expected to be a string, wrong type!")                 return nil end
    if not          is_string(loc_unit_name)            then            script_error("[loc_unit_name] expected to be a string, wrong type!")            return nil end
    if not          is_string(unit_category)            then            script_error("[unit_category] expected to be a string, wrong type!")             return nil end
    if not          is_string(loc_short_desc)           then            script_error("[loc_short_desc] expected to be a string, wrong type!")           return nil end
    if not          is_table(loc_bullet_points)         then            script_error("[loc_bullet_points] expected to be a table, wrong type!")         return nil end
    if not          is_string(unit_card_image_path)     then            script_error("[unit_card_image_path] expected to be a string, wrong type!")     return nil end
    if not          is_number(num_models)               then            script_error("[num_models] expected to be a number, wrong type!")               return nil end
    if not          is_boolean(is_large)                then            script_error("[is_large] expected to be a boolean, wrong type!")                return nil end
    if not          is_number(upkeep_cost)              then            script_error("[upkeep_cost] expected to be a number, wrong type!")              return nil end
    if not          is_number(health_total)             then            script_error("[health_total] expected to be a number, wrong type!")             return nil end
    if not          is_table(stats)                     then            script_error("[stats] expected to be a table, wrong type!")                     return nil end
    if not          is_table(mod_icons) and not is_nil(mod_icons) then  script_error("[mod_icons] expected to be a table or nil, wrong type!")          return nil end

    local icons_table = {} --: map<string, boolean>
    if is_table(mod_icons) then
        for i = 1, #mod_icons do
            icons_table[mod_icons[i]] = true
        end
    end


    -- send the bits to the factory!
    local obj = unit_card_obj.new(self, unit_key, loc_unit_name, unit_category, loc_short_desc, loc_bullet_points, unit_card_image_path, num_models, is_large, upkeep_cost, health_total, stats, icons_table)
    -- save the unit card in the manager
    self._unit_cards[unit_key] = obj
    -- return the new unit card
    return obj

end

----v method(key: string, text: string)
--[[function unit_card_manager:add_additional_ui_effect(key, text)
    --# assume self: VANDY_UCM
    if not          is_string(key)                      then            script_error("[key] expected to be a string, wrong type!")                      return end
    if not          is_string(text)                      then            script_error("[text] expected to be a string, wrong type!")                      return end

    self._additional_ui_effects[key] = text
end]]

--v method(unit_key: string) --> (VANDY_UC | nil)
function unit_card_manager:get_unit_card_with_key(unit_key)
    --# assume self: VANDY_UCM
    -- type error checking!
    if not          is_string(unit_key)             then                script_error("[unit_key] expected to be a string, wrong type!")                 return nil end

    local obj = self._unit_cards[unit_key]

    if not is_nil(obj) then
        return obj
    else
        script_error("Unit card not found, returning nil!")
        return nil
    end
end

local unit_ability = {} --# assume unit_ability: VANDY_ABILITY

--v function(manager: VANDY_UCM, key: string, small_icon: string, localised_name: string, source_key: string, rarity: string, description: string, num_uses: number | false, num_mana: number | false, num_cooldown: number | false, loc_type: string | nil, loc_duration: string | nil, loc_target: string | nil, loc_active_if: string | nil, loc_disabled_if: string | nil, loc_effects: vector<string> | nil) --> VANDY_ABILITY
function unit_ability.new(manager, key, small_icon, localised_name, source_key, rarity, description, num_uses, num_mana, num_cooldown, loc_type, loc_duration, loc_target, loc_active_if, loc_disabled_if, loc_effects)
    local self = {}
    setmetatable(self, {__index = unit_ability})
    --# assume self: VANDY_ABILITY

    self._manager = manager

    ---- Backend details
    self._key = key

    ---- Small Icon UIC details
    self._small_icon = "ui/battle ui/ability_icons/"..small_icon
    self._small_icon_uic = nil --: CA_UIC

    ---- Tooltip UIC details
    self._localised_name = localised_name
    self._source_key = source_key
    self._rarity = rarity
    self._num_uses = num_uses --: number | false
    self._num_mana = num_mana --: number | false
    self._num_cooldown = num_cooldown --: number | false
    self._description = description --: string

    self._loc_type = loc_type --: string | nil
    self._loc_duration = loc_duration --: string | nil
    self._loc_target = loc_target --: string | nil
    self._loc_active_if = loc_active_if --: string | nil
    self._loc_disabled_if = loc_disabled_if --: string | nil
    self._loc_effects = loc_effects --: vector<string> | nil

    self._tooltip_uic = nil --: CA_UIC

    return self
end

--v method(key: string, small_icon: string, localised_name: string, source_key: string, rarity: string, description: string, num_uses: number | false, num_mana: number | false, num_cooldown: number | false, loc_type: string | nil, loc_duration: string | nil, loc_target: string | nil, loc_active_if: string | nil, loc_disabled_if: string | nil, loc_effects: vector<string> | nil) --> VANDY_ABILITY
function unit_card_manager:new_ability(key, small_icon, localised_name, source_key, rarity, description, num_uses, num_mana, num_cooldown, loc_type, loc_duration, loc_target, loc_active_if, loc_disabled_if, loc_effects)
    --# assume self: VANDY_UCM

    local ability = unit_ability.new(self, key, small_icon, localised_name, source_key, rarity, description, num_uses, num_mana, num_cooldown, loc_type, loc_duration, loc_target, loc_active_if, loc_disabled_if, loc_effects)
    self._abilities[key] = ability
    return ability
end

--v method(key: string, text: string, icon: string, tooltip: string)
function unit_card_manager:new_ui_unit_grouping(key, text, icon, tooltip)
    --# assume self: VANDY_UCM

    local entry = {["text"] = text, ["icon"] = icon, ["tooltip"] = tooltip}
    self._ui_unit_groupings[key] = entry
end

--v method(key: string) --> VANDY_ABILITY | nil
function unit_card_manager:get_ability_with_key(key)
    --# assume self: VANDY_UCM

    local ability = self._abilities[key]

    if ability then return ability else return nil end
end

--v method(amount: number)
function unit_card_obj:add_phys_res(amount)
    --# assume self: VANDY_UC

    self._phys_res = amount
end

--v method(amount: number)
function unit_card_obj:add_magic_res(amount)
    --# assume self: VANDY_UC

    self._magic_res = amount
end

--v method(amount: number)
function unit_card_obj:add_missile_res(amount)
    --# assume self: VANDY_UC

    self._missile_res = amount
end

--v method(amount: number)
function unit_card_obj:add_fire_res(amount)
    --# assume self: VANDY_UC

    self._fire_res = amount
end

--v method(amount: number)
function unit_card_obj:add_fire_weakness(amount)
    --# assume self: VANDY_UC

    self._fire_weakness = amount
end

--v method(enable: boolean)
function unit_card_obj:set_siege_attacker(enable)
    --# assume self: VANDY_UC

    self._siege_attacker = not not enable
end

--v method(amount: number)
function unit_card_obj:add_ward_save(amount)
    --# assume self: VANDY_UC

    self._ward_save = amount
end


--v method(amount: number)
function unit_card_obj:add_shield_value(amount)
    --# assume self: VANDY_UC

    self._shield_value = amount
end

--v method(wd: number, ap: number, bvi: number, bvl: number)
function unit_card_obj:add_weapon_strength_breakdown(wd, ap, bvi, bvl)
    --# assume self: VANDY_UC

    wd = wd or 0
    ap = ap or 0
    bvi = bvi or 0
    bvl = bvl or 0

    local entry = {wd, ap, bvi, bvl}

    self._ws_breakdown = entry
end

--v method(unit_key: string, wd: number, ap: number, bvi: number, bvl: number)
function unit_card_manager:add_weapon_strength_breakdown_to_unit(unit_key, wd, ap, bvi, bvl)
    --# assume self: VANDY_UCM

    local obj = self:get_unit_card_with_key(unit_key)
    if obj ~= nil then
        obj:add_weapon_strength_breakdown(wd, ap, bvi, bvl)
    end
end

--v method(md: number, ap: number, eb: number, ebap: number, bvi: number, bvl: number, rl: number)
function unit_card_obj:add_missile_damage_breakdown(md, ap, eb, ebap, bvi, bvl, rl)
    --# assume self: VANDY_UC

    md = md or 0
    ap = ap or 0
    eb = eb or 0
    ebap = ebap or 0
    bvi = bvi or 0
    bvl = bvl or 0
    rl = rl or 0

    local entry = {md, ap, eb, ebap, bvi, bvl, rl}

    self._md_breakdown = entry
end

--v method(key: string)
function unit_card_obj:add_ability_by_key(key)
    --# assume self: VANDY_UC

    local ab = self._manager:get_ability_with_key(key)
    if type(ab) == nil then
        script_error("Tried to add ability by key ["..key.."] but that ability wasn't found - was it added with :new_ability() BEFORE this line?")
        return
    end
    table.insert(self._abilities, ab)
end

--v method(key: string, state: string)
function unit_card_manager:new_ui_unit_bullet_point_enum(key, state)
    --# assume self: VANDY_UCM

    if self._ui_unit_bullet_point_enums[key] ~= nil then
        -- already exists!
        return
    end

    local entry = {["text"] = "unused", ["tooltip"] = "unused", ["state"] = state}

    self._ui_unit_bullet_point_enums[key] = entry

end

--v method(manager: VANDY_UCM, key: string, small_icon: string, localised_name: string, source_name: string, rarity: string, description: string, num_uses: number | false, num_mana: number | false, num_cooldown: number | false, loc_type: string | nil, loc_duration: string | nil, loc_target: string | nil, loc_active_if: string | nil, loc_disabled_if: string | nil, loc_effects: vector<string> | nil) --> VANDY_ABILITY
function unit_card_obj:add_ability(manager, key, small_icon, localised_name, source_name, rarity, description, num_uses, num_mana, num_cooldown, loc_type, loc_duration, loc_target, loc_active_if, loc_disabled_if, loc_effects)
    --# assume self: VANDY_UC
    -- TODO type checking

    local ability = unit_ability.new(manager, key, small_icon, localised_name, source_name, rarity, description, num_uses, num_mana, num_cooldown, loc_type, loc_duration, loc_target, loc_active_if, loc_disabled_if, loc_effects)
    table.insert(self._abilities, ability)
    return ability
end

--v method(key: string)
function unit_card_obj:add_attribute(key)
    --# assume self: VANDY_UC
    local attribute = self._manager._attributes[key]

    if attribute ~= nil then
        table.insert(self._attributes, key)
    end
end

--v method(unit: string, attributes_table: vector<string>)
function unit_card_manager:add_attributes_to_unit(unit, attributes_table)
    --# assume self: VANDY_UCM

    local unit_obj = self._unit_cards[unit]
    
    if type(attributes_table) == "table" and unit_obj ~= nil then
        for i = 1, #attributes_table do
            local attribute_key = attributes_table[i]
            local attribute = self._attributes[attribute_key]
        
            if attribute ~= nil then
                table.insert(unit_obj._attributes, attribute_key)
            end
        end
    end
end

--v method(unit_key: string, ability_key: string)
function unit_card_manager:add_ability_to_unit(unit_key, ability_key)
    --# assume self: VANDY_UCM

    local unit_obj = self._unit_cards[unit_key]

    if unit_obj ~= nil then
        unit_obj:add_ability_by_key(ability_key)
    end
end

--v method(unit_key: string, shield_value: number)
function unit_card_manager:add_shield_value_to_unit(unit_key, shield_value)
    --# assume self: VANDY_UCM

    local unit_obj = self._unit_cards[unit_key]

    if unit_obj ~= nil then
        unit_obj:add_shield_value(shield_value)
    end
end

--v method(unit_key: string, phys_res: number, missile_res: number, magic_res: number, fire_res: number, ward_save: number)
function unit_card_manager:add_resistances_to_unit(unit_key, phys_res, missile_res, magic_res, fire_res, ward_save)
    --# assume self: VANDY_UCM

    local unit_obj = self._unit_cards[unit_key]

    if unit_obj ~= nil then
        if phys_res > 0 then
            unit_obj:add_phys_res(phys_res)
        end
        if missile_res > 0 then
            unit_obj:add_missile_res(missile_res)
        end
        if magic_res > 0 then
            unit_obj:add_magic_res(magic_res)
        end
        if fire_res > 0 or fire_res < 0 then
            unit_obj:add_fire_res(fire_res)
        end
        if ward_save > 0 then
            unit_obj:add_ward_save(ward_save)
        end
    end 
end

--v method(parent: CA_UIC)
function unit_card_obj:create_land_unit_card_for_frontend(parent)
    --# assume self: VANDY_UC
    if not          is_uicomponent(parent)              then            script_error("[parent] expected to be a UIComponent, wrong type!")              return end


    for i = 0, parent:ChildCount() - 1 do
        local child = UIComponent(parent:Find(i))

        if child:Id() == "land_unit_card_"..self._unit_key then
            -- kill it, to prevent bugginess
            delete_component(child)
        end
    end

    -- create the UI Component
    local uic = core:get_or_create_component("land_unit_card_"..self._unit_key, self._land_card_uic_path, parent)

    -- check that it worked
    if not uic then
        script_error("UIC was not able to be made or found!")
        return
    end

    -- save the UI Component in the object
    self._land_card_uic = uic

    -- set the unwanted components on the land unit card invisible
    local health_frame = find_uicomponent(uic, "health_frame")
    health_frame:SetVisible(false)

    local battle_frame = find_uicomponent(uic, "battle")
    battle_frame:SetVisible(false)

    local campaign_frame = find_uicomponent(uic, "campaign")
    campaign_frame:SetVisible(false)

    -- set the unit card image
    uic:SetImagePath("ui/units/icons/" .. self._unit_card_image_path)
    
    -- remove the highlight on hover image
    uic:SetImagePath("ui/vandy_lib/unit_card_blank_smol.png", 4)

    -- set the unit category icon
    local unit_cat_uic = find_uicomponent(uic, "unit_cat_frame", "unit_category_icon")
    local unit_cat = self._manager._ui_unit_groupings[self._unit_category]
    unit_cat_uic:SetImagePath("ui/common ui/unit_category_icons/" .. unit_cat["icon"] .. ".png")

    -- TODO confirm this is the same regardless of resolution
    -- resize for the frontend size (50, 110)
    uic:Resize(50, 110)

end

-- placeholder for later
----v method(parent: CA_UIC)
--[[function unit_card_obj:create_land_unit_card_for_campaign(parent)
    --# assume self: VANDY_UC


end
--]]

--v method()
--@ function testing
function unit_card_obj:create_stat_unit_card_for_frontend()
    --# assume self: VANDY_UC

    local root = core:get_ui_root()
    for i = 0, root:ChildCount() - 1 do
        local child = UIComponent(root:Find(i))

        if child:Id() == "stat_unit_card_"..self._unit_key then
            -- kill it, to prevent bugginess
            delete_component(child)
        end
    end

    local stat_card_uic = core:get_or_create_component("stat_unit_card_"..self._unit_key, self._stat_card_uic_path, root)

    if not stat_card_uic then
        script_error("UIC was not able to be made or found!")
        return
    end

    --print_all_uicomponent_children(stat_card_uic)

    self._stat_card_uic = stat_card_uic
    local land_card_uic = self._land_card_uic

    --[[ SAVING FOR LATER
    local x_off = 0 --: number
    local y_off = 0 --: number
    local docking_point = self._stat_card_docking_point
    if docking_point == "bottom_left" then
        y_off = stat_card_uic:Height() * -1
    elseif docking_point == "top_right" then
        x_off = stat_card_uic:Width()
    elseif docking_point == "bottom_right" then
        y_off = stat_card_uic:Height() * -1
        x_off = stat_card_uic:Width()
    end]]

    -- simple algebra to get the bottom-left corner of the stat card to be touching the right-center of the land card
    local x, y = land_card_uic:Position() 
    local w, h = land_card_uic:Bounds()
    x = x + w
    y = y + (h/2)
    y = y + stat_card_uic:Height() * -1

    stat_card_uic:MoveTo(x, y)

    -- hide needless UIC's, until someone begs for them to be implemented. plz don't beg.
    local kill_1 = find_uicomponent(stat_card_uic, "dy_food")
    local kill_2 = find_uicomponent(stat_card_uic, "details", "health_and_stats_parent", "health_parent", "health_frame", "health_bar", "label_compare")
    local kill_3 = find_uicomponent(stat_card_uic, "top_section", "bret_peasant_icon")
    local kill_4 = find_uicomponent(stat_card_uic, "details", "top_bar", "upkeep_cost")
    local kill_5 = find_uicomponent(stat_card_uic, "details", "top_bar", "experience_parent")
    kill_1:SetVisible(false) kill_2:SetVisible(false) kill_3:SetVisible(false) kill_4:SetVisible(false) kill_5:SetVisible(false)

    -- set various different localisations, should be self-evident
    local unit_name_text = find_uicomponent(stat_card_uic, "top_section", "tx_unit-type")
    unit_name_text:SetStateText(effect.get_localised_string(self._loc_unit_name))


    local unit_cat_text = find_uicomponent(stat_card_uic, "top_section", "custom_name_display")
    local uc = self._manager._ui_unit_groupings[self._unit_category]

    unit_cat_text:SetStateText(uc["text"])
    unit_cat_text:SetTooltipText(uc["tooltip"], true)

    local unit_short_desc_text = find_uicomponent(stat_card_uic, "short_description")
    unit_short_desc_text:SetStateText(effect.get_localised_string(self._loc_short_desc))


    local unit_bullet_point_parent = find_uicomponent(stat_card_uic, "bullet_point_parent")

    for i = 1, #self._loc_bullet_points do
        local key = self._loc_bullet_points[i]
        local bullet_point = self._manager._ui_unit_bullet_point_enums[key]

        local text = "ui_unit_bullet_point_enums_onscreen_name_" .. key
        local tooltip = "ui_unit_bullet_point_enums_tooltip_" .. key
        local state = bullet_point["state"]

        local state_conversion = {
            ["positive"] = "[[col:dark_g]][[img:ui/skins/default/arrow_increase_1.png]][[/img]]",
            ["negative"] = "[[col:dark_r]][[img:ui/skins/default/arrow_decrease_1.png]][[/img]]",
            ["very_positive"] = "[[col:dark_g]][[img:ui/skins/default/arrow_increase_2.png]][[/img]]",
            ["very_negative"] = "[[col:dark_r]][[img:ui/skins/default/arrow_decrease_2.png]][[/img]]",
        }--: map<string, string>


        local header = state_conversion[state]

        local bullet_point_uic = core:get_or_create_component("bullet_point_"..i, "ui/vandy_lib/black_text", unit_bullet_point_parent)
        unit_bullet_point_parent:Adopt(bullet_point_uic:Address())

        bullet_point_uic:SetStateText(header .. effect.get_localised_string(text) .. "[[/col]]")
        bullet_point_uic:SetTooltipText(effect.get_localised_string(tooltip), true)

    end

    local unit_cat_icon = find_uicomponent(unit_cat_text, "unit_cat_frame", "unit_category_icon")
    local icon = self._manager._ui_unit_groupings[self._unit_category]["icon"]
    unit_cat_icon:SetImagePath("ui/common ui/unit_category_icons/" .. icon .. ".png")


    local unit_num_models_text = find_uicomponent(stat_card_uic, "top_bar", "dy_men")

    if self._is_large then
        unit_num_models_text:SetState("large")
    else
        unit_num_models_text:SetState("small")
    end



    unit_num_models_text:SetStateText(tostring(self._num_models))

    local unit_upkeep_cost_text = find_uicomponent(stat_card_uic, "top_bar", "upkeep_cost", "dy_value")
    unit_upkeep_cost_text:SetStateText(tostring(self._upkeep_cost))

    local unit_health = find_uicomponent(stat_card_uic, "details", "health_and_stats_parent", "health_parent", "health_frame")

    local health_bar = find_uicomponent(unit_health, "health_bar")
    health_bar:SetTooltipText("[[img:icon_hp]][[/img]] Hit Points: " .. self._health_total .. "/" .. self._health_total, true)

    local unit_health_amount_text = find_uicomponent(stat_card_uic, "details", "health_and_stats_parent", "health_parent", "health_frame", "hit_points")
    unit_health_amount_text:SetStateText(tostring(self._health_total))


    --unit_health_amount_text:SetTooltipText("")

    -- simple way to convert the stat vector to the stat text needed
    local stat_conversion = {
        [1] = "Armour",
        [2] = "Leadership",
        [3] = "Speed",
        [4] = "Melee Attack",
        [5] = "Melee Defence",
        [6] = "Weapon Strength",
        [7] = "Charge Bonus",
        [8] = "Ammunition",
        [9] = "Range",
        [10] = "Missile Damage"
    } --: map < number, string >

    -- simple way to convert the stat vector to the stat icon needed
    local icon_conversion = {
        [1] = "ui/skins/default/icon_stat_armour.png", 
        [2] = "ui/skins/default/icon_stat_morale.png", 
        [3] = "ui/skins/default/icon_stat_speed.png",
        [4] = "ui/skins/default/icon_stat_attack.png",
        [5] = "ui/skins/default/icon_stat_defence.png",
        [6] = "ui/skins/default/icon_stat_damage.png",
        [7] = "ui/skins/default/icon_stat_charge_bonus.png",
        [8] = "ui/skins/default/icon_stat_ammo.png",
        [9] = "ui/skins/default/icon_stat_range.png",
        [10] = "ui/skins/default/icon_stat_ranged_damage.png"
    } --: map < number, string >

    -- set the max value of a stat (for UI bars)
    local bar_conversion = {
        [1] = 180,
        [2] = 120,
        [3] = 140,
        [4] = 100,
        [5] = 100,
        [6] = 100,
        [7] = 100,
        [8] = 100,
        [9] = 200,
        [10] = 350
    } --: map < number, number >

    -- set the tooltips for a stat
    local tooltip_conversion = {
        [1] = "How resistant a unit is to missile fire and melee attacks.",
        [2] = "A unit with high leadership is less likely to rout in the face of danger.||Leadership is improved by experience in battle.",
        [3] = "This is how fast a unit moves.",
        [4] = "This determines the chance of a successful hit on the enemy when the unit is engaged in melee.||Battle-hardened troops will gain experience through melee, improving this skill.",
        [5] = "This determines the chance of a unit being hit whilst in melee.||This only works in melee and provides no protection from missiles!",
        [6] = "The damage caused by a unit's weapon, split between base and armour piercing.||Armour-piercing damage is always applied; base damage can be blocked by armour.",
        [7] = "This increases a unit's melee attack and damage when charging.",
        [8] = "The amount of ammunition this unit can carry into battle.||Once this has been exhausted the unit will be forced to switch to melee to continue fighting.||After the battle, ammunition is fully replenished.",
        [9] = "A long range enables you to hit enemies from a distance, but weapons are still more accurate at shorter ranges.",
        [10] = "The damage caused by a missile attack, split between base and armour piercing.||Armour-piercing damage is always applied, base damage can be blocked by armour."
    } --: map < number, string >

    -- loop through and create all the new stats!
    local stats_parent = find_uicomponent(stat_card_uic, "details", "health_and_stats_parent", "dynamic_stats")

    local extant_stat = find_uicomponent(stats_parent, "stat1")
    local steve, dave = extant_stat:Position()
    extant_stat:SetVisible(false)

    for i = 1, #self._stats do
        local stat_copy = core:get_or_create_component("stat_"..i, self._stat_card_uic_path, root)
        local stat = find_uicomponent(stat_copy, "details", "health_and_stats_parent", "dynamic_stats", "stat1")
        stats_parent:Adopt(stat:Address())
        delete_component(stat_copy)
    
        stat:MoveTo(steve, dave)

        dave = dave + stat:Height()

        -- get the necessary UI elements for the stat bar
        local bar = find_uicomponent(stat, "bar_frame")
        local bar_mod = find_uicomponent(bar, "bar_mod")
        local bar_base = find_uicomponent(bar, "bar_base")

        bar:SetTooltipText("fuck", true)

        -- resize the width, since the UI template has it started at half
        bar_mod:SetCanResizeHeight(true)
        bar_mod:SetCanResizeWidth(true)
        bar_mod:Resize(bar_mod:Width() * 2, bar_mod:Height())
        bar_mod:SetCanResizeHeight(false)
        bar_mod:SetCanResizeWidth(false)

        -- get necessary coordinates
        local bar_start, _ = bar:Position()
        local bar_width = bar:Width()
        local bar_end = bar_start + bar_width

        -- at this value, the bar should be full
        local max_val = bar_conversion[i]

        -- value of this stat
        local stat_val = self._stats[i]

        -- prevent the bar from going past the border
        if stat_val > max_val then stat_val = max_val end
        local percent = stat_val / max_val

        local width = bar_width * percent

        bar_mod:SetCanResizeHeight(true)
        bar_mod:SetCanResizeWidth(true)
        bar_mod:Resize(width, bar_mod:Height())
        bar_mod:SetCanResizeHeight(false)
        bar_mod:SetCanResizeWidth(false)

        bar_base:SetCanResizeHeight(true)
        bar_base:SetCanResizeWidth(true)
        bar_base:Resize(width, bar_base:Height())
        bar_base:SetCanResizeHeight(false)
        bar_base:SetCanResizeWidth(false)

        -- prevent the weird UI bug from a value 0 stat
        if stat_val == 0 then
            bar_mod:SetVisible(false)
            bar_base:SetVisible(false)
        end

        -- add icons next to the value, if any are applicable
        local icon_holder = find_uicomponent(stat, "dy_value", "mod_icon_holder", "mod_icon_list")

        local mod_icons = self._mod_icons
        if i == 1 then
            -- add armour icons, if any
            if mod_icons["shielded"] and self._shield_value > 0 then
                local mod_icon = core:get_or_create_component("modifier_icon_tooltip_shield", "ui/vandy_lib/custom_image")
                icon_holder:Adopt(mod_icon:Address())

                mod_icon:SetState("custom_state_1")
                mod_icon:SetImagePath("ui/skins/default/modifier_icon_shield.png")
                mod_icon:SetInteractive(true)
                mod_icon:SetTooltipText("Shielded||This unit has a shield and will block ".. tostring(self._shield_value) .. "% of all small-arms missile fire hitting it from the front.", true)

                mod_icon:SetCanResizeHeight(true)
                mod_icon:SetCanResizeWidth(true)
                mod_icon:Resize(16, 16)
                mod_icon:SetCanResizeHeight(false)
                mod_icon:SetCanResizeWidth(false)
            end
        elseif i == 4 then
            -- add MA icons, if any
            if mod_icons["ma_flaming"] then
                local mod_icon = core:get_or_create_component("modifier_icon_tooltip_flaming", "ui/vandy_lib/custom_image")
                icon_holder:Adopt(mod_icon:Address())

                mod_icon:SetState("custom_state_1")
                mod_icon:SetImagePath("ui/skins/default/modifier_icon_flaming.png")
                mod_icon:SetInteractive(true)
                mod_icon:SetTooltipText("Flaming Attacks||This unit inflicts flaming attacks which can do additional damage against units that are vulnerable to fire.", true)

                mod_icon:SetCanResizeHeight(true)
                mod_icon:SetCanResizeWidth(true)
                mod_icon:Resize(16, 16)
                mod_icon:SetCanResizeHeight(false)
                mod_icon:SetCanResizeWidth(false)
            end
            if mod_icons["ma_magical"] then
                local mod_icon = core:get_or_create_component("modifier_icon_tooltip_magical", "ui/vandy_lib/custom_image")
                icon_holder:Adopt(mod_icon:Address())

                mod_icon:SetState("custom_state_1")
                mod_icon:SetImagePath("ui/skins/default/modifier_icon_magical.png")
                mod_icon:SetInteractive(true)
                mod_icon:SetTooltipText("Magical Attacks||This unit inflicts magical attacks which can harm units that are protected from regular physical attacks.", true)

                mod_icon:SetCanResizeHeight(true)
                mod_icon:SetCanResizeWidth(true)
                mod_icon:Resize(16, 16)
                mod_icon:SetCanResizeHeight(false)
                mod_icon:SetCanResizeWidth(false)
            end
        elseif i == 6 then
            -- add WS icons, if any
            if mod_icons["ws_bvsl"] then
                local mod_icon = core:get_or_create_component("modifier_icon_tooltip_bonus_vs_large", "ui/vandy_lib/custom_image")
                icon_holder:Adopt(mod_icon:Address())

                mod_icon:SetState("custom_state_1")
                mod_icon:SetImagePath("ui/skins/default/modifier_icon_bonus_vs_large.png")
                mod_icon:SetInteractive(true)
                mod_icon:SetTooltipText("Bonus vs. Large||This unit inflicts additional damage and has an increased chance of hitting enemies that are cavalry-sized or larger.", true)

                mod_icon:SetCanResizeHeight(true)
                mod_icon:SetCanResizeWidth(true)
                mod_icon:Resize(16, 16)
                mod_icon:SetCanResizeHeight(false)
                mod_icon:SetCanResizeWidth(false)
            end
            if mod_icons["ws_bvsi"] then
                local mod_icon = core:get_or_create_component("modifier_icon_tooltip_bonus_vs_infantry", "ui/vandy_lib/custom_image")
                icon_holder:Adopt(mod_icon:Address())

                mod_icon:SetState("custom_state_1")
                mod_icon:SetImagePath("ui/skins/default/modifier_icon_bonus_vs_infantry.png")
                mod_icon:SetInteractive(true)
                mod_icon:SetTooltipText("Bonus vs. Infantry||This unit inflicts additional damage and has an increased chance of a hit when fighting enemies that are man-sized or smaller.", true)

                mod_icon:SetCanResizeHeight(true)
                mod_icon:SetCanResizeWidth(true)
                mod_icon:Resize(16, 16)
                mod_icon:SetCanResizeHeight(false)
                mod_icon:SetCanResizeWidth(false)
            end
            if mod_icons["ws_ap"] then
                local mod_icon = core:get_or_create_component("modifier_icon_tooltip_armour_piercing", "ui/vandy_lib/custom_image")
                icon_holder:Adopt(mod_icon:Address())

                mod_icon:SetState("custom_state_1")
                mod_icon:SetImagePath("ui/skins/default/modifier_icon_armour_piercing.png")
                mod_icon:SetInteractive(true)
                mod_icon:SetTooltipText("Armour Piercing||The damage of armour-piercing weapons mostly ignores the target's armour, making them the ideal choice against heavily-armoured enemies. They often inflict less damage in total though, making them less efficient against weakly armoured targets.", true)

                mod_icon:SetCanResizeHeight(true)
                mod_icon:SetCanResizeWidth(true)
                mod_icon:Resize(16, 16)
                mod_icon:SetCanResizeHeight(false)
                mod_icon:SetCanResizeWidth(false)
            end
        elseif i == 8 then
            -- add ammo icons, if any
            if mod_icons["ammo_bvsl"] then
                local mod_icon = core:get_or_create_component("modifier_icon_tooltip_bonus_vs_large", "ui/vandy_lib/custom_image")
                icon_holder:Adopt(mod_icon:Address())

                mod_icon:SetState("custom_state_1")
                mod_icon:SetImagePath("ui/skins/default/modifier_icon_bonus_vs_large.png")
                mod_icon:SetInteractive(true)
                mod_icon:SetTooltipText("Bonus vs. Large||This unit inflicts additional damage and has an increased chance of hitting enemies that are cavalry-sized or larger.", true)

                mod_icon:SetCanResizeHeight(true)
                mod_icon:SetCanResizeWidth(true)
                mod_icon:Resize(16, 16)
                mod_icon:SetCanResizeHeight(false)
                mod_icon:SetCanResizeWidth(false)
            end
            if mod_icons["ammo_bvsi"] then
                local mod_icon = core:get_or_create_component("modifier_icon_tooltip_bonus_vs_infantry", "ui/vandy_lib/custom_image")
                icon_holder:Adopt(mod_icon:Address())

                mod_icon:SetState("custom_state_1")
                mod_icon:SetImagePath("ui/skins/default/modifier_icon_bonus_vs_infantry.png")
                mod_icon:SetInteractive(true)
                mod_icon:SetTooltipText("Bonus vs. Infantry||This unit inflicts additional damage and has an increased chance of a hit when fighting enemies that are man-sized or smaller.", true)

                mod_icon:SetCanResizeHeight(true)
                mod_icon:SetCanResizeWidth(true)
                mod_icon:Resize(16, 16)
                mod_icon:SetCanResizeHeight(false)
                mod_icon:SetCanResizeWidth(false)
            end
        elseif i == 10 then
            if mod_icons["mis_ap"] then
                local mod_icon = core:get_or_create_component("modifier_icon_tooltip_armour_piercing", "ui/vandy_lib/custom_image")
                icon_holder:Adopt(mod_icon:Address())

                mod_icon:SetState("custom_state_1")
                mod_icon:SetImagePath("ui/skins/default/modifier_icon_armour_piercing_ranged.png")
                mod_icon:SetInteractive(true)
                mod_icon:SetTooltipText("Armour Piercing||The damage of armour-piercing weapons mostly ignores the target's armour, making them the ideal choice against heavily-armoured enemies. They often inflict less damage in total though, making them less efficient against weakly armoured targets.", true)

                mod_icon:SetCanResizeHeight(true)
                mod_icon:SetCanResizeWidth(true)
                mod_icon:Resize(16, 16)
                mod_icon:SetCanResizeHeight(false)
                mod_icon:SetCanResizeWidth(false)
            end
        end

        -- get the necessary UI elements for the stuff
        local stat_icon = find_uicomponent(stat, "icon")
        local stat_name = find_uicomponent(stat, "stat_name")
        local stat_value = find_uicomponent(stat, "dy_value")

        -- hide the compare UIC's
        find_uicomponent(stat, "bar_frame", "icon_compare"):SetVisible(false)
        find_uicomponent(stat, "bar_frame", "label_compare"):SetVisible(false)

        local key = stat_conversion[i]
        local icon = icon_conversion[i]
        local tt = tooltip_conversion[i]

        if i == 6 then
            -- check for weapon damage breakdown
            local breakdown = self._ws_breakdown

            -- md, ap, bvi, bvl
            tt = tt .. "\n\n [[img:icon_weapon_damage]][[/img]] Weapon Damage: " .. tostring(breakdown[1])

            if breakdown[2] > 0 then
                tt = tt .. "\n [[img:icon_ap]][[/img]] Armour-Piercing Damage: " .. tostring(breakdown[2])
            end

            if breakdown[3] > 0 then
                tt = tt .. "\n [[img:ui/skins/default/modifier_icon_bonus_vs_infantry.png]][[/img]] Bonus vs. Infantry: " .. tostring(breakdown[3])
            end

            if breakdown[4] > 0 then
                tt = tt .. "\n [[img:ui/skins/default/modifier_icon_bonus_vs_large.png]][[/img]] Bonus vs. Large: " .. tostring(breakdown[4])
            end

        elseif i == 10 then 
            -- check for missile damage breakdown
            local breakdown = self._md_breakdown

            -- md, ap, explosive base, explosive ap, bvi, bvl, reload
            tt = tt .. "\n\n [[img:ui/skins/default/icon_stat_ranged_damage.png]][[/img]] Missile Damage: " .. tostring(breakdown[1])

            if breakdown[2] > 0 then
                tt = tt .. "\n [[img:icon_ap_ranged]][[/img]] Armour-Piercing Missile Damage: " .. tostring(breakdown[2])
            end

            if breakdown[3] > 0 then
                tt = tt .. "\n Explosive base damage: " .. tostring(breakdown[3])
            end

            if breakdown[4] > 0 then
                tt = tt .. "\n [[img:icon_ap]][[/img]] Explosive armour-piercing damage: " .. tostring(breakdown[4])
            end

            if breakdown[5] > 0 then
                tt = tt .. "\n [[img:ui/skins/default/modifier_icon_bonus_vs_infantry.png]][[/img]] Bonus vs. Infantry: " .. tostring(breakdown[5])
            end

            if breakdown[6] > 0 then
                tt = tt .. "\n [[img:ui/skins/default/modifier_icon_bonus_vs_large.png]][[/img]] Bonus vs. Large: " .. tostring(breakdown[6])
            end

            if breakdown[7] > 0 then
                tt = tt .. "\n Reload time: " .. tostring(breakdown[7]) .. " seconds"
            end

            tt = tt .. "\n\n Damage value shown is damage over 10 seconds"
        end

        stat_name:SetStateText(key)
        stat_icon:SetImagePath(icon)
        stat_value:SetStateText(tostring(self._stats[i]))
        stat:SetTooltipText(tt, true)
    end

    local abilities_parent = find_uicomponent(stat_card_uic, "ability_list")

    --v function(key: string, icon: string, tooltip: string)
    local function create_new_icon(key, icon, tooltip)
        local uic = core:get_or_create_component(key, "ui/vandy_lib/custom_image", abilities_parent)

        abilities_parent:Adopt(uic:Address())
        uic:SetState("custom_state_1")
        uic:SetInteractive(true)
        uic:SetImagePath("ui/battle ui/ability_icons/" .. icon .. ".png")

        uic:SetCanResizeWidth(true)
        uic:SetCanResizeHeight(true)
        uic:Resize(28, 28)
        uic:SetCanResizeWidth(false)
        uic:SetCanResizeHeight(false)  

        uic:SetTooltipText(tooltip, true)
    end

    if self._siege_attacker then
        create_new_icon("siege_attacker", "can_siege", "Siege Attacker||This unit can attack city gates, allowing you to instantly launch a siege battle without having to wait for towers or battering rams to be built.")
    end

    if self._phys_res > 0 then
        create_new_icon("physical_res", "resistance_physical", "Physical Resistance: " .. tostring(self._phys_res) .. "%||Damage of non-magical attacks is reduced by this amount.")
    end

    if self._missile_res > 0 then
        create_new_icon("missile_res", "resistance_missile", "Missile Resistance: " .. tostring(self._missile_res) .. "%||Damage of missile attacks is reduced by this amount.")
    end

    if self._magic_res > 0 then
        create_new_icon("magic_res", "resistance_magic", "Magic Resistance: " .. tostring(self._magic_res) .. "%||Damage of [[img:ui/skins/default/modifier_icon_magical.png]][[/img]]magical attacks is reduced by this amount.")
    end

    if self._fire_res > 0 then
        create_new_icon("fire_res", "resistance_fire", "Fire Resistance: " .. tostring(self._fire_res) .. "%||Damage of [[img:ui/skins/default/modifier_icon_flaming.png]][[/img]]flaming attacks is reduced by this amount.")
    elseif self._fire_res < 0 then
        create_new_icon("fire_weakness", "weakness_fire", "[[col:red]]Fire Weakness: " .. tostring(self._fire_weakness) .. "%||Damage of [[img:ui/skins/default/modifier_icon_flaming.png]][[/img]]flaming attacks is increased by this amount.[[/col]]")
    end

    if self._ward_save > 0 then
        create_new_icon("ward_save", "resistance_ward_save", "Ward Save: " .. tostring(self._ward_save) .. "%||Any type of damage is reduced by this amount.")
    end

    -- first comes attributes 
    for i = 1, #self._attributes do
        local attribute_key = self._attributes[i]
        local attribute_text = self._manager._attributes[attribute_key]

        local attribute_uic = core:get_or_create_component(attribute_key, "ui/vandy_lib/custom_image", abilities_parent)

        abilities_parent:Adopt(attribute_uic:Address())
        attribute_uic:SetState("custom_state_1")
        attribute_uic:SetInteractive(true)
        attribute_uic:SetImagePath("ui/battle ui/ability_icons/" .. attribute_key .. ".png")

        attribute_uic:SetCanResizeWidth(true)
        attribute_uic:SetCanResizeHeight(true)
        attribute_uic:Resize(28, 28)
        attribute_uic:SetCanResizeWidth(false)
        attribute_uic:SetCanResizeHeight(false)  

        attribute_uic:SetTooltipText(attribute_text, true)
    end

    -- then comes abilities!
    for i = 1, #self._abilities do
        -- stuff
        local ability = self._abilities[i]
        local ability_uic = core:get_or_create_component(ability._key, "ui/vandy_lib/custom_image", abilities_parent)

        abilities_parent:Adopt(ability_uic:Address())
        ability_uic:SetState("custom_state_1")
        ability_uic:SetInteractive(true)
        ability_uic:SetImagePath(ability._small_icon)
        --ability_uic:PropagatePriority(find_uicomponent(stat_card_uic, "parchment"):Priority())

        ability_uic:SetCanResizeWidth(true)
        ability_uic:SetCanResizeHeight(true)
        ability_uic:Resize(28, 28) 
        ability_uic:SetCanResizeWidth(false)
        ability_uic:SetCanResizeHeight(false)        

        local function create_tooltip()
            local tooltip = core:get_or_create_component(ability._key .. "_tooltip", "ui/common ui/special_ability_tooltip")

            local top_parent = find_uicomponent(tooltip, "background", "top_parent")
            
            local source_parent = find_uicomponent(tooltip, "background", "source_parent")
            source_parent:SetState(ability._rarity)

            local title_tier = find_uicomponent(top_parent, "title_tier")
            title_tier:SetState(ability._rarity)

            local title_uic = find_uicomponent(top_parent, "name")
            title_uic:SetStateText(effect.get_localised_string(ability._localised_name))

            local source_name = ability._manager._unit_ability_source_types[ability._source_key]["name"]

            local source_uic = find_uicomponent(source_parent, "source_name")
            source_uic:SetStateText(source_name)


            do
                local top_right_parent = find_uicomponent(tooltip, "background", "top_parent", "top_right_parent")
                local uses_uic = find_uicomponent(top_right_parent, "uses")
                if ability._num_uses == false then 
                    uses_uic:SetVisible(false)
                else
                    uses_uic:SetStateText(tostring(ability._num_uses))
                end

                local mana_uic = find_uicomponent(top_right_parent, "mana")
                if ability._num_mana == false then
                    mana_uic:SetVisible(false)
                else
                    mana_uic:SetStateText(tostring(ability._num_mana))
                end

                local cooldown_uic = find_uicomponent(top_right_parent, "cooldown")
                if ability._num_cooldown == false then
                    cooldown_uic:SetVisible(false)
                else
                    cooldown_uic:SetStateText(tostring(ability._num_cooldown))
                end
            end

            do
                local tm = get_tm()
                tm:callback(function()
                    local effect_list = find_uicomponent(tooltip, "background", "effect_list")

                    local thing = find_uicomponent(tooltip, "background", "source_parent")
                    local tx, ty = thing:Position()
                    local tw, th = thing:Bounds()

                    local all_uics = {}

                    local effects_title
                    local effects = {}

                    local top_left_corner_x = tx
                    local top_left_corner_y = ty + th
                    local gap_h = 0
                    local gap_w = 5

                    if type(ability._loc_type) == "string" and ability._loc_type ~= "" then
                        local main_uic = core:get_or_create_component(ability._key.."_type", "ui/common ui/template_effect_entry", effect_list)
                        effect_list:Adopt(main_uic:Address())

                        local title_text = find_uicomponent(main_uic, "entry_title")
                        local description_text = find_uicomponent(main_uic, "entry_description")
                        
                        title_text:SetVisible(true)
                        title_text:SetStateText("Type:")

                        description_text:SetState("neutral")
                        local text = self._manager._unit_ability_types[ability._loc_type]
                        if text then
                            description_text:SetStateText(text)
                        else
                            description_text:SetStateText("Something went wrong!")
                        end
                    end

                    if type(ability._loc_duration) == "string" and ability._loc_duration ~= "" then
                        local main_uic = core:get_or_create_component(ability._key.."_duration", "ui/common ui/template_effect_entry", effect_list)
                        effect_list:Adopt(main_uic:Address())

                        local title_text = find_uicomponent(main_uic, "entry_title")
                        local description_text = find_uicomponent(main_uic, "entry_description")
                        
                        title_text:SetVisible(true)
                        title_text:SetStateText("Duration:")

                        description_text:SetState("neutral")
                        description_text:SetStateText(ability._loc_duration)
                    end

                    if type(ability._loc_target) == "string" and ability._loc_target ~= "" then
                        local main_uic = core:get_or_create_component(ability._key.."_target", "ui/common ui/template_effect_entry", effect_list)
                        effect_list:Adopt(main_uic:Address())

                        local title_text = find_uicomponent(main_uic, "entry_title")
                        local description_text = find_uicomponent(main_uic, "entry_description")
                        
                        title_text:SetVisible(true)
                        title_text:SetStateText("Target:")

                        description_text:SetState("neutral")
                        description_text:SetStateText(ability._loc_target)
                    end

                    if type(ability._loc_active_if) == "string" and ability._loc_active_if ~= "" then
                        local main_uic = core:get_or_create_component(ability._key.."_active_if", "ui/common ui/template_effect_entry", effect_list)
                        effect_list:Adopt(main_uic:Address())

                        local title_text = find_uicomponent(main_uic, "entry_title")
                        local description_text = find_uicomponent(main_uic, "entry_description")
                        
                        title_text:SetVisible(true)
                        title_text:SetStateText("Active if:")

                        description_text:SetState("neutral")
                        description_text:SetStateText(ability._loc_active_if)
                    end

                    if type(ability._loc_disabled_if) == "string" and ability._loc_disabled_if ~= "" then
                        local main_uic = core:get_or_create_component(ability._key.."_disabled_if", "ui/common ui/template_effect_entry", effect_list)
                        effect_list:Adopt(main_uic:Address())

                        local title_text = find_uicomponent(main_uic, "entry_title")
                        local description_text = find_uicomponent(main_uic, "entry_description")
                        
                        title_text:SetVisible(true)
                        title_text:SetStateText("Disabled if:")

                        description_text:SetState("neutral")
                        description_text:SetStateText(ability._loc_disabled_if)
                    end

                    if type(ability._loc_effects) == "table" then
                        local e_num = 1
                        for i = 1, #ability._loc_effects do
                            local effect = ability._loc_effects[i]
                            local effect_uic = core:get_or_create_component(ability._key .. "_effect".. e_num, "ui/common ui/template_effect_entry", effect_list)
                            effect_list:Adopt(effect_uic:Address())
        
                            local title_text = find_uicomponent(effect_uic, "entry_title")
                            local description_text = find_uicomponent(effect_uic, "entry_description")

                            title_text:SetVisible(true)

                            if e_num == 1 then
                                title_text:SetStateText("Effects:")
                            else
                                title_text:SetStateText("")
                            end

                            --description_text:SetState(state)
                            local text = self._manager._additional_ui_effects[effect]
                            if not text then
                                -- if it's not an additional ui effect key, then keep it like it was
                                text = effect 
                            end
                            description_text:SetStateText(text)

                            e_num = e_num + 1
                        end

                    end
                end, 10)
            end


            local description_uic = find_uicomponent(tooltip, "background", "description")
            description_uic:SetStateText(effect.get_localised_string(ability._description))

            local instruction_parent = find_uicomponent(tooltip, "instruction_parent")
            instruction_parent:SetVisible(false)
                    

            ability._tooltip_uic = tooltip
            
            return tooltip

        end
	
        core:add_listener(
            "on_hover_"..ability._key.."_tooltip",
            "ComponentMouseOn",
            function(context)
                return UIComponent(context.component) == ability_uic
            end,
            function(context)
                local tooltip = ability._tooltip_uic
                if not tooltip then
                    tooltip = create_tooltip()
                end
                if tooltip and not tooltip:Visible() then tooltip:SetVisible(true) end
                --print_all_uicomponent_children(tooltip)
            end,
            true
        )

        core:add_listener(
            "kill_"..ability._key.."_tooltip",
            "ComponentMouseOn",
            function(context)
                return UIComponent(context.component) ~= ability_uic
            end,
            function(context)
                local tooltip = ability._tooltip_uic
                if tooltip and tooltip:Visible() then tooltip:SetVisible(false) end
            end,
            true
        )
    end	
end

--core:add_listener("testing", "ComponentMouseOn", function(context) return context.string == "unit_ability_icon5" end, function(context) local uic = UIComponent(context.component) local timer_obj = get_tm() timer_obj:callback(function() print_all_uicomponent_children(core:get_ui_root()) end, 5000) end, true)

--[[
--v method(x_pos: number, y_pos: number)
function unit_stat_card:set_position(x_pos, y_pos)
    --# assume self: VANDY_USC
    if not is_number(x_pos) or not is_number(y_pos) then 
        script_error("[Unit Card - Set Position] called, but the supplied positions are not valid numbers!")
    end

    self._x_pos = x_pos
    self._y_pos = y_pos
end

--v method(width: number, height: number)
function unit_land_card:set_bounds(width, height)
    --# assume self: VANDY_ULC

    --TODO error debugging

    self._width = width
    self._height = height
end]]

--[[
--v method(x_off: number, y_off: number, docking_corner: ("top_left" | "top_right" | "bottom_left" | "bottom_right"))
function unit_stat_card:set_position_relative_to_uic_on_hover(x_off, y_off, docking_corner)
    --# assume self: VANDY_USC
    if not is_number(x_off) or not is_number(y_off) then 
        script_error("[Unit Card - Set Position] called, but the supplied positions are not valid numbers!")
        return
    end

    local uic_on_hover = self._uic_on_hover
    if not is_uicomponent(uic_on_hover) then
        script_error("Expeted a UIC!")
        return
    end

    self._docking_corner = docking_corner

    local x_rel, y_rel = uic_on_hover:Position()

    self._x_pos = x_rel + x_off
    self._y_pos = y_rel + y_off
end]]


--v method(uic_on_hover: CA_UIC)
function unit_card_obj:add_uic_on_hover(uic_on_hover)
    --# assume self: VANDY_UC
    if not is_uicomponent(uic_on_hover) then
        script_error("[Unit Card - Add UIC On Hover] called, but the supplied uic_on_hover is not a valid ui component!")
        return
    end

    self._uic_on_hover = uic_on_hover

    local function second_listener()
        core:add_listener(
            "HideUnitCard"..self._unit_key,
            "ComponentMouseOn",
            function(context)
                return UIComponent(context.component) ~= self._uic_on_hover and is_uicomponent(self._stat_card_uic) and UIComponent(context.component) ~= self._stat_card_uic and not uicomponent_descended_from(UIComponent(context.component), self._stat_card_uic:Id()) and self._stat_card_uic:Visible()
            end,
            function(context)
                self._stat_card_uic:SetVisible(false)
            end,
            false
        )
    end

    core:add_listener(
        "PopulateUnitCard"..self._unit_key,
        "ComponentMouseOn",
        function(context)
            return UIComponent(context.component) == self._uic_on_hover --or UIComponent(context.component) == self._stat_card_uic
        end,
        function(context)
            if not is_uicomponent(self._stat_card_uic) then
                self:create_stat_unit_card_for_frontend()
            else
                self._stat_card_uic:SetVisible(true)
            end
            second_listener()
        end,
        true
    )

end

-- API STUFF

--v method(frontend_unit: string, starting_general: string)
function unit_card_manager:remove_frontend_unit_for_starting_general(frontend_unit, starting_general)
    if not core:is_frontend() then
        script_error("Remove Frontend Unit for Starting General called while the game isn't in the frontend!")
        return
    end

    core:add_listener(
        "ListenForLordSelected",
        "ComponentLClickUp",
        function(context)
            return context.string == starting_general
        end,
        function(context)
            local timer_obj = get_tm()
            timer_obj:callback(function()
                local parent = find_uicomponent(core:get_ui_root(), "sp_grand_campaign", "dockers", "centre_docker", "lord_details_panel", "units", "start_units", "card_holder")
                if parent then
                    local unit_card = find_uicomponent(parent, frontend_unit)
                    if unit_card then
                        unit_card:SetVisible(false)
                    end
                end
            end, 10)
        end,
        true
    )

end


--v method(unit_key: string, starting_general: string)
function unit_card_manager:add_frontend_unit_for_starting_general(unit_key, starting_general)
    --# assume self: VANDY_UCM

    if not is_string(unit_key) or not is_string(starting_general) then
        script_error("Improper argument types!")
        return
    end

    local unit_card = self:get_unit_card_with_key(unit_key)

    

    core:add_listener(
        "AddUnitForFrontendLord",
        "ComponentLClickUp",
        function(context)
            return context.string == starting_general
        end,
        function(context)
            local timer_obj = get_tm()
            timer_obj:callback(function()
                local parent = find_uicomponent(core:get_ui_root(), "sp_grand_campaign", "dockers", "centre_docker", "lord_details_panel", "units", "start_units", "card_holder")
                unit_card:create_land_unit_card_for_frontend(parent)
                local land_unit_uic = unit_card._land_card_uic
                parent:Adopt(land_unit_uic:Address())
                unit_card:add_uic_on_hover(land_unit_uic)
                --local w, h = uic:Bounds()
                --unit_stat_card:set_position_relative_to_uic_on_hover(w, h/2, "bottom_left")
            end, 20)
        end,
        true
    )

end

unit_card_manager.init()

return unit_card_manager

--[[ SAVING FOR LATER
--v method(parent: CA_UIC)
function unit_land_card:create_component(parent)
    --# assume self: VANDY_ULC
    if not is_uicomponent(parent) then script_error("UIComponent expected!") return end

    local uic = core:get_or_create_component(self._unit_key, self._uic_path, parent)

    local health_frame = find_uicomponent(uic, "health_frame")
    health_frame:SetVisible(false)

    local battle_frame = find_uicomponent(uic, "battle")
    battle_frame:SetVisible(false)

    local campaign_frame = find_uicomponent(uic, "campaign")
    campaign_frame:SetVisible(false)

    uic:SetImagePath(self._unit_icon)

    local unit_cat = find_uicomponent(uic, "unit_cat_frame", "unit_category_icon")
    unit_cat:SetImagePath("ui/common ui/unit_category_icons/cannon.png")

    self._uic = uic

    uic:Resize(self._width, self._height)

    if not self._highlight_on_hover then
        core:add_listener("disable_hover", "ComponentMouseOn", function(context) return UIComponent(context.component) == self._uic end, function(context) self._uic:SetImagePath("", 4) end, true)
    end
end]]

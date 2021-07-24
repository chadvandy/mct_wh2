--# type SOURCE_ENUMS = {name: string, tooltip: string}

local unit_ability_source_types = {
    ["army"] = {["name"] = "Army ability", ["tooltip"] = "These abilities are not bound to any one unit and can therefore be used anywhere on the battlefield."},
    ["banner"] = {["name"] = "Banner", ["tooltip"] = "Banners can be carried into battle by any unit, improving their condition for the duration of the fray."},
    ["bound"] = {["name"] = "Bound spell", ["tooltip"] = "Spells sometimes apply limited charges to items or weapons, without draining the Winds of Magic."},
    ["character"] = {["name"] = "Character ability", ["tooltip"] = "Lords and Heroes all have abilities to aid them in their quest for supremacy on campaign and in battle."},
    ["default"] = {["name"] = "default", ["tooltip"] = ""},
    ["faction"] = {["name"] = "Faction", ["tooltip"] = "These abilities are intrinsic to the faction and its specific personality."},
    ["hero"] = {["name"] = "Hero ability", ["tooltip"] = "A Hero's abilities are specific to their owner, providing temporary or permanent assistance."},
    ["item"] = {["name"] = "Item", ["tooltip"] = "Items with magical properties may assist their owners on the battlefield."},
    ["lord"] = {["name"] = "Lord ability", ["tooltip"] = "A Lord's abilities are specific to their owner, providing temporary or permanent assistance."},
    ["lore"] = {["name"] = "Lore attribute", ["tooltip"] = "The foundation of any spell connected to a magical Lore, attributes offer wide-reaching and constant effects."},
    ["mark"] = {["name"] = "Mark of Chaos", ["tooltip"] = "When the Ruinous Powers smile upon their servants, those marks - and their beneficial effects - are borne for the duration of the battle."},
    ["mount"] = {["name"] = "Mount ability", ["tooltip"] = "A mount's abilities are a core part of its being and, used wisely, can mark the difference between victory and defeat."},
    ["quest"] = {["name"] = "Quest ability", ["tooltip"] = "Unique and bizarre abilities that can only be found at the mysterious locations where quest battles are fought."},
    ["rune"] = {["name"] = "Rune", ["tooltip"] = "A varied and powerful ability type, often concerned with defence."},
    ["spell"] = {["name"] = "Spell", ["tooltip"] = "Spells are summoned from the Winds of Magic, taking time and energy to conjure, and always directed outwards - never on the magic-user themself."},
    ["unit"] = {["name"] = "Unit ability", ["tooltip"] = "An ability is as much a part of its owning units as arms or legs, and can mark the difference between victory and defeat."},
    ["weapon"] = {["name"] = "Weapon", ["tooltip"] = "Weapons can do so much more than hack and slash - some are imbued with magical properties to further aid their bearers."}
} --: map<string, SOURCE_ENUMS>

return unit_ability_source_types
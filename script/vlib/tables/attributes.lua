local attributes = {
    ["cant_run"] = "Cannot Run||This unit cannot run and will only move at walking pace.",
    ["causes_fear"] = "Causes Fear||This unit frightens all enemy units, reducing their [[img:icon_morale]][[/img]]leadership when nearby. It is also immune to fear. Fear penalties do not stack.",
    ["causes_terror"] = "Causes Terror||This unit can cause terror, making its melee target rout for a short time. Units that cause terror are immune to terror and fear themselves.",
    ["charge_reflector"] = "Expert Charge Defence||When bracing, this unit negates the [[img:icon_charge]][[/img]]charge bonus of any attacker.",
    ["charge_reflector_vs_large"] = "Charge Defence vs. Large||When bracing, this unit negates the [[img:icon_charge]][[/img]]charge bonus of any large attacker.",
    ["construct"] = "Construct||This unit is an animated construct (does not rout, is immune to terror, becomes unstable when [[img:icon_morale]][[/img]]{{tr:morale}} is low). Necrotects can push it to its full combat potential and restore it in battle.",
    ["encourages"] = "Encourage||This unit provides a [[img:icon_morale]][[/img]]leadership bonus to nearby allies. Units within range of both the [[img:icon_general]][[/img]]Lord's aura and an encouraging unit will receive the larger of the two bonuses.",
    ["expendable"] = "Expendable||Witnessing friendly expendable units rout does not reduce other units' [[img:icon_morale]][[/img]]leadership, unless they are themselves expendable.",
    ["fatigue_immune"] = "Perfect Vigour||Even when performing the most fatiguing actions, this unit never loses vigour. ",
    ["fatigue_res"] = "Strong Vigour||This unit's vigour is less affected by fatiguing actions, such as combat.",
    ["guerrilla_deploy"] = "{{tr:guerrilla_deployment}}",
    ["hide_forest"] = "Hide (forest)||This unit can hide in forests until enemy units get too close.",
    ["ignore_forest_penalties"] = "Strider||Speed and combat penalties caused by terrain are ignored by this unit.",
    ["immune_to_psychology"] = "Immune to Psychology||The unit is immune to psychological attacks (fear and terror).",
    ["mounted_fire_move"] = "Fire Whilst Moving||This unit can fire while on the move.",
    ["rampage"] = "Rampage||When this unit gets hurt it may go on a rampage against nearby enemy units, attacking the closest one and ignoring any orders given.",
    ["resist_cold"] = "Resistant to Cold||This unit tires less quickly in snow.",
    ["resist_heat"] = "Resistant to Heat||This unit tires less quickly in the desert.",
    ["scare_immune"] = "Immune to Fear||This unit is immune to the fear effects of scary units.",
    ["snipe"] = "Snipe||This unit remains hidden while firing.",
    ["stalk"] = "Stalk||This unit can move hidden in any terrain.",
    ["unbreakable"] = "Unbreakable||This unit does not suffer any form of [[img:icon_morale]][[/img]]leadership loss and will never rout.",
    ["undead"] = "{{tr:wh2_dlc09_undead_description}}",
    ["unspottable"] = "Unspottable||If this unit can hide at its current location it will not be spotted until the enemy is very close."   
} --: map<string, string>

return attributes
    --[[
        return { 
            __used_profile = "main",
            __profiles = {
                main = {
                    __name = "",
                    __description = ""
                    __mods = {
                        mod_key = {
                            __settings = {
                                option_key = value
                            },
                            __patch = 0,
                            __other_variables = nil,
                        }
                    }
                },
                --- Only store DIFFERENTLY SAVED options
                user_made_profile = {
                    mod_key = {
                        __settings = {
                            option_key = value
                        }
                    }
                }
            },
            __cached_settings = {
                mod_key = {
                    option_key = value,
                }
            },
        }
    ]]

    return {
        ["Testing Profile"] = {
            ["selected"] = true,
            ["settings"] = {
                ["mixu_LL1"] = {
                    ["mixu_LL1_lord_menu_emp_edward_van_der_kraal"] = true,
                    ["mixu_LL1_hero_menu_emp_vorn_thugenheim"] = false,
                    ["mixu_LL1_lord_menu_dwf_kazador_dragonslayer"] = true,
                    ["mixu_LL1_hero_menu_emp_theodore_bruckner"] = false,
                    ["mixu_LL1_lord_menu_emp_alberich_haupt_anderssen"] = true,
                    ["mixu_LL1_lord_menu_emp_aldebrand_ludenhof"] = true,
                    ["mixu_LL1_lord_menu_brt_adalhard"] = true,
                    ["mixu_LL1_lord_menu_emp_valmir_von_raukov"] = true,
                    ["mixu_LL1_lord_menu_wef_daith"] = true,
                    ["mixu_LL1_lord_menu_emp_theoderic_gausser"] = true,
                    ["mixu_LL1_lord_menu_brt_cassyon"] = true,
                    ["mixu_LL1_hero_menu_emp_luthor_huss"] = false,
                    ["mixu_LL1_lord_menu_emp_wolfram_hertwig"] = true,
                    ["mixu_LL1_lord_menu_emp_marius_leitdorf"] = true,
                    ["mixu_LL1_lord_menu_dwf_kragg_the_grim"] = true,
                    ["mixu_LL1_perfomance_mode"] = true,
                    ["mixu_LL1_lord_menu_emp_helmut_feuerbach"] = true,
                    ["mixu_LL1_lord_menu_brt_bohemond"] = true,
                    ["mixu_LL1_lord_menu_brt_chilfroy"] = true,
                    ["mixu_LL1_lord_menu_mixu_elspeth_von_draken"] = true,
                    ["mixu_LL1_hero_menu_brt_almaric_de_gaudaron"] = false,
                },
                ["pj_selectable_start"] = {
                    ["pj_selectable_start_is_always_visible"] = false,
                    ["pj_selectable_start_is_whole_province_takeover_enabled"] = false,
                },
                ["mixu_LL2"] = {
                    ["mixu_LL2_hero_menu_tmb_ramhotep"] = true,
                    ["mixu_LL2_lord_menu_dwf_bloodline_grimm_burloksson"] = true,
                    ["mixu_LL2_lord_menu_wef_naieth_the_prophetess"] = true,
                    ["mixu_LL2_hero_menu_def_kouran_darkhand"] = true,
                    ["mixu_LL2_hero_menu_lzd_chakax"] = true,
                    ["mixu_LL2_hero_menu_brt_donna_don_domingio"] = true,
                    ["mixu_LL2_lord_menu_hef_bloodline_caradryan"] = true,
                    ["mixu_LL2_cabal_invasion_turn"] = 90,
                    ["mixu_LL2_cabal_invasion_difficulty"] = "normal",
                    ["mixu_LL2_lord_menu_lzd_tetto_eko"] = true,
                    ["mixu_LL2_perfomance_mode"] = false,
                    ["mixu_LL2_lord_menu_lzd_lord_huinitenuchli"] = true,
                    ["mixu_LL2_lord_menu_def_tullaris_dreadbringer"] = true,
                    ["mixu_LL2_lord_menu_skv_feskit"] = true,
                    ["mixu_LL2_lord_menu_brt_john_tyreweld"] = true,
                    ["mixu_LL2_lord_menu_hef_belannaer"] = true,
                    ["mixu_LL2_lord_menu_nor_egil_styrbjorn"] = true,
                    ["mixu_LL2_hero_menu_cst_drekla"] = true,
                    ["mixu_LL2_lord_menu_bst_ghorros_warhoof"] = true,
                    ["mixu_LL2_lord_menu_hef_korhil"] = true,
                    ["mixu_LL2_lord_menu_grn_gorfang_rotgut"] = true,
                    ["mixu_LL2_lord_menu_bst_slugtongue"] = true,
                    ["mixu_LL2_lord_menu_wef_wychwethyl"] = true,
                    ["mixu_LL2_lord_menu_tmb_tutankhanut"] = true,
                },
                ["mct_mod"] = {
                    ["enable_logging"] = true,
                },
                ["pj_extended_roster_kislev"] = {
                    ["pj_extended_roster_kislev_praag_ownership"] = "pj_extended_roster_kislev_praag_ownership_default",
                },
            },
        },
        ["Test"] = {
            ["selected"] = false,
            ["settings"] = {
                ["mixu_LL1"] = {
                    ["mixu_LL1_lord_menu_emp_edward_van_der_kraal"] = false,
                    ["mixu_LL1_hero_menu_emp_vorn_thugenheim"] = true,
                    ["mixu_LL1_lord_menu_dwf_kazador_dragonslayer"] = false,
                    ["mixu_LL1_hero_menu_emp_theodore_bruckner"] = true,
                    ["mixu_LL1_lord_menu_emp_alberich_haupt_anderssen"] = false,
                    ["mixu_LL1_lord_menu_emp_aldebrand_ludenhof"] = false,
                    ["mixu_LL1_lord_menu_brt_adalhard"] = false,
                    ["mixu_LL1_lord_menu_emp_valmir_von_raukov"] = false,
                    ["mixu_LL1_lord_menu_wef_daith"] = false,
                    ["mixu_LL1_lord_menu_emp_theoderic_gausser"] = false,
                    ["mixu_LL1_lord_menu_brt_cassyon"] = false,
                    ["mixu_LL1_hero_menu_emp_luthor_huss"] = true,
                    ["mixu_LL1_lord_menu_emp_wolfram_hertwig"] = false,
                    ["mixu_LL1_lord_menu_emp_marius_leitdorf"] = false,
                    ["mixu_LL1_lord_menu_dwf_kragg_the_grim"] = false,
                    ["mixu_LL1_perfomance_mode"] = true,
                    ["mixu_LL1_lord_menu_emp_helmut_feuerbach"] = false,
                    ["mixu_LL1_lord_menu_brt_bohemond"] = false,
                    ["mixu_LL1_lord_menu_brt_chilfroy"] = false,
                    ["mixu_LL1_lord_menu_mixu_elspeth_von_draken"] = false,
                    ["mixu_LL1_hero_menu_brt_almaric_de_gaudaron"] = true,
                },
                ["pj_selectable_start"] = {
                    ["pj_selectable_start_is_always_visible"] = false,
                    ["pj_selectable_start_is_whole_province_takeover_enabled"] = false,
                },
                ["mixu_LL2"] = {
                    ["mixu_LL2_hero_menu_tmb_ramhotep"] = true,
                    ["mixu_LL2_lord_menu_dwf_bloodline_grimm_burloksson"] = true,
                    ["mixu_LL2_lord_menu_wef_naieth_the_prophetess"] = true,
                    ["mixu_LL2_hero_menu_def_kouran_darkhand"] = true,
                    ["mixu_LL2_hero_menu_lzd_chakax"] = true,
                    ["mixu_LL2_hero_menu_brt_donna_don_domingio"] = true,
                    ["mixu_LL2_lord_menu_hef_bloodline_caradryan"] = true,
                    ["mixu_LL2_cabal_invasion_turn"] = 90,
                    ["mixu_LL2_cabal_invasion_difficulty"] = "normal",
                    ["mixu_LL2_lord_menu_lzd_tetto_eko"] = true,
                    ["mixu_LL2_perfomance_mode"] = false,
                    ["mixu_LL2_lord_menu_lzd_lord_huinitenuchli"] = true,
                    ["mixu_LL2_lord_menu_def_tullaris_dreadbringer"] = true,
                    ["mixu_LL2_lord_menu_skv_feskit"] = true,
                    ["mixu_LL2_lord_menu_brt_john_tyreweld"] = true,
                    ["mixu_LL2_lord_menu_hef_belannaer"] = true,
                    ["mixu_LL2_lord_menu_nor_egil_styrbjorn"] = true,
                    ["mixu_LL2_hero_menu_cst_drekla"] = true,
                    ["mixu_LL2_lord_menu_bst_ghorros_warhoof"] = true,
                    ["mixu_LL2_lord_menu_hef_korhil"] = true,
                    ["mixu_LL2_lord_menu_grn_gorfang_rotgut"] = true,
                    ["mixu_LL2_lord_menu_bst_slugtongue"] = true,
                    ["mixu_LL2_lord_menu_wef_wychwethyl"] = true,
                    ["mixu_LL2_lord_menu_tmb_tutankhanut"] = true,
                },
                ["mct_mod"] = {
                    ["enable_logging"] = true,
                },
                ["pj_extended_roster_kislev"] = {
                    ["pj_extended_roster_kislev_praag_ownership"] = "pj_extended_roster_kislev_praag_ownership_default",
                },
            },
        },
    }
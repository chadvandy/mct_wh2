--- UI system for informing the player if there are new options added after MCT is initialized
----- ie., if options are added because you selected a different lord, or whatever.

local mct = get_mct()

local new_options_added = {}
local booly = false

local function start_delay()
    core:add_listener(
        "do_stuff",
        "RealTimeTrigger",
        function(context)
            return context.string == "mct_new_option_created"
        end,
        function(context)
            local mod_keys = {}

            for k,_ in pairs(new_options_added) do
                -- mct:log("Adding mod key: "..k)
                mod_keys[#mod_keys+1] = k
            end

            local key = context.string
            local text = effect.get_localised_string("mct_new_settings_created_start") .. "\n\n" .. effect.get_localised_string("mct_new_settings_created_mid") .. "\n"

            for i = 1, #mod_keys do
                local mod_obj = mct:get_mod_by_key(mod_keys[i])
                local mod_title = mod_obj:get_title()

                if 1 == #mod_keys then
                    text = text .. "\"" .. mod_title .. "\"" .. ". "
                else

                    if i == #mod_keys then
                        text = text .. "and \"" .. mod_title .. "\"" .. ". "
                    else
                        text = text .. "\"" .. mod_title .. "\"" .. ", "
                    end
                end

            end

            mct.ui:create_popup(
                key,
                function()
                    if not mct.ui.opened then 
                        return text .. "\n" .. effect.get_localised_string("mct_new_settings_created_end")
                    else 
                        return text
                    end
                end,
                function()
                    if not mct.ui.opened then
                        return true
                    else
                        return false
                    end
                end,
                function()
                    if mct.ui.opened then
                        -- do nothing
                    else
                        mct.ui:open_frame()
                    end
                end,
                function()
                    -- do nothing?
                end
            )

            booly = false
            new_options_added = {}
        end,
        false
    )

    -- trigger above listener in 0.1s
    real_timer.register_singleshot("mct_new_option_created", 100)
end

-- check for new options created after MCT has been started and loaded.
-- ~0.1s after a new option has been created, trigger a popup. This'll prevent triggering like 60 popups if 60 new options are added within a tick or two.
core:add_listener(
    "mct_new_option_created",
    "MctNewOptionCreated",
    function(context)
        return context:mct()._initialized
    end,
    function(context)
        if not booly then
            -- in 0.1s, trigger the popup
            booly = true
            start_delay()
        end

        local mod_key = context:mod():get_key()
        local option_key = context:option():get_key()

        if is_nil(new_options_added[mod_key]) then
            new_options_added[mod_key] = {}
        end

        local tab = new_options_added[mod_key]

        tab[#tab+1] = option_key
    end,
    true
)
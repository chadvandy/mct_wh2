-- TODO, get this into its own system or a secondary system, for all logging, so the player can immediately known in-game when there's a script error. (Rimworld!)

local mct = get_mct()
local ui = mct.ui

ui:set_tab_action(
    "logging",
    function(ui_obj, mod, list_view)
        local logging_list_box = find_uicomponent(list_view, "list_clip", "list_box")

        -- delete any former logging
        logging_list_box:DestroyChildren()

        local log_file = io.open(mod:get_log_file_path(), "r+")

        if not log_file then
            mct:err("do_log_list_view() called with mod ["..mod:get_key().."], but no log file with the name ["..mod:get_log_file_path().."] was found. Issue!")
            return false
        end

        log_file:close()

        local lines = {}
        for line in io.lines(mod:get_log_file_path()) do
            lines[#lines+1] = line
        end


        for line_num, line_txt in pairs(lines) do
            local ok, msg = pcall(function()
            local text_component = core:get_or_create_component("line_text_"..tostring(line_num), "ui/vandy_lib/text/la_gioconda/unaligned", logging_list_box)

            local ow,oh = logging_list_box:Width() * 0.7, text_component:Height()
            text_component:Resize(ow, oh)

            local str = tostring(line_num) .. ": " .. line_txt

            local w,h = text_component:TextDimensionsForText(str)
            text_component:ResizeTextResizingComponentToInitialSize(w,h)

            _SetStateText(text_component, str)

            text_component:Resize(ow,oh)
            text_component:ResizeTextResizingComponentToInitialSize(ow,oh)


            --local w,h,num = text_component:TextDimensionsForText(tostring(line_num) .. ": " .. line_txt)

            text_component:SetDockingPoint(1)
            text_component:SetDockOffset(10, 10)

            _SetVisible(text_component, true)
            end) if not ok then mct:err(msg) end
        end

        logging_list_box:Layout()
    end
)

ui:set_tab_validity_check(
    "logging",
    ---@param ui_obj mct_ui
    ---@param mod mct_mod
    function(ui_obj, mod)
        local path = mod:get_log_file_path()
        if path == nil then
            return false
        end

        if not io.open(path, "r+") then
            return false, "Log file is set, but the path doesn't reference a valid file, or the file can't be opened!"
        end

        return true
    end
)
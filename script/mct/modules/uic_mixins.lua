--- MCT UIC Mixins. INTERNAL USE ONLY.
-- @script mct_uic_mixins

local uic_mixins = {
    --[[uic_IsUicomponent = function(self, uic)
        return assert(is_uicomponent(uic), "uic provided is not a valid UIComponent!")
    end,]]

    uic_SetState = function(self, uic, state_name)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_SetState() called but the uic provided is not a valid UIComponent!")
            return false
        end

        if not is_string(state_name) then
            script_error("ERROR: uic_SetState() called but the [state_name] provided (["..tostring(state_name).."]) is not a valid string!")
            return false
        end

        return uic:SetState(state_name)
    end,

    uic_MoveTo = function(self, uic, x, y)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_MoveTo() called but the uic provided is not a valid UIComponent!")
            return false
        end

        if not is_number(x) then
            script_error("ERROR: uic_MoveTo() called but the [x] provided (["..tostring(x).."]) is not a valid number!")
            return false
        end

        if not is_number(y) then
            script_error("ERROR: uic_MoveTo() called but the [y] provided (["..tostring(y).."]) is not a valid number!")
            return false
        end

        return uic:MoveTo(x, y)
    end,

    uic_SetMoveable = function(self, uic, set_moveable_bool)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_SetMoveable() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_boolean(set_moveable_bool) then
            script_error("ERROR: uic_SetMoveable() called but the [set_moveable_bool] provided (["..tostring(set_moveable_bool).."]) is not a valid boolean!")
            return false
        end

        return uic:SetMoveable(set_moveable_bool)
    end,

    uic_Resize = function(self, uic, w, h, resize_children)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_Resize() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_number(w) then
            script_error("ERROR: uic_Resize() called but the [w] provided (["..tostring(w).."]) is not a valid number!")
            return false
        end

        if not is_number(h) then
            script_error("ERROR: uic_Resize() called but the [h] provided (["..tostring(h).."]) is not a valid number!")
            return false
        end

        if is_nil(resize_children) then
            resize_children = true
        end

        if not is_boolean(resize_children) then
            script_error("ERROR: uic_Resize() called but the [resize_children] provided (["..tostring(resize_children).."]) is not a valid boolean!")
            return false
        end

        return uic:Resize(w,h,resize_children)
    end,

    uic_SetCanResizeWidth = function(self, uic, can_resize)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_SetCanResizeWidth() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_boolean(can_resize) then
            script_error("ERROR: uic_SetCanResizeWidth() called but the [can_resize] provided (["..tostring(can_resize).."]) is not a valid boolean!")
            return false
        end

        return uic:SetCanResizeWidth(can_resize)
    end,

    uic_SetCanResizeHeight = function(self, uic, can_resize)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_SetCanResizeHeight() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_boolean(can_resize) then
            script_error("ERROR: uic_SetCanResizeHeight() called but the [can_resize] provided (["..tostring(can_resize).."]) is not a valid boolean!")
            return false
        end

        return uic:SetCanResizeHeight(can_resize)
    end,

    uic_ResizeTextResizingComponentToInitialSize = function(self, uic, w, h)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_ResizeTextResizingComponentToInitialSize() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_number(w) then
            script_error("ERROR: uic_ResizeTextResizingComponentToInitialSize() called but the [w] provided (["..tostring(w).."]) is not a valid number!")
            return false
        end

        if not is_number(h) then
            script_error("ERROR: uic_ResizeTextResizingComponentToInitialSize() called but the [h] provided (["..tostring(h).."]) is not a valid number!")
            return false
        end

        return uic:ResizeTextResizingComponentToInitialSize(w, h)

    end,

    uic_TextDimensionsForText = function(self, uic, text)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_TextDimensionsForText() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_string(text) then
            script_error("ERROR: uic_TextDimensionsForText() called but the [text] provided (["..tostring(text).."]) is not a valid string!")
            return false
        end

        return uic:TextDimensionsForText(text)
    end,

    uic_WidthOfTextLine = function(self, uic, text)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_WidthOfTextLine() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_string(text) then
            script_error("ERROR: uic_WidthOfTextLine() called but the [text] provided (["..tostring(text).."]) is not a valid string!")
            return false
        end

        return uic:WidthOfTextLine(text)
    end,

    uic_SetDockingPoint = function(self, uic, dock_point)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_SetDockingPoint() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_number(dock_point) then
            script_error("ERROR: uic_SetDockingPoint() called but the [dock_point] provided (["..tostring(dock_point).."]) is not a valid number!")
            return false
        end

        return uic:SetDockingPoint(dock_point)
    end,

    uic_SetDockOffset = function(self, uic, x_offset, y_offset)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_SetDockOffset() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_number(x_offset) then
            script_error("ERROR: uic_SetDockOffset() called but the [x_offset] provided (["..tostring(x_offset).."]) is not a valid number!")
            return false
        end

        if not is_number(y_offset) then
            script_error("ERROR: uic_SetDockOffset() called but the [y_offset] provided (["..tostring(y_offset).."]) is not a valid number!")
            return false
        end

        return uic:SetDockOffset(x_offset, y_offset)
    end,

    uic_SetStateText = function(self, uic, localised_text, shrink_to_fit, max_lines)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_SetStateText() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_string(localised_text) then
            script_error("ERROR: uic_SetStateText() called but the [localised_text] provided (["..tostring(localised_text).."]) is not a valid string!")
            return false
        end

        if is_nil(shrink_to_fit) then
            shrink_to_fit = false
        end

        if not is_boolean(shrink_to_fit) then
            script_error("ERROR: uic_SetStateText() called but the [shrink_to_fit] provided (["..tostring(shrink_to_fit).."]) is not a valid boolean or nil!")
            return false
        end

        if is_nil(max_lines) then
            max_lines = 0
        end

        if not is_number(max_lines) then
            script_error("ERROR: uic_SetStateText() called but the [max_lines] provided (["..tostring(max_lines).."]) is not a valid number or nil!")
            return false
        end

        return uic:SetStateText(localised_text, shrink_to_fit, max_lines)
    end,

    uic_SetTooltipText = function(self, uic, tt_text, set_all_states)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_SetTooltipText() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_string(tt_text) then
            script_error("ERROR: uic_SetTooltipText() called but the [tt_text] provided (["..tostring(tt_text).."]) is not a valid string!")
            return false
        end

        if is_nil(set_all_states) then
            set_all_states = false
        end

        if not is_boolean(set_all_states) then
            script_error("ERROR: uic_SetTooltipText() called but the [set_all_states] provided (["..tostring(set_all_states).."]) is not a valid boolean or nil!")
            return false
        end

        return uic:SetTooltipText(tt_text, set_all_states)
    end,

    uic_SetImagePath = function(self, uic, image_path, image_index)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_SetImagePath() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_string(image_path) then
            script_error("ERROR: uic_SetImagePath() called but the [image_path] provided (["..tostring(image_path).."]) is not a valid string!")
            return false
        end

        image_index = image_index or 0

        if not is_number(image_index) then
            script_error("ERROR: uic_SetImagePath() called but the [image_index] provided (["..tostring(image_index).."]) is not a valid number or nil!")
            return false
        end

        return uic:SetImagePath(image_path, image_index)
    end,

    uic_SetVisible = function(self, uic, set_visible)
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_SetVisible() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_boolean(set_visible) then
            script_error("ERROR: uic_SetVisible() called but the [set_visible] provided (["..tostring(set_visible).."]) is not a valid boolean!")
            return false
        end

        return uic:SetVisible(set_visible)
    end
}

    --[[ UIC Error
        if not is_uicomponent(uic) then
            script_error("ERROR: uic_Function() called but the [uic] provided is not a valid UIComponent!")
            return false
        end
    ]]

    --[[ String Error
        if not is_string(argument) then
            script_error("ERROR: uic_Function() called but the [argument] provided (["..tostring(argument).."]) is not a valid string!")
            return false
        end
    ]]

    --[[ Number Error
        if not is_number(argument) then
            script_error("ERROR: uic_Function() called but the [argument] provided (["..tostring(argument).."]) is not a valid number!")
            return false
        end
    ]]

    --[[ Boolean Error
        if not is_boolean(argument) then
            script_error("ERROR: uic_Function() called but the [argument] provided (["..tostring(argument).."]) is not a valid boolean!")
            return false
        end
    ]]

function mct:mixin(object)
    for index, method in pairs(uic_mixins) do
        object[index] = method
    end
end
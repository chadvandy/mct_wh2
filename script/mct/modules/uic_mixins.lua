---- MCT UIC Mixins. INTERNAL USE ONLY.
--- @script mct_uic_mixins

local mct = mct

local uic_mixins = {
    --[[uic_IsUicomponent = function(self, uic)
        return assert(is_uicomponent(uic), "uic provided is not a valid UIComponent!")
    end,]]

    SetState = function(self, uic, state_name)
        if not is_uicomponent(uic) then
            mct:error("ERROR: SetState() called but the uic provided is not a valid UIComponent!")
            return false
        end

        if not is_string(state_name) then
            mct:error("ERROR: SetState() called but the [state_name] provided (["..tostring(state_name).."]) is not a valid string!")
            return false
        end

        return uic:SetState(state_name)
    end,

    MoveTo = function(self, uic, x, y)
        if not is_uicomponent(uic) then
            mct:error("ERROR: MoveTo() called but the uic provided is not a valid UIComponent!")
            return false
        end

        if not is_number(x) then
            mct:error("ERROR: MoveTo() called but the [x] provided (["..tostring(x).."]) is not a valid number!")
            return false
        end

        if not is_number(y) then
            mct:error("ERROR: MoveTo() called but the [y] provided (["..tostring(y).."]) is not a valid number!")
            return false
        end

        return uic:MoveTo(x, y)
    end,

    SetMoveable = function(self, uic, set_moveable_bool)
        if not is_uicomponent(uic) then
            mct:error("ERROR: SetMoveable() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_boolean(set_moveable_bool) then
            mct:error("ERROR: SetMoveable() called but the [set_moveable_bool] provided (["..tostring(set_moveable_bool).."]) is not a valid boolean!")
            return false
        end

        return uic:SetMoveable(set_moveable_bool)
    end,

    Resize = function(self, uic, w, h, resize_children)
        if not is_uicomponent(uic) then
            mct:error("ERROR: Resize() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_number(w) then
            mct:error("ERROR: Resize() called but the [w] provided (["..tostring(w).."]) is not a valid number!")
            return false
        end

        if not is_number(h) then
            mct:error("ERROR: Resize() called but the [h] provided (["..tostring(h).."]) is not a valid number!")
            return false
        end

        --if is_nil(resize_children) then
        --    resize_children = true
        --end

        if is_nil(resize_children) == false and not is_boolean(resize_children) == false then
            mct:error("ERROR: Resize() called but the [resize_children] provided (["..tostring(resize_children).."]) is not a valid boolean!")
            return false
        end

        return uic:Resize(w,h,resize_children)
    end,

    SetCanResizeWidth = function(self, uic, can_resize)
        if not is_uicomponent(uic) then
            mct:error("ERROR: SetCanResizeWidth() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_boolean(can_resize) then
            mct:error("ERROR: SetCanResizeWidth() called but the [can_resize] provided (["..tostring(can_resize).."]) is not a valid boolean!")
            return false
        end

        return uic:SetCanResizeWidth(can_resize)
    end,

    SetCanResizeHeight = function(self, uic, can_resize)
        if not is_uicomponent(uic) then
            mct:error("ERROR: SetCanResizeHeight() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_boolean(can_resize) then
            mct:error("ERROR: SetCanResizeHeight() called but the [can_resize] provided (["..tostring(can_resize).."]) is not a valid boolean!")
            return false
        end

        return uic:SetCanResizeHeight(can_resize)
    end,

    ResizeTextResizingComponentToInitialSize = function(self, uic, w, h)
        if not is_uicomponent(uic) then
            mct:error("ERROR: ResizeTextResizingComponentToInitialSize() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_number(w) then
            mct:error("ERROR: ResizeTextResizingComponentToInitialSize() called but the [w] provided (["..tostring(w).."]) is not a valid number!")
            return false
        end

        if not is_number(h) then
            mct:error("ERROR: ResizeTextResizingComponentToInitialSize() called but the [h] provided (["..tostring(h).."]) is not a valid number!")
            return false
        end

        return uic:ResizeTextResizingComponentToInitialSize(w, h)

    end,

    TextDimensionsForText = function(self, uic, text)
        if not is_uicomponent(uic) then
            mct:error("ERROR: TextDimensionsForText() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_string(text) then
            mct:error("ERROR: TextDimensionsForText() called but the [text] provided (["..tostring(text).."]) is not a valid string!")
            return false
        end

        return uic:TextDimensionsForText(text)
    end,

    WidthOfTextLine = function(self, uic, text)
        if not is_uicomponent(uic) then
            mct:error("ERROR: WidthOfTextLine() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_string(text) then
            mct:error("ERROR: WidthOfTextLine() called but the [text] provided (["..tostring(text).."]) is not a valid string!")
            return false
        end

        return uic:WidthOfTextLine(text)
    end,

    SetDockingPoint = function(self, uic, dock_point)
        if not is_uicomponent(uic) then
            mct:error("ERROR: SetDockingPoint() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_number(dock_point) then
            mct:error("ERROR: SetDockingPoint() called but the [dock_point] provided (["..tostring(dock_point).."]) is not a valid number!")
            return false
        end

        return uic:SetDockingPoint(dock_point)
    end,

    SetDockOffset = function(self, uic, x_offset, y_offset)
        if not is_uicomponent(uic) then
            mct:error("ERROR: SetDockOffset() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_number(x_offset) then
            mct:error("ERROR: SetDockOffset() called but the [x_offset] provided (["..tostring(x_offset).."]) is not a valid number!")
            return false
        end

        if not is_number(y_offset) then
            mct:error("ERROR: SetDockOffset() called but the [y_offset] provided (["..tostring(y_offset).."]) is not a valid number!")
            return false
        end

        return uic:SetDockOffset(x_offset, y_offset)
    end,

    SetStateText = function(self, uic, localised_text)
        if not is_uicomponent(uic) then
            mct:error("ERROR: SetStateText() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_string(localised_text) then
            mct:error("ERROR: SetStateText() called but the [localised_text] provided (["..tostring(localised_text).."]) is not a valid string!")
            return false
        end

        --[[if is_nil(shrink_to_fit) then
            shrink_to_fit = false
        end

        if not is_boolean(shrink_to_fit) then
            mct:error("ERROR: SetStateText() called but the [shrink_to_fit] provided (["..tostring(shrink_to_fit).."]) is not a valid boolean or nil!")
            return false
        end

        if is_nil(max_lines) then
            max_lines = 0
        end

        if not is_number(max_lines) then
            mct:error("ERROR: SetStateText() called but the [max_lines] provided (["..tostring(max_lines).."]) is not a valid number or nil!")
            return false
        end]]

        return uic:SetStateText(localised_text)
    end,

    SetTooltipText = function(self, uic, tt_text, set_all_states)
        if not is_uicomponent(uic) then
            mct:error("ERROR: SetTooltipText() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_string(tt_text) then
            mct:error("ERROR: SetTooltipText() called but the [tt_text] provided (["..tostring(tt_text).."]) is not a valid string!")
            return false
        end

        if is_nil(set_all_states) then
            set_all_states = false
        end

        if not is_boolean(set_all_states) then
            mct:error("ERROR: SetTooltipText() called but the [set_all_states] provided (["..tostring(set_all_states).."]) is not a valid boolean or nil!")
            return false
        end

        return uic:SetTooltipText(tt_text, set_all_states)
    end,

    SetImagePath = function(self, uic, image_path, image_index)
        if not is_uicomponent(uic) then
            mct:error("ERROR: SetImagePath() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_string(image_path) then
            mct:error("ERROR: SetImagePath() called but the [image_path] provided (["..tostring(image_path).."]) is not a valid string!")
            return false
        end

        image_index = image_index or 0

        if not is_number(image_index) then
            mct:error("ERROR: SetImagePath() called but the [image_index] provided (["..tostring(image_index).."]) is not a valid number or nil!")
            return false
        end

        return uic:SetImagePath(image_path, image_index)
    end,

    SetVisible = function(self, uic, set_visible)
        if not is_uicomponent(uic) then
            mct:error("ERROR: SetVisible() called but the [uic] provided (["..tostring(uic).."]) is not a valid UIComponent!")
            return false
        end

        if not is_boolean(set_visible) then
            mct:error("ERROR: SetVisible() called but the [set_visible] provided (["..tostring(set_visible).."]) is not a valid boolean!")
            return false
        end

        return uic:SetVisible(set_visible)
    end,

    SetInteractive = function(self, uic, set_interactive)
        if not is_uicomponent(uic) then
            mct:error("ERROR: Function() called but the [uic] provided is not a valid UIComponent!")
            return false
        end

        if not is_boolean(set_interactive) then
            mct:error("ERROR: Function() called but the [set_interactive] provided (["..tostring(set_interactive).."]) is not a valid boolean!")
            return false
        end

        return uic:SetInteractive(set_interactive)
    end,

}

    --[[ UIC Error
        if not is_uicomponent(uic) then
            mct:error("ERROR: uic_Function() called but the [uic] provided is not a valid UIComponent!")
            return false
        end
    ]]

    --[[ String Error
        if not is_string(argument) then
            mct:error("ERROR: uic_Function() called but the [argument] provided (["..tostring(argument).."]) is not a valid string!")
            return false
        end
    ]]

    --[[ Number Error
        if not is_number(argument) then
            mct:error("ERROR: uic_Function() called but the [argument] provided (["..tostring(argument).."]) is not a valid number!")
            return false
        end
    ]]

    --[[ Boolean Error
        if not is_boolean(argument) then
            mct:error("ERROR: uic_Function() called but the [argument] provided (["..tostring(argument).."]) is not a valid boolean!")
            return false
        end
    ]]

function mct:mixin(object)
    for index, method in pairs(uic_mixins) do
        object[index] = method
    end
end
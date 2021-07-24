-- TODO only overwrite this on MCT Verbose Logging
-- local UI = UIComponent
-- function UIComponent(address)
--     if not is_component(address) then return script_error("Calling UIComponent(), but the address/component passed is not valid!") end

--     return UI(address)
-- end

--- Overwrote this to plop in the pair of error checks
function core_object:get_or_create_component(name, path, uic_parent)
    uic_parent = uic_parent or core:get_ui_root();
    
    if not is_uicomponent(uic_parent) then
        script_error("get_or_create_component() called but the uic_parent supplied is not a valid UIC!")
        return false
    end

    if not is_string(name) then
        script_error("get_or_create_component() called but the name supplied is not a string!")
        return false
    end
	
	for i = 0, uic_parent:ChildCount() - 1 do
		local uic_child = UIComponent(uic_parent:Find(i));
		
		if uic_child:Id() == name then
			return uic_child, false;
		end;
	end;
	
	return UIComponent(uic_parent:CreateComponent(name, path)), true;
end;
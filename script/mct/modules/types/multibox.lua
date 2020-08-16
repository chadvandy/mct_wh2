local mct = mct

local template_type = mct._MCT_TYPES.template

local type = mct:create_class(template_type)

--[[function type.new(mct_mod, mct_option, key)
    local new_type = template_type.new(mct_mod, mct_option, key)

    setmetatable(new_type, type)
    
    return new_type
end]]


--------- OVERRIDEN SECTION -------------
-- These functions exist for every type, and have to be overriden from the version defined in template_types.

function type:check_validity(value)


    -- TODO hookup

    return false
end

--------- UNIQUE SECTION -----------
-- These functions are unique for this type only. Be careful calling these!

return type
local mct = mct

local template_type = mct._MCT_TYPES.template

local lua_type = type

local type = mct:create_class(template_type)

function type:__index(attempt)
    mct:log("start")
    mct:log("calling: "..attempt)
    --mct:log("key: "..self:get_key())
    --mct:log("calling "..attempt.." on mct option "..self:get_key())
    local field = rawget(getmetatable(self), attempt)
    local retval = nil

    if lua_type(field) == "nil" then
        mct:log("not found, checking template_type")
        local wrapped = rawget(self, "template_type")

        field = wrapped and wrapped[attempt]

        if lua_type(field) == "nil" then
            mct:log("not found, check mct_option")
            -- not found in mct_option, check template_type!
            local wrapped_boi = rawget(self, "option")

            field = wrapped_boi and wrapped_boi[attempt]

            if lua_type(field) == "function" then
                retval = function(obj, ...)
                    return field(wrapped_boi, ...)
                end
            else
                retval = field
            end
        else
            -- found in mct_option, woop
            if lua_type(field) == "function" then
                mct:log("func found")
                retval = function(obj, ...)
                    return field(wrapped, ...)
                end
            else
                mct:log("non-func found")
                retval = field
            end
        end
    else
        if lua_type(field) == "function" then
            retval = function(obj, ...)
                return field(self, ...)
            end
        else
            retval = field
        end
    end
    
    return retval
end

--------- OVERRIDEN SECTION -------------
-- These functions exist for every type, and have to be overriden from the version defined in template_types.

function type:check_validity(value)


    -- TODO hookup

    return false
end

--------- UNIQUE SECTION -----------
-- These functions are unique for this type only. Be careful calling these!

return type
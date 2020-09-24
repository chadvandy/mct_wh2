local mct = mct

local mct_action = {}

function mct_action.new(mod_obj, action_key)
    if not mct:is_mct_mod(mod_obj) then
        -- errmsg
        return false
    end
    
    if not is_string(action_key) then
        -- errmsg
        return false
    end
   
    local o = {}
    setmetatable(o, {__index = mct_action})
    
    o.key = action_key
    
    return o 
end

function mct_action:get_key()
    return self.key
end


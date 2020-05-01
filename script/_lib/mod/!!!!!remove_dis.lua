-- enables more varied usages of the "custom_context" object, so you can supply the function name as well as the object
-- ie., `custom_context:add_data("testing string", "blorp")` will enable you to use `conetxt:blorp()` to output "testing string". 
function custom_context:add_data_with_key(value, key)
    -- make index optional
    if not is_string(key) then
        script_error("ERROR: adding data to custom context, but the key provided is not a string!")
        return false
    end

    --self[key.."_data"] = value

    self[key] = function(self) return value end
end


function core_object:trigger_custom_event(event, data_items)

    -- build an event context
    local context = custom_context:new();

    if not is_string(event) then
        script_error("ERROR: triggering custom event, but the event key provided is not a string!")
        return false
    end

    out("triggering event with name ["..event.."].")

    if not is_table(data_items) then
        -- issue
        script_error("ERROR: triggering custom event, but the data_items arg provided is not a table!")
        return false
    end

    for key, value in pairs(data_items) do
        out("adding function ["..key.."()] to event with value ["..tostring(value).."]")
        context:add_data_with_key(value, key)
    end

    local event_table = events[event]
    if event_table then
        for i = 1, #event_table do
            event_table[i](context)
        end
    end
end
---- This file is stuff added to the campaign manager, to make it operate better or to add new functions.

function cm:get_faction_of_subculture(subculture_key)
	if not is_string(subculture_key) then
		script_error("ERROR: get_faction_of_subculture() called but supplied subculture key [" .. tostring(subculture_key) .. "] is not a string")
		return false
	end

    local faction_list = cm:model():world():faction_list()

	for i = 0, faction_list:num_items() - 1 do
		local faction = faction_list:item_at(i)

		if faction:subculture() == subculture_key then
			-- if self:faction_is_alive(faction) then
            return faction
			-- end
		end
	end

	return false
end

function cm:get_faction_of_culture(culture_key)
	if not is_string(culture_key) then
		script_error("ERROR: get_faction_of_culture() called but supplied culture key [" .. tostring(culture_key) .. "] is not a string")
		return false
	end

    local faction_list = cm:model():world():faction_list()

	for i = 0, faction_list:num_items() - 1 do
		local faction = faction_list:item_at(i)

		if faction:culture() == culture_key then
			-- if self:faction_is_alive(faction) then
            return faction
			-- end
		end
	end

	return false
end
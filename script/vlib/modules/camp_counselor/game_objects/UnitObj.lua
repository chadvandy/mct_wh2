--- TODO add
--- TODO clear up the States stuff, make it more usable.
--- TODO move unit_ui stuff here? as static methods on UnitObj mehaps?

local vlib = get_vandy_lib()
local log,logf,err,errf = vlib:get_log_functions("[unit]")

---@type vlib_camp_counselor
local cc = vlib:get_module("camp_counselor")

---@class unit_class : class_prototype
local UnitObj = vlib:new_class("UnitObj")
UnitObj.__index = UnitObj

---@class unit_class_state
local UnitObjState = {
    ---@type string The relevant faction key.
    _faction_key = "",

    ---@type lock_state
    _lock_state = 0,

    ---@type string Tooltip to display for why this unit is locked.
    _lock_reason = "",
}

--- Initialize the UnitObj factory.
function UnitObj:__init()
    -- vlib:logf("Creating a new unit w/ key %s", "[boop]", o._key)
    -- o = o or {}
    -- return setmetatable(o, self)

    return self
end

function UnitObj:__tostring()
    return "UnitObj ["..self._key.."]"
end

function UnitObj:get_key()
    vlib:logf("Getting key %s for a unit!", "[boop]", self._key)
    return self._key
end

--- creates all the states for a new unit
function UnitObj:new_states(filters)
    for i,faction_key in ipairs(filters) do
        local state = table.deepcopy(UnitObjState)
        state._faction_key = faction_key

        self._states[faction_key] = state
    end
end

function UnitObjState:set_lock_state(lock_state, lock_reason)
	self._lock_state = lock_state
	self._lock_reason = lock_reason
end

function UnitObjState:get_lock_state()
	return self._lock_state, self._lock_reason
end

---comment
---@param faction_key string
---@return unit_class_state
function UnitObj:get_state(faction_key)
    local state = self._states[faction_key]
    
    return state
end

function UnitObj:set_lock_state(lock_state, lock_reason, faction_key)
    local state = self:get_state(faction_key)

	state:set_lock_state(lock_state, lock_reason)
end

function UnitObj:get_lock_state(faction_key)
    local state = self:get_state(faction_key)

    return state:get_lock_state()
end

--- create a unit obj from the factory.
function UnitObj.new(key, filters)
    ---@type unit_class
    local o = {
        _key = key,
        ---@type table<string, unit_class_state>
        _states = {},

        _building_key = "",

        -- TODO remove this?
        _localised_name = "",
    }
    o = UnitObj.instantiate(o)

    -- create a state per "filter"
    o:new_states(filters)
    return o
end

---@return unit_class
function UnitObj.instantiate(o)
    return setmetatable(o, UnitObj)
end

function UnitObj:get_building_key()
    return self._building_key
end

function UnitObj:set_building_key(building_key)
    self._building_key = building_key
end

function UnitObj:set_localised_name(name)
    if self:get_localised_name() ~= "" then return end
    if not is_string(name) then return end

    self._localised_name = name
end

function UnitObj:get_localised_name()
	return self._localised_name
end

-- TODO, needed for the building_key_to_units thingy?
-- function unit_obj:instantiate(o)
-- 	setmetatable(o, {__index = unit_obj})
-- 	-- TODO make it a bit prettier?
-- 	-- This is entirely needed so unit manager gets update with building_key_to_units. (Save the building key to units table stuff?)
-- 	o:set_building_key(o._building_key)

-- 	logf("Instantiating unit obj %q. Building key %q", o:get_key(), tostring(o:get_building_key()))
-- end


---- All of the Unit UI stuff!
local _building_hovered

function UnitObj.get_cp()
    local construction_popups = {"construction_popup", "second_construction_popup"}
	for i = 1, #construction_popups do
		local cp = find_uicomponent(construction_popups[i])
		if cp then
			return cp
		end
	end

    return errf("Trying to get the Construction Popup within the Unit UI, but can't find any!")
end

function UnitObj.get_bip(is_settlement_panel)
	local bip

	-- if an arg is passed, just test that one BIP
	if is_boolean(is_settlement_panel) then
		if is_settlement_panel == true then
			return find_uicomponent("layout", "info_panel_holder", "secondary_info_panel_holder", "info_panel_background", "BuildingInfoPopup")
		else
			return find_uicomponent("building_browser", "info_panel_background", "BuildingInfoPopup")
		end
	end

	-- no arg is passed; we don't know which direction the BIP is coming from, so test both!
	bip = find_uicomponent("layout", "info_panel_holder", "secondary_info_panel_holder", "info_panel_background", "BuildingInfoPopup")

	if not bip then
		bip = find_uicomponent("building_browser", "info_panel_background", "BuildingInfoPopup")
	end

	return bip
end

function UnitObj.edit_building_info_panel(bip_uic)
	if is_nil(bip_uic) then bip_uic = UnitObj.get_bip() end
	if not bip_uic then return end
	if not _building_hovered then return end

	local building_key = _building_hovered

	local faction_key = cm:get_local_faction_name(true)
    local units = cc:get_units_for_building(building_key, faction_key)

	logf("Hovering over building %q that has unit key stuff!", building_key)

	local unit_names = {}
	for i = 1, #units do
		local unit = units[i]

        local name = unit:get_localised_name()
        local lock_state = unit:get_lock_state(faction_key)

		-- only if they're hidden entirely, not locked with visual stuff
		if lock_state == 1 then
			unit_names[name] = 1
        elseif lock_state >= 2 then
            unit_names[name] = 2
		end
	end

	logf("Checking BIP for effects and shit")

	local entry_parent = find_uicomponent(bip_uic, "effects_list", "building_info_recruitment_effects", "entry_parent")

	if not entry_parent then return end

	local all = entry_parent:ChildCount()
	local total = 0

	for i = 0, all-1 do
		local child = UIComponent(entry_parent:Find(i))
		local unit_name_uic = UIComponent(child:Find("unit_name"))
		local unit_name_text = unit_name_uic:GetStateText()

		logf("Seeing if %q is a unit to hide", unit_name_text)

        local state = unit_names[unit_name_text]
        if state then
            if state == 1 then
                child:SetVisible(false)
				total = total + 1
            elseif state == 2 then
                unit_name_text = "[[col:red]]"..unit_name_text.."[[/col]]"
                unit_name_uic:SetStateText(unit_name_text)
            end
        end
	end

	if total == all then
		UIComponent(entry_parent:Parent()):SetVisible(false)
	end
end

--- Handles the "slot parent" component, which is used within the Building Browser and within Construction Popups. Goes through all of the building slots, checks their unit lists, and handles shit appropriately.
---@param slot_parent userdata
function UnitObj.handle_slot_parent(slot_parent)
	logf("Handling the slot parent component! Locking unit cards visibly and shtuff.")
	-- local slot_parent

	if not is_uicomponent(slot_parent) then
		return logf("Trying to handle the slot parent shtuff, but the slot parent provided wasn't valid!")
	end

    local faction_key = cm:get_local_faction_name(true)

	-- loop through all of the "slots" within the building tree. Order here goes Slot Parent -> Slot # -> Building UIC
	logf("Pre-loop, num children is %d", slot_parent:ChildCount())
	for i = 0, slot_parent:ChildCount() -1 do
		-- logf("Getting slot address, child num %d", i)
		logf("Getting slot UIC at child index %d", i)
		local slot = UIComponent(slot_parent:Find(i))
        if not is_uicomponent(slot) then logf("No UIC found?") end

        if is_uicomponent(slot) and slot:ChildCount() > 0 and slot:Find(0) then
            logf("Retrieved slot w/ key %s", slot:Id())
            logf("Getting building UIC")
            local building_uic = UIComponent(slot:Find(0))
            logf("Gotten building w/ key %s", building_uic:Id())

            -- holder for floating unit cards!
            local unit_list_uic = UIComponent(building_uic:Find("units_list"))

            logf("Gotten units list")

            -- loop through all floating unit cards
            for j = 0, unit_list_uic:ChildCount() -1 do
                logf("Looping through unit list, at index %d", j)
                local unit_entry = UIComponent(unit_list_uic:Find(j))
                logf("Unit entry founded")
                local unit_key = unit_entry:Id()
                logf("Unit key is %q", unit_key)

                -- ignore template unit cards
                if unit_key ~= "unit_entry" and unit_key ~= "agent_entry" then
                    -- check if there's a unit in the manager with this key!
					---@type unit_class
                    local unit = cc:get_object("UnitObj", unit_key)

                    if unit then
                        -- save the localised name for other parts of the manager.
                        unit:set_localised_name(unit_entry:GetTooltipText())
                        unit:set_building_key(building_uic:Id())

                        -- if this unit is locked, hide it
                        local lock_state,lock_reason = unit:get_lock_state(faction_key)
                        if lock_state == 1 then
                            -- hide it entirely from the UI
                            unit_entry:SetVisible(false)
                        elseif lock_state >= 2 then
                            -- set locked, visually, and set the tooltip
                            local tt = unit_entry:GetTooltipText()
                            if not tt:find(lock_reason) then
                                tt = tt .. "\n\n [[col:red]]" .. lock_reason .. "[[/col]]"

                                unit_entry:SetState("active_red")
                                unit_entry:SetTooltipText(tt, true)
                            end
                        end
                    end
                end
            end
		end
	end
end

--- TODO this has to be removed w/ a panel closed listener!
function UnitObj.building_hover_listener(is_settlement_panel)
	local parent
	
	-- they have a different structure based on the spot!
	if is_settlement_panel then
		parent = find_uicomponent("settlement_panel", "main_settlement_panel")
	else
		parent = find_uicomponent("building_browser", "main_settlement_panel")
	end
	
	-- no main settlement panel found; err!
	if not parent then
		return errf("In unit_ui:building_hover_listener(), but there's no main_settlement_panel found!")
	end

	logf("Starting the building hover listener!")

	-- TODO listen for a hover over a construction slot within a settlement panel
		-- there's a "Construction_Slot" UIC type that can exist, only within settlement_panel->main_settlement_panel
		-- within that, a construction_popup triggers with each building set UIC within. once you hover over a building set UIC, a second_construction_popup triggers
		-- within THAT, the second_cp, we need to trigger the handle_slot_parent function again!


	--[ui] <531.5s>   path from root:		root > settlement_panel > main_settlement_panel > capital > settlement_capital > building_slot_3 > Slot2_Construction_Site > frame_expand_slot > button_expand_slot
		-- settlement_capital
		-- player
		-- button_expand_slot
		-- hover

	-- Listen for a hover over a "construction slot" that's available within the UI, to adjust the available buildings that popup within the construction dialogs.
    local is_hovered = false
	core:remove_listener("VLIB_ConstructionHovered")
	core:add_listener(
		"VLIB_ConstructionHovered",
		"ComponentMouseOn",
		function(context)
			local uic = UIComponent(context.component)
			if not uicomponent_descended_from(uic, "main_settlement_panel") then return false end

			-- Make sure it's a button expand slot, and make sure it's being hovered (otherwise, it's another faction's/it's locked/etc)
            logf("Hovering over UIC in main settlement panel w/ key %q", context.string)
			return context.string == "button_expand_slot" and uic:CurrentState() == "hover" and is_hovered == false
		end,
		function(context)
            logf("Hovering upon an expand slot, checking for Second Construction Popup!")
			-- while this button is hovered, we're gonna do a repeated check!
			local handled = false
            is_hovered = true

			vlib:repeat_callback(
				function()

                    logf("Checking for SCP repeat call!")

					-- first, test if the construction_popup is on screen. If it isn't, we've moved on!
					local cp = find_uicomponent("construction_popup")
					if not cp or cp and not cp:Visible() then
                        logf("No Construction Popup is found; aborting the SCP check!")
                        is_hovered = false
						return vlib:remove_callback("VLIB_ConstructionHovered")
                    end

					-- grab the "second_construction_popup", if there's one. this is the panel with all of the building icons to construct!
					local scp = find_uicomponent("second_construction_popup")
					if not scp then
						handled = false
						return
					end

					logf("At SCP, handled is: "..tostring(handled))

					-- if not handled then
						local slot_parent = find_uicomponent(scp, "list_holder", "building_tree", "slot_parent")

                        if is_uicomponent(slot_parent) and slot_parent:Visible() and slot_parent:ChildCount() > 0 then
    						UnitObj.handle_slot_parent(slot_parent)
                            handled = true
                        end
					-- end
				end,
				10, -- every ms to check
				"VLIB_ConstructionHovered"
			)
		end,
		true
	)


	core:remove_listener("VLIB_BuildingHovered")
	core:add_listener(
		"VLIB_BuildingHovered",
		"ComponentMouseOn",
		function(context)
			local uic = UIComponent(context.component)
			local p = UIComponent(uic:Parent())

			return 
                (string.find(p:Id(), "building_slot_") and 
                uicomponent_descended_from(uic, "main_settlement_panel")) or 
                uicomponent_descended_from(uic, "slot_parent")
		end,
		function(context)
			local uic = UIComponent(context.component)
			_building_hovered = context.string

			logf("Hovered over building w/ key %q", context.string)

			local ok, er = pcall(function()
			
			vlib:callback(
				function()
					logf("trying to get the BIP!")
					local bip = UnitObj.get_bip(is_settlement_panel)
					if not bip or not bip:Visible() then return end

					if not uicomponent_descended_from(uic, "construction_popup") then
						local construction_popup = UnitObj.get_cp()
						if not construction_popup then return end
						if not _building_hovered then return end
					
						local slot_parent = find_uicomponent(construction_popup, "list_holder", "building_tree", "slot_parent")
						UnitObj.handle_slot_parent(slot_parent)
					end

					UnitObj.edit_building_info_panel(bip)
				end,
				5,
				"VLIB_BuildingHovered"
			) end) if not ok then errf(er) end
		end,
		true
	)
end

--- Hide/remove all of the units in the recruitment pool that should be removed!
function UnitObj.open_recruitment_panel()
	logf("Hiding units from recruitment pool!")

	local ok, er = pcall(function()
	local recruitment_listbox = find_uicomponent("units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox")

	local faction_key = cm:get_local_faction_name(true)
    local units = cc:get_units_for_faction(faction_key)

	if units and #units >= 1 then
		for _, intermediate_id in ipairs({"global", "local1", "local2"}) do
			local intermediate_parent = find_uicomponent(recruitment_listbox, intermediate_id)
			if intermediate_parent then
				for i = 1, #units do
                    local unit = units[i]
					local unit_key = unit:get_key()
                    logf("Checking %s within the recruitment panel", unit_key)
					local unit_uic = find_uicomponent(intermediate_parent, "unit_list", "listview", "list_clip", "list_box", unit_key.."_recruitable")
					if unit_uic then
                        local lock_state,lock_reason = unit:get_lock_state(faction_key)
                        logf("Lock state for unit [%s] in faction %q is [%s]", unit_key, faction_key, tostring(lock_state))
						if lock_state == 1 then
                            logf("%q is disabled, setting invisible!", unit_key)
							unit_uic:SetVisible(false)
						elseif lock_state >= 2 then
                            logf("%q is locked, setting visible w/ special tooltip.", unit_key)
							-- get rid of a silly white square!
							local lock = find_uicomponent(unit_uic, "disabled_script")
							lock:SetVisible(false)

							-- change the unit icon state to "locked", which shows that padlock over the unit card.
							local icon = find_uicomponent(unit_uic, "unit_icon")
							icon:SetState("locked")

							-- grab the existing tooltip, to edit.
							local tt = unit_uic:GetTooltipText()
							
							-- we're grabbing the `[[col:red]]Cannot recruit unit.[[/col]]` bit and replacing it on our own.
							local str = effect.get_localised_string("random_localisation_strings_string_StratHudbutton_Cannot_Recruit_Unit0")

							-- get rid of the col bits. the % are needed because string.gsub treats [ as a special character, so these are being "escaped"
							str = string.gsub(str, "%[%[col:red]]", "")
							str = string.gsub(str, "%[%[/col]]", "")

							-- this replaces the remaining bit, "Cannot recruit unit.", with whatever the provided lock reason is.
							-- TODO don't do this if there isn't a lock reason
							tt = string.gsub(tt, str, lock_reason, 1)

							-- cut off everything AFTER the lock reason. vanilla has trailing \n for no raisin.
							local _,y = string.find(tt, lock_reason)
							tt = string.sub(tt, 1, y)

							-- replace the tooltip!
							unit_uic:SetTooltipText(tt, true)
						end
					end
				end
			end
		end
	end
end) if not ok then errf(er) end
end

function UnitObj.open_building_browser()
	local building_browser = find_uicomponent("building_browser")
	if building_browser then
		local slot_parent = find_uicomponent(building_browser, "listview", "list_clip", "list_box", "building_tree", "slot_parent")
		UnitObj.handle_slot_parent(slot_parent)
	end

	UnitObj.building_hover_listener(false)
end

function UnitObj.open_settlement_panel()
	UnitObj.building_hover_listener(true)
end

--- TODO check if there needs to be any deets from unit_ui cleared out!
function UnitObj.close_building_browser()
    core:remove_listener("VLIB_ConstructionHovered")
    core:remove_listener("VLIB_BuildingHovered")

    _building_hovered = nil
end

function UnitObj.close_settlement_panel()
    core:remove_listener("VLIB_ConstructionHovered")
    core:remove_listener("VLIB_BuildingHovered")

    _building_hovered = nil
end

--- Hookup all the necessary listeners to do shtuff
function UnitObj.init()
	-- delay these calls by 10ms so UI can catch up
	local function f(callback, key)
		vlib:callback(callback, 10, key)
	end

	core:add_lookup_listener_callback(
		"panel_opened", "UnitObjPanelOpened", "building_browser",
		function(context)
			f(UnitObj.open_building_browser, "UnitObjPanelOpened")
		end,
		true
	)

	core:add_lookup_listener_callback(
		"panel_opened", "UnitObjPanelOpened", "settlement_panel",
		function(context)
			f(UnitObj.open_settlement_panel, "UnitObjPanelOpened")
		end,
		true
	)

	core:add_lookup_listener_callback(
		"panel_opened", "UnitObjPanelOpened", "units_recruitment",
		function(context)
			f(UnitObj.open_recruitment_panel, "UnitObjPanelOpened")
		end,
		true
	)

	core:add_lookup_listener_callback(
		"panel_opened", "UnitObjPanelOpened", "mercenary_recruitment",
		function(context)
			f(UnitObj.open_recruitment_panel, "UnitObjPanelOpened")
		end,
		true
	)

	core:add_lookup_listener_callback(
		"panel_closed", "UnitObjPanelClosed", "building_browser",
		function(context)
			f(UnitObj.close_building_browser, "UnitObjPanelClosed")
		end,
		true
	)

	core:add_lookup_listener_callback(
		"panel_closed", "UnitObjPanelClosed", "settlement_panel",
		function(context)
			f(UnitObj.close_settlement_panel, "UnitObjPanelClosed")
		end,
		true
	)
end

return UnitObj
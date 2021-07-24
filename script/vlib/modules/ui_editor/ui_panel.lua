-- the actual physical for the UI, within the game.
-- weird concept, right?

---@type UIED
local uied = core:get_static_object("ui_editor_lib")

---@class UIED_UI
local ui_obj = {
    new_button = nil,
    opened = false,

    panel = nil,
    headers_data = {},
    details_data = {},

    row_index = 1,
    rows_to_objs = {},

    key_to_uics = {},
    value_to_uics = {},

    ---@type number
    selected_row = nil,
}

function ui_obj:init()
    local new_button
    if __game_mode == __lib_type_campaign or __game_mode == __lib_type_battle then
        uied:log("bloop")
        local button_group = find_uicomponent(core:get_ui_root(), "menu_bar", "buttongroup")
        new_button = UIComponent(button_group:CreateComponent("button_ui_editor", "ui/templates/round_small_button"))

        new_button:SetTooltipText("UI Editor", true)

        uied:log("bloop 2")
        --new_button:SetImagePath()

        new_button:PropagatePriority(button_group:Priority())

        button_group:Layout()

        uied:log("bloop 5")
    elseif __game_mode == __lib_type_frontend then
        local button_group = find_uicomponent(core:get_ui_root(), "sp_frame", "menu_bar")

        new_button = UIComponent(button_group:CreateComponent("button_ui_editor", "ui/templates/round_small_button"))
        new_button:SetTooltipText("UI Editor", true)

        button_group:Layout()
    end

    if not is_uicomponent(new_button) then uied:log("NO NEW BUTTON") return end

    self.button = new_button

    -- new_button:SetVisible(false)

    core:add_listener(
        "ui_editor_opened",
        "ComponentLClickUp",
        function(context)
            return UIComponent(context.component) == self.button
        end,
        function(context)
            uied:log("button_pressed()")
            self:button_pressed()
        end,
        true
    )
end

-- 
function ui_obj:button_pressed()
    if self.opened then
        self:close_panel()
    else
        self:open_panel()
    end
end

function ui_obj:close_panel()
    -- close the panel
    local panel = self.panel

    delete_component(panel)

    self.panel = nil
    self.opened = false
end

function ui_obj:open_panel()
    -- open da panel
    local panel = self.panel

    if is_uicomponent(panel) then
        panel:SetVisible(true)
    else
        self:create_panel()
    end
end

function ui_obj:create_panel()
    local root = core:get_ui_root()
    local panel = UIComponent(root:CreateComponent("ui_editor", "ui/ui_editor/frame"))

    panel:SetVisible(true)

    uied:log("test 1")

    self.panel = panel

    --panel:PropagatePriority(5000)
    --panel:LockPriority()

    panel:SetCanResizeWidth(true) panel:SetCanResizeHeight(true)

    
    uied:log("test 2")

    local sw,sh = core:get_screen_resolution()
    panel:Resize(sw*0.95, sh*0.95)

    panel:SetCanResizeWidth(false) panel:SetCanResizeHeight(false)

    uied:log("test 3")

    -- edit the name
    local title_plaque = UIComponent(panel:Find("title_plaque"))
    local title = UIComponent(title_plaque:Find("title"))
    title:SetStateText("UI Editor")

    uied:log("test 4")

    -- hide stuff from the gfx window
    local comps = {
        UIComponent(panel:Find("checkbox_windowed")),
        UIComponent(panel:Find("ok_cancel_buttongroup")),
        UIComponent(panel:Find("button_advanced_options")),
        UIComponent(panel:Find("button_recommended")),
        UIComponent(panel:Find("dropdown_resolution")),
        UIComponent(panel:Find("dropdown_quality")),
    }

    uied:log("test 5")

    delete_component(comps)

    -- create the close button!   
    local close_button_uic = core:get_or_create_component("ui_editor_close", "ui/templates/round_medium_button", panel)
    local img_path = effect.get_skinned_image_path("icon_cross.png")
    close_button_uic:SetImagePath(img_path)
    close_button_uic:SetTooltipText("Close panel", true)

    uied:log("test 6")

    -- move to bottom center
    close_button_uic:SetDockingPoint(8)
    close_button_uic:SetDockOffset(0, -5)

    self:create_sections()
end

-- create the independent sections of the UI
-- top left (majority of the screen) will be the Testing Grounds, where the demo'd UI actually is located
-- center right will be the Details Screen, where the bits of the UI can be properly viewed/edited
-- bottom will be buttons and some other things (fullscreen mode, new UIC, load UIC, etcetcetc)
function ui_obj:create_sections()
    local panel = self.panel

    local testing_grounds = UIComponent(panel:CreateComponent("testing_grounds", "ui/vandy_lib/custom_image_tiled"))
    testing_grounds:SetState("custom_state_2")

    local ow,oh = panel:Dimensions()
    local w,h = ow*0.6,oh*0.6-20

    testing_grounds:SetCanResizeWidth(true) testing_grounds:SetCanResizeHeight(true)
    testing_grounds:Resize(w,h) -- matches the resolution of the full screen
    testing_grounds:SetCanResizeWidth(false) testing_grounds:SetCanResizeHeight(false)

    testing_grounds:SetImagePath("ui/skins/default/panel_back_border.png", 1)
    testing_grounds:SetVisible(true)

    testing_grounds:SetDockingPoint(1)
    testing_grounds:SetDockOffset(10, 45)

    do
        local details_screen = UIComponent(panel:CreateComponent("details_screen", "ui/vandy_lib/custom_image_tiled"))
        details_screen:SetState("custom_state_2")

        local nw = ow-w-20
        local nh = oh-110

        details_screen:SetCanResizeWidth(true) details_screen:SetCanResizeHeight(true)
        details_screen:Resize(nw,nh)
        details_screen:SetCanResizeWidth(false) details_screen:SetCanResizeHeight(false)

        details_screen:SetImagePath("ui/skins/default/panel_stack.png", 1)
        details_screen:SetVisible(true)
    
        details_screen:SetDockingPoint(3)
        details_screen:SetDockOffset(-5, 45)

        local details_title = UIComponent(details_screen:CreateComponent("details_title", "ui/templates/panel_subtitle"))
        details_title:Resize(details_screen:Width() * 0.9, details_title:Height())
        details_title:SetDockingPoint(2)
        details_title:SetDockOffset(0, details_title:Height() * 0.1)
    
        local details_text = core:get_or_create_component("text", "ui/vandy_lib/text/la_gioconda/center", details_title)
        details_text:SetVisible(true)
    
        details_text:SetDockingPoint(5)
        details_text:SetDockOffset(0, 0)
        details_text:Resize(details_title:Width() * 0.9, details_title:Height() * 0.9)

        do
    
            local w,h = details_text:TextDimensionsForText("[[col:fe_white]]Details[[/col]]")
        
            details_text:ResizeTextResizingComponentToInitialSize(w, h)
            details_text:SetStateText("[[col:fe_white]]Details[[/col]]")
        
            details_title:SetTooltipText("Details are cool, m8", true)
            details_text:SetInteractive(false)
            --details_text:SetTooltipText("{{tt:mct_profiles_tooltip}}", true)

        end

        local filter_holder = UIComponent(details_screen:CreateComponent("filter_holder", "ui/campaign ui/script_dummy"))
        filter_holder:SetCanResizeWidth(true)
        filter_holder:SetCanResizeHeight(true)

        filter_holder:SetDockingPoint(2)
        filter_holder:SetDockOffset(0, details_title:Height() + 5)

        filter_holder:Resize(details_title:Width(), details_title:Height() * 2.5)

        filter_holder:SetCanResizeWidth(false)
        filter_holder:SetCanResizeHeight(false)

        do
            local key_filter_text = UIComponent(filter_holder:CreateComponent("key_filter_text", "ui/vandy_lib/text/la_gioconda/center"))
            key_filter_text:SetVisible(true)

            key_filter_text:SetDockingPoint(4)
            key_filter_text:SetDockOffset(10, -30)
            key_filter_text:Resize(filter_holder:Width() * 0.3, key_filter_text:Height())

            do
                local mw,mh = key_filter_text:TextDimensionsForText("[[col:fe_white]]Filter by Key[[/col]]")
            
                key_filter_text:ResizeTextResizingComponentToInitialSize(mw, mh)
                key_filter_text:SetStateText("[[col:fe_white]]Filter by Key[[/col]]")
            
                key_filter_text:SetTooltipText("Filter by Key, wtf else do you want me to say", true)
                key_filter_text:SetInteractive(false)
            end
            
            local value_filter_text = UIComponent(filter_holder:CreateComponent("value_filter_text", "ui/vandy_lib/text/la_gioconda/center"))
            value_filter_text:SetVisible(true)

            value_filter_text:SetDockingPoint(4)
            value_filter_text:SetDockOffset(10, 30)
            value_filter_text:Resize(filter_holder:Width() * 0.3, value_filter_text:Height())

            do
                local mw,mh = value_filter_text:TextDimensionsForText("[[col:fe_white]]Filter by Value[[/col]]")
            
                value_filter_text:ResizeTextResizingComponentToInitialSize(mw, mh)
                value_filter_text:SetStateText("[[col:fe_white]]Filter by Value[[/col]]")
            
                value_filter_text:SetTooltipText("Filter by Value, do it, I dare you", true)
                value_filter_text:SetInteractive(false)
            end

            local key_filter = UIComponent(filter_holder:CreateComponent("key_filter_input", "ui/common ui/text_box"))

            key_filter:SetVisible(true)
            key_filter:SetDockingPoint(5)
            key_filter:SetDockOffset(20, -30)
        
            key_filter:SetTooltipText("The filter for the key, wtf", true)
        
            key_filter:SetInteractive(true)
            
            key_filter:SetCanResizeWidth(true)
            key_filter:Resize(filter_holder:Width() * 0.5, key_filter:Height())
        
            key_filter:SetStateText("")
            
            local value_filter = UIComponent(filter_holder:CreateComponent("value_filter_input", "ui/common ui/text_box"))

            value_filter:SetVisible(true)
            value_filter:SetDockingPoint(5)
            value_filter:SetDockOffset(20, 30)
        
            value_filter:SetTooltipText("Hiiiiiii filter the value", true)
        
            value_filter:SetInteractive(true)
            
            value_filter:SetCanResizeWidth(true)
            value_filter:Resize(filter_holder:Width() * 0.5, key_filter:Height())
        
            value_filter:SetStateText("")

            local do_filter = UIComponent(filter_holder:CreateComponent("do_filter", "ui/templates/square_medium_button"))
            do_filter:SetTooltipText("Do the filter", true)
            do_filter:SetVisible(true)

            do_filter:SetDockingPoint(6)
            do_filter:SetDockOffset(-20, 0)
        end

        local w,h = nw-20, (nh-details_title:Height()-filter_holder:Height()-50) * 0.45

        -- header list view
        do
            local list_view = UIComponent(details_screen:CreateComponent("ui_obj_list_view", "ui/vandy_lib/vlist"))
            list_view:SetCanResizeWidth(true) list_view:SetCanResizeHeight(true)
            list_view:Resize(w, h)
            list_view:SetDockingPoint(2)
            list_view:SetDockOffset(10, details_title:Height() + filter_holder:Height() + 5)
        
            local x,y = list_view:Position()
            local w,h = list_view:Bounds()
            uied:log("list view bounds: ("..tostring(w)..", "..tostring(h)..")")
        
            local lclip = UIComponent(list_view:Find("list_clip"))
            lclip:SetCanResizeWidth(true) lclip:SetCanResizeHeight(true)
            lclip:SetDockingPoint(0)
            lclip:SetDockOffset(0, 0)
            lclip:Resize(w,h)
    
            uied:log("list clip bounds: ("..tostring(lclip:Width()..", "..tostring(lclip:Height())..")"))
        
            local lbox = UIComponent(lclip:Find("list_box"))
            lbox:SetCanResizeWidth(true) lbox:SetCanResizeHeight(true)
            lbox:SetDockingPoint(0)
            lbox:SetDockOffset(0, 0)
            lbox:Resize(w-30,h)
    
            uied:log("list box bounds: ("..tostring(lbox:Width()..", "..tostring(lbox:Height())..")"))
        end

        -- details list view
        do
            local list_view = UIComponent(details_screen:CreateComponent("ui_details_list_view", "ui/vandy_lib/vlist"))
            list_view:SetCanResizeWidth(true) list_view:SetCanResizeHeight(true)
            list_view:Resize(w, h)
            list_view:SetDockingPoint(8)
            list_view:SetDockOffset(10, 5)
        
            local x,y = list_view:Position()
            local w,h = list_view:Bounds()
            -- uied:log("list view bounds: ("..tostring(w)..", "..tostring(h)..")")
        
            local lclip = UIComponent(list_view:Find("list_clip"))
            lclip:SetCanResizeWidth(true) lclip:SetCanResizeHeight(true)
            lclip:SetDockingPoint(0)
            lclip:SetDockOffset(0, 0)
            lclip:Resize(w,h)
    
            -- uied:log("list clip bounds: ("..tostring(lclip:Width()..", "..tostring(lclip:Height())..")"))
        
            local lbox = UIComponent(lclip:Find("list_box"))
            lbox:SetCanResizeWidth(true) lbox:SetCanResizeHeight(true)
            lbox:SetDockingPoint(0)
            lbox:SetDockOffset(0, 0)
            lbox:Resize(w-30,h)
    
            -- uied:log("list box bounds: ("..tostring(lbox:Width()..", "..tostring(lbox:Height())..")"))
        end
    end

    do
        local buttons_holder = UIComponent(panel:CreateComponent("buttons_holder", "ui/vandy_lib/custom_image_tiled"))
        buttons_holder:SetState("custom_state_2")

        local nw = w-20
        local nh = oh-h-150

        buttons_holder:SetCanResizeWidth(true) buttons_holder:SetCanResizeHeight(true)
        buttons_holder:Resize(nw,nh)
        buttons_holder:SetCanResizeWidth(false) buttons_holder:SetCanResizeHeight(false)

        buttons_holder:SetImagePath("ui/skins/default/parchment_texture.png", 1)
        buttons_holder:SetVisible(true)
    
        buttons_holder:SetDockingPoint(7)
        buttons_holder:SetDockOffset(10, -85)

        self:create_buttons_holder()
    end
end

-- TODO clear filter function
-- TODO better row uic names and getting and shit

function ui_obj:do_filter()
    uied:log("Doing the filter")
    local panel = self.panel
    local filter_holder = find_uicomponent(panel, "details_screen", "filter_holder")

    if not is_uicomponent(filter_holder) then
        uied:log("Wtf no filter holder.")
        return false
    end

    local ok, msg = pcall(function()

    local key_filter_input = UIComponent(filter_holder:Find("key_filter_input"))
    local value_filter_input = UIComponent(filter_holder:Find("value_filter_input"))

    local key_filter = key_filter_input:GetStateText()
    local value_filter = value_filter_input:GetStateText()

    if key_filter == "" then key_filter = nil end
    if value_filter == "" then value_filter = nil end


    local root = uied.copied_uic

    local function loopy(stuff, parent_uic)
        local str = tostring(stuff)
        if str:find("UI_Field") then
            local key = stuff:get_key()
            local value = stuff:get_value_text()

            local create = false

            if key_filter and key:find(key_filter) then
                create = true
            end

            if value_filter and value:find(value_filter) then
                create = true
            end

            if create then
                self:create_details_row_for_field(stuff, parent_uic)
            end

            return create
        else
            local list_box = self.headers_data.list_box
            local uic = stuff:get_uic()
            local id = uic:Id()

            local canvas = UIComponent(list_box:Find(id.."_canvas"))

            local data = stuff:get_data()
            local any_created = false
            for i = 1, #data do
                local datum = data[i]

                local created = loopy(datum, uic)
                if created then any_created = true end
            end

            if any_created then
                if is_uicomponent(canvas) then
                    canvas:SetVisible(true)
                end
            end
        end
    end

    loopy(root)

    end) if not ok then uied:err(msg) end

end

-- create the various buttons of the bottom bar
function ui_obj:create_buttons_holder()
    -- to start, just a "load" button that automatically loads "ui/templates/bullet_point"

    local panel = self.panel
    local buttons_holder = UIComponent(panel:Find("buttons_holder"))
    if not is_uicomponent(buttons_holder) then
        -- errmsg
        return false
    end

    local load_button = core:get_or_create_component("ui_editor_load_button", "ui/templates/square_medium_button", buttons_holder)
    load_button:SetVisible(true)
    load_button:SetDockingPoint(5)
    load_button:SetDockOffset(0,0)
    load_button:SetInteractive(true)
    load_button:SetTooltipText("Load UIC Details", true)

    local save_button = core:get_or_create_component("ui_editor_save_button", "ui/templates/square_medium_button", buttons_holder)
    save_button:SetVisible(true)
    save_button:SetDockingPoint(5)
    save_button:SetDockOffset(65,0)
    save_button:SetInteractive(true)
    save_button:SetTooltipText("Save UIC as Copy", true)

    local test_button = core:get_or_create_component("ui_editor_test_button", "ui/templates/square_medium_button", buttons_holder)
    test_button:SetVisible(true)
    test_button:SetDockingPoint(5)
    test_button:SetDockOffset(-100, 0)
    test_button:SetInteractive(true)
    test_button:SetTooltipText("Display UIC", true)

    local full_screen_button = core:get_or_create_component("ui_editor_full_screen_button", "ui/templates/square_medium_button", buttons_holder)
    full_screen_button:SetVisible(true)
    full_screen_button:SetDockingPoint(5)
    full_screen_button:SetDockOffset(-100, -50)
    full_screen_button:SetInteractive(true)
    full_screen_button:SetTooltipText("Display UIC as Fullscreen", true)


    local path_name_input = core:get_or_create_component("path_name_input","ui/common ui/text_box", buttons_holder)

    path_name_input:SetVisible(true)
    path_name_input:SetDockingPoint(5)
    path_name_input:SetDockOffset(0, 50)

    path_name_input:SetTooltipText("Path to loaded UIC (from where Warhammer2.exe is located)", true)

    path_name_input:SetInteractive(true)
    
    path_name_input:SetCanResizeWidth(true)
    path_name_input:Resize(test_button:Width() * 8, path_name_input:Height())
    --path_name_input:SetCanResizeWidth(false)

    path_name_input:SetStateText("")
end

function ui_obj:get_path()
    local panel = self.panel
    local path_name_input = find_uicomponent(panel, "buttons_holder", "path_name_input")

    if not is_uicomponent(path_name_input) then
        -- errmsg
        return false
    end

    local path = path_name_input:GetStateText()

    -- TODO verify that the path is valid - there's a file there and what not


    return path
end

function ui_obj:create_loaded_uic_in_testing_ground(is_copied, is_fullscreen)
    local path = uied.loaded_uic_path

    if is_copied then
        path = "ui/ui_editor/"..uied:get_testing_file_string()
    end

    local panel = self.panel
    if not panel or not is_uicomponent(panel) or not path then
        uied:log("create loaded uic in testing ground failed")
        return false
    end

    local testing_grounds = UIComponent(panel:Find("testing_grounds"))
    testing_grounds:DestroyChildren()

    if is_fullscreen then
        -- local cw,ch = core:get_screen_resolution()
        -- testing_grounds:Resize(cw, ch)

        -- TODO add in a un-fullscreen button or functionality somehow
        local test_uic = UIComponent(core:get_ui_root():CreateComponent("testing_component", path))

        if not is_uicomponent(test_uic) then
            uied:log("test uic failed!")
            return false
        end

        test_uic:SetVisible(true)

        local fullscreen_disable_button = UIComponent(core:get_ui_root():CreateComponent("fullscreen_disable", "ui/templates/square_medium_button"))
        fullscreen_disable_button:SetDockingPoint(2)
        fullscreen_disable_button:SetDockOffset(0, 40)

        panel:SetVisible(false)

        core:add_listener(
            "fullscreen_disable",
            "ComponentLClickUp",
            function(context)
                return context.string == "fullscreen_disable"
            end,
            function(context)
                uied:log("fullscreen_disable")
                local uic = UIComponent(context.component)

                delete_component(uic)
                delete_component(test_uic)

                if is_uicomponent(panel) then
                    panel:SetVisible(true)
                end
            end,
            false
        )

        return
    end

    local test_uic = UIComponent(testing_grounds:CreateComponent("testing_component", path))
    if not is_uicomponent(test_uic) then
        uied:log("test uic failed!")
        return false
    end

    test_uic:SetVisible(true)
    test_uic:SetDockingPoint(5)
    test_uic:SetDockOffset(0, 0)

    local w,h = test_uic:Bounds()

    local ow,oh = testing_grounds:Dimensions()

    local wf,hf = 0,0

    if w > ow then
        wf = w/ow
    end

    if h > oh then
        hf = h/oh
    end

    local f

    if wf >= hf then f = wf else f = hf end

    if f == 0 then
        return
    end

    test_uic:SetCanResizeWidth(true)
    test_uic:SetCanResizeHeight(true)

    test_uic:Resize(w/f,h/f)

    test_uic:SetCanResizeWidth(false)
    test_uic:SetCanResizeHeight(false)
    
end

---comment
---@param obj UIC_BaseClass
---@return boolean
function ui_obj:create_details_header_for_obj(obj)
    local list_box = self.headers_data.list_box
    local x_margin = self.headers_data.x_margin
    local default_h = self.headers_data.default_h

    if not is_uicomponent(list_box) then
        uied:log("display called on obj ["..obj:get_key().."], but the list box don't exist yo")
        uied:log(tostring(list_box))
        return false
    end

    -- create the header_uic for the holder of the UIC
    local header_uic = UIComponent(list_box:CreateComponent("ui_header_"..self.row_index, "ui/vandy_lib/expandable_row_header"))

    self.rows_to_objs[tostring(self.row_index)] = obj
    obj:set_row_number(self.row_index)
    self.row_index = self.row_index+1

    obj:set_uic(header_uic)


    header_uic:SetCanResizeWidth(true)
    header_uic:SetCanResizeHeight(false)
    header_uic:Resize(list_box:Width() * 0.95 - x_margin, header_uic:Height())
    header_uic:SetCanResizeWidth(false)

    if default_h == 0 then self.headers_data.default_h = header_uic:Height() end

    -- TODO set a tooltip on the header uic entirely
    header_uic:SetDockingPoint(0)
    header_uic:SetDockOffset(x_margin, 0)

    local dy_title = UIComponent(header_uic:Find("dy_title"))
    dy_title:SetStateText(obj:get_type() .. ": " .. obj:get_key())

    local child_count = UIComponent(header_uic:Find("child_count"))
    if obj:get_type() == "UI_Collection" then
        local str = tostring(#obj.data)
        if not str or str == "" then
            child_count:SetVisible(false)
        else
            child_count:SetStateText(tostring(#obj.data))
        end
    else
        child_count:SetVisible(false)
    end

    ---@diagnostic disable-next-line
    if (obj:get_type() == "Component" and not obj:is_root()) or obj:get_type() ~= "Component" and obj:get_type() ~= "UI_Collection" then
        local delete_button = UIComponent(header_uic:CreateComponent("delete", "ui/templates/square_medium_button"))

        delete_button:SetDockingPoint(6)
        delete_button:SetDockOffset(-5, 0)

        delete_button:SetCanResizeWidth(true)
        delete_button:SetCanResizeHeight(true)
        delete_button:Resize(header_uic:Height() * 0.8, header_uic:Height() * 0.8)
        delete_button:SetCanResizeHeight(false)
        delete_button:SetCanResizeWidth(false)

        core:add_listener(
            "delete_component",
            "ComponentLClickUp",
            function(context)
                return UIComponent(context.component) == delete_button
            end,
            function(context)
                uied:log("Object ["..obj:get_key().."] with type ["..obj:get_type().."] being deleted!")
                local parent = obj:get_parent()

                uied:log("Parent obj key is ["..parent:get_key().."], of type ["..parent:get_type().."].")

                -- remove the data from the parent!
                parent:remove_data(obj)

                uied:log("Bloop 1")


                -- delete the canvas and the header UIC
                local header_uic_id = header_uic:Id()
                uied:log("Bloop 2")
                delete_component(header_uic)
                uied:log("Bloop 3")

                local find = list_box:Find(header_uic_id.."_canvas")
                if find then
                    delete_component(UIComponent(find))
                end
                
                uied:log("Bloop 4")
            end,
            false
        )
    end

    -- move the x_margin over a bit
    self.headers_data.x_margin = x_margin + 10

    ---- TODO debug stuff, keep this?
    -- set the state of the header to closed
    -- if obj is a UIC, set it to closed
    -- if obj:get_type() == "UIED_Component" or obj:get_type() == "UI_Collection" and obj:get_key() == "Components" then
        header_uic:SetState("active")
        header_uic:SetVisible(true)
        obj.state = "closed"
    -- else 
    --     -- set it to invisible
    --     header_uic:SetState("active")
    --     header_uic:SetVisible(false)
    --     obj.state = "invisible"
    -- end

    -- loop through every field in "data" and call its own display() method
    local data = obj:get_data()

    uied:log("hand-crafting details header for obj ["..obj:get_key().."] with type ["..obj:get_type().."].\nNumber of data is: "..tostring(#data))

    for i = 1, #data do
        uied:log("in ["..tostring(i).."] within obj ["..obj:get_key().."].")
        local d = data[i]
        -- local d_key = d.key -- needed?
        local d_obj

        uied:log("Testing obj: "..tostring(d))
        uied:log("")

        -- if obj:get_key() == "dy_txt" then
        --     uied:log("VANDY LOOK HERE")
        --     uied:log(i.."'s key: " .. d:get_key())
        --     if tostring(d) == "UI_Field" then
        --         uied:log(i.."'s val: " .. tostring(d:get_value()))
        --     end
        -- end

        if string.find(tostring(d), "Component") or string.find(tostring(d), "UI_Collection") or string.find(tostring(d), "UI_Field") then
            uied:log("inner child is a class")
            d_obj = d
        -- elseif type(d) == "table" then
        --     uied:log("inner child is a table")
        --     if not is_nil(d.value) then
        --         d_obj = d.value
        --     else
        --         uied:log("inner child table doesn't ")
        --     end
        else
            -- TODO errmsg
            uied:log("inner child is not a field or a class, Y")
            -- TODO resolve what to do if it's just a raw value?
        end

        if is_nil(d_obj) or not is_table(d_obj) then
            uied:log("we have a nil d_obj!")
        else
            self:display(d_obj)
        end
    end

    -- move the x_margin back to where it began here, after doing the internal loops
    self.headers_data.x_margin = x_margin
end

---comment
---@param obj UIC_Field
---@return boolean
function ui_obj:create_details_row_for_field(obj)
    local list_box = self.details_data.list_box
    local x_margin = 0
    local default_h = self.headers_data.default_h
    
    if not is_uicomponent(list_box) then
        uied:log("display called on field ["..obj:get_key().."], but the list box don't exist yo")
        uied:log(tostring(list_box))
        return false
    end
    
    -- TODO get this working betterer (prettierer) for tables

    local key = obj:get_key()

    local type_text,tooltip_text,value_text = obj:get_display_text()

    local row_uic = UIComponent(list_box:CreateComponent("ui_field_"..self.row_index, "ui/campaign ui/script_dummy"))

    self.rows_to_objs[tostring(self.row_index)] = obj
    obj:set_row_number(self.row_index)
    self.row_index = self.row_index + 1

    obj:set_uic(row_uic)

    row_uic:SetCanResizeWidth(true) row_uic:SetCanResizeHeight(true)
    row_uic:Resize(math.floor(list_box:Width() * 0.95 - x_margin), default_h)
    row_uic:SetCanResizeWidth(false) row_uic:SetCanResizeHeight(false)
    row_uic:SetInteractive(true)

    row_uic:SetDockingPoint(0)

    row_uic:SetDockOffset(x_margin, 0)

    row_uic:SetTooltipText(tooltip_text, true)

    if self.key_to_uics[key] then
        self.key_to_uics[key][#self.key_to_uics[key]+1] = row_uic
    else
        self.key_to_uics[key] = {row_uic}
    end

    if self.value_to_uics[value_text] then
        self.value_to_uics[value_text][#self.value_to_uics[value_text]+1] = row_uic
    else
        self.value_to_uics[value_text] = {row_uic}
    end

    local left_text_uic = UIComponent(row_uic:CreateComponent("key", "ui/vandy_lib/text/la_gioconda/unaligned"))

    do
        local ow,oh = row_uic:Width() * 0.3, row_uic:Height() * 0.9
        local str = "[[col:white]]"..type_text.."[[/col]]"

        left_text_uic:Resize(ow,oh)

        local w,h = left_text_uic:TextDimensionsForText(str)
        left_text_uic:ResizeTextResizingComponentToInitialSize(w,h)

        left_text_uic:SetStateText(str)

        left_text_uic:Resize(ow,oh)
        w,h = left_text_uic:TextDimensionsForText(str)
        left_text_uic:ResizeTextResizingComponentToInitialSize(ow,oh)
    end

    left_text_uic:SetVisible(true)
    left_text_uic:SetDockingPoint(4)
    left_text_uic:SetDockOffset(5, 0)

    left_text_uic:SetTooltipText(tooltip_text, true)

    -- change the str
    if obj:is_editable() and obj:get_native_type() == "utf8" or obj:get_native_type() == "utf16"--[[and obj:get_key() == "text"]] then
        local right_text_uic = UIComponent(row_uic:CreateComponent("uied_textbox", "ui/common ui/text_box"))
        local ok_button = UIComponent(right_text_uic:CreateComponent("uied_check_name", "ui/templates/square_medium_button"))

        right_text_uic:SetVisible(true)
        right_text_uic:SetDockingPoint(5)
        right_text_uic:SetDockOffset(10, 0)

        right_text_uic:SetTooltipText(obj:get_hex(), true)

        right_text_uic:SetInteractive(true)
        right_text_uic:Resize(row_uic:Width() * 0.5, row_uic:Height() * 0.85)

        right_text_uic:SetStateText(value_text)

        ok_button:SetDockingPoint(6)
        ok_button:SetDockOffset(20, 0)

        ok_button:Resize(right_text_uic:Height() * 0.6, right_text_uic:Height() * 0.6)
        
        -- local right_text_uic = UIComponent(row_uic:CreateComponent("right_text_uic", ""))
    -- TODO pick one, fucker (bool or boolean, that is)
    elseif obj:is_editable() and obj:get_native_type() == "bool" or obj:get_native_type() == "boolean" then
        local right_text_uic = UIComponent(row_uic:CreateComponent("uied_checkbox", "ui/templates/checkbox_toggle"))

        right_text_uic:SetVisible(true)
        right_text_uic:SetDockingPoint(5)
        right_text_uic:SetDockOffset(30, 0)

        right_text_uic:SetTooltipText(obj:get_hex(), true)

        right_text_uic:SetInteractive(true)

        local val = obj:get_value()

        if val == true then
            right_text_uic:SetState("selected")
        else 
            right_text_uic:SetState("active")
        end
        -- right_text_uic:Resize(row_uic:Width() * 0.5, row_uic:Height() * 0.85)

        -- right_text_uic:SetStateText(value_text)
    else        
        local right_text_uic = UIComponent(row_uic:CreateComponent("value", "ui/vandy_lib/text/la_gioconda/unaligned"))
        right_text_uic:SetCanResizeWidth(true) right_text_uic:SetCanResizeHeight(true)
        do
            local ow,oh = row_uic:Width() * 0.6, row_uic:Height() * 0.9
            local str = "[[col:white]]"..value_text.."[[/col]]"

            right_text_uic:Resize(ow,oh)

            local w,h = right_text_uic:TextDimensionsForText(str)
            right_text_uic:ResizeTextResizingComponentToInitialSize(w,h)

            right_text_uic:SetStateText(str)

            right_text_uic:Resize(ow,oh)
            w,h = right_text_uic:TextDimensionsForText(str)
            right_text_uic:ResizeTextResizingComponentToInitialSize(ow,oh)
        end

        right_text_uic:SetVisible(true)
        right_text_uic:SetDockingPoint(6)
        right_text_uic:SetDockOffset(0, 0)

        right_text_uic:SetTooltipText(obj:get_hex(), true)
    end
end

--- TODO; write up the visual stuff for a details collection
-- Used for stuff like "dimensions" or "shader vars"; can either be an array or a map (implicit or explicit keys!)
-- Give a main row with the primary stuff about the collection and then one more row for each field in the table :)
function ui_obj:create_details_row_for_collection(obj)
    local list_box = self.details_data.list_box
    local x_margin = 0
    local default_h = self.headers_data.default_h
    
    if not is_uicomponent(list_box) then
        uied:log("display called on field ["..obj:get_key().."], but the list box don't exist yo")
        uied:log(tostring(list_box))
        return false
    end
    
    -- TODO get this working betterer (prettierer) for tables

    local key = obj:get_key()

    -- local type_text,tooltip_text,value_text = obj:get_display_text()

    local row_uic = UIComponent(list_box:CreateComponent("ui_field_"..self.row_index, "ui/campaign ui/script_dummy"))

    self.rows_to_objs[tostring(self.row_index)] = obj
    obj:set_row_number(self.row_index)
    self.row_index = self.row_index + 1

    obj:set_uic(row_uic)

    row_uic:SetCanResizeWidth(true) row_uic:SetCanResizeHeight(true)
    row_uic:Resize(math.floor(list_box:Width() * 0.95 - x_margin), default_h)
    row_uic:SetCanResizeWidth(false) row_uic:SetCanResizeHeight(false)
    row_uic:SetInteractive(true)

    row_uic:SetDockingPoint(0)

    row_uic:SetDockOffset(x_margin, 0)

    row_uic:SetTooltipText("TODO This tooltip!", true)

    -- if self.key_to_uics[key] then
    --     self.key_to_uics[key][#self.key_to_uics[key]+1] = row_uic
    -- else
    --     self.key_to_uics[key] = {row_uic}
    -- end

    -- if self.value_to_uics[value_text] then
    --     self.value_to_uics[value_text][#self.value_to_uics[value_text]+1] = row_uic
    -- else
    --     self.value_to_uics[value_text] = {row_uic}
    -- end

    local left_text_uic = UIComponent(row_uic:CreateComponent("key", "ui/vandy_lib/text/la_gioconda/unaligned"))

    do
        local ow,oh = row_uic:Width() * 0.3, row_uic:Height() * 0.9
        local str = "[[col:white]]Collection: "..key.."[[/col]]"

        left_text_uic:Resize(ow,oh)

        local w,h = left_text_uic:TextDimensionsForText(str)
        left_text_uic:ResizeTextResizingComponentToInitialSize(w,h)

        left_text_uic:SetStateText(str)

        left_text_uic:Resize(ow,oh)
        w,h = left_text_uic:TextDimensionsForText(str)
        left_text_uic:ResizeTextResizingComponentToInitialSize(ow,oh)
    end

    left_text_uic:SetVisible(true)
    left_text_uic:SetDockingPoint(4)
    left_text_uic:SetDockOffset(5, 0)

    -- left_text_uic:SetTooltipText(tooltip_text, true)

    local ok, msg = pcall(function()

    local data = obj:get_data()

    uied:logf("Creating details collection with key %q. Looping through data!", key)

    uied:logf("Num fields: %q", #data)
    for i = 1, #data do
        uied:logf("in %d", i)
        local datum = data[i]

        uied:logf("In collection %q, within field %q", tostring(key), tostring(datum:get_key()))

        self:create_details_row_for_field(datum)
    end
end) if not ok then uied:err(msg) end
end

--- REFACTOR
function ui_obj:display(obj)
    -- only create headers for objects and collections of objects
    if string.find(tostring(obj), "Component") or (string.find(tostring(obj), "UI_Collection") and not uied.parser:is_valid_type(obj:get_held_type())) then
        if string.find(tostring(obj), "UI_Collection") then
            uied:logf("Creating a collection with held data %q", obj:get_held_type())
        end

        self:create_details_header_for_obj(obj)
    end
end

---comment
---@param obj UIC_BaseClass
function ui_obj:set_selected_details_row(obj)
    local lb = ui_obj.details_data.list_box
    lb:DestroyChildren()
    
    if is_number(self.selected_row) then
        local list_box = self.headers_data.list_box
        local uic = find_uicomponent(list_box, "ui_header_"..self.selected_row)
        -- local uic = UIComponent(self.selected_row)
        if is_uicomponent(uic) then
            uic:SetState("active")

            if self.selected_row == obj:get_row_number() then
                self.selected_row = nil
                return
            end
        end
    end

    local row_uic = obj:get_uic()
    row_uic:SetState("selected")

    self.selected_row = obj:get_row_number()

    obj:create_details()

    lb:Layout()
end



function ui_obj:create_details_for_loaded_uic()
    local panel = self.panel

    local root_uic = uied.copied_uic

    self.selected_row = nil

    uied:log("bloop 1")

    -- TODO figure out the actual look of the text for each thing
    -- TODO figure out tables

    local ok, msg = pcall(function()

    local details_screen = UIComponent(panel:Find("details_screen"))

    -- save the list_box and the x_margin to the ui_obj so it can be easily accessed through all the displays
    self.headers_data.list_box = find_uicomponent(details_screen, "ui_obj_list_view", "list_clip", "list_box")
    self.headers_data.x_margin = 0
    self.headers_data.default_h = 25

    self.details_data.list_box = find_uicomponent(details_screen, "ui_details_list_view", "list_clip", "list_box")

    -- destroy chil'un of list_box (clear previous shit)
    self.headers_data.list_box:DestroyChildren()
    self.details_data.list_box:DestroyChildren()

    -- TODO this is a potentially very expensive operation, take a look how it feels with huge files (probably runs like shit (: )
    -- Fun fact, it actually runs pretty quickly even with the largest files. Dunno how :)
    uied:log("beginning")

    self:display(root_uic)

    uied:log("end")

    -- layout the list_box to make sure everything refreshes propa
    self.headers_data.list_box:Layout()
    end) if not ok then uied:err(msg) end
end

-- load the currently deciphered UIC
-- opens the UIC in the testing grounds, and displays all the deciphered details
function ui_obj:load_uic()
    uied:log("load_uic() called")
    local panel = self.panel

    if not is_uicomponent(panel) then
        uied:log("load_uic() called, panel not found?")
        return false
    end

    self:create_details_for_loaded_uic()
end

core:add_listener(
    "checkbox_clicked",
    "ComponentLClickUp",
    function(context)
        return context.string == "uied_checkbox"
    end,
    function(context)
        uied:log("checkbox_clicked")
        local uic = UIComponent(context.component)
        local row = UIComponent(uic:Parent())
        local row_id = string.gsub(row:Id(), "ui_header_", "")
        
        local obj = ui_obj.rows_to_objs[row_id]
        if not obj then
            -- errmsg
            return false
        end

        -- local state_text = right_text_uic:GetStateText()
        local my_state = obj:get_value()

        local new_state = not my_state
        -- local new_state = UIComponent(context.component):CurrentState()
        -- local b = false
        uied:log("My new state for ["..obj:get_key().."] is: "..tostring(new_state))
        -- if new_state == "selected" then
        --     b = true
        -- end
        
        -- uied:log("Checking text: "..tostring(state_text))

        local ok, msg = pcall(obj:change_val(new_state))
        if not ok then uied:err(msg) end
    end,
    true
)

core:add_listener(
    "button_clicked",
    "ComponentLClickUp",
    function(context)
        return context.string == "uied_check_name"
    end,
    function(context)
        uied:log("button_clicked ok_button")
        local uic = UIComponent(context.component)
        local parent = UIComponent(uic:Parent())
        if parent:Id() ~= "uied_textbox" then return end
        local state_text = parent:GetStateText()

        local row = UIComponent(parent:Parent())
        local row_id = string.gsub(row:Id(), "ui_header_", "")

        local obj = ui_obj.rows_to_objs[row_id]

        uied:log("Checking text: "..tostring(state_text))

        local ok, msg = pcall(obj:change_val(state_text))
        if not ok then uied:err(msg) end
    end,
    true
)

core:add_listener(
    "header_pressed",
    "ComponentLClickUp",
    function(context)
        local str = context.string

        return string.find(str, "ui_header_")
    end,
    function(context)
        uied:log("Header pressed!")
        local str = context.string
        local ind = string.gsub(str, "ui_header_", "")

        local obj = ui_obj.rows_to_objs[ind]

        ui_obj:set_selected_details_row(obj)
    end,
    true
)


core:add_listener(
    "save_button",
    "ComponentLClickUp",
    function(context)
        return context.string == "ui_editor_save_button"
    end,
    function(context)
        uied:log("ui editor save button")
        uied:print_copied_uic()
    end,
    true
)

core:add_listener(
    "test_button",
    "ComponentLClickUp",
    function(context)
        return context.string == "ui_editor_test_button"
    end,
    function(context)
        uied:log("ui_editor_test_button")
        ui_obj:create_loaded_uic_in_testing_ground(true)
    end,
    true
)

core:add_listener(
    "full_screen_button",
    "ComponentLClickUp",
    function(context)
        return context.string == "ui_editor_full_screen_button"
    end,
    function(context)
        uied:log("ui_editor_full_screen_button")
        ui_obj:create_loaded_uic_in_testing_ground(true, true)
    end,
    true
)

core:add_listener(
    "load_button",
    "ComponentLClickUp",
    function(context)
        return context.string == "ui_editor_load_button"
    end,
    function(context)
        uied:log("ui_editor_load_button")
        -- TODO make sure get_path is valid 
        local path = ui_obj:get_path()

        uied:load_uic_with_path(path)

        --ui_obj:
    end,
    true
)

core:add_listener(
    "do_the_filter",
    "ComponentLClickUp",
    function(context)
        return context.string == "do_filter"
    end,
    function(context)
        uied:log("DO FILTER")
        -- ui_obj:do_filter()
    end,
    true
)

-- listener for the close button
core:add_listener(
    "ui_editor_close_button",
    "ComponentLClickUp",
    function(context)
        return context.string == "ui_editor_close"
    end,
    function(context)
        uied:log("ui_editor_close")
        ui_obj:close_panel()
    end,
    true
)

core:add_listener(
    "bloopity",
    "UICreated",
    true,
    function()
        uied:log("UI Created")
        local ok, msg = pcall(function()
        ui_obj:init()
        end) if not ok then uied:err(msg) end
    end,
    true
)

return ui_obj
--- TODO hook in as MCT option?
--- TODO higher latency on the repeat callback?
--- TODO doesn't work for custom battles????

local vlib = get_vlib()
local log,logf,err,errf = vlib:get_log_functions("[unit_order_bar_fix]")

local function init()
    vlib:callback(
        function()
            local orders_pane = find_uicomponent("layout", "battle_orders", "battle_orders_pane")
            local orders_parent = find_uicomponent(orders_pane, "orders_parent")
            local withdraw_button = find_uicomponent(orders_parent, "hud_extension")

            --- move the withdraw button over
        
            -- get the spacing between each element
            local one,two = find_uicomponent(orders_parent, "button_movespeed"), find_uicomponent(orders_parent, "button_melee")
            local w = one:Width()
            local dist_x = 0
            do
                local ax,_ = one:Position()
                local bx,_ = two:Position()
        
                dist_x = bx - ax - w
            end
        
            -- get the position of the final element
            local final = find_uicomponent(orders_parent, "behaviour_parent", "button_slot3")
            local fx = final:Position()
        
            local w_x,w_y = withdraw_button:Position()
            w_x = fx+dist_x+w
            withdraw_button:MoveTo(w_x, w_y)
        
            local nx,ny = withdraw_button:Position()
        
            log("Moving withdraw button from " .. w_x .. " to " .. fx+dist_x+w)
            log("New withdraw pos: ("..nx..", "..ny..")")
        
            --- widen the bottom_bar
            local bottom_bar = find_uicomponent(orders_pane, "bottom_bar")
            local bw,bh = bottom_bar:GetCurrentStateImageDimensions(1)
            bottom_bar:SetCanResizeCurrentStateImageWidth(1, true)
            bottom_bar:ResizeCurrentStateImage(1, bw+dist_x*2+w, bh)
        
            --- reposition the orders_parent by the difference
            local ax,ay = orders_parent:Position()
            local o_x,o_y = ax-dist_x-w/2, ay
            orders_parent:MoveTo(o_x, o_y)

            w_x = withdraw_button:Position()

            -- reapply the withdraw button / orders_parent move every 1s (to catch hiding/unhiding the entire layout)
            vlib:repeat_callback(function()
                local orders_pane = find_uicomponent("layout", "battle_orders", "battle_orders_pane")
                if not orders_pane then return end
                local orders_parent = find_uicomponent(orders_pane, "orders_parent")
                local withdraw_button = find_uicomponent(orders_parent, "hud_extension")
                
                orders_parent:MoveTo(o_x, o_y)
                withdraw_button:MoveTo(w_x, w_y)
            end, 1000, "unit_order_bar_fix")
        end, 1000
    )
end

-- bm:register_phase_change_callback("Deployment", function()  init() end)
core:add_listener(
    "t",
    "ScriptEventDeploymentPhaseBegins",
    true,
    function(context)
        init()
    end,
    false
)
--- This is the internal functionality to have fully customizable custom tabs for your mct_mod.
--- TODO move all tab stuff in here
--- TODO add-new-tabs in here.
--- @class ui_tab

local mct = get_mct()

local ui_tab = {}

function ui_tab.new(mct_mod, key, image_path, tooltip_text)
    local self = {}
    setmetatable(self, {__index = ui_tab})

    self.mod = mct_mod
    self.key = key
    self.image_path = image_path
    self.tooltip_text = tooltip_text
end

function ui_tab:set_validity_callback(callback)
    


end
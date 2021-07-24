---@class effect
---@type effect
effect = {
    --- Get the localised text for any loc-key. Returns a blank string if none are found.
    ---@param key string The loc key - ie., what would be passed to the key column in a .loc file.
    ---@return string text The returned localised text.
    get_localised_string = function(key) return "" end,

    --- Performs a VFS lookup in the specified relative path (root is data/) for files matching the supplied pattern. Returns a comma-delimited list of files found. 
    ---@param path string Path from data/ in which to look.
    ---@param path string Search pattern. Can use wildcard (*), ie. "*.lua"
    ---@return string list Comma-delimited list of files found, with the full paths.
    filesystem_lookup = function(path, path) return "" end,

    --- Retrieves a full image path from the working data folder for a supplied image name that obeys the currently loaded skins. For each loaded skin, the existence of the image is queried and, should it exist, the path to that image is returned. If the image is not found then a path to the image in the default skin folder is returned, although in this case the existence of the image is not checked for. The returned image path can subsequently be supplied to uicomponent:SetImagePath.
    ---@param img_name string The name of the image searched for, including file extension - ie. "icon_ritual.png"
    ---@return string path The returned path for the image.
    get_skinned_image_path = function(img_name) return "" end,
}

---@param key string
---@param template string
---@param parent UIComponent
---@return UIComponent
function core:get_or_create_component(key, template, parent) return end

function string.gfind() end

---@class real_timer
---@type real_timer
real_timer = {
    --- Register a string that will trigger a RealTimeTrigger event in [ms] milliseconds, with the context.string [name].
    ---@param name string The name of the event.
    ---@param ms number How many milliseconds between triggers.
    register_singleshot = function(name, ms) return end,

    --- Register a string that triggers a RealTimeTrigger, every [ms], with the context.strings [name].
    ---@param name string The name of the event.
    ---@param ms number How many milliseconds between triggers.
    register_repeating = function(name, ms) return end,

    --- Cancel an in-progress repeating event, set by register_repeating.
    ---@param name string The name of the event to cancel.
    unregister = function(name) return end,
}

---@class CampaignUI
---@type CampaignUI
CampaignUI = {
    --- Allows the script running on one machine in a multiplayer game to cause a scripted event, UITriggerScriptEvent, to be triggered on all machines in that game. By listening for this event, scripts on all machines in a multiplayer game can therefore respond to a UI event occuring on just one of those machines.
    --- An optional string event id and number faction cqi may be specified. If specified, these values are passed from the triggering script through to all listening scripts, using the context objects supplied with the events. The event id may be accessed by listening scripts by calling <context>:trigger() on the supplied context object, and can be used to identify the script event being triggered. The faction cqi may be accessed by calling <context>:faction_cqi() on the context object, and can be used to identify a faction associated with the event. Both must be specified, or neither.
    ---@see VanishMP
    ---@param faction_cqi number The supplied faction_cqi, so we know what faction triggered the message. Can be any other number, if the faction triggering is known through other means.
    ---@param event_id string The string to pass between PC's.
    TriggerCampaignScriptEvent = function(faction_cqi, event_id) end
}

--- TODO fill this out (:
---@class UIComponent
---@type UIComponent
local UIC = {
    SetState = function(self, state) return end,
    SetStateText = function(self, text) return end,
    MoveTo = function(self) return end,
    SetMoveable = function(self) return end,
    Resize = function(self) return end,
    SetCanResizeHeight = function(self) return end,
    SetCanResizeWidth = function(self) return end,
    ResizeTextResizingComponentToInitialSize = function(self) return end,
    SetDockingPoint = function(self) return end,
    SetDockOffset = function(self) return end,
    SetTooltipText = function(self) return end,
    SetImagePath = function(self) return end,
    SetVisible = function(self) return end,
    SetInteractive = function(self) return end,
    SetDisabled = function(self) return end,
    SetProperty = function(self) return end,
    Address = function(self) return end,
    Parent = function(self) return end,
    Visible = function(self) return end,
    Find = function(self) return end,
    GetStateText = function(self) return end,
    ChildCount = function(self) return end,
    CreateComponent = function(self) return end,
    Id = function(self) return end,
    GetTooltipText = function(self) return end,
    CurrentState = function(self) return end,
    GetDockOffset = function(self) return end,
    TextDimensionsForText = function(self) return end,
    DestroyChildren = function(self) return end,
    Destroy = function(self) return end,
    Bounds = function(self) return end,
    RemoveTopMost = function(self) return end,
    PropagatePriority = function(self) return end,
    PropagateVisibility = function(self) return end,
    Dimensions = function(self) return end,
    Width = function(self) return end,
    Height = function(self) return end,
    Position = function(self) return end,
    Priority = function(self) return end,
    LockPriority = function(self) return end,
    UnLockPriority = function(self) return end,
    GetCurrentStateImageDimensions = function(self) return end,
    ResizeCurrentStateImage = function(self) return end,
    Layout = function(self) return end,
    Adopt = function(self) return end,
    Highlight = function(self) return end,
    SimulateLClick = function(self) return end,
    RegisterTopMost = function(self) return end,
    StartPulseHighlight = function(self) return end,
    StopPulseHighlight = function(self) return end,
}

---@type battle_manager
battle_manager = battle_manager;

--- Turn the address of a UIC to the wrapped UIComponent object.,
---@param address userdata|string Gotten through context.component in Component events, or UIC:Address()
---@return UIComponent
function UIComponent(address)
    return UIC
end

---@return UIComponent
function find_uicomponent(...)

end

---@class VFS Stands for "Virtual File System". I wish it did more. :)
vfs = {
    --- Check if there's any file with the name, path, and extension provided.
    ---@param name string The file searched.
    ---@return boolean
    exists = function(name) return true end,
}

---@type string The name of the currently loaded campaign.
CampaignName = ""
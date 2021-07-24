--- A system for creating classes in Lua.

-- TODO this. Have all the shared "manager" stuff between all of the various managers within this.
-- Filters, getting, setting, tostring'ing, grabbing, creating.
-- Also handle the held class[es] within each manager, and understand the types therein, etc.
-- Potentially hold all of the save-state stuff within here as well?

local vlib = get_vlib()
local log,logf,err,errf = vlib:get_log_functions("[managers]")

-- Handles some high-level stuff, hold individual Objects and the Classes they're derived from. Used for getting/setting and doing most outside-in work.
---@class manager_prototype
local Manager = {
    __tostring = function(self) return "Manager [" ..  self._key .. "]" end,
    _key = "Manager Prototype",
}

-- Acts as an instance of a Class - might be a specific unit or tech, built off of a Class of that type.
---@class object_prototype
local Object = {
    _key = "Object Prototype",
}

function Manager.new(key)
    if not is_string(key) then return false end
    ---@type manager_prototype
    local o = {}
    o._key = key
    o._classes = {}
    o._objects = {}
    setmetatable(o, {__index = Manager})

    return o
end

---@return object_prototype
function Manager:get_class(key)
    if not is_string(key) then return false end
    return self._classes[key]
end

---@return object_prototype
function Manager:new_class(class_key, prototype)
    --- check if this already exists!
    local class = self:get_class(class_key)
    if class then return class end

    logf("Creating a new class w/ key %q", class_key)

    ---@type object_prototype
    class = {}
    class._prototype = prototype
    class._type = class_key

    setmetatable(class, {
        __index = Object,
        __tostring = function(t) return t._type .. " Prototype" end,    
    })

    setmetatable(class._prototype, {
        __index = Object,
        __tostring = function(t) return t._type .. " [" .. t._key .. "]" end,
    })

    self._classes[class_key] = class
    self._objects[class_key] = {}

    return class
end

--- Create a new object, build off of an existing class.
---@param obj_key string The string of the object to be created.
---@param class_key string The string of the class this object is being created from.
---@param is_external boolean|nil Set to true if you don't want the Manager to save this object locally.
---@return object_prototype
function Manager:new_object(obj_key, class_key, is_external)
    local class = self:get_class(class_key)
    if not class then return false end

    logf("Creating a new object w/ key %q of type %s", obj_key, class_key)

    if is_external then
        return class:new(obj_key)
    end

    local test = self:get_obj(obj_key, class_key)
    if test then
        logf("Trying to create a new object, but there's already one with that key found!")
        return test
    end

    local new_obj = class:new(obj_key)
    self._objects[class_key][obj_key] = new_obj

    return new_obj
end

function Object:new(key)
    logf("Duplicating a new object w/ key %q of type %s", key, self._type)

    ---@type object_prototype
    local o = table.deepcopy(self._prototype)
    o._type = self._type
    o._key = key

    o = self:instantiate(o)

    return o
end

function Object:instantiate(o)
    logf("Instantiating object w/ key %q of type %s", o._key, self._type)

    setmetatable(o, {
        __index = self._prototype,
        __tostring = function(t) return t._type .. " [" .. t._key .. "]" end,
    })

    return o
end

function Object:get_key()
    return self._key
end

function Object:get_type()
    return self._type
end

function Manager:get_obj(obj_key, class_key)
    if not all_of_type("string", obj_key, class_key) then return false end
    return self._classes[class_key] and self._objects[class_key][obj_key]
end

-- TODO, get class prototype from instance!
-- function Object:get_class()
--     local 
-- end

vlib._prototypes.MANAGER = Manager
vlib._prototypes.OBJECT = Object

--- Stuff.
---@vararg string Bloop.
---@return manager_prototype
function vlib:new_manager(...)
    return self._prototypes.MANAGER.new(...)
end
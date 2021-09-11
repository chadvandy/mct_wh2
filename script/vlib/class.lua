--- A system for creating classes in Lua.
-- Inspired by SinisterRectus's implementation in Discordia, 

--- TODO change this to just a single, simple "class" system, and then make a "Manager" class that can be duplicated for specific managers
-- TODO this. Have all the shared "manager" stuff between all of the various managers within this.
-- Filters, getting, setting, tostring'ing, grabbing, creating.
-- Also handle the held class[es] within each manager, and understand the types therein, etc.
-- Potentially hold all of the save-state stuff within here as well?

local vlib = get_vlib()
local log,logf,err,errf = vlib:get_log_functions("[managers]")

--- Metatable for all classes.
local meta = {
    -- local class_prototype = vlib:new_class("ClassName")
    -- local class = class_prototype(args, for, init)
    -- runs through class_prototype.__init()
    __call = function(self, ...)
        -- local o = setmetatable(self, self)
        --- objects[o] = true
        self:__init(...)
        return self
    end,
    __tostring = function(self)
        return 'class ' .. self.__name
    end,
}

--- Default values for all classes.
---@class class_prototype
local default = {
    -- TODO decide
    __init = function(self, ...)
        -- Default __init function if I don't want to actually do any for something.
    end,
    __name = "",
    _key = "",

    get_key = function(self)
        return self._key
    end
}

---@type table<class_prototype, boolean> Holds all existing created classes
local classes = {}

---@type table<string, class_prototype> Holds all existing class names.
local names = {}

local function is_class(obj)

end

local function is_object(obj)

end

do
    return function(name, obj, ...)
        obj = obj or {}
        if names[name] then
            --- errmsg, class already exists with this name
            return false
        end

        local class = setmetatable(obj, meta)
        classes[class] = true

        for k,v in pairs(default) do
            class[k] = v
        end

        local parents = {...}
        local getters = {}
        local setters = {}

        for _,parent in ipairs(parents) do
            for k1,v1 in pairs(parent) do
                class[k1] = v1

                for k2,v2 in pairs(parent.__getters) do
                    getters[k2] = v2
                end

                for k2,v2 in pairs(parent.__setters) do
                    setters[k2] = v2
                end
            end
        end

        class.__name = name
        class.__class = class
        class.__parents = parents
        class.__getters = getters
        class.__seters = setters

        names[name] = class

        -------
        --- These two functions are only "triggered" into the MT when __init() is called on the class, so anything defined before then is safe!
        -------

        function class:__index(k)
            if getters[k] then
                return getters[k](self)
            else
                return class[k]
            end
        end

        function class:__newindex(k, v)
            if setters[k] then
                return setters[k](self, v)
            elseif class[k] or getters[k] then
                -- errmsg, can't overwrite stuff!
                return class[k](self, v)
            end
        end

        return class, getters, setters
    end
end
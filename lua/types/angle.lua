local assert_with_level = require("utils/common").assert_with_level
local luau_vector = vector


local t = {}
function luau_vector_set(v: vector, k: number, x: number): vector
    t[1] = v[1]
    t[2] = v[2]
    t[3] = v[3]
    t[4] = v[4]
    t[k] = x
    return luau_vector(t[1], t[2], t[3], t[4])
end


local Angle_lib = {}
local Angle_lib_mt = {}
setmetatable(Angle_lib, Angle_lib_mt)

local name = "Angle"
local component_count = 3
local Angle_mt = {}
Angle_mt.__type = name
Angle_lib.metatable = Angle_mt

local Angle_methods = {}

local library_methods = {}
local method_argument_counts = {}
local library_method_aliases = {}



local function construct_from_base(base)
    local v = {
        __base = base,
        __size = 3
    }

    setmetatable(v, Angle_lib.metatable)
    return v
end


local short_new = false
function Angle_lib.new(...)
    local arg_count = select("#", ...)
    if arg_count == 0 then
        local base = luau_vector(1, 1, 1, 1)
        return construct_from_base(base)
    end

    if arg_count == 1 then
        local other = select(1, ...)
        assert_with_level(typeof(other) == name, "invalid argument #1 (expected " .. name .. ", got " .. typeof(other) .. ")", short_new and 4 or 3)
        
        local other_base = other.__base
        local base = luau_vector(other_base[1], other_base[2], other_base[3], other_base[4])
        return construct_from_base(base)
    end

    assert_with_level(arg_count == 3, name .. " constructor expects 0 or 3 component arguments (got " .. arg_count .. ")", short_new and 4 or 3)
    
    for i = 1, arg_count do
        local arg_type = type(select(i, ...))
        assert_with_level(arg_type == "number", "invalid argument #" .. i .. " (expected number, got " .. arg_type .. ")", short_new and 4 or 3)
    end

    local base = luau_vector(...)
    return construct_from_base(base)
end



local to_index_map = {
    p = 1, pitch = 1,
    y = 2, yaw = 2,
    r = 3, roll = 3,
}

function Angle_mt:__index(k)
    local method = Angle_methods[k]
    if method then
        return method
    end

    local old_k = k
    k = to_index_map[k] or k
    assert_with_level(type(k) == "number" and k >= 1 and k <= component_count, "attempt to index " .. name .. " with \"" .. old_k .. "\"", 3)
end

function Angle_mt:__newindex(k, v)
    local old_k = k
    k = to_index_map[k] or k
    assert_with_level(type(k) == "number" and k >= 1 and k <= component_count, "attempt to write to " .. name .. " at " .. old_k, 3)

    local v_type = type(v)
    assert_with_level(v_type == "number", "attempt to write " .. v_type .. " into " .. name, 3)
    self.__base = luau_vector_set(self.__base, k, v)
    return self.__base[k]
end

function Angle_mt:__len()
    return component_count
end

function Angle_mt:__add(other)
    return construct_from_base(self.__base + other.__base)
end

function Angle_mt:__sub(other)
    return construct_from_base(self.__base - other.__base)
end

function Angle_mt:__mul(other)
    return construct_from_base(self.__base * other.__base)
end
    
function Angle_mt:__div(other)
    local other_base = other.__base
    for i = component_count + 1, 4 do
        other_base = luau_vector_set(other_base, i, 1)
    end

    local base = self.__base / other_base
    return construct_from_base(base)
end

function Angle_mt:__tostring()
    local base = self.__base
    return "Angle(" .. base[1] .. ", " .. base[2] .. ", " .. base[3] .. ")"
end



for k, v in pairs(library_methods) do
    local required_argument_count = method_argument_counts[k]
    local method = function(...)
        local argument_count = select("#", ...)
        assert_with_level(argument_count >= required_argument_count, "missing argument #" .. argument_count+1 .. " (expected " .. name .. ")", 3)
        assert_with_level(argument_count <= required_argument_count, "method \"" .. k .. "\" expects " .. required_argument_count .. " arguments", 3)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            assert_with_level(typeof(v) == name, "invalid argument #" .. i .. " (expected " .. name .. ", got " .. typeof(v) .. ")", 3)
        end

        return v(component_count, ...)
    end

    Angle_lib[k] = method
    Angle_methods[k] = method
    
    for _, v in pairs(library_method_aliases[k] or {}) do
        Angle_lib[v] = method
        Vector_methods[k] = method
    end
end


function Angle_lib_mt:__call(...)
    short_new = true
    local v = Angle_lib.new(...)
    short_new = false
    return v
end


--[[
for k, v in pairs(constants) do
    Angle_lib[k] = v
    Angle_lib[string.upper(k)] = v
end
]]


return Angle_lib

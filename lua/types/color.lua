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


local Color_lib = {}
local Color_lib_mt = {}
setmetatable(Color_lib, Color_lib_mt)

local name = "Color"
local component_count = 4
local Color_mt = {}
Color_mt.__type = name
Color_lib.metatable = Color_mt

local Color_methods = {}

local library_methods = {}
local method_argument_counts = {}
local library_method_aliases = {}







local function construct_from_base(base)
    local v = {
        __base = base,
        __size = 4
    }

    setmetatable(v, Color_lib.metatable)
    return v
end


local short_new = false
function Color_lib.new(...)
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

    assert_with_level(arg_count >= 3 and arg_count <= 4, name .. " constructor expects 3 or " .. component_count .. " component arguments (got " .. arg_count .. ")", short_new and 4 or 3)
    
    for i = 1, arg_count do
        local arg_type = type(select(i, ...))
        assert_with_level(arg_type == "number", "invalid argument #" .. i .. " (expected number, got " .. arg_type .. ")", short_new and 4 or 3)
    end

    local base = luau_vector(...)
    if arg_count == 3 then
        base = luau_vector(base[1], base[2], base[3], 1)
    end

    return construct_from_base(base)
end



local to_index_map = {r = 1, g = 2, b = 3, a = 4}
function Color_mt:__index(k)
    local method = Color_methods[k]
    if method then
        return method
    end

    local old_k = k
    k = to_index_map[k] or k
    assert_with_level(type(k) == "number" and k >= 1 and k <= component_count, "attempt to index " .. name .. " with \"" .. old_k .. "\"", 3)
    return self.__base[k]
end

function Color_mt:__newindex(k, v)
    local old_k = k
    k = to_index_map[k] or k
    assert_with_level(type(k) == "number" and k >= 1 and k <= component_count, "attempt to write to " .. name .. " at " .. old_k, 3)

    local v_type = type(v)
    assert_with_level(v_type == "number", "attempt to write " .. v_type .. " into " .. name, 3)
    self.__base = luau_vector_set(self.__base, k, v)
end

function Color_mt:__len()
    return component_count
end

function Color_mt:__add(other)
    return construct_from_base(self.__base + other.__base)
end

function Color_mt:__sub(other)
    return construct_from_base(self.__base - other.__base)
end

function Color_mt:__mul(other)
    return construct_from_base(self.__base * other.__base)
end


function Color_mt:__tostring()
    local base = self.__base
    return "Color(" .. base[1] .. ", " .. base[2] .. ", " .. base[3] .. ", " .. base[4] .. ")"
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

    Color_lib[k] = method
    Color_methods[k] = method
    
    for _, v in pairs(library_method_aliases[k] or {}) do
        Color_lib[v] = method
        Vector_methods[k] = method
    end
end


function Color_lib_mt:__call(...)
    short_new = true
    local v = Color_lib.new(...)
    short_new = false
    return v
end


local constants = require("utils/color_constants")(function(r, g, b, a)
    a = a or 255
    return Color_lib.new(r / 255, g / 255, b / 255, a / 255)
end)

for k, v in pairs(constants) do
    Color_lib[k] = v
    Color_lib[string.upper(k)] = v
end


return Color_lib

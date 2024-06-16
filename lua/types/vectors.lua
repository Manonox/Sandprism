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


-- component_count: 2, 3 or 4
local to_index_maps = {
    [2] = {x = 1, y = 2},
    [3] = {x = 1, y = 2, z = 3},
    [4] = {x = 1, y = 2, z = 3, w = 4},
}

local to_key_maps = {
    [2] = {"x", "y"},
    [3] = {"x", "y", "z"},
    [4] = {"x", "y", "z", "w"},
}


local function construct_from_base_generic(base, component_count, metatable)
    local v = {
        __base = base,
        __size = component_count
    }

    setmetatable(v, metatable)
    return v
end



local library_methods = {}
local method_argument_counts = {}
local library_method_aliases = {}



method_argument_counts.isZero = 1
function library_methods.isZero(component_count, v)
    local base = v.__base
    for i = 1, component_count do
        if base[i] ~= 0 then
            return false
        end
    end
    return true
end


local pos_inf, neg_inf = 1/0, -1/0
local function isFinite(x)
    return x ~= pos_inf and x ~= neg_inf
end

method_argument_counts.isFinite = 1
function library_methods.isFinite(component_count, v)
    local base = v.__base
    for i = 1, component_count do
        if not isFinite(base[i]) then
            return false
        end
    end
    return true
end


local function isInfinite(x)
    return x == pos_inf and x == neg_inf
end

method_argument_counts.isInfinite = 1
function library_methods.isInfinite(component_count, v)
    local base = v.__base
    for i = 1, component_count do
        if isInfinite(base[i]) then
            return true
        end
    end
    return false
end


local function isNaN(x)
    return x ~= x
end

method_argument_counts.containsNaN = 1
function library_methods.containsNaN(component_count, v)
    local base = v.__base
    for i = 1, component_count do
        if isNaN(base[i]) then
            return true
        end
    end
    return false
end
library_method_aliases.containsNaN = {
    "containsNan"
}


local library_methods_containsNaN = library_methods.containsNaN
method_argument_counts.isValid = 1
function library_methods.isValid(component_count, v)
    return not library_methods.containsNaN(component_count, v)
end


method_argument_counts.dot = 2
function library_methods.dot(component_count, v1, v2)
    local sum = 0
    local base1, base2 = v1.__base, v2.__base
    for i = 1, component_count do
        sum = sum + base1[i] * base2[i]
    end
    return sum
end

local library_methods_dot = library_methods.dot
method_argument_counts.lengthSquared = 1
function library_methods.lengthSquared(component_count, v)
    return library_methods_dot(component_count, v, v)
end
library_method_aliases.lengthSquared = {
    "magnitudeSquared", "squareLength", "squareMagnitude"
}


local math_sqrt = math.sqrt
method_argument_counts.length = 1
local library_methods_lengthSquared = library_methods.lengthSquared
function library_methods.length(component_count, v)
    return math_sqrt(library_methods_lengthSquared(component_count, v))
end
library_method_aliases.length = {
    "magnitude"
}

function library_methods.cross(component_count, a, b)
    assert(component_count == 3, "cross product requires 3 components")
    local metatable = getmetatable(a)
    a, b = a.__base, b.__base
    local base = luau_vector(a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1], 0)
    return construct_from_base_generic(base, component_count, metatable)
end



local shared_constants = {
    zero = luau_vector(0, 0, 0, 0),
    one = luau_vector(1, 1, 1, 1),
}

local constants = {
    [2] = {
        left    = luau_vector(-1, 0),
        right   = luau_vector(1, 0),
        up      = luau_vector(0, -1),
        down    = luau_vector(0, 1),
    },

    [3] = {
        left    = luau_vector(-1, 0, 0),
        right   = luau_vector(1, 0, 0),
        up      = luau_vector(0, 1, 0),
        down    = luau_vector(0, -1, 0),
        forward = luau_vector(0, 0, -1),
        back    = luau_vector(0, 0, 1),
    }
}





local function vector_lib_factory(component_count)
    local to_index_map = to_index_maps[component_count]
    local to_key_map = to_key_maps[component_count]

    
    local name = "Vector" .. component_count
    local Vector_lib = {}
    local Vector_lib_mt = {}
    setmetatable(Vector_lib, Vector_lib_mt)

    local Vector_mt = {}
    Vector_mt.__type = name

    local Vector_methods = {}

    local function construct_from_base(base)
        return construct_from_base_generic(base, component_count, Vector_mt)
    end
    
    -- If we called Vector() instead of Vector.new()
    local short_new = false

    function Vector_lib.new(...)
        local arg_count = select("#", ...)
        if arg_count == 0 then
            local base = luau_vector(0, 0, 0, 0)
            return construct_from_base(base)
        end

        if arg_count == 1 then
            local other = select(1, ...)
            assert_with_level(typeof(other) == name, "invalid argument #1 (expected " .. name .. ", got " .. typeof(other) .. ")", short_new and 4 or 3)
            
            local other_base = other.__base
            local base = luau_vector(other_base[1], other_base[2], other_base[3], other_base[4])
            return construct_from_base(base)
        end

        assert_with_level(arg_count == component_count, name .. " constructor expects 0 or " .. component_count .. " component arguments (got " .. arg_count .. ")", short_new and 4 or 3)
        
        for i = 1, component_count do
            local arg_type = type(select(i, ...))
            assert_with_level(arg_type == "number", "invalid argument #" .. i .. " (expected number, got " .. arg_type .. ")", short_new and 4 or 3)
        end

        local base = luau_vector(...)
        return construct_from_base(base)
    end


    function Vector_mt:__index(k)
        local method = Vector_methods[k]
        if method then
            return method
        end

        local old_k = k
        k = to_index_map[k] or k
        assert_with_level(type(k) == "number" and k >= 1 and k <= component_count, "attempt to index " .. name .. " with \"" .. old_k .. "\"", 3)
        return self.__base[k]
    end

    function Vector_mt:__newindex(k, v)
        local old_k = k
        k = to_index_map[k] or k
        assert_with_level(type(k) == "number" and k >= 1 and k <= component_count, "attempt to write to " .. name .. " at " .. old_k, 3)

        local v_type = type(v)
        assert_with_level(v_type == "number", "attempt to write " .. v_type .. " into " .. name, 3)
        self.__base = luau_vector_set(self.__base, k, v)
    end

    function Vector_mt:__len()
        return component_count
    end

    function Vector_mt:__add(other)
        return construct_from_base(self.__base + other.__base)
    end
    
    function Vector_mt:__sub(other)
        return construct_from_base(self.__base - other.__base)
    end
    
    function Vector_mt:__mul(other)
        return construct_from_base(self.__base * other.__base)
    end
    
    function Vector_mt:__div(other)
        local other_base = other.__base
        for i = component_count + 1, 4 do
            other_base = luau_vector_set(other_base, i, 1)
        end

        local base = self.__base / other_base
        return construct_from_base(base)
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

        Vector_lib[k] = method
        Vector_methods[k] = method
        
        for _, v in pairs(library_method_aliases[k] or {}) do
            Vector_lib[v] = method
            Vector_methods[k] = method
        end
    end


    function Vector_mt:__tostring()
        local base = self.__base
        local components = base[1]
        for i = 2, component_count do
            components = components .. ", " .. base[i]
        end

        return name .. "(" .. components .. ")"
    end

    
    function Vector_lib_mt:__call(...)
        short_new = true
        local v = Vector_lib.new(...)
        short_new = false
        return v
    end


    for k, v in pairs(shared_constants or {}) do
        v = construct_from_base(v)
        Vector_lib[k] = v
        Vector_lib[string.upper(k)] = v
    end

    for k, v in pairs(constants[component_count] or {}) do
        v = construct_from_base(v)
        Vector_lib[k] = v
        Vector_lib[string.upper(k)] = v
    end

    
    return Vector_lib
end


local Vectors_lib = {}
for i = 2, 4 do
    Vectors_lib[i] = vector_lib_factory(i)
end
return Vectors_lib



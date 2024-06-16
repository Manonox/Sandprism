local checktype = require("utils/common").checktype

local select, memoize, iscallable = select, memoize, iscallable

unpack = table.unpack or unpack
table.unpack = unpack


function table.isempty(t)
    checktype(1, t, "table")

    local k = next(t)
    return k == nil
end


function table.address(t)
    checktype(1, t, "table")

    local metatable = getmetatable(t)
    setmetatable(t, nil)
    local s = tostring(t)
    setmetatable(t, metatable)

    return s:sub(8)
end


local math_random = math.random
function table.randomchoice(t)
    checktype(1, t, "table")

    return t[math_random(#t)]
end


function table.weightedchoice(t)
    checktype(1, t, "table")
    
    local sum = 0
    for _, v in t do
        assert(v >= 0, "weight value less than zero")
        sum = sum + v
    end
    assert(sum ~= 0, "all weights are zero")
    local rnd = math_random() * sum
    for k, v in t do
        if rnd < v then return k end
        rnd = rnd - v
    end
end


function table.shuffle(t)
    local result = {}
    for i = 1, #t do
        local r = math_random(i)
        if r ~= i then
            result[i] = result[r]
        end
        result[r] = t[i]
    end
    return result
end


function table.extend(dst, ...)
    checktype(1, dst, "table")
    for i = 1, select("#", ...) do
        local src = select(i, ...)
        checktype(i + 1, src, "table")
        
        for _, x in ipairs(src) do
            dst[#dst + 1] = x
        end
    end
end


local make_accessor_func = memoize(function(field)
    return function(t)
        return t[field]
    end
end)

function table.map(t, func)
    checktype(1, t, "table")

    local func_type = type(func)
    if func_type == "string" then
        func = make_accessor_func(func)
    end
    assert(iscallable(func), "invalid argument #2 (expected function, got " .. type(func) .. ")")
    
    local result = {}
    for k, v in t do
        result[k] = func(v)
    end
    return result
end


local math_type = math.type
if math_type then
    function table.filter(t, func)
        checktype(1, t, "table")
        assert(iscallable(func), "invalid argument #2 (expected function, got " .. type(func) .. ")")

        local is_array = true
        local result = {}
        for k, v in t do
            if type(k) ~= "number" or math_type(k) ~= "integer" then
                is_array = false
            end

            if func(v, k) then result[k] = v end
        end

        if is_array then
            local result_array = {}
            for _, v in pairs(result) do
                result_array[#result_array + 1] = v
            end
            return result_array
        end

        return result
    end
end


function table.count(t)
    checktype(1, t, "table")

    local count = 0
    for k in t do count += 1 end
    return count
end


function table.invert(t)
    checktype(1, t, "table")

    local result = {}
    for k, v in pairs(t) do result[v] = k end
    return result
end


function table.keys(t)
    checktype(1, t, "table")

    local result = {}
    for k in pairs(t) do result[#result + 1] = k end
    return result
end


function table.values(t)
    checktype(1, t, "table")

    local result = {}
    for _, v in pairs(t) do result[#result + 1] = k end
    return result
end

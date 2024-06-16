local checktype = require("utils/common").checktype


local _typeof = typeof
function typeof(x)
    if type(x) == "table" and x.class and x.class.name then
        return x.class.name
    end
    
    return _typeof(x)
end


function dostring(s, ...)
    checktype(1, s, "string")

    local func, err = loadstring(s)
    if not func then
        error(err, 2)
    end
    return func(...)
end


function iscallable(x)
    if type(x) == "function" then return true end
    if type(x) ~= "table" then return false end
    local mt = getmetatable(x)
    return mt and mt.__call ~= nil or false
end


local ripairs_iter = function(t, i)
    i = i - 1
    local v = t[i]
    if v ~= nil then
        return i, v
    end
end

function ripairs(t)
    checktype(1, t, "table")
    return ripairs_iter, t, (#t + 1)
end


local memoize_key = {}
local memoize_nil = {}
function memoize(func)
    assert(iscallable(func), "invalid argument #1 (expected function, got " .. type(func) .. ")")
    local cache = {}
    return function(...)
        local c = cache
        for i = 1, select("#", ...) do
            local a = select(i, ...)
            if a == nil then a = memoize_nil end
            c[a] = c[a] or {}
            c = c[a]
        end
        c[memoize_key] = c[memoize_key] or {func(...)}
        return unpack(c[memoize_key])
    end
end
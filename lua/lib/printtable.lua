local function is_good_key(s)
    return string.match(s, "^[%a_][%w_]*$") ~= nil
end

local printtable_lib = {}

local prettyprint_map = {
    string = function(v)
        return "\"" .. v .. "\""
    end,

    vector = function(v)
        return "vector(" .. tostring(v) .. ")"
    end,

    ["function"] = function(v)
        local funcname = debug.info(v, "n")
        funcname = funcname ~= "" and (funcname .. " at ") or funcname
        return tostring(v), "-- " .. funcname .. debug.info(v, "s") .. ":" .. debug.info(v, "l")
    end,
}

local cache
local function _printtable(t, i, printcustom, p)
    if cache[t] then return false end
    cache[t] = p or true
    local prefix = string.rep("\t", i)
    for k, v in pairs(t) do
        if type(k) ~= "string" then
            k = "[" .. tostring(k) .. "]"
        elseif not is_good_key(k) then
            k = "[\"" .. k .. "\"]"
        end
        
        local vtype = type(v)
        local vtypeof = typeof(v)
        if vtype ~= "table" then
            local prettyprint = prettyprint_map[vtype]
            local extra = ""
            if prettyprint then
                v, extra = prettyprint(v)
            else
                v = tostring(v)
            end
            extra = extra == nil and "" or extra
            printcustom(prefix .. k .. " = " .. v .. ", " .. extra)
            continue
        end

        local mt = getmetatable(v)
        if mt and mt.__tostring then
            v = tostring(v)
            printcustom(prefix .. k .. " = " .. v .. ",")
            continue
        end
            

        if next(v) == nil then
            printcustom(prefix .. k .. " = {},")
            continue
        end
        
        if cache[v] then
            local lastname = type(cache[v]) == "string" and (" (at ." .. cache[v] .. ")") or ""
            printcustom(prefix .. k .. " = { --[[ cyclic" .. lastname .. " ]] },")
            continue
        end

        printcustom(prefix .. k .. " = {")
        _printtable(v, i + 1, printcustom, (p and (p .. "." .. k) or k))
        printcustom(prefix .. "},")
    end
    cache[t] = nil
    return true
end


local function printtable(t, printcustom)
    printcustom = printcustom or print

    if type(t) ~= "table" then
        printcustom(t)
        return
    end

    if next(t) == nil then
        printcustom("{}")
        return
    end

    cache = {}
    print("{")
    _printtable(t, 1, printcustom)
    print("}")
end


setmetatable(printtable_lib, {__call = function(self, ...)
    return printtable(...)
end})

return printtable_lib

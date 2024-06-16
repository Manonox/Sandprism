local common = {}

local _error = error
local _type = type

function common.assert_with_level<T>(value: T, message: string, level: number): T
    if value then return value end
    _error(message, level or 1)
end

function common.checktype<T>(narg: integer, value: T, typename: string, level: integer | nil): T
    local value_type = _type(value)
    if value_type == typename then return value end
    _error("invalid argument #" .. narg .. " (expected " .. typename .. ", got " .. value_type .. ")", level or 3)
end

return common

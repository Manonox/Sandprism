-- # Includes
require("include/global")
require("include/table")


-- # Libraries
bit = require("lib/bit")
net = require("lib/net")


-- # Types
local vector_types = require("types/vectors")
for i, vector_type in pairs(vector_types) do
    _G["Vector" .. i] = vector_type
end

Color = require("types/color")
Angle = require("types/angle")
vector = nil


-- # Events
Event = require("lib/event")

do
    -- ## Engine events
    Engine = {}

    local onProcess = Event()
    Engine.onProcess = onProcess
    Engine.onUpdate = onProcess -- alias

    local onPhysicsProcess = Event()
    Engine.onPhysicsProcess = onPhysicsProcess
    Engine.onFixedUpdate = onPhysicsProcess -- alias
end


-- Other
printtable = require("lib/printtable")
printTable = require("lib/printtable")


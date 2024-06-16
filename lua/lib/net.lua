local assert_with_level = require("utils/common").assert_with_level
local bit = require("lib/bit")
local StringStream = bit.StringStream
local Event = require("lib/event")


local net = {}


net.channels = {}
net.channelsLookup = {}
net.channelEvents = {}


local NetStream = StringStream:subclass("NetStream")
NetStream.__instanceDict.__type = "NetStream"
function NetStream:initialize(channelNameOrOther)
    if type(channelNameOrOther) == "table" then
        if channelNameOrOther.isInstanceOf and channelNameOrOther:isInstanceOf(NetStream) then
            local other = channelNameOrOther
            self.channel = other.channel
            
            StringStream.initialize(self, other)
            return
        end
    end

    self.channel = 0
    if channelNameOrOther then
        local channelName = channelNameOrOther
        assert_with_level(type(channelName) == "string", "invalid argument #1 (expected string, got " .. typeof(channelName) .. ")", 3)
        local channel = net.channelsLookup[channelName]
        assert_with_level(channel, "channel \"" .. channelName .. "\" not yet registered with net.registerChannel", 3)
        self.channel = channel
    end

    StringStream.initialize(self)
end


function NetStream:toSelf()
    net.onIncoming:invoke(NetStream(self), nil)
end

function NetStream:toServer()

end

function NetStream:toClients(t)

end

function NetStream:toClient(client)
    self:to_clients({client})
end


net.onIncoming = Event()

function net.registerChannel(channelName)
    assert_with_level(type(channelName) ~= "string", "invalid argument #1 (expected string, got " .. typeof(channelName) .. ")", 3)
    --assert(type(channelName) == "string", "invalid argument #1 (expected string, got " .. typeof(channelName) .. ")")
    local id = #net.channels + 1
    net.channels[id] = channelName
    net.channelsLookup[channelName] = id

    local event = Event()
    net.channelEvents[channelName] = event
    net.onIncoming:add(function(stream, sender)
        local channel = stream.channel
        if channelName == net.channels[channel] then
            event:invoke(stream, sender, channel)
        end
    end)
end


function net.send(channelName)
    if channelName ~= nil then
        assert_with_level(type(channelName) == "string", "invalid argument #1 (expected string, got " .. typeof(channelName) .. ")", 3)
        assert_with_level(net.channelsLookup[channelName], "channel \"" .. channelName .. "\" not yet registered with net.registerChannel", 3)
    end

    return NetStream(channelName)
end

function net.listen(channelName, listener)
    local event = net.onIncoming
    if listener then
        assert_with_level(type(channelName) == "string", "invalid argument #1 (expected string, got " .. typeof(channelName) .. ")", 3)
        assert_with_level(type(listener) == "function", "invalid argument #2 (expected function, got " .. typeof(listener) .. ")", 3)
        
        event = net.channelEvents[channelName]
        assert_with_level(event, "channel \"" .. channelName .. "\" not yet registered with net.registerChannel", 3)
    else
        listener = channelName
        assert_with_level(type(listener) == "function", "invalid argument #1 (expected function, got " .. typeof(listener) .. ")", 3)
    end
    
    event:add(listener)
end


return net
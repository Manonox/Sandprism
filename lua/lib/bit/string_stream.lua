local assert_with_level = require("utils/common").assert_with_level
local class = require("lib/middleclass")

local StringStream = class("StringStream")
StringStream.__instanceDict.__type = "StringStream"
function StringStream:initialize(other)
    self.data = ""
    self.position = 0

    if other then
        assert_with_level(other.isInstanceOf and other:isInstanceOf(StringStream), "invalid argument #1 (expected StringStream, got " .. typeof(other) .. ")", 5)
        self.data = other.data
    end
end


function StringStream:__tostring()
    return self.class.name .."(" .. (self.position >= #self.data and "eof" or self.position) .. "/" .. (#self.data <= 0 and "empty" or #self.data - 1) .. ")"
end


function StringStream:seek(x)
    assert_with_level(x and math.floor(x) == x, "invalid argument #1 (expected integer, got " .. typeof(x) .. ")", 3)
    assert_with_level(x >= 0, "can't seek to negative position", 3)
    
    x = math.min(x, #self.data)
    self.position = x
end


function StringStream:getData()
    return self.data
end


function StringStream:isEOF()
    return self.position + 1 > #self.data
end

local function checkEOF(ss)
    assert_with_level(not ss:isEOF(), "end of stream reached", 4)
end


function StringStream:writeFromStream(stream)
    self.data = self.data .. stream.data
    return self
end

local function stringWrite(s, at, ss)
	return s:sub(1, at - 1) .. ss .. s:sub(at + #ss)
end

function StringStream:writeData(s)
    assert_with_level(type(s) == "string", "invalid argument #1 (expected string, got " .. typeof(s) .. ")", 3)
    self.data = stringWrite(self.data, self.position + 1, s)
    self:seek(self.position + #s)
    return self
end

function StringStream:readData(bytes)
    assert_with_level(bytes and math.floor(bytes) == bytes, "invalid argument #1 (expected integer, got " .. typeof(bytes) .. ")", 3)

    checkEOF(self)
    assert_with_level(self.position + bytes <= #self.data, "data too short", 3)
    local result = self.data:sub(self.position + 1, self.position + bytes)
    self:seek(self.position + bytes)
    return result
end


local function writePack(self, pattern, value)
    local success, result = pcall(string.pack, pattern, value)
    assert_with_level(success, "writing error: " .. result, 4)
    self:writeData(result)
    return self
end

local function readPack(self, pattern, bytes)
    checkEOF(self)
    if bytes then
        assert_with_level(self.position + bytes <= #self.data, "data too short", 4)
    end
    local success, result = pcall(string.unpack, pattern, self.data, self.position + 1)
    assert_with_level(success, "reading error: " .. result, 4)
    if bytes then
        self:seek(self.position + bytes)
    end
    return result
end



local function declareVariableIntFunctions(t, pattern_prefix)
    StringStream["write" .. t] = function(self, x, bytes)
        assert_with_level(x and math.floor(x) == x, "invalid argument #1 (expected integer, got " .. typeof(bytes) .. ")", 3)
        assert_with_level(bytes and math.floor(bytes) == bytes, "invalid argument #2 (expected integer, got " .. typeof(bytes) .. ")", 3)

        return writePack(self, "<" .. pattern_prefix .. bytes, x)
    end
    
    StringStream["read" .. t] = function(self, bytes)
        assert_with_level(bytes and math.floor(bytes) == bytes, "invalid argument #2 (expected integer, got " .. typeof(bytes) .. ")", 3)
        return readPack(self, "<" .. pattern_prefix .. bytes, bytes)
    end
end

declareVariableIntFunctions("Int", "i")
declareVariableIntFunctions("UInt", "I")



function StringStream:writeFloat(x)
    return writePack(self, "<f", x)
end

function StringStream:readFloat()
    return readPack(self, "<f", 4)
end


function StringStream:writeDouble(x)
    return writePack(self, "<d", x)
end

function StringStream:readDouble()
    return readPack(self, "<d", 8)
end


function StringStream:writeBool(x)
    return self:writeUInt(x, 1)
end

function StringStream:readBool(x)
    return self:readUInt(1)
end


function StringStream:writeString(s, withEncodedLength)
    return writePack(self, "<" .. (withEncodedLength and "s" or "z"), s)
end

function StringStream:readString(withEncodedLength)
    local s = readPack(self, "<" .. (withEncodedLength and "s" or "z"))
    self:seek(self.position + #s + (withEncodedLength and 4 or 1))
    return s
end






local lib = {
    class = StringStream
}

local lib_mt = {
    __call = function(self, ...)
        assert_with_level(pcall(self.class(...)), 3)
    end
}

setmetatable(lib, lib_mt)


return StringStream

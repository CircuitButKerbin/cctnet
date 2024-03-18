require "cctnet.lowlevel.modem"

---@param e any
---@param base integer
---@return integer
---@overload fun(e:any):number
local function stricttonumber(e, base)
    if (base == nil) then
        assert(type(tonumber(e)) == "number", debug.traceback("bad argument #1 (no valid numerical representation for \"" .. tostring(e) .. "\")"))
        ---@diagnostic disable-next-line
        return tonumber(e) 
    else
        assert(type(tonumber(e, base)) == "number", debug.traceback("bad argument #1 (no valid numerical representation for \"" .. tostring(e) .. "\")"))
        return tonumber(e, base)
    end
end

---@class MACAddress
---@field mac integer
---@field toString fun():string
---@field toInteger fun():integer
---@field new fun(mac:integer|string):MACAddress
MACAddress = {
    ---@private
    __type = "MACAddress",
    ---@private
    __tostring = function(self)
        return self:toString()
    end,
    ---@private
    __eq = function(self, other)
        if type(other) == "string" then
            return self:toString() == other
        end
        if type(other) == "number" then
            return self:toInteger() == other
        end
        if other.__type == "MACAddress" then
            return self.mac == other.mac
        end
        error(debug.traceback("Cannot compare MACAddress with " .. type(other)))
    end,
    ---@return string
    toString = function()
        local result;
        local string = string.format("%012X", MACAddress.mac)
        for i = 1, 6 do
            local byte = stricttonumber(string:sub(i * 2 - 1, i * 2), 16)
            if i == 1 then
                result = string.format("%02X", byte)
            else
                result = result .. ":" .. string.format("%02X", byte)
            end
        end 
        return result
    end,
    ---@return integer
    toInteger = function()
        return MACAddress.mac
    end,

    ---@param mac integer|string
    ---@return MACAddress 
    ---@nodiscard
    new = function(mac)
        local o = MACAddress
        if type(mac) == "string" then
            local tmp = string.gmatch(mac, "[^:]+")
            local parts = {}
            for i in tmp do
                table.insert(parts, i)
            end
            assert(#parts == 6, "Invalid mac : " .. mac .. "(Parts : " .. #parts .. ")")
            mac = ""
            for i = 1, 6 do
                mac = mac .. string.format("%02X", stricttonumber(parts[i],16))
            end
            o.mac = stricttonumber(mac, 16)
        else
            assert(mac >= 0 and mac <= 0xFFFFFFFFFF, "Invalid mac : " .. mac)
            o.mac = mac
        end
        local meta = {
            __tostring = MACAddress.__tostring,
            __eq = MACAddress.__eq
        }
        --[[@as MACAddress]]
        o = setmetatable(o, meta)
        return o;
    end
}

---@enum EtherType
EthernetType = {
    ---@param index integer
    ---@return string
    toString = function(index)
        local quick = {
            [0x0800] = "IPv4",
            [0x0806] = "ARP",
            [0x86DD] = "IPv6"
        }
        return quick[index]
    end,
    IPv4 = 0x0800,
    ARP = 0x0806,
    IPv6 = 0x86DD
}

---@class iPayload
---@field __type string
---@field demangle fun(self:iPayload): iPayload
---@field send fun(self:iPayload)

---@class EthernetFrame
---@field Type EtherType
---@field source MACAddress
---@field destination MACAddress
---@field EthernetPayload iPayload
---@field demangle fun(self:EthernetFrame): EthernetFrame
---@field send fun(self:EthernetFrame, networkInterface:Modem)
---@field __eq fun(self:EthernetFrame, other:EthernetFrame): boolean
---@field __type string

EthernetII = {
    source = MACAddress.new(0),
    destination = MACAddress.new(0),
    Type = EthernetType.IPv4,
    EthernetPayload = nil,
    __type = "EthernetII",
    --When transmited, all functions and metatables are stripped
    demangle = function (self)
        self.demagle = EthernetII.demangle
        self.send = EthernetII.send
        local meta = {
            __eq = EthernetII.__eq
        }
        --[[@as EthernetFrame]]
        return setmetatable(self, meta)
    end,
    __eq = function (self, other)
        if other.__type == "EthernetII" then
            return self.source == other.source and self.destination == other.destination and self.Type == other.Type and self.EthernetPayload == other.EthernetPayload
        end
        error(debug.traceback("Cannot compare EthernetII with " .. type(other)))
    end,
    new = function (source, destination, Type, EthernetPayload)
        ---@type EthernetFrame
        ---@diagnostic disable-next-line: assign-type-mismatch
        local o = EthernetII
        o.source = source
        o.destination = destination
        o.Type = Type
        o.EthernetPayload = EthernetPayload
        ---@diagnostic disable-next-line: inject-field
        local meta = {
            __index = EthernetII,
            __eq = EthernetII.__eq
        }
        --[[@as EthernetFrame]]
        o = setmetatable(o, meta)
        return o
    end,
    ---@param self EthernetFrame
    ---@param networkInterface Modem
    send = function (self, networkInterface)
        assert(self.source.__type == "MACAddress", debug.traceback("Invalid source MAC"))
        assert(self.destination.__type == "MACAddress", debug.traceback("Invalid destination MAC"))
        assert(self.EthernetPayload ~= nil, debug.traceback("No payload"))
        if self.EthernetPayload.__type == "IPv4" then
            ---@diagnostic disable-next-line: undefined-field
            local proto = self.EthernetPayload.protocol
            --defined port
            if proto == IPv4Protocol.UDP or proto == IPv4Protocol.TCP then
                networkInterface:transmit(proto.sourcePort, proto.destinationPort, self.EthernetPayload)
            elseif proto == IPv4Protocol.ICMP then
                --port 8
                networkInterface:transmit(8, 8, self.EthernetPayload)
            end 
        elseif self.EthernetPayload.__type == "ARP" then
            --port 1
            networkInterface:transmit(1, 1, self.EthernetPayload)
        end
    end
}
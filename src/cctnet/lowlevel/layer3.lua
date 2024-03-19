require "cctnet.lowlevel.layer2"

--Strict tonumber() method that throws an error if the conversion fails
---@overload fun(e:any):number
local function stricttonumber(e, base)
    if (base == nil) then
        assert(type(tonumber(e)) == "number", debug.traceback("bad argument #1 (no valid numerical representation)"))
        ---@diagnostic disable-next-line
        return tonumber(e) 
    else
        assert(type(tonumber(e, base)) == "number", debug.traceback("bad argument #1 (no valid numerical representation)"))
        return tonumber(e, base)
    end
end
---@diagnostic disable-next-line
local bit32 = bit32


---@class IPAddress
---@field ip integer
---@field toString fun(self:IPAddress):string
---@field toInteger fun(self:IPAddress):integer
---@field new fun(ip:integer|string):IPAddress
IPAddress = {
    __type = "IPAddress",
    __tostring = function(self)
        return self:toString()
    end,
    __eq = function(self, other)
        if type(other) == "string" then
            return self:toString() == other
        end
        if type(other) == "number" then
            return self:toInteger() == other
        end
        if other.__type == "IPAddress" then
            return self.ip == other.ip
        end
        error(debug.traceback("attempt to compare IPAddress with" .. type(other)))
    end,
    ---@return string
    toString = function(self)
        local result;
        for i = 1, 4 do
            local byte = bit32.rshift(bit32.band(self.ip, bit32.lshift(0xFF, ((5-i) - 1) * 8)), ((5-i) - 1) * 8)
            if i == 1 then
                result = tostring(byte)
            else
                result = result .. "." .. tostring(byte)
            end
        end
        return result
    end,
    ---@return integer
    toInteger = function(self)
        return self.ip
    end,
    ---@param ip integer|string
    ---@return IPAddress
    ---@nodiscard
    new = function(ip)
        local o = {
            ip = 0,
            toString = IPAddress.toString,
            toInteger = IPAddress.toInteger
        }
        if type(ip) == "string" then
            local parts = {string.match(ip, "(%d+)%.(%d+)%.(%d+)%.(%d+)")}
            assert(#parts == 4, string.format("bad argument #1 to 'IPAddress.new (value %s is not a valid string formatted IP address; Split returned %d parts)'", ip, #parts))
            o.ip = 0
            for i = 1, 4 do
                o.ip = bit32.bor(o.ip, bit32.lshift(stricttonumber(parts[i]), ((5-i) - 1) * 8))
            end
        elseif type(ip) == "number" then
            assert(ip >= 0 and ip <= 0xFFFFFFFF, "bad argument #1 to 'IPAddress.new' (value out of range of a u32)")
            o.ip = ip
        else
            error(debug.traceback(string.format("bad argument #1 to 'IPAddress.new' (value of type %s is not a valid IP address representation)", type(ip))))
        end
        local meta = {
            __tostring = IPAddress.__tostring,
            __eq = IPAddress.__eq
        }
        --[[@as IPAddress]]
        o = setmetatable(o, meta)
        return o
    end
}
---@enum IPv4Protocol
IPv4Protocol = {
    toString = function(self)
        local quick = {
            [1] = "ICMP",
            [2] = "IGMP",
            [6] = "TCP",
            [17] = "UDP",
            [47] = "GRE",
            [50] = "ESP",
            [51] = "AH",
            [58] = "ICMPv6",
            [88] = "EIGRP",
            [89] = "OSPF",
            [103] = "PIM",
            [132] = "SCTP",
            [115] = "L2TP"
        }
        return quick[self]
    end,
    ICMP = 1,
    IGMP = 2,
    TCP = 6,
    UDP = 17,
    GRE = 47,
    ESP = 50,
    AH = 51,
    ICMPv6 = 58,
    EIGRP = 88,
    OSPF = 89,
    PIM = 103,
    SCTP = 132,
    L2TP = 115
}


---@class iIPv4 : iPayload
---@field source IPAddress
---@field destination IPAddress 
---@field options table
---@field ttl integer
---@field protocol IPv4Protocol
---@field __type string
---@field toString fun(self:iIPv4):string
---@field __eq fun(self:iIPv4, other:iIPv4):boolean
---@field demangle fun(self:iIPv4):iIPv4

IPv4 = {
    __eq = function (self, other)
        if other.__type == "IPv4" then
            return self.source == other.source and self.destination == other.destination and self.ttl == other.ttl and self.protocol == other.protocol and self.payload == other.payload
        end
        error(debug.traceback("attempt to compare IPv4Packet with " .. type(other)))
    end,
    __tostring = function(self)
        ---#TODO update to new format
        return "IPv4: " .. self.source:toString() .. " -> " .. self.destination:toString() .. " Protocol: " .. self.protocol:toString() .. " TTL: " .. tostring(self.ttl)
    end,
    __type = "IPv4",
    ---@param self iIPv4
    ---@return iIPv4
    demangle = function(self)
        ---#TODO: Implement
        return self
    end,
    ---@param source IPAddress
    ---@param destination IPAddress
    ---@param ttl integer
    ---@param protocol IPv4Protocol
    ---@param payload iPayload
    ---@return iIPv4
    new = function(source, destination, ttl, protocol, payload)
        local o = {
            source = source,
            destination = destination,
            ttl = ttl,
            protocol = protocol,
            payload = payload
        }
        local meta = {
            __tostring = IPv4.__tostring,
            __eq = IPv4.__eq
        }
        --[[@as iIPv4]]
        o = setmetatable(o, meta)
        return o
    end
}

---@class iARP : iPayload
---@field sourceMAC MACAddress
---@field sourceIP IPAddress
---@field destinationMAC MACAddress
---@field destinationIP IPAddress
---@field __type string
---@field toString fun(self:iARP):string
---@field __eq fun(self:iARP, other:iARP):boolean
---@field demangle fun(self:iARP):iARP

ARP = {

}
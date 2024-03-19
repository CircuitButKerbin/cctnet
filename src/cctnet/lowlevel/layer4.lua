require "cctnet.lowlevel.layer3"

---@class iUDP : iPayload
---@field sourcePort integer
---@field destinationPort integer
---@field payload table
---@field toString fun(self:iUDP):string
UDP = {
    __type = "UDP",
    __eq = function (self, other)
        if other.__type == "UDP" then
            return self.sourcePort == other.sourcePort and self.destinationPort == other.destinationPort and self.payload == other.payload
        end
        error(debug.traceback("attempt to compare UDP with " .. type(other)))
    end,
    __tostring = function(self)
        return self:toString()
    end,
    toString = function(self)
        assert(self.__type == "UDP", "bad argument #1 to 'UDP.toString' (UDP expected, got " .. self.__type .. ")")
        return string.format("UDP Packet [%d -> %d] {Payload:%s}", self.sourcePort, self.destinationPort, tostring(self.payload))
    end,
    new = function (sourcePort, destinationPort, payload)
        assert(sourcePort >= 0 and sourcePort <= 65535, "bad argument #1 to 'UDP.new' (port number must be between 0 and 65535)")
        assert(destinationPort >= 0 and destinationPort <= 65535, "bad argument #2 to 'UDP.new' (port number must be between 0 and 65535)")
        ---@type iUDP
        ---@diagnostic disable-next-line: assign-type-mismatch
        local o = {
            sourcePort = sourcePort,
            destinationPort = destinationPort,
            payload = payload
        }
        ---@diagnostic disable-next-line: inject-field
        
        local meta = {
            __eq = UDP.__eq,
            __tostring = UDP.toString
        }
        --[[@as iUDP]]
        o = setmetatable(o, meta)
        return o
    end
}

---@class TCPFlags
---@field URG boolean
---@field ACK boolean
---@field PSH boolean
---@field RST boolean
---@field SYN boolean
---@field FIN boolean
iTCPFlags = {
    URG = false,
    ACK = false,
    PSH = false,
    RST = false,
    SYN = false,
    FIN = false
}

---@class iTCP : iPayload
---@field sourcePort integer
---@field destinationPort integer
---@field payload table
---@field sequenceNumber integer
---@field ackNumber integer
---@field flags TCPFlags

TCP = {
    __type = "TCP",
    __eq = function (self, other)
        if other.__type == "TCP" then
            return self.sourcePort == other.sourcePort and self.destinationPort == other.destinationPort and self.payload == other.payload and self.sequenceNumber == other.sequenceNumber and self.ackNumber == other.ackNumber and self.flags == other.flags
        end
        error(debug.traceback("attempt to compare TCP with " .. type(other)))
    end,
    __tostring = function(self)
        assert(self.__type == "TCP", "bad argument #1 to 'TCP.toString' (TCP expected, got " .. self.__type .. ")")
        return string.format("TCP Packet [%d -> %d] {Seq:%d, Ack:%d, Flags:%s, Payload:%s}", self.sourcePort, self.destinationPort, self.sequenceNumber, self.ackNumber, tostring(self.flags), tostring(self.payload))
    end,
    new = function (sourcePort, destinationPort, sequenceNumber, ackNumber, flags, payload)
        assert(type(flags) == "table", "bad argument #5 to 'TCP.new' (table expected, got " .. type(flags) .. ")")
        assert(flags.__type == "TCPFlags", "bad argument #5 to 'TCP.new' (TCPFlags expected, got " .. flags.__type .. ")")
        assert(type(sequenceNumber) == "number", "bad argument #3 to 'TCP.new' (number expected, got " .. type(sequenceNumber) .. ")")
        assert(type(ackNumber) == "number", "bad argument #4 to 'TCP.new' (number expected, got " .. type(ackNumber) .. ")")
        assert(sourcePort >= 0 and sourcePort <= 65535, "bad argument #1 to 'TCP.new' (port number must be between 0 and 65535)")
        assert(destinationPort >= 0 and destinationPort <= 65535, "bad argument #2 to 'TCP.new' (port number must be between 0 and 65535)")
        ---@type iTCP
        ---@diagnostic disable-next-line: assign-type-mismatch
        local o = {
            sourcePort = sourcePort,
            destinationPort = destinationPort,
            sequenceNumber = sequenceNumber,
            ackNumber = ackNumber,
            flags = flags,
            payload = payload
        }
        local meta = {
            __eq = TCP.__eq
        }
        --[[@as iTCP]]
        o = setmetatable(o, meta)
        return o
    end
}
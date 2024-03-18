require "cctnet.lowlevel.layer3"

---@class iUDP : iPayload
---@field sourcePort integer
---@field destinationPort integer
---@field payload table
UDP = {
    __type = "UDP",
    __eq = function (self, other)
        if other.__type == "UDP" then
            return self.sourcePort == other.sourcePort and self.destinationPort == other.destinationPort and self.payload == other.payload
        end
        error(debug.traceback("Cannot compare UDP with " .. type(other)))
    end,
    new = function (sourcePort, destinationPort, payload)
        ---@type iUDP
        ---@diagnostic disable-next-line: assign-type-mismatch
        local o = UDP
        o.sourcePort = sourcePort
        o.destinationPort = destinationPort
        o.payload = payload
        ---@diagnostic disable-next-line: inject-field
        
        local meta = {
            __eq = UDP.__eq
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
        error(debug.traceback("Cannot compare TCP with " .. type(other)))
    end,
    new = function (sourcePort, destinationPort, sequenceNumber, ackNumber, flags, payload)
        ---@type iTCP
        ---@diagnostic disable-next-line: assign-type-mismatch
        local o = TCP
        o.sourcePort = sourcePort
        o.destinationPort = destinationPort
        o.sequenceNumber = sequenceNumber
        o.ackNumber = ackNumber
        o.flags = flags
        o.payload = payload
        ---@diagnostic disable-next-line: inject-field
        
        local meta = {
            __eq = TCP.__eq
        }
        --[[@as iTCP]]
        o = setmetatable(o, meta)
        return o
    end
}
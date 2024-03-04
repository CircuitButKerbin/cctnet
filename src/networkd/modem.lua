
---@class bit32
---@diagnostic disable-next-line
local bit32 = bit32;

---@class peripheral
---@field find fun(name:string):table
---@diagnostic disable-next-line 
local peripheral = peripheral;

---@class networkd.modem
---@field mac integer
---@field device table
---@field openPorts table<integer>
---@field isWireless fun():boolean
---@field openPort fun(self:networkd.modem, port:integer)
---@field closePort fun(self:networkd.modem, port:integer)
---@field closeAllPorts fun(self:networkd.modem)
---@field transmit fun(self:networkd.modem, channel:integer, replyChannel:integer, message:any)
---@field getModemEvent fun(self:networkd.modem):ModemEvent
---@field new fun():networkd.modem

---@class os
---@field pullEvent fun(event:string):any
---@field getComputerID fun():integer
---@diagnostic disable-next-line
local os = os;


local function crc24(str)
    local i = 1
    local crc = 2 ^ 24 - 1
    local poly = 0xDF3261 

    for k = string.len(str), 1, -1 do
        local byte = string.byte(str, i)
        crc = bit32.bxor(crc, byte)
        for j = 0, 7 do
            if bit32.band(crc, 1) ~= 0 then
                crc = bit32.bxor(bit32.rshift(crc, 1), poly)
            else
                crc = bit32.rshift(crc, 1)
            end
        end
        i = i + 1
    end
    crc = bit32.bxor(crc, 0xFFFFFF)
    if crc < 0 then crc = crc + 2 ^ 24 end
    return crc
end


Modem = {
    ---Initializes a new modem object
    ---@return networkd.modem
    new = function (self)
        local o = self
        local modem = peripheral.find("modem") or error("No modem found")
        if modem == nil then
            error("networkd.modem requires a modem to be attached!")
        end
        o.device = modem
        local pchash = crc24(tostring(os.getComputerID()))
        local modemhash = crc24(tostring(modem))
        pchash = bit32.band(pchash, 0xEFFFFF) -- unicast
        local mac = string.format("%X", pchash) .. string.format("%X", modemhash)
        o.mac = tonumber(mac, 16)
        return o
    end,
    mac = nil;
    ---@private
    device = nil,
    ---Blocking method that returns a ModemEvent once recieved
    ---@param self networkd.modem
    ---@return ModemEvent
    ---@nodiscard
    getModemEvent = function (self)
        local eventData = table.pack(os.pullEvent("modem_message"))
        return {
            name = "modem_message",
            side = eventData[2],
            channel = eventData[3],
            replyChannel = eventData[4],
            message = eventData[5],
            distance = eventData[6]
        }
    end,
    --The ports opened on the modem
    ---@type table<integer>
    openPorts = {},
    ---Returns whether the modem is wireless
    ---@param self networkd.modem
    ---@return boolean
    isWireless = function (self)
        return self.device.isWireless()
    end,
    ---Opens a port on the modem
    ---@param self networkd.modem
    ---@param port integer
    openPort = function (self, port)
        self.device.open(port)
        table.insert(self.openPorts, port)
    end,
    ---Closes a port on the modem
    ---@param self networkd.modem
    ---@param port integer
    closePort = function (self, port)
        self.device.close(port)
        for i, v in ipairs(self.openPorts) do
            if v == port then
                table.remove(self.openPorts, i)
            end
        end
    end,
    ---Close all ports on the modem
    ---@param self networkd.modem
    closeAllPorts = function (self)
        self.device.closeAll()
        self.openPorts = {}
    end,
    ---Transmits a message on the modem
    ---@param self networkd.modem
    ---@param channel integer
    ---@param replyChannel integer
    ---@param message any
    transmit = function (self, channel, replyChannel, message)
        self.device.transmit(channel, replyChannel, message)
    end,


}
---@class ModemEvent
ModemEvent = {
    ---@type string
    name = "",
    ---@type string
    side = "",
    ---@type integer
    channel = 0,
    ---@type integer
    replyChannel = 0,
    ---@type any
    message = nil,
    ---@type number
    distance = 0,
}


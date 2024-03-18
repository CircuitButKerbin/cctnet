require("networkd.networklayer")

---@diagnostic disable-next-line
parallel = parallel


---@return IPv4Address ConfiguredIP
function RegisterDHCP()
    local selectedServer = 0;
    local function handleOfferResponse()
        while true do
            local recievedEvent = Modem:getModemEvent()
            if recievedEvent.channel == 68 then
                ---@type EthernetIIFrame
                local packet = recievedEvent.message
                if packet.Type == EthernetType.IPv4 and packet.destinationMAC == Modem.mac then
                    --[[@as IPv4Packet]]
                    local ipframe = packet.data
                    if ipframe.protocol == IPv4Protocol.UDP and ipframe.data.data.transactionID == TID then
                        --[[@as DHCPMessage]]
                        local dhcppacket = ipframe.data.data
                        if dhcppacket.messageType == DHCPMessageType.Offer then
                            ConfiguredIP = dhcppacket.yourIP
                            DHCPRequest = {
                                messageType = DHCPMessageType.Request,
                                transactionID = TID,
                                yourIP = 0,
                                serverIP = ipframe.source,
                                clientMAC = Modem.mac,
                                gatewayIP = 0,
                                clientIP = 0,
                                options = {}
                            }
                            DHCPRequest.options[DHCPOptions.RequestedIP] = ConfiguredIP
                            DHCPRequest.options[DHCPOptions.Server] = ipframe.source
                            selectedServer = ipframe.source
                            local DHCPRequestPacket = EthernetII:new(Modem.mac, packet.sourceMAC, EthernetType.IPv4, IPv4.new(0, IPv4.addressFromString("255.255.255.255"), 17, IPv4Protocol.UDP, UDP.new(68, 67, DHCPRequest)))
                            print("Sent DHCP Request")
                            DHCPRequestPacket:send()
                            return
                        end
                    end
                end
            end
        end
    end
    local function handleAcknowlegement()
        while true do
            local recievedEvent = Modem:getModemEvent()
            if recievedEvent.channel == 68 then
                ---@type EthernetIIFrame
                local packet = recievedEvent.message
                if packet.Type == EthernetType.IPv4 and packet.destinationMAC == Modem.mac then
                    --[[@as IPv4Packet]]
                    local ipframe = packet.data
                    if ipframe.protocol == IPv4Protocol.UDP and ipframe.data.data.transactionID == TID and ipframe.data.data.options[DHCPOptions.Server] == selectedServer then
                        --[[@as DHCPMessage]]
                        local dhcppacket = ipframe.data.data
                        if dhcppacket.messageType == DHCPMessageType.Ack then
                            print("Recieved DHCP Ack")
                            ConfiguredIP = dhcppacket.yourIP
                            return
                        else
                            print("Recieved DHCP Nack")
                            ConfiguredIP = 0
                            return
                        end
                    end
                end
            end
        end
    end
    ---@param sourceMAC MACAddress
    ---@param IPtoProbe IPv4Address
    ---@return boolean addressAvaliable
    local function ARPProbe(sourceMAC, IPtoProbe)
        local originalPortState = Modem.openPorts[1] or false
        if not originalPortState then
            Modem:openPort(1)
        end
        ---@type ARPPacket
        ARP = {
            operation = ARPOperation.Request,
            sourceMAC = Modem.mac,
            sourceIPv4 = 0,
            targetMAC = 0,
            targetIPv4 = IPtoProbe
        }
        ARPPacket = EthernetII:new(Modem.mac, 0xFFFFFFFFFFFF, EthernetType.ARP, ARP)
        ARPPacket:send()
        local passed = false;
        parallel.waitForAny(function()
            while true do
                local event = Modem:getModemEvent()
                if event.channel == 1 then
                    ---@type EthernetIIFrame
                    local packet = event.message
                    if packet.Type == EthernetType.ARP and packet.data.operation == ARPOperation.Reply then
                        if packet.data.sourceIPv4 == IPtoProbe then
                            passed = false
                            return
                        end
                    end
                end
            end
        end, function()
            os.sleep(2)
            passed = true
        end)
        if not originalPortState then
            Modem:closePort(1)
        end
        return passed
    end

    TID = math.random(1, 1000000000)
    ConfiguredIP = nil;
    Modem:openPort(68)
    ---@type DHCPMessage
    local DHCPDiscover = {
        messageType = DHCPMessageType.Discover,
        ConfiguredIP = 0,
        transactionID = TID,
        yourIP = 0,
        serverIP = 0,
        gatewayIP = 0,
        clientMAC = Modem.mac,
        clientIP = 0,
        options = {}
    }
    local DHCPDiscoverPacket = EthernetII:new(Modem.mac, 0xFFFFFFFFFFFF, EthernetType.IPv4, IPv4.new(0, IPv4.addressFromString("255.255.255.255"), 17, IPv4Protocol.UDP, UDP.new(68, 67, DHCPDiscover)))
    print("Sent DHCP Discover")
    DHCPDiscoverPacket:send()
    local progress = false

    local timeout = false
    parallel.waitForAny(function()
        handleOfferResponse()
    end,
    function()
        os.sleep(2)
        timeout = true
    end)
    local timeout = false
    parallel.waitForAny(function()
        handleAcknowlegement()
    end,
    function()
        os.sleep(2)
        timeout = true
    end)
    if ConfiguredIP == nil then
        
    end
    if (ARPProbe(Modem.mac, ConfiguredIP)) then
        ---@type DHCPMessage
        local DHCPDecline = {
            messageType = DHCPMessageType.Decline,
            transactionID = math.random(1, 1000000000),
            yourIP = 0,
            serverIP = 0,
            clientMAC = Modem.mac,
            gatewayIP = 0,
            clientIP = 0,
            options = {}
        }
        local DHCPDeclinePacket = EthernetII:new(Modem.mac, 0xFFFFFFFFFFFF, EthernetType.IPv4, IPv4.new(0, IPv4.addressFromString("255.255.255.255"), 17, IPv4Protocol.UDP, UDP.new(68, 67, DHCPDecline)))
        DHCPDeclinePacket:send()

    end
    
    
    return ConfiguredIP;
end





print(xpcall(RegisterDHCP, debug.traceback))
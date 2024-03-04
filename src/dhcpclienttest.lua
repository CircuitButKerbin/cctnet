require("networkd.networklayer")

---@return IPv4Address ConfiguredIP
function RegisterDHCP()
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
    print("Awaiting Offer")
    repeat
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
                            progress = true
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
                            local DHCPRequestPacket = EthernetII:new(Modem.mac, packet.sourceMAC, EthernetType.IPv4, IPv4.new(0, IPv4.addressFromString("255.255.255.255"), 17, IPv4Protocol.UDP, UDP.new(68, 67, DHCPRequest)))
                            print("Sent DHCP Request")
                            DHCPRequestPacket:send()
                            progress = true
                            break
                        end
                    end
                end
            end
    until progress;
    print("Awaiting ACK")
    progress = false
    repeat
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
                    if dhcppacket.messageType == DHCPMessageType.Ack then
                        print("Recieved DHCP Ack")
                        ConfiguredIP = dhcppacket.yourIP
                        progress = true
                        break
                    end
                end
            end
        end
    until progress;
    print("Acquired IP: " .. ConfiguredIP)
    --[[@as IPv4Address]]
    if ConfiguredIP == nil then
        error("Failed to acquire IP")
    end
    return ConfiguredIP;
end

print(xpcall(RegisterDHCP, debug.traceback))
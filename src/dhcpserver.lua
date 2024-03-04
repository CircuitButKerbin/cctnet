require ("networkd.networklayer")

IPv4TypetoString = {}
IPv4TypetoString[IPv4Protocol.UDP] = "UDP"
IPv4TypetoString[IPv4Protocol.ICMP] = "ICMP"
IPv4TypetoString[IPv4Protocol.TCP] = "TCP"
IPv4TypetoString[IPv4Protocol.IGMP] = "IGMP"
IPv4TypetoString[IPv4Protocol.OSPF] = "OSPF"
IPv4TypetoString[IPv4Protocol.SCTP] = "SCTP"

function HostDHCPServer()
    local DHCPAddress = IPUtil.strtoaddr("192.168.1.1")
    ARPCache = {}
    AssignedAddresses = {}
    OngoingDHCP = {}
    local function isAddressAvaliable(address)
        for k, v in pairs(AssignedAddresses) do
            if v == address then
                return false
            end
        end
        return true
    end
    Modem:openPort(67) -- Open the DHCP port
    while true do
        local event = Modem:getModemEvent()
        if event.channel == 67 then -- DHCP
            ---@type EthernetIIFrame
            local packet = event.message
            if packet.Type == EthernetType.IPv4 then
                --[[@as IPv4Packet]]
                local ipframe = packet.data
                if ipframe.protocol ~= IPv4Protocol.UDP then
                    goto pass
                end
                if ipframe.destination ~= IPUtil.strtoaddr("255.255.255.255") then
                    goto pass
                end
                ---@type DHCPMessage
                local dhcp = ipframe.data.data -- DHCP message in the UDP packet
                if dhcp.messageType == DHCPMessageType.Discover then
                    local offer;
                    repeat
                        offer = IPUtil.strtoaddr("192.168.1." .. tostring(math.random(2, 254)))
                    until isAddressAvaliable()
                    OngoingDHCP[dhcp.transactionID] = {
                        OfferedIP = offer
                    }
                    ---@type DHCPMessage
                    local payload = {
                        messageType = DHCPMessageType.Offer,
                        transactionID = dhcp.transactionID,
                        yourIP = offer,
                        serverIP = DHCPAddress,
                        clientMAC = packet.sourceMAC,
                        gatewayIP = DHCPAddress,
                        clientIP = 0,
                        ---@type table<any>
                        options = {}
                    }
                    payload.options[DHCPOptions.Server] = DHCPAddress;
                    DHCPOfferPacket = EthernetII:new(Modem.mac, packet.sourceMAC, EthernetType.IPv4, IPv4.new(DHCPAddress, ipframe.source, 17, IPv4Protocol.UDP, UDP.new(67, 68, payload)))
                    DHCPOfferPacket:send()
                end
                if dhcp.messageType == DHCPMessageType.Request then
                    if OngoingDHCP[dhcp.transactionID] == nil then
                        goto pass
                    end
                    if OngoingDHCP[dhcp.transactionID].OfferedIP ~= dhcp.options[DHCPOptions.RequestedIP] then
                        goto pass
                    end
                    ---@type DHCPMessage
                    local payload = {
                        messageType = DHCPMessageType.Ack,
                        transactionID = dhcp.transactionID,
                        yourIP = OngoingDHCP[dhcp.transactionID].OfferedIP;
                        serverIP = DHCPAddress,
                        clientMAC = packet.sourceMAC,
                        gatewayIP = 0,
                        clientIP = 0,
                        ---@type table<any>
                        options = {}
                    }
                    payload.options[DHCPOptions.Server] = DHCPAddress;
                    DHCPAckPacket = EthernetII:new(Modem.mac, packet.sourceMAC, EthernetType.IPv4, IPv4.new(DHCPAddress, ipframe.source, 17, IPv4Protocol.UDP, UDP.new(67, 68, payload)))
                    OngoingDHCP[dhcp.transactionID] = nil
                    DHCPAckPacket:send()
                end
            end
        elseif event.channel == 7 then -- ICMP
            ---@type EthernetIIFrame
            local packet = event.message
            if packet.Type == EthernetType.IPv4 then
                if packet.data.destination ~= DHCPAddress then -- Not for us
                    goto pass
                end
                --[[@as IPv4Packet]]
                local ipframe = packet.data 
                if ipframe.protocol == IPv4Protocol.ICMP then
                    --[[@as ICMPPacket]]
                    local icmp = ipframe.data
                    if icmp.Type == ICMPType.EchoRequest then -- Ping
                        local echo = EthernetII:new(Modem.mac, packet.sourceMAC, EthernetType.IPv4, IPv4:new(ipframe.destination, ipframe.source, 112, 1, ICMP:new(ICMPType.EchoReply, 0, {})))
                        echo:send()
                    end
                end
            end
        elseif event.channel == 1 then -- ARP
            ---@type EthernetIIFrame
            local packet = event.message
            if packet.Type == EthernetType.ARP then
                --[[@as ARPPacket]]
                local arp = packet.data
                if arp.operation == ARPOperation.Request then
                    if arp.destinationIPv4 == DHCPAddress then
                        local reply = EthernetII:new(Modem.mac, packet.sourceMAC, EthernetType.ARP, ARP:new(ARPOperation.Reply, Modem.mac, arp.targetMAC, arp.targetIP, arp.sourceIP))
                        reply:send()
                    end
                end
            end
        end
        ::pass::
    end
end

HostDHCPServer()
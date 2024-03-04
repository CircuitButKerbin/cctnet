require( "networkd.networklayer" )

Modem:openPort( 1 ) -- Open the ARP
Modem:openPort( 7 ) -- Open IMCP
Modem:openPort( 67 ) -- Open the DHCP port
Modem:openPort( 68 ) -- Open the DHCP port
while true do
    local event = Modem:getModemEvent()
    pcall(NetworkDebug.prettyPrintFrame,event.message)
end
_G.cctnet = {

}
local config = textutils.unserialiseJSON(fs.open("/cctnet/config.json", "r").readAll())
if not config then
    print("No configuration file found, using default values")
    local config = textutils.unserialiseJSON("{\n\"hostname\":\"desktop-0\",\n\"ip_assignment_method\":\"dhcp\",\n\"static_ip\":\"0.0.0.0\",\n\"default_gateway\":\"0.0.0.0\",\n\"subnet_mask\":\"0.0.0.0\",\n\"dns_server\":\"0.0.0.0\"\n}")
else
    
end
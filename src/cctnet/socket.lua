---@enum SocketType
SocketType = {
    SOCK_STREAM = 1,
    SOCK_DGRAM = 2,
    SOCK_SEQPACKET = 3,
}
---@enum SocketDomain
SocketDomain = {
    AF_UNSPEC = 0,
    AF_INET = 1,
    AF_INET6 = 2,
    AF_UNIX = 3,
}

---@class socket
---@field socket fun()
---@field accept fun(self:socket):table, IPAddress
---@field bind fun(self:socket, address:IPAddress):boolean
---@field connect fun(self:socket, address:IPAddress):boolean
---@field getpeername fun(self:socket):IPAddress
---@field getsockname fun(self:socket):IPAddress
---@field recvfrom fun(self:socket, address:IPAddress):table
---@field listen fun(self:socket, backlog:integer):boolean

--Get the hostname of the server
local ngx      = ngx
local lua_data = ngx.shared.lua_data;

function get_hostname()
    local f = io.popen ("/bin/hostname")
    if not f then
        return 'Invalid hostname,please  make sure  /bin/hostname exists'
    end
    local hostname = f:read("*a") or ""
    f:close()
    hostname =string.gsub(hostname, "\n$", "")
    return hostname
end


local hostname = get_hostname()
lua_data:set("hostname", hostname)


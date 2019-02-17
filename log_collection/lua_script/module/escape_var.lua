local _M = {}

_M.escape_uri = function(list)
    for k,v in  pairs(list) do
        if v == 'http_user_agent' and http_user_agent ~= '' then
            http_user_agent = ngx.escape_uri(http_user_agent)
        elseif v == 'http_referer' and http_referer  ~= ''  then
            http_referer = ngx.escape_uri(http_referer)
        elseif v == 'args' and args  ~= ''  then
            args = ngx.escape_uri(args)
        elseif v == 'uri' and uri  ~= '' then
            uri = ngx.escape_uri(uri)
        elseif v == 'host' and host  ~= '' then
            host = ngx.escape_uri(host)
        end
    end
end


return _M

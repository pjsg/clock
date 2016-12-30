-- httpserver

local H = {}

local function sendfile(conn, fn)
  local f = file.open(fn)

  if f == nil then
    conn:close()
    return
  end

  conn:on('sent', function(c)
     local buf = f:read(1024)
     if buf then
       c:send(buf)
     else
       c:close()
       f:close()
     end
  end)

  local buf = f:read(1024)
  conn:send(buf)
end

H["GET/"] = function(conn)
  sendfile(conn, "index.html") 
end

local srv = net.createServer(net.TCP)
srv:listen(80, function(conn)
    conn:on("receive", function(c, request)
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.*)?(.+) HTTP")
        if method == nil then
            _, _, method, path = string.find(request, "([A-Z]+) (.*) HTTP")
        end
        local _GET = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                _GET[k] = v
            end
        end

        local f = (H[method .. path])
        if f == nil then
           sendfile(c, "notfound.html")
        else
           f(c, _GET)
        end        
    end)
end)

return function (method, path, fn) 
  H[method .. path] = fn
end
-- webserver.lua

local M = {}

local t = require "time"
local config = require "config"
local tz = require "tz"

local function wrapit(fn)
  return function (conn)
      local buf = "HTTP/1.1 200 OK\r\n" ..
                  "Content-type: application/json\r\n" ..
                  "Connection: close\r\n\r\n" ..
                  cjson.encode(fn())
      conn:send(buf, function(c) c:close() end)
    end
end

local function getstatus()
    local R = {}
    R.time = {rtctime.get()}
    R.hms = t.getpos()
    R.running = t.getrunning()
    R.config = config.table
    R.ntp = lastNtpResult
    R.freemem = node.heap()
    return R 
end

local wrappedGetstatus = wrapit(getstatus)

function M.register(adder)
  function addjson(path, fn)
    adder("GET", path, wrapit(fn)) 
  end
  adder("GET", "/status", wrappedGetstatus)
  addjson("/zones", function ()
    return tz.getzones()
  end)
  
  adder("POST", "/set", function (conn, vars)
    if vars.start then
      t.start()
    end
    if vars.stop then
      t.stop()
    end
    if vars.pos then
      t.setpos(vars.pos)
    end
    if vars.zone then
      if tz.exists(vars.zone) then
        config.tz = vars.zone
      end
    end
    wrappedGetstatus(conn)
  end)
end

return M
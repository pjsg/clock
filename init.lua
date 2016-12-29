function printrtc()
  local _, _, rate = rtctime.get()
  print ('rate', rate)
end

function logit(server, data)
  if data['offset_us'] then
      local _, _, rate = rtctime.get()
      url = string.format("http://data.sparkfun.com/input/6JzRpa26jAuwJp0pnA4X?private_key=WwknrR9XeytMxd0dmzNA&mac=%s&delay_us=%d&offset_us=%s&rate=%d&root_delay_us=%d&server=%s",
        wifi.sta.getmac(), data['delay_us'], data['offset_us'], 
        rate, data['root_delay_us'], server)
      http.get(url, nil, function(code, data)
        if (code < 0) then
          print("HTTP request failed", code, data)
        end
      end)
  end
end

--syslog = require("syslog")("192.168.1.68");

function startsync()
    sntp.sync({"192.168.1.21", "0.nodemcu.pool.ntp.org", "1.nodemcu.pool.ntp.org", "2.nodemcu.pool.ntp.org"
    }, function (a,b, c, d ) 
      print(a,b, c, d['offset_us']) printrtc() 
      logit(c, d)
      --syslog:send("SNTP: Server " .. c .. " offset " .. (d['offset_us'] or 'nil') .. " delay " .. (d['delay_us'] or 'nil') .. " rate " .. rtcmem.read32(14))
    end, function(e) print (e) end, 1)
end

function ptime()
  local sec, usec, rate = rtctime.get()
  print ('time', sec, usec, rate)
end

ptime()

tmr.alarm(0, 3000, 1, function()
   local ip = wifi.sta.getip()
   if ip == nil then
     return
   end
   tmr.unregister(0)
   startsync()
end)

dofile("pps.lua")
dofile("tick.lua")

print_pps = 1

function logpps()
    local get = rtctime.get
    local now = tmr.now
    gpio.mode(2, gpio.INT)
    gpio.trig(2, "up", function (level, when)
       offset = now() - when
       sec, usec = get()
       if print_pps then
         local d = usec - offset
         if d > 500000 then
           d = d - 1000000
         end
         print ("offset", d, offset)
       end
    end)
end

logpps()

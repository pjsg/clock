pin = { 3, 8 }

inactive = 0

pulsetime = 30000
minwait = 100000
pulsetot = pulsetime + minwait

gpio.mode(pin[1], gpio.OUTPUT)
gpio.mode(pin[2], gpio.OUTPUT)
gpio.write(pin[1], inactive)
gpio.write(pin[2], inactive)

local time = require "time"
local timer = tmr.create()

function tick()
  if adc.read(0) > 800 then
      local want, clock, inus, evenodd = time.get()
      if want >= 0 and inus >= 0 then
          --print ('want', want, clock, inus)
          -- if clock is reading noon and we want to have it say 1:00, then we step fast
          -- if the clock is reading 1:00 and we want to have it say noon, then we stop
          local offset = (want - clock + 43200) % 43200
          if offset < 37000 then
            local steps = offset
            local maxsteps = inus / (pulsetot + 32000)
            if maxsteps == 0 then
              maxsteps = 1
            end
            if steps > maxsteps then
              steps = maxsteps
            end
            if steps > 0 then
              -- the goal is to have the pulse train end in "inus"
              -- total train time is steps * pulsetot - minwait
              local P = {}
              local gap = inus / steps - pulsetime - 32000
              P[1] = inus - (steps * (pulsetime + gap + 32000) - gap - 32000)
              if P[1] < minwait / 2 then
                P[1] = minwait / 2
              end
              P[2] = pulsetime
              P[3] = 10000
              gpio.serout(pin[evenodd > 0 and 1 or 2], inactive, P, 1, 
              function () time.tick() tick() end) 
              --print ('P', P[1], P[2], P[3], 'steps', steps, 'gap', gap)
              return
            end
          end
      end
  end
  timer:alarm(250, 0, function() tick() end)
end

tick()
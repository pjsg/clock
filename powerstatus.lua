-- powerstatus.lua

local m = {}

local adcval = bit.lshift(adc.read(0), 5)
local last = 1

function m.powerok()
  local current = adc.read(0)
  adcval = adcval + current - bit.rshift(adcval, 5)

  -- 10% below moving average
  if current * 35 < adcval then
    print ('Power', current, bit.rshift(adcval, 5))
    last = 0
  elseif current * 27 > adcval then
    -- 10% above moving average
    print ('Power', current, bit.rshift(adcval, 5))
    last = 1
  end
  return last
end

function m.get()
  return bit.rshift(adcval, 5)
end

return m

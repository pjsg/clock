-- time.lua

local M = {}
local MEMPOS = 16
local clockpos = 0
local pulse = 0  -- either 0x10000 or 0
local PULSEVAL = 0x10000
local running = 1

local tz = require "tz"

function M.tick() 
  pulse = PULSEVAL - pulse
  M.set(clockpos + 1)
end

function M.stop()
  running = 0
end

function M.start()
  running = 1
end

function M.set(pos)
  clockpos = pos % 43200
  rtcmem.write32(MEMPOS, clockpos + pulse)
end

function M.get()
  if running == 0 then
    return -1, -1, -1, -1
  end
  local us, nus = rtctime.get()
  if us < 1000000 then
    return -1, -1, -1, -1
  end
  us = us - sntp.getoffset()
  local want = (us + 1 + tz.getoffset(us + 1)) % 43200
  return want, clockpos, 1000000 - nus, pulse
end

clockpos = bit.band(rtcmem.read32(MEMPOS), PULSEVAL - 1)
pulse = bit.band(rtcmem.read32(MEMPOS), PULSEVAL)
if clockpos < 0 or clockpos >= 43200 then
  M.set(0)
end

sntp.setoffset(0)

return M
-- time.lua

local M = {}
local MEMPOS = 16
local clockpos = 0
local savedpos = 0
local pulse = 0  -- either 0x10000 or 0
local PULSEVAL = 0x10000
local running = 1
local filename = "clockpos.state"
local statefile 

local tz = require "tz"

function M.tick() 
  pulse = PULSEVAL - pulse
  M.setpos(clockpos + 1)
  if not statefile then
    -- this means that we have already saved the (now) wrong pos
    file.remove(filename)
    statefile = file.open(filename, "w")
  end
end

function M.stop()
  running = 0
end

function M.start()
  running = 1
end

function M.setpos(pos)
  clockpos = pos % 43200
  rtcmem.write32(MEMPOS, clockpos + pulse)
end

function M.sethms(hour, min, sec)
  M.set(hour * 3600 + min * 60 + sec)
  M.start()
end

function M.gethms()
  return clockpos / 3600, (clockpos / 60) % 60, clockpos % 60
end

function M.getpos()
  return clockpos
end

function M.getrunning()
  return running
end

function M.get()
  if running == 0 then
    return -1, -1, -1, -1
  end
  local us, nus = rtctime.get()
  if us < 1000000 then
    return -1, -1, -1, -1
  end
  local offset = sntp.getoffset()
  us = us - offset
  local want = (us + 1 + tz.getoffset(us + 1)) % 43200
  print (string.format("%d.%06d offset=%d want=%d", us + offset, nus, offset, want))
  return want, clockpos, 1000000 - nus, pulse
end

function M.save()
  local savevalue = rtcmem.read32(MEMPOS)
  
  if savevalue ~= savedpos then
    if not statefile then
      statefile = file.open(filename, "w+")
    end
    statefile:write(struct.pack("L", savevalue))
    statefile:close()
    statefile = nil
    savedpos = savevalue
  end
end

statefile = file.open(filename)
if statefile then
    local clockposstr = statefile:read(5)
    statefile:close()
    if clockposstr and string.len(clockposstr) == 4 then
      rtcmem.write32(MEMPOS, struct.unpack("L", clockposstr))
    end
    file.remove(filename)
end

statefile = file.open(filename, "w")

local mem = rtcmem.read32(MEMPOS)
clockpos = bit.band(mem, PULSEVAL - 1)
pulse = bit.band(mem, PULSEVAL)
if clockpos < 0 or clockpos >= 43200 then
  M.setpos(0)
end


sntp.setoffset(0)

return M

-- config.lua

local config = {}
local cache = {}

local fields = { tz=1 }

local mt = {
  __index = function(t, k) 
    if k == "json" then
      return cjson.encode(cache)
    end
    if k == "table" then
      return cache
    end
    return (cache[k])
  end,
  __newindex = function(t, k, v)
    if fields[k] then
      cache[k] = v
      file.open("config.json", "w+")
      file.write(cjson.encode(cache))
      file.close()
    end
    return 1
  end
}

setmetatable(config, mt)

if file.open("config.json") then
  cache = cjson.decode(file.read())
  file.close()
else
  cache = { tz="eastern" }
end

return config

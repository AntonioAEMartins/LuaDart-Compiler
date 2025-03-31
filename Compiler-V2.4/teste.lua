function min(a, b)
  if a < b then
      return a
  else
      return b
  end
end

local a = 1
local b = 2

local v = min(1,min(a,b))

print(v)
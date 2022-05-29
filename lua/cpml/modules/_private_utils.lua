-- Functions exported by utils.lua but needed by vec2 or vec3 (which utils.lua requires)

local private = {}
local floor   = math.floor
local ceil    = math.ceil

function private.round(value, precision)
	if precision then return utils.round(value / precision) * precision end
	return value >= 0 and floor(value+0.5) or ceil(value-0.5)
end

-- Make it easier to tell when something is "exactly 0" (can no longer distinguish -0 from +0 tho)
function private.strf3(v)
	return v == 0 and "=0.000" or string.format("%+0.3f",v)
end

return private

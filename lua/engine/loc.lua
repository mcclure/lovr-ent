-- Rigid body transform class based on CPML
-- Assumes PL, CPML in namespace
-- IMPORTS ALL ON REQUIRE

namespace "standard"

local plMetatable = {__tostring = function(o) return o:to_string() end}
class.Loc(nil, nil, plMetatable)
function Loc:_init(at, rotate, scale) -- Warning treat contents as const
	self.at = at or vec3()
	self.rotate = rotate or quat()
	self.scale = scale or 1
end
function Loc.fromPose(x,y,z, angle,ax,ay,az)
	return Loc(vec3(x,y,z), quat.from_angle_axis(angle,ax,ay,az))
end
function Loc:toPose()
	return self.at.x, self.at.y, self.at.z, self.rotate:to_angle_axis_unpack()
end
function Loc:clone()
	return Loc(self.at, self.rotate, self.scale)
end
function Loc:assign(loc)
	self.at = loc.at
	self.rotate = loc.rotate
	self.scale = loc.scale
end
function Loc:scaleUnpack() -- Return scale in 3-component form
	return self.scale, self.scale, self.scale
end
function Loc:apply(v) -- The following methods are untested
    return self.rotate * (v * self.scale) + self.at
end
function Loc:applyToVector(v)
    return self.rotate * (v * self.scale)
end
function Loc:compose(v) -- Return Loc equivalent to "apply self, then v"
    return Loc(v:apply(self.at), v.rotate * self.rotate, self.scale * v.scale)
end
function Loc:precompose(v) -- Return Loc equivalent to "apply v, then self"
	return v:compose(self)
end
function Loc:inverse(v)
	local unrotate = self.rotate:inverse()
	local unscale = self.scale ~= 0 and 1/self.scale or 0
    return Loc(unrotate * -self.at * unscale, unrotate, unscale)
end
function Loc:pow(s)
	return Loc(self.at * s, self.rotate:pow(s), math.pow(self.scale, s))
end
function Loc:lerp(v, s)
	return Loc(self.at:lerp(v.at, s), self.rotate:slerp(v.rotate, s), self.scale + (v.scale - self.scale) * s)
end
function Loc:to_string()
	local s = "(at:" .. tostring(self.at) .. " rot:" .. tostring(self.rotate)
	if self.scale ~= 1 then s = s .. " scale:" .. tostring(self.scale) end
	s = s .. ")"
	return s
end

-- Helpers that are not basic lua tools but rather specifically rely on lovr APIs
namespace "standard"

-- Extend Loc class with a function to "push" the transform to lovr.graphics
function Loc:push()
	lovr.graphics.push()
	lovr.graphics.translate(self.at:unpack())
	lovr.graphics.rotate(self.rotate:to_angle_axis_unpack())
	if scale ~= false then
		lovr.graphics.scale(self:scaleUnpack())
	end
end

-- Convert a controller's current orientation to a simple vec3 and quat pair. With nil name gives headset
-- Second argument is a "basis" Loc which is assumed to occur "before" the controller transform
function unpackPose(controllerName, transform)
	local x, y, z, angle, ax, ay, az = lovr.headset.getPose(controllerName)
	local at = vec3(x,y,z)-- * 4
    local rotate = quat.from_angle_axis(angle, ax, ay, az)
    if transform then
        local loc = transform:precompose(Loc(at, rotate))
        return loc.at, loc.rotate
    end
	return at, rotate
end

-- These two functions are in lovr.lua because they use the (point, quaternion) pair returned by unpackPose

-- Offset from a point, treating a line as an axis against which to interpret the offset
-- Args: starting point, quaternion orientation, offset
function offsetLine(at, q, v)
	return Loc(at, q):apply(v)
end

-- Get a point "a little ways along" a line
-- Args: starting point, quaternion orientation
function forwardLine(at, q)
	return offsetLine(at, q, vec3(0,0,-6))
end

-- The basic thumb directional may be either "touchpad" or "thumbstick" depending on unit.
-- These wrappers provide touched, down, and axis information for whichever the controller has (assuming only one is present)

function primaryTouched(controllerName)
	return lovr.headset.isTouched(controllerName, "touchpad")
	    or lovr.headset.isTouched(controllerName, "thumbstick")
end

function primaryDown(controllerName)
	return lovr.headset.isDown(controllerName, "touchpad")
	    or lovr.headset.isDown(controllerName, "thumbstick")
end

function primaryAxis(controllerName)
	return vec2(lovr.headset.getAxis(controllerName, "touchpad"))
	     + vec2(lovr.headset.getAxis(controllerName, "thumbstick"))
end

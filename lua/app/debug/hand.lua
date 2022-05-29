-- Minimal controller draw ent. Inherit and override "guideline" function to control pointer line display 
namespace "standard"

local Hand = classNamed("Hand", Ent)

local desktop = lovr.headset.getDriver() == "desktop"

-- If first value is false, no guideline. If true, guideline.
-- First and second values may optionally be a color (cpml style table) and a termination point (a vec3)
function Hand:guideline(i, controllerName)
	return false
end

function Hand:onDraw()
	for i,controllerName in ipairs(lovr.headset.getHands()) do
		-- Attempt to load a model
		if not self.controllerModel then self.controllerModel = {} end
		if self.controllerModel[i] == nil then
			if lovr.headset.getDriver() == "vrapi" then -- See issue#417
				self.controllerModel[i] = false print "Skipping controller model on Oculus Mobile"
			else
				self.controllerModel[i] = lovr.headset.newModel(controllerName)
				if not self.controllerModel[i] then self.controllerModel[i] = false print "NO CONTROLLER MODEL!" end -- If model load fails, don't try again
			end
		end

		if self.controllerModel[i] then
			local x, y, z, angle, ax, ay, az = lovr.headset.getPose(controllerName)
			--x = x * 4 y = y * 4 z = z * 4 -- Good for background debug mode
			self.controllerModel[i]:draw(x,y,z,1,angle,ax, ay, az)
		elseif not desktop then -- On OculusVR, no-model is expected, due to lack of avatar sdk support
			local x, y, z, angle, ax, ay, az = lovr.headset.getPose(controllerName) -- Placeholder: Draw a little box at an
			local q = quat.from_angle_axis(angle, ax, ay, az)
			local v = vec3(x, y, z) + q * vec3(0, -.025, .05)
			lovr.graphics.setColor(1,1,1,1)
			lovr.graphics.box('fill', v.x, v.y, v.z, .1, .05, .1, angle, ax, ay, az)
		end

		local guideline, guidelineTo = self:guideline(i, controllerName)
		if guideline then
			if type(guideline) == "table" then
				lovr.graphics.setColor(unpack(guideline))
			end
			local at, q = unpackPose(controllerName)
			local a2 = guidelineTo or forwardLine(at, q)
			lovr.graphics.line(at.x,at.y,at.z, a2.x,a2.y,a2.z)
		end
	end
end

return Hand

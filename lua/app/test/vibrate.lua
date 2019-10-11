-- Test screenToWorldRay when clicking in mirror

namespace "standard"

local VibrateTest = classNamed("VibrateTest", Ent)

local intensity = 0.65

function VibrateTest:onLoad()
	self.vibrations = {}
end

function VibrateTest:onUpdate()
	for i,controllerName in ipairs(lovr.headset.getHands()) do
		local length
		if lovr.headset.isDown(controllerName, 'y') or lovr.headset.isDown(controllerName, 'b') then
			length = 0.2
		elseif lovr.headset.isDown(controllerName, 'x') or lovr.headset.isDown(controllerName, 'a') then
			length = 0.04
		elseif lovr.headset.isDown(controllerName, 'trigger') then
			length = 1
		end
		if not self.vibrations[i] then
			if length then
				lovr.headset.vibrate(controllerName, intensity, length)
			end
		end
		self.vibrations[i] = toboolean(length)
	end
end

function VibrateTest:onDraw()
	lovr.graphics.print('Y or B: 0.2ms\nX or A: 0.05ms\nTrigger: 1s\nAll intensities: '..intensity, 0, 1.7, -3, .2)
end

return VibrateTest

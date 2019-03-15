-- Simple "draw some cubes" test
namespace("cubetest", "standard")

local CubeTest = classNamed("CubeTest", Ent)
local shader = require "shader/shader"

function CubeTest:onLoad(dt)
	self.time = 0
end

function CubeTest:onUpdate(dt)
	self.time = self.time + math.max(dt, 0.05)
end

function CubeTest:onDraw(dt)
	lovr.graphics.clear(1,1,1) lovr.graphics.setShader(shader)

	local count, width, spacing = 5, 0.4, 2
	local function toColor(i) return (i-1)/(count-1) end
	local function toCube(i) local span = count*spacing return -span/2 + span*toColor(i) end

	for x=1,count do for y=1,count do for z=1,count do
		lovr.graphics.setColor(toColor(x), toColor(y), toColor(z))
		lovr.graphics.cube('fill', toCube(x),toCube(y),toCube(z), cubeWidth, self.time/8, -y, x, -z)
	end end end
end

return CubeTest

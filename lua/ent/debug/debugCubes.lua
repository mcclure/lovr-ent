-- Convenience class for drawing lines and cubes (so you can "see" points of interest)
namespace "standard"

-- spec:
--     cubes: {at=vec3, rotate=quat, color={r,g,b}, expire=time in seconds, size=diameter, lineTo=vec3, lineColor={r,g,b}}
--            only "at" is required, also add "noCube=true" to suppress cube
--     topCubes: same as cubes
--     speed: set to slow/speed all timeouts
--     size: default size (diameter) of cubes
--     color: default color of cubes (default 0.5, 0.5, 0.5)
--     lineColor: default color of lines (if absent forward to color)
--     shader: shader for cubes (default to shader.shader)
--     onTop: if true default to ignoring depth
--     duration: default time to expire (default 1, false means never timeout, true means 1 frame)
--     neverExpire: if true expiration is disabled everywhere
-- members:
--     time: current point in the animation (in "animation time")
-- methods:
--     add(cube, duration): duration defaults 1 w/same rules as above, cube may be vec3 or a cube table as above
--     expireAll(): forget everything
local DebugCubes = classNamed("DebugCubes", Ent)

function DebugCubes:_init(spec) -- Do this in init instead of onLoad() so add() can be called before onLoad()
	self:super(spec)

	self.cubes = self.cubes or {}
	self.topCubes = self.topCubes or {}
	self.time = 0
	self.speed = self.speed or 1
	if self.duration == nil then self.duration = 1 end
	self.size = self.size or 1
	self.color = self.color or {0.5, 0.5, 0.5}
	self.shader = self.shader or require "shader.shader"
end

function DebugCubes:onUpdate(dt)
	self.time = self.time + dt*self.speed
end

function DebugCubes:timedOut(t)
	if self.neverExpire or t.expire == false then return false end
	if t.expire == true then t.expire = -1 return false end 
	return t.expire < self.time
end

function DebugCubes:add(cube, duration, onTop)
	if self.onTop and onTop == nil then onTop = true end

	if cube.x and cube.y and cube.z then
		cube = {at=cube}
	end
	if not cube.at then error("Debug cube: no position?") end
	if cube.expire == nil then
		if duration == nil then duration = self.duration end
		if duration == nil then duration = 1 end
		if duration == false or duration==true then cube.expire = duration
		else cube.expire = self.time + duration
		end
	end
	table.insert(onTop and self.topCubes or self.cubes, cube)
end

function DebugCubes:expireAll()
	self.cubes = {}
	self.topCubes = {}
end

local function maybeUnpack(q)
	if q then
		return q:to_angle_axis_unpack()
	end
end

function DebugCubes:doDraw(cubes)
	local upTo = #cubes

	-- Draw cubes first, then lines because lovr batching behavior is currently weird
	-- Could also get optimal perf by turning blend mode to off
	for i=1,upTo do
		local t = cubes[i]

		-- Manage list
		if not t then break end
		if self:timedOut(t) then
			local clip = 1
			while true do
				local t2 = cubes[i+clip]
				if t2 and self:timedOut(t2) then
					clip = clip + 1
				else
					break
				end
			end
			for i2=i,upTo do
				cubes[i2] = cubes[i2 + clip]
			end
			t = cubes[i]
			if not t then break end
		end

		-- Draw cube
		if not t.noCube then
			local color = t.color or self.color
			lovr.graphics.setShader(self.shader)
			lovr.graphics.setColor(unpack(color))
			lovr.graphics.cube('fill', t.at.x, t.at.y, t.at.z, t.size or self.size, maybeUnpack(t.rotate))
		end
	end -- Draw line
	for i,t in ipairs(cubes) do
		if t.lineTo then
			lovr.graphics.setShader()
			local color = t.lineColor or self.lineColor or t.color or self.color
			lovr.graphics.setColor(unpack(color))
			lovr.graphics.line(t.at.x, t.at.y, t.at.z, t.lineTo:unpack())
		end
	end
end

function DebugCubes:onDraw()
	self:doDraw(self.cubes)
	if tableTrue(self.topCubes) then
		lovr.graphics.setDepthTest()
		self:doDraw(self.topCubes)
		lovr.graphics.setDepthTest("lequal")
	end
end

return DebugCubes

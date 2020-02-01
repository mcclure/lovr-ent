-- Test to make sure Loc composition and such works right
namespace("standard")

local ui2 = require "ent.ui2"

local LocTest = classNamed("LocTest", ui2.ScreenEnt)

local epsilon = 1/128
local axisRad = 3
local tripletOffset = 7
local animateLen = 1

-- Before setting up GUI, run a tiny unit test of Loc
local function consistencyTest()
	local function isClose(a,b)
		local c = a - b
		return c:len2() < 1/4096
	end

	local points = {
		vec3(0,0,0), vec3(1,0,0), vec3(0,1,0), vec3(0,0,1), vec3(1,1,1), vec3(-1,2,5), vec3(10,-10,-5)
	}
	local transforms = {
		Loc(nil, quat.from_angle_axis( 2*math.pi/3, 1,0,0 ), nil),
		Loc(vec3(-10, 1, 5), quat.from_angle_axis( math.pi/5, 0,1,0 )),
		Loc(nil, quat.from_angle_axis( 4*math.pi/3, 0,1,0 ), nil),
		Loc(vec3(4, 2, 1), quat.from_angle_axis( 2*math.pi, 0,1,1 ), 5),
		Loc(vec3(10, -1, -5), quat.from_angle_axis( -math.pi/5, 0,1,0 )),
		Loc(vec3(4, 2, 1)),
	}

	for i,point in ipairs(points) do
		local test1 = point

		for i2, transform in ipairs(transforms) do
			local pre = test1

			test1 = transform:apply(test1)
			test1 = transform:inverse():apply(test1)

			if not isClose(pre, test1) then
				error(string.format("point %d, transform %d failed inverse test", i, i2))
			end
		end
	end

	for i,point in ipairs(points) do
		local test1 = point
		local testTransform = Loc()

		for i2, transform in ipairs(transforms) do
			test1 = transform:apply(test1)

			testTransform = testTransform:compose(transform)
			local test2 = testTransform:apply(point)

			if not isClose(test1, test2) then
				error(string.format("point %d, transform %d failed compose test", i, i2))
			end
		end
	end
	print("Consistency test passed")
end
consistencyTest()

-- lovr.graphics.push a matrix with the coordinates from a Loc transform.
local function locTransform(t)
	if not t then return end
	lovr.graphics.translate(t.at:unpack())
	lovr.graphics.rotate(t.rotate:to_angle_axis_unpack())
	lovr.graphics.scale(t:scaleUnpack())
end

-- Take Loc transform "transform" to a power, but recenter first.
function LocTest:centeredTransform(transform, recenterVector)
	return Loc(-recenterVector):compose(transform):compose(Loc(recenterVector))
end

function LocTest:drawAxis()
	lovr.graphics.setColor(1,0,0)
	lovr.graphics.line(0,0,0, axisRad, 0, 0)
	lovr.graphics.line(0,0,0, 0, axisRad, 0)
	lovr.graphics.line(0,0,0, 0, 0, axisRad)
	lovr.graphics.line(0,0,0, -axisRad, 0, 0)
	lovr.graphics.line(0,0,0, 0, -axisRad, 0)
	lovr.graphics.line(0,0,0, 0, 0, -axisRad)
end

function LocTest:drawBox(shader, offset)
	lovr.graphics.push()
	if offset then
		lovr.graphics.translate(offset:unpack())
	end

	lovr.graphics.setShader(shader)
	lovr.graphics.setColor(1,1,1)
	lovr.graphics.box('fill', 0, 0, 0, self.boxSize:unpack())

	lovr.graphics.setShader(nil)
	lovr.graphics.print("FRANT", 0, 0, self.boxSize.z/2 + epsilon)

	lovr.graphics.rotate(math.pi, 0,1,0)
	lovr.graphics.print("BACKK", 0, 0, self.boxSize.z/2 + epsilon)

	lovr.graphics.pop()
end

function LocTest:startAnimate(loc)
	self.animateTo = loc
	self.animateStart = self.time
end

function LocTest:onLoad(dt)
	self.boxSize = self.boxSize or vec3(4,1.5,0.5)
	self.boxCenter = self.boxCenter or self.boxSize*vec3(1,-1,1)/2

	self.time = 0

	self.shader = lovr.graphics.newShader("standard", {emissive = true})

	self.transform = {nil, Loc(), Loc()}

	-- UI setup
	ui2.routeMouse()

	local appendStr = "Appending:"
	local ents = {
		ui2.ButtonEnt{label=appendStr, onButton = function(button)
			self.prepend = not self.prepend
			button.label = self.prepend and "Prepending:" or appendStr
		end},
		ui2.ButtonEnt{label="Forward90", onButton = function()
			self:startAnimate( Loc(nil, quat.from_angle_axis(math.pi/2, 1,0,0)) )
		end},
		ui2.ButtonEnt{label="Sideside90", onButton = function()
			self:startAnimate( Loc(nil, quat.from_angle_axis(math.pi/2, 0,1,0)) )
		end},
		ui2.ButtonEnt{label="Roll90", onButton = function() -- Test swap
			self:startAnimate( Loc(nil, quat.from_angle_axis(math.pi/2, 0,0,1)) )
		end},
		ui2.ButtonEnt{label="In-2x", onButton = function() -- Test swap
			self:startAnimate( Loc(nil, nil, 0.5) )
		end},
		ui2.ButtonEnt{label="Out-2x", onButton = function() -- Test swap
			self:startAnimate( Loc(nil, nil, 2) )
		end},
		ui2.ButtonEnt{label="Left-1", onButton = function() -- Test swap
			self:startAnimate( Loc(vec3(-1,0,0)) )
		end},
		ui2.ButtonEnt{label="Right-1", onButton = function() -- Test swap
			self:startAnimate( Loc(vec3(1,0,0)) )
		end},
		ui2.ButtonEnt{label="Bck-1", onButton = function() -- Test swap
			self:startAnimate( Loc(vec3(0,0,-1)) )
		end},
		ui2.ButtonEnt{label="Fwd-1", onButton = function() -- Test swap
			self:startAnimate( Loc(vec3(0,0,1)) )
		end},
	}

	-- Lay all the buttons out
	local layout = ui2.PileLayout{managed=ents, parent=self}
	layout:layout()
end

function LocTest:transformPlus(i, loc)
	if i == 3 then
		loc = self:centeredTransform(loc, self.boxCenter)
	end

	if self.prepend then
		return self.transform[i]:precompose(loc)
	else
		return self.transform[i]:compose(loc)
	end
end

function LocTest:onUpdate(dt)
	self.time = self.time + math.max(dt, 0.05)

	if self.animateTo and self.time > self.animateStart + animateLen then
		for k,_ in pairs(self.transform) do
			self.transform[k] = self:transformPlus(k, self.animateTo)
		end
		self.animateTo = nil
	end
end

function LocTest:onDraw(dt)
	lovr.graphics.clear(0.9,0.9,0.9)

	for i,off in ipairs{-tripletOffset, 0, tripletOffset} do
		lovr.graphics.push()
		lovr.graphics.translate(off)

		self:drawAxis()

		if i ~= 1 then
			local transform

			if self.animateTo then
				local ratio = (self.time - self.animateStart)/animateLen
				transform = self:transformPlus(i, self.animateTo:pow(ratio))
			else
				transform = self.transform[i]
			end

			locTransform(transform)
		end

		self:drawBox(self.shader, i==3 and self.boxCenter)

		lovr.graphics.pop()
	end
end

function animatingFilter(self)
	if self.animateTo then
		return route_terminate
	end
end

function LocTest:onMirror()
	ui2.ScreenEnt:onMirror(self)
	return animatingFilter(self)
end
LocTest.onPress = animatingFilter
LocTest.onRelease = animatingFilter

return LocTest

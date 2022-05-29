-- 3D UI classes
-- Assumes pl, ent and mode are in namespace

namespace "standard"

local DebugHand = require "app.debug.hand"

local ui3 = {}

-- This "magic" value is set to the surface being processed whenever ui3 synthesizes a click.
-- A ui2 can use this to learn the "true" source of an event was ui3.
ui3.surfaceWithin = false       -- Points to Surface
ui3.surfaceWithinHand = false   -- Points to controller name
ui3.surfaceWithinHandObject = false

-- Clumsy global signal that all ui3 Hands should not show a line for a moment.
-- Currently is true/false, if contention occurs later could make it a number
ui3.suppressGuideline = {}

local function within(self, hand, f)
	ui3.surfaceWithin = self
	ui3.surfaceWithinHand = hand
	f()
	ui3.surfaceWithin = false
	ui3.surfaceWithinHand = false
end

local function ui3Mode() -- FIXME: Should live in mode.lua?
	ent.mode = "ui3"
	lovr.graphics.setShader()
	lovr.graphics.setBlendMode("alpha", "alphamultiply")
	lovr.graphics.setDepthTest(nil) -- TODO: Test if necessary
end

-- Create either a ui2 layout or a ui3 layout, depending on whether the surface exists.
function ui3.makeLayout(surface, layoutClass, ...)
	if surface then return surface:makeLayout(layoutClass, ...) end
	return layoutClass(...)
end

-- Load the SurfaceEnt and Hand for this ent, UNLESS force2d is true.
function ui3.loadSurfaceAndHand(self, force2d)
	if force2d then return end
	if not self.surface3 then
		self.surface3 = ui3.SurfaceEnt{}:insert(self)
	end
	if not self.hand then
		self.hand = ui3.Hand{doHover=true}:insert(self)
	end
end

-- This is a container for ui2 objects *specifically*. The "2" has been omitted.
-- It can be moved (and scaled), but note once "makeLayout" is called, it cannot be resized.
-- spec:
--     at [Loc]: Location to center on
--     screenSize [vec3]: Screen size to emulate   
ui3.SurfaceEnt = classNamed("SurfaceEnt", Ent)

-- TODO: Support non-pixel-based ways of specifying size, support yfactor>1
function ui3.SurfaceEnt:_init(spec)
	self:super(spec)
	if not self.transform then self.transform = Loc(vec3(0,1,-2)) end
	if not self.screenSize then self.screenSize = vec2(1280, 720) end -- TODO various ways to input
	self.aspect = self.screenSize.x/self.screenSize.y -- Currently unused
	self.yfactor = 1 -- Currently unused
	self.lastDownAt = {}
	self.lastHoverAt = {}
end

-- To make this work, all layout classes must be created through this function.
-- constructorSpec will be modified, ... will be passed in as addl constructor arguments
-- parent in spec will be overloaded
function ui3.SurfaceEnt:makeLayout(layoutClass, constructorSpec, ...)
	constructorSpec.parent = self
	return layoutClass(constructorSpec, ...)
end

local hoverColor = {1,1,0}
local downColor = {1,0,0}

function ui3.SurfaceEnt:onDraw()
	self.transform:push()
	ui3Mode()
	self.insideRoute = true
	self:route("onMirror")
	local function draw(v, color) -- Position indicator
		if v then
			lovr.graphics.setColor(unpack(color))
			local x,y,z = v:unpack()
			lovr.graphics.plane('fill',x,y,z,1/16,1/16,self.transform.rotate:unpack())
		end
	end
	for i,v in pairs(self.lastDownAt) do
		draw(v, downColor)
	end
	for i,v in pairs(self.lastHoverAt) do
		if not self.lastDownAt[i] then
			draw(v, hoverColor)
		end
	end
	self.insideRoute = false
	lovr.graphics.pop()
end

function ui3.SurfaceEnt:onMirror()
	if not self.insideRoute then
		return route_terminate -- Must prevent ui2 children from actually drawing their mirrors at mirror time
	end
end

function ui3.SurfaceEnt:transformToSurface(controllerTransform)
	local a = controllerTransform.at
	local b = forwardLine(a, controllerTransform.rotate)

	local at = a
	local v = (b - a):normalize()

	local normal = self.transform:applyToVector(vec3.unit_z)

	local distanceDenominator = v:dot(normal)
	local downAt = nil
	local pointAtGlobal = nil
	if distanceDenominator ~= 0 then
		local anchor = self.transform.at -- Because screen transform is centered, can avoid some math here
		local distance = (anchor-at):dot(normal)/distanceDenominator
		pointAtGlobal = at + v*distance
		local unloc = self.transform:inverse()
		local pointAtLocal = unloc:apply(pointAtGlobal)
		--print(pointAtGlobal, pointAtLocal) -- Top left will be 1, -aspect
		downAt = vec2(pointAtLocal)
	end

	return downAt, pointAtGlobal
end

-- Mostly a copypaste from LevelIntersectEnt:onDraw
-- The "spooky action at a distance" communication between Hand and Surface here is to support
-- a hypothetical future time when there are multiple surfaces at once
function ui3.SurfaceEnt:onPress3(i, controllerName, controllerTransform)
	local downAt = self:transformToSurface(controllerTransform)
	if downAt then
		within(self, controllerName, function()
			self:route("onPress", downAt)
		end)
	end
	self.lastDownAt[i] = downAt
end

function ui3.SurfaceEnt:onRelease3(i, controllerName, controllerTransform)
	local lastDownAt = self.lastDownAt[i]
	if lastDownAt then
		within(self, controllerName, function()
			self:route("onRelease", lastDownAt) -- Notice down location is where edge was, not the true location
		end)
		self.lastDownAt[i] = false
	end
end

function ui3.SurfaceEnt:onHoverImpl(i, controllerName, controllerTransform)
	local downAt, pointAtGlobal = self:transformToSurface(controllerTransform)
	local result
	if downAt then
		within(self, controllerName, function()
			result = self:routeFirstValue("onHoverSearch", downAt)
		end)
	end
	self.lastHoverAt[i] = result and downAt or false -- Lua ternary behavior intentional
	return result, result and pointAtGlobal
end

-- Annoying duplication is because routeFirstValue cannot return multiple values yet (FIXME?)
function ui3.SurfaceEnt:onHover3Search(...)
	local result, _ = self:onHoverImpl(...)
	return result
end

function ui3.SurfaceEnt:onContact3Search(...)
	local _, result = self:onHoverImpl(...)
	return result
end

-- This serves the function of lovr-mouse.lua when doing UI3 UI.
ui3.Hand = classNamed("ui3.Hand", DebugHand)

local hoverColor = {0.5, 0.5, 0.5}

function ui3.Hand:guideline(i, controllerName)
	if ui3.suppressGuideline[controllerName] then return false end
	if self.trigger and self.trigger[i] then return true, self.guidelineTerminate[i] end
	if self.hover and self.hover[i] then return hoverColor, self.guidelineTerminate[i] end
	return false
end

local function routeGlobal(...)
	ent.root:route(...)
end

function ui3.Hand:onUpdate()
	ui3.surfaceWithinHandObject = self
	for i,controllerName in ipairs(lovr.headset.getHands()) do
		local transform = Loc(unpackPose(controllerName))
		if self.trackingPress and self.trackingPress[controllerName] then
			for surface,callbackList in pairs(self.trackingPress[controllerName]) do
				local point = surface:transformToSurface(transform)
				for _,callback in ipairs(callbackList) do
					callback(point)
				end
			end
		end
		if lovr.headset.isDown(controllerName, "trigger") then
			self.edge = self.edge or {}
			self.trigger = self.trigger or {}
			local triggerWas = self.trigger[i]
			local edge = not triggerWas

			self.trigger[i] = controllerName
			self.edge[i] = edge
			if edge then
				routeGlobal("onPress3", i, controllerName, transform)
			end
		else
			if self.trigger then
				self.trigger[i] = false
				routeGlobal("onRelease3", i, controllerName, transform)
			end
			if self.doHover then
				self.hover = self.hover or {}
				self.hover[i] = ent.root:routeFirstValue("onHover3Search", i, controllerName, transform)
			end
			if self.edge then self.edge[i] = false end -- TODO: Handle controller disconnect
			if self.trackingPress then self.trackingPress[controllerName] = nil end
		end
		if (self.trigger and self.trigger[i]) or (self.hover and self.hover[i]) then
			self.guidelineTerminate = self.guidelineTerminate or {}
			self.guidelineTerminate[i] = ent.root:routeFirstValue("onContact3Search", i, controllerName, transform)
		end
	end
	ui3.surfaceWithinHandObject = false
end

function ui3.Hand:trackPress(hand, callback) -- Note ui2.trackPress behavior is split across ui2.trackPress and this function
	if not self.trackingPress then self.trackingPress = {} end
	if not self.trackingPress[hand] then self.trackingPress[hand] = {} end 
	local surface = ui3.surfaceWithin
	if not self.trackingPress[hand][surface] then self.trackingPress[hand][surface] = {} end
	table.insert(self.trackingPress[hand][surface], callback)
end

-- ui2 variants

local ui2 = require "ent.ui2"

function ui3.trackPress(callback, initial, ...)
	if not ui3.surfaceWithinHandObject then return end
	if callback then
		ui3.surfaceWithinHandObject:trackPress(ui3.surfaceWithinHand, callback)
		if initial then
			callback(initial, ...)
		end
	end
end

local function trackPressForward(_, ...) ui3.trackPress(...) end
ui3.trackPressForward = trackPressForward

function ui3.makeSliderEnt(spec, force2d)
	if not force2d then
		spec.trackPress = trackPressForward
	end
	return ui2.SliderEnt(spec)
end

function ui3.makeSliderTripletEnt(spec, force2d)
	if not force2d then
		if not spec.sliderSpec then spec.sliderSpec = {} end
		spec.sliderSpec.trackPress = trackPressForward
	end
	return ui2.SliderTripletEnt(spec)
end

return ui3

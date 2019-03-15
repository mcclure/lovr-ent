-- 2D UI classes
-- Assumes pl, ent and mode are in namespace

namespace "standard"

local flat = require "engine.flat"
local ui2 = {}

-- Not an ent-- feeds ents to other ents with set bounds
-- spec:
--     managed: array of ButtonEnts
--     swap: ent that can be safely swapped out when "screen" is done
--     parent: ent that laid out items should have as parent
-- members:
--     managedAt: How many managed items are successfully laid out?
ui2.Layout = classNamed("Layout")
function ui2.Layout:_init(spec)
	pull(self, {managedTo = 0})
	pull(self, spec)
end

function ui2.Layout:add(e)
	table.insert(self.managed, e)
end

ui2.PileLayout = classNamed("PileLayout", ui2.Layout)

local margin = 0.05

function ui2.PileLayout:layout()
	local mn = #self.managed -- Number of managed items
	local fh = flat.font:getHeight()*flat.fontscale -- Raw height of font
	local h = fh + margin*2 -- Height of a button
	local gap = h/2 -- Space between 2 buttons
	local screenmargin = h/2 -- Space between edge of screen and buttons
	local leftedge = -flat.xspan + h/2 -- Start lines on left
	local rightedge = -leftedge        -- Wrap around on right
	local at = vec2(leftedge, - flat.yspan + h/2) -- Placement cursor (start at bottom left)
	for i = (self.managedTo+1),mn do
		local e = self.managed[i] -- Entity to place
		if not e.label then error("Button without label") end
		local fw = flat.font:getWidth(e.label)*flat.fontscale -- Text width
		local w = fw + margin*2 -- Button width
		local to = at + vec2(w, h) -- Upper right of button
		local bound = bound2.at(at, to) -- Button bounds
		e.bound = bound
		at = vec2(at.x + w + margin, at.y) -- Move cursor
		if self.pass and e.layoutPass then e:layoutPass(self.pass) end
		if self.parent then e:insert(self.parent) end
	end
	self.managedTo = mn
end

-- Mouse support
local RouteMouseEnt = classNamed("RouteMouseEnt", Ent)
local routeMouseEnt

function RouteMouseEnt:onLoad()
	local function route(key, x, y)
		local inx =     x * flat.width  / flat.pixwidth  - flat.width/2    -- Convert pixel x,y to our coordinate system
		local iny = - ( y * flat.height / flat.pixheight - flat.height/2 ) -- GLFW has flipped y-coord
		ent.root:route(key, vec2(inx, iny)) -- FIXME: Better routing?
	end

	lovr.handlers['mousepressed'] = function(x,y)
		route("onPress", x, y)
	end

	lovr.handlers['mousereleased'] = function(x,y)
		route("onRelease", x, y)
	end
end

function ui2.routeMouse()
	if not routeMouseEnt then
		if not lovr.mouse then lovr.mouse = require 'lib.lovr-mouse' end
		routeMouseEnt = RouteMouseEnt()
		routeMouseEnt:insert(ent.root) -- FIXME: Better routing?
	end
end

ui2.SwapEnt = classNamed("SwapEnt", Ent)

function ui2.SwapEnt:swap(ent)
	local parent = self.parent
	self:die()
	queueBirth(ent, parent)
end


ui2.ScreenEnt = classNamed("ScreenEnt", ui2.SwapEnt)

function ui2.ScreenEnt:onMirror() -- Screen might not draw anything but it needs to set up coords
	uiMode()
end

-- Buttons or layout items
-- spec:
--     label: text label
--     swap: set by layout, sometimes unused, swap target if needed
--     bound: draw area
-- members:
--     down: is currently depressed (if a button)

ui2.UiEnt = classNamed("UiEnt", Ent)

function ui2.UiEnt:onMirror()
	local center = self.bound:center()
	local size = self.bound:size()

	lovr.graphics.setFont(flat.font)
	lovr.graphics.print(self.label, center.x, center.y, 0, flat.fontscale)
end

function ui2.UiEnt:layoutPass(pass) pull(self, pass) end

ui2.ButtonEnt = classNamed("ButtonEnt", ui2.UiEnt) -- Expects in spec: bounds=, label=

function ui2.ButtonEnt:onPress(at)
	if self.bound:contains(at) then
		self.down = true
	end
end

function ui2.ButtonEnt:onRelease(at)
	if self.bound:contains(at) then
		self:onButton(at) -- FIXME: Is it weird this is an "on" but it does not route?
	end
	self.down = false
end

function ui2.ButtonEnt:onButton()
end

function ui2.ButtonEnt:onMirror()
	local center = self.bound:center()
	local size = self.bound:size()
	local gray = self.down and 0.5 or 0.8
	lovr.graphics.setColor(gray,gray,gray,0.8)
	lovr.graphics.plane('fill', center.x, center.y, 0, size.x, size.y)
	lovr.graphics.setColor(1,1,1,1)

	ui2.UiEnt.onMirror(self)
end

return ui2
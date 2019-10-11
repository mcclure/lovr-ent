-- 2D UI classes
-- Assumes pl, ent and mode are in namespace

-- "PSEUDOEVENTS"- FUNCTIONS CALLED, BUT NOT ROUTED, AS PART OF UI
-- onButton, onChange, onLayout(l)

namespace "standard"

local flat = require "engine.flat"
local ui2 = {}

local function fontHeight()
	return flat.font:getHeight()*flat.fontscale
end

-- Return a point anchored to a bound
-- bound: a bound2
-- anchor: combination of (l)eft, (r)ight, (t)op, (b)ottom, x (c)enter, y (m)iddle
-- Currently, repeating letters is ok; they'll be overwritten
function ui2.t (bound) return bound.max.y end
function ui2.b (bound) return bound.min.y end
function ui2.l (bound) return bound.min.x end
function ui2.r (bound) return bound.max.x end
function ui2.tl(bound) return vec2(bound.min.x,bound.max.y) end
function ui2.bl(bound) return bound.min end
function ui2.tr(bound) return bound.max end
function ui2.br(bound) return vec2(bound.max.x,bound.min.y) end
function ui2.anchor(bound, anchor)
	local v = vec2(bound.min)
	for i,ch in ichars(anchor) do
		    if ch == "l" then v.x = bound.min.x
     	elseif ch == "r" then v.x = bound.max.x
     	elseif ch == "c" then v.x = (bound.min.x+bound.max.x)/2
     	elseif ch == "t" then v.y = bound.max.y
     	elseif ch == "b" then v.y = bound.min.y
     	elseif ch == "m" then v.y = (bound.min.y+bound.max.y)/2
     	else error(string.format("Unrecognized character %s in anchor", ch))
     	end
	end
	return v
end
function ui2.anchorBools(anchor)
 	local r, b = false, false
 	for i,ch in ichars(anchor) do
 		    if ch == "l" then r = true
      	elseif ch == "r" then r = false
      	elseif ch == "c" then r = true
      	elseif ch == "t" then b = false
      	elseif ch == "b" then b = true
      	elseif ch == "m" then b = false
      	else error(string.format("Unrecognized character %s in anchor", ch))
      	end
 	end
 	return r,b
end

-- Not an ent-- feeds ents to other ents with set bounds
-- spec:
--     managed: array of ButtonEnts
--     swap: ent that can be safely swapped out when "screen" is done
--     parent: ent that laid out items should have as parent
-- members:
--     managedTo: How many managed items have been inserted?
--     placedTo: How many managed items have been laid out?
ui2.Layout = classNamed("Layout")
function ui2.Layout:_init(spec)
	pull(self, {managedTo = 0, placedTo=0})
	pull(self, spec)
	self.managed = self.managed or {}
end

function ui2.Layout:add(e) -- Call to manage another item
	table.insert(self.managed, e)
end

function ui2.Layout:manage(e) -- For internal use
	if self.pass and e.layoutPass then e:layoutPass(self.pass) end
	if self.parent then e:insert(self.parent) end
end

-- Esoteric -- Call this if for some reason insertion/loading needs to occur before layout
function ui2.Layout:prelayout()
	local mn = #self.managed -- Number of managed items
	for i = (self.managedTo+1),mn do
		self:manage(self.managed[i])
	end
	self.managedTo = mn
end

ui2.PileLayout = classNamed("PileLayout", ui2.Layout)

-- spec:
--     face: "x" or "y" -- default "x"
--     anchor: any combination of "tblr", default "lb"
-- members:
--     cursor: Next place to put a button
--     linemax (optional): greatest width of a button this line
function ui2.PileLayout:_init(spec)
	pull(self, {face="x"})
	self:super(spec)
	self.anchor = "lb" .. (self.anchor or "")
end

local margin = 0.05 -- Margin around text. Tunable 

-- Perform all layout at once. If true, re-lay-out things already laid out
function ui2.PileLayout:layout(relayout)
	-- Constants: Logic
	local moveright, moveup = ui2.anchorBools(self.anchor) -- Which direction are we moving?
	local mn = #self.managed -- Number of managed items
	local startAt = relayout and 1 or (self.placedTo+1) -- From what button do we begin laying out?

	-- Constants: Metrics
	local fh = fontHeight() -- Raw height of font
	local screenmargin = (fh + margin*2)/2 -- Space between edge of screen and buttons. Tunable
	local spacing = margin

	-- Logic constants
	local leftedge = -flat.xspan + screenmargin -- Start lines on left
	local rightedge = -leftedge        -- Wrap around on right
	local bottomedge = -flat.yspan + screenmargin -- Start render on bottom
	local topedge = -bottomedge
	local xface = self.face == "x"
	local axis = vec2(moveright and 1 or -1, moveup and 1 or -1) -- Only thing anchor impacts

	-- State
	local okoverflow = toboolean(self.cursor) -- Overflows should be ignored
	self.cursor = self.cursor or vec2(leftedge, bottomedge) -- Placement cursor (start at bottom left)

	for i = startAt,mn do -- Lay out everything not laid out
		local e = self.managed[i] -- Entity to place
		
		-- Item Metrics
		local buttonsize = e:sizeHint(margin)
		local w, h = buttonsize:unpack()
		local to = self.cursor + buttonsize -- Upper right of button

		-- Wrap
		local didoverflow = okoverflow and (
			(xface and to.x > rightedge) or (not xface and to.y > topedge)
		)
		if didoverflow then
			if xface then
				self.cursor = vec2(leftedge, to.y + spacing)
			else
				self.cursor = vec2(self.cursor.x + self.linemax + spacing, bottomedge)
				self.linemax = 0
			end
			to = self.cursor + buttonsize
		else
			okoverflow = true
		end

		local bound = bound2.at(self.cursor*axis, to*axis) -- Button bounds
		e.bound = bound
		if xface then
			self.cursor = vec2(self.cursor.x + w + spacing, self.cursor.y) -- Move cursor
		else
			self.cursor = vec2(self.cursor.x, self.cursor.y + h + spacing) -- Move cursor
			self.linemax = math.max(self.linemax or 0, buttonsize.x)
		end
		if e.onLayout then e:onLayout() end
		if i > self.managedTo then self:manage(e) end
	end
	self.managedTo = mn
	self.placedTo = mn
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
--     swap: set by layout, sometimes unused, swap target if needed
--     bound: draw area
-- members:
--     down: is currently depressed (if a button)
-- must-implement methods:
--     sizeHint(margin) - return recommended size

ui2.UiBaseEnt = classNamed("UiBaseEnt", Ent)

function ui2.UiBaseEnt:layoutPass(pass) pull(self, pass) end

-- Items with text
-- spec:
--     label (required): text label

ui2.UiEnt = classNamed("UiEnt", ui2.UiBaseEnt)

function ui2.UiEnt:sizeHint(margin, overrideText)
	local label = overrideText or self.label
	if not label then error("Button without label") end -- TODO: This may be too restrictive

	local fh = fontHeight() -- Raw height of font
	local h = fh + margin*2 -- Height of a button
	local fw = flat.font:getWidth(label)*flat.fontscale -- Text width
	local w = fw + margin*2 -- Button width
	return vec2(w, h)
end

function ui2.UiEnt:onMirror()
	local center = self.bound:center()
	local size = self.bound:size()

	lovr.graphics.setColor(1,1,1,1)
	lovr.graphics.setFont(flat.font)
	lovr.graphics.print(self.label, center.x, center.y, 0, flat.fontscale)
end

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

	ui2.UiEnt.onMirror(self)
end

ui2.ToggleEnt = classNamed("ToggleEnt", ui2.ButtonEnt) -- ButtonEnt but stick down instead of hold

function ui2.ToggleEnt:onPress(at)
	if self.bound:contains(at) then
		self.down = not self.down
	end
end

function ui2.ToggleEnt:onRelease(at)
end

-- Draggable slider
-- spec:
--     lineWidth: recommended line width float
--     handleWidth: recommended handle width+height
--     wholeWidth: recommended size of entire line
--     minRange, maxRange: span of underlying value range (default 0,1)
-- members:
--	   value: value minRange-maxRange (so 0-1 by default)
--     disabled: if true hide handle

ui2.SliderEnt = classNamed("SliderEnt", ui2.UiBaseEnt)

function ui2.SliderEnt:_init(spec) -- Note by allowing wholeWidth I made my life really hard
	self:super(tableConcat({value=0, minRange=0, maxRange=1}, spec))
	if self.lineWidth and self.handleWidth and self.wholeWidth then
		error("Can only specify two of lineWidth, handleWidth, wholeWidth")
	end
	if self.handleWidth and self.wholeWidth then
		self.lineWidth = self.wholeWidth-self.handleWidth
	else
		self.lineWidth = self.lineWidth or 0.3
	end
	if self.wholeWidth then
		if self.lineWidth >= self.wholeWidth then error ("wholeWidth too small") end
		self.handleWidth = self.wholeWidth - self.lineWidth
	else
		if not self.handleWidth then
			self.handleWidth = fontHeight()
		end
		self.wholeWidth = self.lineWidth+self.handleWidth
	end
end

function ui2.SliderEnt:sizeHint(margin)
	return vec2(self.wholeWidth,self.handleWidth+margin*2)
end

function ui2.SliderEnt:onMirror()
	local center = self.bound:center()
	local zoff = 0.125
	lovr.graphics.setColor(0,1,1,1)
	lovr.graphics.line(center.x - self.lineWidth/2, center.y, -zoff, center.x + self.lineWidth/2, center.y, -zoff)
	if not self.disabled and self.value then
		local across = (self.value-self.minRange) / (self.maxRange - self.minRange)
		across = center.x + self.lineWidth * (across - 0.5)
		lovr.graphics.setColor(0.2,0.2,0.2,0.8)
		lovr.graphics.plane('fill', across, center.y, 0, self.handleWidth, self.handleWidth)
		lovr.graphics.setColor(1,1,1,1)
		lovr.graphics.line(across, center.y-self.handleWidth/2, zoff, across, center.y+self.handleWidth/2, zoff)
	end
end

function ui2.SliderEnt:onPress(at)
	if not self.disabled and self.bound:contains(at) then
		local halfline = self.lineWidth/2
		self.value = utils.clamp(
			(at.x - (self.bound.min.x + self.handleWidth/2))/self.lineWidth,
			0,1
		) * (self.maxRange-self.minRange) + self.minRange
		if self.onChange then self:onChange(self.value) end -- See also: self:onButton "is it weird"?
	end
end

-- Draggable slider
-- spec:
--     watch: SliderEnt to watch
-- Problem: Will not properly handle relayouts

ui2.SliderWatcherEnt = classNamed("SliderWatcherEnt", ui2.UiEnt)

function ui2.SliderWatcherEnt:sizeHint(margin, overrideText)
	return ui2.UiEnt.sizeHint(self, margin, overrideText or "8.88")
end

function ui2.SliderWatcherEnt:onMirror()
	self.label = (not self.disabled and self.watch.value) and string.format("%.2f", self.watch.value) or ""
	return ui2.UiEnt.onMirror(self)
end

-- Ent which acts as a container for other objects
-- spec:
--     layout: a Layout object (required)
-- members:
--     lastCenter: tracks center over time so if the ent moves the offset is known
--     layoutCenter: tracks center at last sizeHint

ui2.LayoutEnt = classNamed("LayoutEnt", ui2.UiBaseEnt)

function ui2.LayoutEnt:_init(spec)
	pull(self, {lastCenter = vec2.zero})
	self:super(spec)
	self.layout = self.layout or
		ui2.PileLayout{anchor=self.anchor, face=self.face, managed=self.managed, parent=self}
		self.anchor = nil self.face = nil self.managed = nil
end

function ui2.LayoutEnt:sizeHint(margin, overrideText)
	self.layout:layout()
	local bound
	for i,v in ipairs(self.layout.managed) do
		bound = bound and bound:extendBound(v.bound) or v.bound
	end
	if not bound then error(string.format("LayoutEnt (%s) with no members", self)) end
	self.layoutCenter = bound:center()
	return bound:size()
end

function ui2.LayoutEnt:onLayout()
	local center = self.bound:center()
	local offset = center - self.lastCenter - self.layoutCenter
	for i,v in ipairs(self.layout.managed) do
		v.bound = v.bound:offset(offset)
	end
	self.lastCenter = center
end

function ui2.LayoutEnt:onLoad()
	if self.standalone then
		self.layout:layout() -- In case sizeHint wasn't called
	end
end

-- A label, a slider, and a slider watcher
-- spec:
--     startLabel: initial label
--     sliderSpec: label display props
-- members:
--     labelEnt, sliderEnt, sliderWatcherEnt: as named
-- methods:
--     getLabel(), setLabel(label)
--     getValue(), setValue(value)

ui2.SliderTripletEnt = classNamed("SliderTripletEnt", ui2.LayoutEnt)

function ui2.SliderTripletEnt:_init(spec)
	pull(self, {anchor = "lt"})
	self:super(spec)
	self.labelEnt = self.labelEnt or ui2.UiEnt{label=self.startLabel}
		self.layout:add(self.labelEnt) self.startLabel = nil

	local sliderSpec = {value=self.value, onChange = function(slider)
		self.value = slider.value
		if self.onChange then self:onChange(self.value) end
	end}
	pull(sliderSpec, self.sliderSpec)
	self.sliderEnt = self.sliderEnt or ui2.SliderEnt(sliderSpec)
		self.layout:add(self.sliderEnt) self.sliderSpec = nil

	self.sliderWatcherEnt = self.sliderWatcherEnt or ui2.SliderWatcherEnt{watch=self.sliderEnt}
		self.layout:add(self.sliderWatcherEnt)
end

function ui2.SliderTripletEnt:getLabel() return self.labelEnt.label end
function ui2.SliderTripletEnt:setLabel(l) self.labelEnt.label = l end
function ui2.SliderTripletEnt:getValue() return self.sliderEnt.value end
function ui2.SliderTripletEnt:setValue(v) self.sliderEnt.value = v end
function ui2.SliderTripletEnt:getDisabled() return self.sliderEnt.disabled end
function ui2.SliderTripletEnt:setDisabled(v)
	self.sliderEnt.disabled = v
	self.sliderWatcherEnt.disabled = v
end

return ui2
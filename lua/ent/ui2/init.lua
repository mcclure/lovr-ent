-- 2D UI classes
-- Assumes pl, ent and mode are in namespace

-- "PSEUDOEVENTS"- FUNCTIONS CALLED, BUT NOT ROUTED, AS PART OF UI
-- onButton, onChange, onLayout(l)

namespace "standard"

local flat = require "engine.flat"
local ui2 = {}
local mouse = require "lib.lovr-mouse"

local function fontHeight()
	return flat.font:getHeight()*flat.fontscale
end

ui2.textmargin = 0.05 -- Margin around text. Tunable
ui2.iconmargin = ui2.textmargin/2
ui2.screenmargin = (fontHeight() + ui2.textmargin*2)/2 -- Space between edge of screen and buttons. Tunable
ui2.itemmargin = ui2.screenmargin
ui2.fontHeight = fontHeight

local margin = ui2.textmargin
local iconMargin = ui2.iconmargin

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
 	local l, b = false, false
 	for i,ch in ichars(anchor) do
 		    if ch == "l" then l = true
      	elseif ch == "r" then l = false
      	elseif ch == "c" then l = false
      	elseif ch == "t" then b = false
      	elseif ch == "b" then b = true
      	elseif ch == "m" then b = false
      	else error(string.format("Unrecognized character %s in anchor", ch))
      	end
 	end
 	return l,b
end
function ui2.anchorBoolsCentered(anchor)
 	local c, m = false, false
 	for i,ch in ichars(anchor) do
 		    if ch == "l" then c = false
      	elseif ch == "r" then c = false
      	elseif ch == "c" then c = true
      	elseif ch == "t" then m = false
      	elseif ch == "b" then m = false
      	elseif ch == "m" then m = true
      	else error(string.format("Unrecognized character %s in anchor", ch))
      	end
 	end
 	return c,m
end


-- Not an ent-- feeds ents to other ents with set bounds
-- spec:
--     managed: array of ButtonEnts
--     swap: ent that can be safely swapped out when "screen" is done
--     parent: ent that laid out items should have as parent
--     pass: all keys in this table will be set on items on add
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
	if self.mutable and not self.pass then self.pass = {} end
	if self.mutable and not self.pass.relayout then
		self.relayoutTemplate = function() self:layout(true) end
		self.pass.relayout = self.relayoutTemplate
	end
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

-- Lay out in a row or column, with "wrapping"
ui2.PileLayout = classNamed("PileLayout", ui2.Layout)

ui2.PileLayout.linebreak = {} -- Insert this item in a layout to break directly to next line

-- spec:
--     face: "x" or "y" -- default "x"
--     anchor: any combination of "tblr", default "lb"
--     itemMargin: distance between items
-- members:
--     cursor: Next place to put a button
--     linemax (optional): greatest width of a button this line
function ui2.PileLayout:_init(spec)
	pull(self, {face="x"})
	self:super(spec)
	self.anchor = "lb" .. (self.anchor or "")
end

-- Perform all layout at once. If true, re-lay-out things already laid out
function ui2.PileLayout:layout(relayout)
	-- Constants: Logic
	local moveright, moveup = ui2.anchorBools(self.anchor) -- Which direction are we moving?
	local anchorcenter, anchormiddle = ui2.anchorBoolsCentered(self.anchor)
	local mn = #self.managed -- Number of managed items
	local startAt = relayout and 1 or (self.placedTo+1) -- From what button do we begin laying out?

	-- Constants: Metrics
	local fh = fontHeight() -- Raw height of font
	local screenmargin = ui2.screenmargin -- Space between edge of screen and buttons. Tunable
	local spacing = self.itemMargin or ui2.itemmargin

	-- Logic constants
	local leftedge = -flat.xspan + screenmargin -- Start lines on left
	local rightedge = -leftedge        -- Wrap around on right
	local bottomedge = -flat.yspan + screenmargin -- Start render on bottom
	local topedge = -bottomedge
	local xface = self.face == "x"
	local axis = vec2(moveright and 1 or -1, moveup and 1 or -1) -- Only thing anchor impacts besides i == 1 case below
	if anchorcenter or anchormiddle then                         -- OK also this
		local button1size = self.managed and self.managed[1]:sizeHint(margin) or vec2.zero
		if anchorcenter then
			leftedge = -button1size.x/2
		end
		if anchormiddle then
			bottomedge = -button1size.y/2
		end
	end

	if self.mutable then
		for _,v in ipairs(self.managed) do if not v.label then
			self:prelayout()
			return
		end end
	end

	-- State
	local okoverflow = toboolean(self.cursor) -- Overflows should be ignored
	if relayout then self.cursor = nil end
	self.cursor = self.cursor or vec2(leftedge, bottomedge) -- Placement cursor (start at bottom left)

	for i = startAt,mn do -- Lay out everything not laid out
		local e = self.managed[i] -- Entity to place

		local function nextLine(to) -- Perform line wrap
			if xface then
				self.cursor = vec2(leftedge, to.y + spacing)
			else
				self.cursor = vec2(self.cursor.x + self.linemax + spacing, bottomedge)
				self.linemax = 0
			end
		end

		if e == ui2.PileLayout.linebreak then -- Special entity
			-- FIXME: Don't hardcode the size?
			nextLine(self.cursor + vec2(0, fontHeight() + margin*2))
		else -- Normal entity
			-- Item Metrics
			local buttonsize = e:sizeHint(margin)
			local w, h = buttonsize:unpack()
			local to = self.cursor + buttonsize -- Upper right of button

			-- Wrap
			local didoverflow = okoverflow and (
				isLinebreak or
				(xface and to.x > rightedge) or (not xface and to.y > topedge)
			)
			if didoverflow then
				nextLine(to)
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
	end
	self.managedTo = mn
	self.placedTo = mn
end

-- Lay out in a grid
-- All items need a gx and a gy
-- gx and gy always grow x-right y-up, but they grow in any direction (you can go negative)
-- blank spaces are allowed
-- You can layout again to grow the grid but must do it "toward center" or buttons will go offscreen
-- If you need to add buttons and have the grid move to accomodate them, use relayout
ui2.GridLayout = classNamed("GridLayout", ui2.Layout)

-- spec:
--     anchor: any combination of "tblr", default "lb"
-- members:
--     cursor: Next place to put a button
--     linemax (optional): greatest width of a button this line
function ui2.GridLayout:_init(spec)
	self:super(spec)
	self.anchor = "lb" .. (self.anchor or "")
end

-- Perform all layout at once. If true, re-lay-out things already laid out
function ui2.GridLayout:layout(relayout)
	if relayout or not self.laidOut then
		self.xo = {} -- Map of gridx -> x origin positions [relative to self.po]
		self.yo = {} -- Map of gridy -> y origin positions
		self.widths = {} -- Map of grix -> width
		self.heights = {} -- Map of grid -> height
		self.go = nil -- vec2 grid origin (ie which cell is attached to the anchor)
		self.po = nil -- vec2 grid origin position (ie what is the xy of the grid origin)
		self.gb = nil -- grid bound2
		self.laidOut = true
	end

	local mn = #self.managed -- Number of managed items
	if mn > 0 then

		-- Constants: Logic
		local startAt = relayout and 1 or (self.placedTo+1) -- From what button do we begin laying out?
		local anchorleft, anchorbottom = ui2.anchorBools(self.anchor)
		local anchorcenter, anchormiddle = ui2.anchorBoolsCentered(self.anchor)

		-- Constants: Metrics
		local fh = fontHeight() -- Raw height of font
		local screenmargin = ui2.screenmargin -- Space between edge of screen and buttons. Tunable
		local spacing = ui2.itemmargin

		-- Logic constants
		local leftedge = -flat.xspan + screenmargin -- Start lines on left
		local rightedge = -leftedge        -- Wrap around on right
		local bottomedge = -flat.yspan + screenmargin -- Start render on bottom
		local topedge = -bottomedge

		if self.mutable then
			for _,v in ipairs(self.managed) do if not v.label then
				self:prelayout()
				return
			end end
		end

		-- State
		local pass = A2()
		
		for i = startAt,mn do -- Lay out everything not laid out
			local e = self.managed[i] -- Entity to place
			if not (e.gx and e.gy) then error(string.format("Entity %d in grid layout doesn't have grid coordinates", i)) end
			pass:set(e.gx, e.gy, e)
			-- Expand gb to include this point
			local at = vec2(e.gx, e.gy)
			if not self.gb then
				self.gb = bound2.at(at)
			elseif not self.gb:contains(at) then
				self.gb = self.gb:extend(at)
			end
		end

		-- Get widths
		for x=ui2.l(self.gb),ui2.r(self.gb) do
			if not self.widths[x] then
				for y=ui2.b(self.gb),ui2.t(self.gb) do
					local e = pass:get(x, y)
					if e then
						self.widths[x] = e:sizeHint(margin).x
						break
					end
				end
			end
		end

		-- Get heights
		for y=ui2.b(self.gb),ui2.t(self.gb) do
			if not self.heights[y] then
				for x=ui2.l(self.gb),ui2.r(self.gb) do
					local e = pass:get(x, y)
					if e then
						self.heights[y] = e:sizeHint(margin).y
						break
					end
				end
			end
		end

		-- Set go
		if not self.go then
			self.go = vec2((anchorleft or anchorcenter) and ui2.l(self.gb) or ui2.r(self.gb), -- Notice: centered has tl for go
						   anchorbottom and ui2.b(self.gb) or ui2.t(self.gb))
		end

		-- Set xes+
		local totalWidth, totalHeight = 0, 0
		do
			local xc = 0 -- cumulative x
			local lastWidth = 0
			for x=self.go.x,ui2.r(self.gb) do
				if self.widths[x] then
					lastWidth = self.widths[x]
				else
					self.widths[x] = lastWidth
				end
				self.xo[x] = xc
				local width = self.widths[x]
				xc = xc + width + margin
				totalWidth = totalWidth + width + (totalWidth > 0 and margin or 0)
			end
		end
		-- Set xes-
		do
			local xc = 0 -- cumulative x
			local lastWidth = self.widths[self.go.x]
			for x=self.go.x-1,ui2.l(self.gb),-1 do
				if self.widths[x] then
					lastWidth = self.widths[x]
				else
					self.widths[x] = lastWidth
				end
				local width = self.widths[x]
				xc = xc - width - margin
				self.xo[x] = xc
				totalWidth = totalWidth + width + margin
			end
		end
		-- Set yes+
		do
			local yc = 0 -- cumulative x
			local lastHeight = 0
			for y=self.go.y,ui2.t(self.gb) do
				if self.heights[y] then
					lastHeight = self.heights[y]
				else
					self.heights[y] = lastHeight
				end
				self.yo[y] = yc
				local height = self.heights[y]
				yc = yc + height + margin
				totalHeight = totalHeight + height + (totalHeight > 0 and margin or 0)
			end
		end
		-- Set yes-
		do
			local yc = 0 -- cumulative x
			local lastHeight = self.heights[self.go.y]
			for y=self.go.y-1,ui2.b(self.gb),-1 do
				if self.heights[y] then
					lastHeight = self.heights[y]
				else
					self.heights[y] = lastHeight
				end
				local height = self.heights[y]
				yc = yc - height - margin
				self.yo[y] = yc
				totalHeight = totalHeight + height + margin
			end
		end

		-- Set po
		if not self.po then
			self.po = vec2(anchorleft and leftedge or rightedge,
				           anchorbottom and bottomedge or topedge)
			if anchorcenter then -- Overwrite po fully
				self.po.x = -totalWidth/2
			elseif not anchorleft then
				self.po.x = self.po.x - self.widths[self.go.x]
			end
			if anchormiddle then
				self.po.y = totalHeight/2 - self.heights[self.go.y] -- Adjustment bc button anchor is low-y
			elseif not anchorbottom then
				self.po.y = self.po.y - self.heights[self.go.y]
			end
		end

		for i = startAt,mn do -- Now that we have the information we need, laying everything out is easy
			local e = self.managed[i] -- Entity to place
			local min = vec2(self.xo[e.gx], self.yo[e.gy])+self.po
			local size = vec2(self.widths[e.gx], self.heights[e.gy])
			local bound = bound2(min, min + size) -- Button bounds
			e.bound = bound
			if e.onLayout then e:onLayout() end
			if i > self.managedTo then self:manage(e) end
		end
	end
	self.managedTo = mn
	self.placedTo = mn
end

-- Lay out in a grid, but it calculates gx and gy for you.
-- In other words this is a PileLayout that wraps after a fixed number of entities instead of screen edge.
-- Entries with gx/gy already will be skipped when calculating
-- If first entry starts with a gx, gy all other items will be centered around it
-- spec:
--     face: which direction are you facing
--     xreverse: grow left rather than right
--     yreverse: grow up rather than down
--     gmax: width or height (depending on face)
-- members [auto inits during layout()]:
--     gmanagedto: Index of last grid-managed item
--     gmanaged: Number of grid-managed items 
ui2.GridPileLayout = classNamed("GridPileLayout", ui2.GridLayout)

function ui2.GridPileLayout:layout(relayout)
	if not self.gmax then error("GridPileLayout without gmax") end
	if relayout then
		self.gmanagedto = nil
		self.gmanaged = nil
		self.root = nil
	end
	self.gmanaged = self.gmanaged or 0
	self.gmanagedto = self.gmanaged or 0
	self.face = self.face or "x"

	local mn = #self.managed -- Number of managed items
	local xface = self.face == "x"
	local moveright, moveup = ui2.anchorBools(self.anchor)
	local major = xface and vec2.unit_x or vec2.unit_y
	local minor = xface and vec2.unit_y or vec2.unit_x
	if self.xreverse then
		major = major:flip_x()  minor = minor*flip_x()
	end
	if not self.yreverse then -- Axis is y-, so we invert if you *aren't* inverting
		major = major:flip_y()  minor = minor:flip_y()
	end

	for i=(self.gmanaged+1),mn do
		local e = self.managed[i] -- Entity to place
		if i==1 or not self.root then -- Use first item as root
			if e.gx and e.gy then
				self.root = self.root or vec2(e.gx, e.gy) -- Weird shuffling to support root in spec, I guess
			else
				self.root = vec2.zero
				e.gx = self.root.x  e.gy = self.root.y
			end
			self.gmanaged = 1
		else
			if not (e.gx and e.gy) then
				local gidx = self.gmanaged -- Effectively self.gmanaged - 1
				local majoridx = gidx % self.gmax
				local minoridx = math.floor(gidx / self.gmax)
				local at = self.root + major*majoridx + minor*minoridx
				e.gx = at.x
				e.gy = at.y
				self.gmanaged = self.gmanaged + 1
			end
		end
	end
	self.gmanagedto = mn

	ui2.GridLayout.layout(self, relayout)
end

-- Mouse support
local RouteMouseEnt = classNamed("RouteMouseEnt", Ent)
local routeMouseEnt

function RouteMouseEnt.mouseCoordinatesConvert(x,y)
	return x * flat.width  / flat.pixwidth  - flat.width/2,   -- Convert pixel x,y to our coordinate system
       - ( y * flat.height / flat.pixheight - flat.height/2 ) -- GLFW has flipped y-coord
end

function RouteMouseEnt.mouseCoordinatesConvertVector(x,y)
	return x * flat.width  / flat.pixwidth,   -- Convert relative pixel x,y to our coordinate system
       - ( y * flat.height / flat.pixheight ) -- GLFW has flipped y-coord
end

function RouteMouseEnt:onLoad()
	local function route(key, x, y, ...)
		local inx, iny = RouteMouseEnt.mouseCoordinatesConvert(x,y)
		ent.root:route(key, vec2(inx, iny), ...) -- FIXME: Better routing?
	end

	lovr.handlers['mousepressed'] = function(x,y)
		route("onPress", x, y)
	end

	lovr.handlers['mousereleased'] = function(x,y)
		route("onRelease", x, y)
	end

	lovr.handlers['wheelmoved'] = function(wx, wy, x, y)
		route("onWheel", x, y, wx, wy) -- Notice argument order differs between lovr and lovr-ent
	end
end

function ui2.routeMouse()
	if not routeMouseEnt then
		if not lovr.mouse then lovr.mouse = require 'lib.lovr-mouse' end
		routeMouseEnt = RouteMouseEnt()
		routeMouseEnt:insert(ent.root) -- FIXME: Better routing?
	end
end

function ui2.trackPress(callback, initial, ...)
	if not mouse then return end
	if callback then
		mouse.trackPress(function(x,y,dx,dy)
			local inx, iny = RouteMouseEnt.mouseCoordinatesConvert(x,y)
			local indx, indy = RouteMouseEnt.mouseCoordinatesConvertVector(dx,dy)
			callback(vec2(inx,iny), vec2(indx,indy))
		end)
		if initial then
			callback(initial, ...)
		end
	else
		mouse.trackPress()
	end
end

local RouteKeyboardEnt = classNamed("RouteKeyboardEnt", Ent)
local routeKeyboardEnt

function RouteKeyboardEnt:onLoad()
	lovr.keyboard.suppressChar = false

	lovr.handlers['keypressed'] = function(key)
		ent.root:route("onKeyPress", key)
	end

	lovr.handlers['keyreleased'] = function(key)
		ent.root:route("onKeyRelease", key)
	end

	lovr.handlers['keychar'] = function(codepoint)
		ent.root:route("onKeyChar", codepoint)
	end
end

function ui2.routeKeyboard()
	if not routeKeyboardEnt then
		if not lovr.keyboard then lovr.keyboard = require 'lib.lovr-keyboard' end
		routeKeyboardEnt = RouteKeyboardEnt()
		routeKeyboardEnt:insert(ent.root) -- FIXME: Does this even need to be an ent?
	end
end

-- Ent that is allowed to replace itself with another ent
-- spec:
--     maySwapNothing: Do not throw an error if swap() is called with nil
ui2.SwapEnt = classNamed("SwapEnt", Ent)

function ui2.SwapEnt:swap(ent)
	local parent = self.parent
	if not (ent or self.maySwapNothing) then
		error("Tried to swap an ent with nothing")
	end
	if not (parent.kidRequestedSwap and parent:kidRequestedSwap(self, ent)) then -- Allow for magic handling in SplitScreenEnt. Returns true here if swap eaten
		self:die()
		if ent then queueBirth(ent, parent) end
	end
end


ui2.ScreenEnt = classNamed("ScreenEnt", ui2.SwapEnt)

function ui2.ScreenEnt:onLoad()
	ui2.routeMouse()
end

function ui2.ScreenEnt:onMirror() -- Screen might not draw anything but it needs to set up mode
	uiMode()
end

-- Buttons or layout items
-- spec:
--     swap: set by layout, sometimes unused, swap target if needed
--     bound: draw area
-- members:
--     down: is currently depressed (if a button)
-- must-implement methods:
--     sizeHint(margin) - return recommended size [note: might get called before onLoad]

ui2.UiBaseEnt = classNamed("UiBaseEnt", Ent)

function ui2.UiBaseEnt:layoutPass(pass) pull(self, pass) end

function ui2.UiBaseEnt:trackPress(...) ui2.trackPress(...) end -- May be overridden, for example by ui3

-- Items with text or an icon
-- spec:
--     label (At least one of label, icon or iconFrame required): text label
--     icon: display material to left of label
--     iconTexture: will generate icon from this if no icon 
--     iconPath: will generate icon from this if no icon
--     iconFrame (optional, defaults to fontheight square): Space to allocate for icon
--     iconSize (optional, defaults to iconFrame): Size to draw icon at within its frame
--     iconAspect (optional): number, if present calculate iconSize using this (w/h) aspect ratio
--     iconTexBound (optional, defaults to 0,0,1,1): Texels to draw within icon

ui2.UiEnt = classNamed("UiEnt", ui2.UiBaseEnt)

ui2.UiEnt.iconFrameDefault = vec2(fontHeight()+(margin-iconMargin)*2)
ui2.UiEnt.iconTextBoundDefault = bound2(vec2.zero, vec2(1,1))

-- Returns the icon and if needed inits the many icon related variables
function ui2.UiEnt:getIcon()
	if not self.iconInit then
		if self.iconPath then
			self.iconTexture = lovr.graphics.newTexture(self.iconPath)
			self.iconPath = nil
			self._ownTexture = true
		end
		if self.iconTexture then
			if not self.icon then
				self.icon = lovr.graphics.newMaterial(self.iconTexture)
				self._ownMaterial = true
			end
			if self._ownTexture then
				self.iconTexture:release()
				self._ownTexture = false
			end
			self.iconTexture = nil
		end
		if self.icon then
			if not self.iconFrame then self.iconFrame = ui2.UiEnt.iconFrameDefault end
			if not self.iconSize then
				if self.iconAspect then
					if self.iconAspect < 1 then
						self.iconSize = self.iconFrame*vec2(self.iconAspect, 1)
					else
						self.iconSize = self.iconFrame*vec2(1, 1/self.iconAspect)
					end
				else
					self.iconSize = self.iconFrame
				end
			end
			if not self.iconTexBound then self.iconTexBound = ui2.UiEnt.iconTextBoundDefault end
		end
		self.iconInit = true
	end
	return self.icon
end

function ui2.UiEnt:onBury()
	if self._ownMaterial then
		self.icon:release()
		self._ownMaterial = false
		self.icon = nil
	end
end

function ui2.UiEnt:sizeHint(margin, overrideText)
	local label = overrideText or self.label
	local icon = self:getIcon()
	if not label and not icon then
		error("Button without label or icon") -- TODO: This may be too restrictive
	end

	-- At base assume left and right margins
	local w,h = 0,0
	-- Add size contribution from label
	if label then
		local fw = flat.font:getWidth(label)*flat.fontscale -- Text width
		w = fw + margin -- Button width + right margin
		local fh = fontHeight() -- Raw height of font
		h = fh + margin*2 -- Text height plus top and bottom margins
		if not icon then
			w = w + margin
		end
	end
	-- Add size contribution from icon
	if icon then
		w = w + self.iconFrame.x + iconMargin*2
		h = math.max(h, self.iconFrame.y + iconMargin*2)
	end
	return vec2(w, h)
end

function ui2.UiEnt:onMirror()
	local center = self.bound:center()
	local size = self.bound:size()

	lovr.graphics.setColor(1,1,1,1)

	local icon = self:getIcon()
	if icon then
		local iconCenter = center
		if icon and self.label then
			-- FIXME: Code duplication? Support other fonts?
			local fontWidth = flat.font:getWidth(self.label)*flat.fontscale
			local offset = margin-iconMargin -- Because left and right margins aren't equal
			iconCenter = iconCenter - vec2((fontWidth + iconMargin + offset)/2, 0)
			center = center + vec2((self.iconFrame.x + iconMargin)/2, 0) -- FIXME: Could put - offset? I just eyeballed this
		end
		local iconTexSize = self.iconTexBound:size()
		lovr.graphics.plane(self.icon, iconCenter.x, iconCenter.y, 0, self.iconSize.x, self.iconSize.y, self.iconRotate or 0,0,0,1, self.iconTexBound.min.x,self.iconTexBound.min.y,iconTexSize.x,iconTexSize.y )
	end

	if self.label then
		if self.labelColor then
			lovr.graphics.setColor(unpack(self.labelColor))
		end
		lovr.graphics.setFont(flat.font)
		lovr.graphics.print(self.label, center.x, center.y, 0, flat.fontscale)
	end
end

-- members:
--     down: depressed when true
--     disabled: turn into a label when true
ui2.ButtonEnt = classNamed("ButtonEnt", ui2.UiEnt) -- Expects in spec: bounds=, label=

function ui2.ButtonEnt:onPress(at)
	if self.bound:contains(at) and not self.disabled then
		self.down = true

		ui2.trackPress(function(at) -- Cancel-depress by drag away
			self.down = self.bound:contains(at)
		end)
		return route_poison
	end
end

function ui2.ButtonEnt:onRelease(at)
	if self.down and self.bound:contains(at) then
		self:onButton(at) -- FIXME: Is it weird this is an "on" but it does not route?
	end
	self.down = false
end

function ui2.ButtonEnt:onHoverSearch(at)
	if self.bound:contains(at) and not self.disabled then
		return self
	end
end

function ui2.ButtonEnt:onButton()
end

function ui2.ButtonEnt:onMirror()
	if not self.disabled then
		local center = self.bound:center()
		local size = self.bound:size()
		local gray = self.down and 0.25 or 0.5
		lovr.graphics.setColor(gray,gray,gray,0.9)
		lovr.graphics.plane('fill', center.x, center.y, 0, size.x, size.y)
	end

	ui2.UiEnt.onMirror(self)
end

function ui2.maybeButton(cond, spec)
	if cond then
		return ui2.ButtonEnt(spec)
	else
		return ui2.UiEnt(spec)
	end
end

ui2.ToggleEnt = classNamed("ToggleEnt", ui2.ButtonEnt) -- ButtonEnt but stick down instead of hold

function ui2.ToggleEnt:onToggle(_) end

function ui2.ToggleEnt:onPress(at)
	if self.bound:contains(at) and not self.disabled then
		self.down = not self.down

		self:onToggle(self.down)

		ui2.trackPress() -- Don't let anything else process this click
		return route_poison
	end
end

function ui2.ToggleEnt:onRelease(at)
end

-- Draggable slider
-- spec:
--     lineWidth: recommended line width float (default 0.3)
--     handleWidth: recommended handle width+height
--     wholeWidth: recommended size of entire line
--     minRange, maxRange: span of underlying value range (default 0,1)
-- members:
--	   value: value minRange-maxRange (so 0-1 by default)
--     disabled: if true hide handle

ui2.SliderEnt = classNamed("SliderEnt", ui2.UiBaseEnt)

function ui2.SliderEnt:_init(spec) -- Note by allowing wholeWidth I made my life really hard
	self:super(tableMerge({value=0, minRange=0, maxRange=1}, spec))
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
	local zoff = 1/2048
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
		self:trackPress(function(at)
			if self.bound:contains(at) then
				local halfline = self.lineWidth/2
				self.value = utils.clamp(
					(at.x - (self.bound.min.x + self.handleWidth/2))/self.lineWidth,
					0,1
				) * (self.maxRange-self.minRange) + self.minRange
				if self.onChange then self:onChange(self.value) end -- See also: self:onButton "is it weird"?
			end
		end, at)

		return route_poison
	end
end

function ui2.SliderEnt:onHoverSearch(at)
	if self.bound:contains(at) and not self.disabled then
		return self
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
--     layout: a Layout object
-- members:
--     lastCenter: tracks center over time so if the ent moves the offset is known
--     layoutCenter: tracks center at last sizeHint

ui2.LayoutEnt = classNamed("LayoutEnt", ui2.UiBaseEnt)

function ui2.LayoutEnt:_init(spec)
	pull(self, {lastCenter = vec2.zero})
	self:super(spec)
	self.layout = self.layout or
		ui2.PileLayout{anchor=self.anchor, face=self.face, managed=self.managed, itemMargin=self.itemMargin, parent=self}
		self.anchor = nil self.face = nil self.managed = nil
end

function ui2.LayoutEnt:sizeHint(margin, overrideText)
	self.layout:layout()
	local bound
	for i,v in ipairs(self.layout.managed) do
		bound = bound and bound:extend_bound(v.bound) or v.bound
	end
	if not bound then error(string.format("LayoutEnt (%s) with no members", self)) end
	self.layoutCenter = bound:center()
	return bound:size()
end

function ui2.LayoutEnt:onLayout()
	local center = self.bound:center()
	local offset = center - self.lastCenter - self.layoutCenter
	
	self:onLayoutMove(offset, center)
end

function ui2.LayoutEnt:onLayoutMove(offset, center) -- pseudo-event-- center is NOT sent when calling children
	for i,v in ipairs(self.layout.managed) do
		v.bound = v.bound:offset(offset)
		if v.onLayoutMove then v:onLayoutMove(offset) end -- In case a LayoutEnt is ent-managing another LayoutEnt
	end

	self.lastCenter = center or self.bound:center()
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

-- A group of buttons that act like radio buttons
-- spec:
--     labels: array of strings for labels
--     count [optional-- must set one of count or labels]: number of labels
--     selected [default 1]: starting selection id
--     tags [optional]: if present selected/
-- members:
--     selected: current selection tag
-- methods:
--     onSelect(tag): method to call when selection is made
--     onSelects: table of onSelect(self, tag) methods, keyed by id
ui2.SelectEnt = classNamed("SelectEnt", ui2.LayoutEnt)

ui2.SelectEnt.noSelection = {} -- Magic value (actually not magic, just unique)

function ui2.SelectEnt:_init(spec)
	self:super(spec)
	self.count = self.count or #self.labels

	local hadSelects = toboolean(self.onSelects)
	if not self.selected then
		self.selected = self.tags and self.tags[1] or 1
	end
	local managed
	managed = spec.managed or mapRange(self.count, function(i)
		local tag = self.tags and self.tags[i] or i
		local label = self.labels and self.labels[i] or i
		local onSelect = self.onSelects and self.onSelects[i]

		return ui2.ButtonEnt{label=label, onRelease=function() end, onPress=function(e, at)
			if (e.bound:contains(at)) then -- TODO: Maybe make this a SelectEnt
				if hadSelects then -- FIXME why this special case?
					if onSelect then onSelect(self, tag) end
				end
				if self.onSelect then self:onSelect(tag) end
				for i,v in ipairs(managed) do v.down = false end
				e.down = true
				self.selected = tag -- Do this last so select methods can do "if changed"

				ui2.trackPress() -- Don't let anything else process this click
				return route_poison
			end
		end, down=self.selected==tag}
	end)
	self.layout.managed = managed
	self.labels = nil self.onSelects = nil self.tags = nil
end

-- Same programming interface as SelectEnt but 1 at a time

ui2.ScrollSelectEnt = classNamed("ScrollSelectEnt", ui2.LayoutEnt)

function ui2.ScrollSelectEnt:_init(spec) -- FIXME some copypaste here
	self:super(spec)
	self.count = self.count or (self.labels and #self.labels) or (self.tags and #self.tags)

	if not self.count then error("Must specify count, labels or tags") end
	if not self.labels and self.tags then self.labels = tablex.map(tostring, self.tags) end

	local hadSelects = toboolean(self.onSelects)
	if self.selected and not self.selectedIdx then
		for i=1,self.count do -- FIXME consider an iterator
			local tag = self.tags and self.tags[i] or i
			if self.selected == tag then
				self.selectedIdx = i
				break
			end
		end
	end
	if not self.selectedIdx then
		self.selectedIdx = 1
	end
	if not self.selected then
		self.selected = self.tags and self.tags[self.selectedIdx] or self.selectedIdx
	end
	local managed = spec.managed
	if not managed then
		local longestLabel
		local longestLabelWidth = 0
		for i=1,self.count do
			local label = self.labels and self.labels[i] or i
			local width = flat.font:getWidth(label)
			if width>longestLabelWidth then
				longestLabel = label
				longestLabelWidth = width
			end
		end
		local LabelEnt = ui2.UiEnt{label=self.labels and self.labels[self.selectedIdx] or self.selectedIdx,
			sizeHint = function(_self, margin, overrideText)
				if not overrideText then
					overrideText = longestLabel
				end
				return ui2.UiEnt.sizeHint(_self, margin, overrideText)
			end
		}
		local function makeButton(label, dir)
			return ui2.ButtonEnt{label=label, onButton = function(_self)
				self.selectedIdx = self.selectedIdx + dir
				if self.selectedIdx > self.count then self.selectedIdx = 1
				elseif self.selectedIdx < 1 then self.selectedIdx = self.count end

				local tag = self.tags and self.tags[self.selectedIdx] or self.selectedIdx
				local label = self.labels and self.labels[self.selectedIdx] or self.selectedIdx
				local onSelect = self.onSelects and self.onSelects[self.selectedIdx]
				if hadSelects then
					if onSelect then onSelect(self, tag) end
				end
				if self.onSelect then self:onSelect(tag) end

				self.selected = tag
				LabelEnt.label = label
			end}
		end
		managed = {makeButton("<", -1), LabelEnt, makeButton(">", 1)}
	end
	self.layout.managed = managed
end


return ui2
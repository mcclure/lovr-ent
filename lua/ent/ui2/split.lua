-- Class for keeping several screens live at once and switching between them quickly, without support from the screen itself

namespace "standard"

local ui2 = require "ent.ui2"

local split = {}

split.SplitScreenEnt = classNamed("SplitScreenEnt", ui2.ScreenEnt)

function split.SplitScreenEnt:onLoad()
	local left = ui2.ButtonEnt{label="<", onButton = function(_self) -- Die
		self:turnPage(-1)
	end}
	local right = ui2.ButtonEnt{label=">", onButton = function(_self) -- Die
		self:turnPage(1)
	end}

	self.favoredKids = {left, right}
	if not self.pages then self.pages = {} end
	if not self.pageAt then self.pageAt = 1 end
	self.page = self.pages[self.pageAt]

	if not self.dontInsert then for i,v in ipairs(self.pages) do
		v:insert(self)
	end end

	do -- Left
		local layout = ui2.PileLayout{managed={left}, parent=self, anchor="lm"}
		layout:layout()
	end
	do -- Right
		local layout = ui2.PileLayout{managed={right}, parent=self, anchor="rm"}
		layout:layout()
	end
end

function split.SplitScreenEnt:turnPage(dir)
	local pagesn = #self.pages
	if self.pagesn == 0 then return end
	self.pageAt = (self.pageAt + dir - 1)%pagesn + 1
	self.page = self.pages[self.pageAt]
end

function split.SplitScreenEnt:kidRequestedSwap(from, to)
	local swapAt
	for i,v in ipairs(self.pages) do
		if v == from then swapAt = i break end
	end
	if swapAt then
		queueDoom(function() -- Delay so that events aren't routed to unborn kid. Could break if swap called multiple times in one frame?
			self.pages[swapAt] = to
			if self.page == from then self.page = to end
		end)
	end
end -- Let old page be destroyed

-- FIXME: Screen out pages rather than screening in control buttons?
local function implementWrap(key)
	split.SplitScreenEnt[key] = function(self, ...)
		local result
		if self.page then
			result = self.page:route(key, ...)
		end
		for i,v in ipairs(self.favoredKids) do
			if result == route_poison then break end
			v:route(key, ...)
		end
		return result == route_poison and route_poison or route_terminate
	end
end

implementWrap("onMirror")
implementWrap("onPress")
implementWrap("onRelease")
implementWrap("onWheel")

return split

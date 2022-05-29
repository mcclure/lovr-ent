-- Test all anchor points for the grid layout, plus unusual configurations

namespace "standard"

local ui2 = require "ent.ui2"
local flat = require "engine.flat"

local TestGridUi = classNamed("TestGridUi", ui2.ScreenEnt)

local GrowButton = classNamed("GrowButton", ui2.ButtonEnt)

-- Every button adds a button to the layout
function GrowButton:onButton()
	queueDoom(function()
		self.layout:add( GrowButton{label=self.idSource:nextId(), gx=self.gx+self.dir.x, gy=self.gy+self.dir.y, dir=self.dir} )
		self.layout:layout()
	end)
end

function TestGridUi:nextId()
	self.lastId = (self.lastId or 0) + 1
	return tostring(self.lastId)
end

function TestGridUi:onLoad()
	ui2.routeMouse()
	-- Create some buttons that do different things
	-- Remember: Grids always lay out from the top left, which means x-negative, y=positive.
	do -- tl
		local ents = {
			GrowButton{label=self:nextId(), gx=3, gy=4, dir=vec2(0,-1)},
			GrowButton{label=self:nextId(), gx=3, gy=5, dir=vec2(1,0)},
			GrowButton{label=self:nextId(), gx=4, gy=4, dir=vec2(0,-1)},
			GrowButton{label=self:nextId(), gx=4, gy=5, dir=vec2(1,0)},
		}
		local layout = ui2.GridLayout{managed=ents, parent=self, anchor="tl"}
		layout.pass = {layout=layout, idSource=self}
		layout:layout()
	end
	do -- tr
		local ents = {
			GrowButton{label=self:nextId(), gx=1, gy=10, dir=vec2(0,-1)},
			GrowButton{label=self:nextId(), gx=2, gy=10, dir=vec2(0,-1)},
			GrowButton{label=self:nextId(), gx=3, gy=10, dir=vec2(0,-1)},
		}
		local layout = ui2.GridLayout{managed=ents, parent=self, anchor="tr"}
		layout.pass = {layout=layout, idSource=self}
		layout:layout()
	end
	do -- bl
		local ents = {
			GrowButton{label=self:nextId(), gx=1, gy=-3, dir=vec2(0,1)},
			GrowButton{label=self:nextId(), gx=2, gy=-3, dir=vec2(1,0)},
			GrowButton{label=self:nextId(), gx=2, gy=-4, dir=vec2(1,0)},
			GrowButton{label=self:nextId(), gx=1, gy=-5, dir=vec2(0,1)},
			GrowButton{label=self:nextId(), gx=2, gy=-5, dir=vec2(1,0)},
		}
		local layout = ui2.GridLayout{managed=ents, parent=self, anchor="bl"}
		layout.pass = {layout=layout, idSource=self}
		layout:layout()
	end
	do -- br
		local ents = {
			GrowButton{label=self:nextId(), gx=-1, gy=1, dir=vec2(0,1)},
			GrowButton{label=self:nextId(), gx=-2, gy=2, dir=vec2(-1,0)},
			GrowButton{label=self:nextId(), gx=-3, gy=3, dir=vec2(-1,1)},
		}
		local layout = ui2.GridLayout{managed=ents, parent=self, anchor="br"}
		layout.pass = {layout=layout, idSource=self}
		layout:layout()
	end
	do -- cm
		local ents = {
			GrowButton{label=self:nextId(), gx=0, gy=0, dir=vec2(0,3)},
			GrowButton{label=self:nextId(), gx=0, gy=1, dir=vec2(0,1)},
			GrowButton{label=self:nextId(), gx=0, gy=-1, dir=vec2(0,-1)},
			GrowButton{label=self:nextId(), gx=-1, gy=0, dir=vec2(-1,0)},
			GrowButton{label=self:nextId(), gx=1, gy=0, dir=vec2(1,0)},
			--GrowButton{label=self:nextId(), gx=-1, gy=1, dir=vec2(-1,-1)},
		}
		local layout = ui2.GridLayout{managed=ents, parent=self, anchor="cm"}
		layout.pass = {layout=layout, idSource=self}
		layout:layout()
	end
	do -- ct + GridPile
		local ents = {}
		for _=1,4 do
			table.insert(ents, GrowButton{label=self:nextId(), dir=vec2(0,-2)})
		end
		local layout = ui2.GridPileLayout{managed=ents, parent=self, anchor="ct", gmax=3}
		layout.pass = {layout=layout, idSource=self}
		layout:layout()
	end
end

function TestGridUi:onMirror()
	ui2.ScreenEnt.onMirror(self)
	lovr.graphics.line(-flat.xspan,0,0, flat.xspan,0,0)
	lovr.graphics.line(0,-flat.yspan,0, 0,flat.yspan,0)
end

return TestGridUi

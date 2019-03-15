-- Establish that all the basic features of ui2 work

namespace "standard"

local flat = require "engine.flat"
local ui2 = require "ent.ui2"

local TestUi = classNamed("TestUi", ui2.ScreenEnt)

local margin = .05

function TestUi:onLoad()
	ui2.routeMouse()
	local ents = {
		ui2.ButtonEnt{label="X", onButton = function(self) -- Test die
			self.swap:die()
		end},
		ui2.UiEnt{label="testUi"},
		ui2.ButtonEnt{label="one", onButton = function(self)
				print("ONE!")
		end},
		ui2.ButtonEnt{label="two", onButton = function(self)
				print("TWO!")
		end},
		ui2.ButtonEnt{label="three four five", onButton = function(self)
				print("THREE FOUR FIVE!")
		end},
		ui2.ButtonEnt{label="RESET", onButton = function(self) -- Test swap
			self.swap:swap( TestUi() )
		end},
		ui2.ButtonEnt{label=1, onButton = function(self) -- Give this ui some state
				self.label = self.label + 1
		end},
	}

	local layout = ui2.PileLayout{managed=ents, parent=self, pass={swap=self}}
	layout:layout()
end

return TestUi

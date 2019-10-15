-- Establish that all the basic features of ui2 work

namespace "standard"

local ui2 = require "ent.ui2"

local TestUi = classNamed("TestUi", ui2.ScreenEnt)

function TestUi:onLoad()
	ui2.routeMouse()
	-- Create some buttons that do different things
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
	-- Dynamically create some buttons that do nothing, just to fill up space and demonstrate line wrapping
	for i,v in ipairs{"buttonx", "nonsense", "garb", "garbage", "not", "hing", "nothing", "no", "thing"} do
		table.insert(ents, ui2.ButtonEnt{label=v})
	end
	-- Create a slider and a value watcher for that slider
	local slider = ui2.SliderEnt()
	table.insert(ents, slider)
	table.insert(ents, ui2.SliderWatcherEnt{watch=slider})

	-- Lay all the buttons out
	local layout = ui2.PileLayout{managed=ents, parent=self, pass={swap=self}}
	layout:layout()
end

return TestUi

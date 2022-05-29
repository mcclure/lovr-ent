-- Establish that all the unique features of ui3 work
-- Accepted arguments: --force2d, --force3d
namespace "standard"

local ui2 = require "ent.ui2"
local ui3 = require "ent.ui3"
local split3 = require "ent.ui3.split"
local Floor = require "ent.debug.floor"
local shader = require "shader.shader"

-- To show ui3 can show multiple screens at once, we will build two copies of this screen
-- The screen is trivial and displays a UI for the appearance of a rectangular prism
local TestSubscreen = classNamed("TestUi3", ui2.ScreenEnt)

function TestSubscreen:onLoad()
	self.color = mapRange(3, function() return lovr.math.random() end) -- Initial random color
	self.height = 2

	local function changeColor(button)
		for i=1,3 do
			self.color[i] = utils.clamp(self.color[i] + button.color[i], 0, 1)
		end
	end

	local ents = {
		ui2.UiEnt{label=self.label},

		-- Height slider
		ui3.makeSliderTripletEnt({startLabel="Height", sliderSpec={minRange=0, maxRange=5, value=self.height},
			onChange=function(_self, value)
				self.height = value
			end,
		}, not self.surface3), -- Last argument is "use 2d"; self.surface3 is populated by ui3.makeLayout

		ui2.ButtonEnt{label="Darker",  onButton=changeColor, color={-0.5,-0.5,-0.5}},
		ui2.ButtonEnt{label="Redder",  onButton=changeColor, color={ 0.5,   0,   0}},
		ui2.ButtonEnt{label="Greener", onButton=changeColor, color={   0, 0.5,   0}},
		ui2.ButtonEnt{label="Bluer",   onButton=changeColor, color={   0,   0, 0.5}},
	}

	local layout = ui3.makeLayout(self.surface3, ui2.PileLayout, {managed=ents, parent=self, pass={swap=self}})
	layout:layout()
end

function TestSubscreen:onDraw()
	lovr.graphics.setShader(shader)
	lovr.graphics.setColor(unpack(self.color))
	lovr.graphics.box('fill', self.root.x, self.root.y + self.height/2, self.root.z, 0.75, self.height, 0.75)
end

-- App/container for the screens
local TestUi3 = classNamed("TestUi3", ui2.ScreenEnt)

function TestUi3:onLoad()
	ui2.ScreenEnt.onLoad(self)

	-- Something for the towers to stand out against 
	Floor():insert(self)

	-- Decide whether to follow 2d or 3d for this UI
	-- Usually you will just want to do:
	--     local use3d = lovr.headset.getDriver() ~= "desktop"
	local desktop = lovr.headset.getDriver() == "desktop"
	local force2d = self.arg and self.arg.force2d
	local force3d = self.arg and self.arg.force3d
	if force2d and force3d then error("Forced 2d and 3d at once?") end

	local use2d = (desktop and not force3d) or force2d

	-- Create subscreens but don't insert, makeSplitScreen does that for us
	local leftSubscreen  = TestSubscreen{label="Left tower",  root=vec3(-2, 0, -3), use3d=use2d}
	local rightSubscreen = TestSubscreen{label="Right tower", root=vec3( 2, 0, -3), use3d=use2d}

	local splitScreen = split3.makeSplitScreen({pages={leftSubscreen, rightSubscreen}}, use2d)
	splitScreen:insert(self)

	ui3.loadSurfaceAndHand(self, use2d)
end

return TestUi3

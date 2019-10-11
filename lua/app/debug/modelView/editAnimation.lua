-- View an animation

namespace "standard"

local flat = require "engine.flat"
local ui2 = require "ent.ui2"
local ModelDrawer = require "app.debug.modelView.modelDrawer"

local ModelEditAnimationUi = classNamed("ModelEditAnimationUi", ModelDrawer)

function ModelEditAnimationUi:onLoad()
	local function Home() return self.back[1](self.back[2]) end
	-- Horizontal
	local ents = {
		ui2.ButtonEnt{label="<", onButton = function(_self) -- Die
			self:swap( Home() )
		end},
		ui2.UiEnt{label=self.target}
	}

	local layout = ui2.PileLayout{managed=ents, parent=self}
	layout:layout()

	-- Vertical
	self.duration = self.model:getAnimationDuration(self.target)
	if self.duration <= 0 then self.duration = 0 end
	self.timeSlider = ui2.SliderTripletEnt{startLabel="Time", sliderSpec={minRange=0, maxRange=self.duration}}
	self.mixerSlider = ui2.SliderTripletEnt{startLabel="Mix", sliderSpec={value=1}}
	ents = {
		ui2.ButtonEnt{label="Play", onButton = function(_self)
			self.playing = not self.playing
			_self.label = self.playing and "Stop" or "Play"
		end},
		self.timeSlider,
		self.mixerSlider
	}

	local layout = ui2.PileLayout{managed=ents, parent=self, face="y", anchor="tr"}
	layout:layout()
end

function ModelEditAnimationUi:onUpdate()
	if self.dead then return end
	self.model:pose()
	local time = lovr.timer.getTime()
	if self.playing then self.timeSlider:setValue(time % self.duration) end
	self.model:animate(self.target, self.playing and time or self.timeSlider:getValue(), self.mixerSlider:getValue())
end

function ModelEditAnimationUi:onBury()
	self.model:pose()
end

return ModelEditAnimationUi
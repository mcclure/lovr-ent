-- Edit the properties of the standard shader

namespace "standard"

local flat = require "engine.flat"
local ui2 = require "ent.ui2"
local ModelDrawer = require "app.debug.modelView.modelDrawer"

local ModelEditShaderUi = classNamed("ModelEditShaderUi", ModelDrawer)

function ModelEditShaderUi:onLoad()
	local function Home() return self.back[1](self.back[2]) end

	-- Horizontal
	local ents = {
		ui2.ButtonEnt{label="<", onButton = function(_self) -- Die
			self:swap( Home() )
		end},
	}

	local layout = ui2.PileLayout{managed=ents, parent=self}
	layout:layout()

	-- Vertical
	local function makeTriplet(spec)
		local label, uniform, index = unpack(spec)
		local startValue
		if index then startValue = self.shaderProps[uniform][index] else startValue = self.shaderProps[uniform] end

		return ui2.SliderTripletEnt{startLabel=label, value=startValue,
			sliderSpec={minRange=spec.minRange, maxRange=spec.maxRange},
			onChange=function(_self, value)
			local send
			if index then
				send = self.shaderProps[uniform]
				send[index] = value
			else
				send = value
				self.shaderProps[uniform] = value
			end
			self.shader:send(uniform, send)
		end}
	end

	ents = {
		makeTriplet{"Light direction X", "lovrLightDirection", 1, minRange=-1},
		makeTriplet{"Light direction Y", "lovrLightDirection", 2, minRange=-1},
		makeTriplet{"Light direction Z", "lovrLightDirection", 3, minRange=-1},
		makeTriplet{"Light color R", "lovrLightColor", 1},
		makeTriplet{"Light color G", "lovrLightColor", 2},
		makeTriplet{"Light color B", "lovrLightColor", 3},
		makeTriplet{"Light intensity", "lovrLightColor", 4, maxRange=10},
		makeTriplet{"Exposure", "lovrExposure", maxRange=10},
	}

	local layout = ui2.PileLayout{managed=ents, parent=self, face="y", anchor="tr"}
	layout:layout()
end

return ModelEditShaderUi

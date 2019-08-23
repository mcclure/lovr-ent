-- Show 3D model

namespace "standard"

local flat = require "engine.flat"
local ui2 = require "ent.ui2"

local ModelViewUi = classNamed("ModelViewUi", ui2.ScreenEnt)

local _standardShader 
local function standardShader()
	if not _standardShader then
		_standardShader = lovr.graphics.newShader('standard', { flags = {
			emissive = true, tonemap = true
		} })
		_standardShader:send('lovrLightDirection', {-1,-1,-1})
		_standardShader:send('lovrLightColor', {1,1,1,2})
		_standardShader:send('lovrExposure', 1)
	end
	return _standardShader
end

local simpleShader = require "shader.shader"

function ModelViewUi:onLoad()
	local Home = require "app.debug.modelView"
	lovr.graphics.setBackgroundColor(0.1,0.1,0.1)

	ui2.routeMouse()
	local ents = {
		ui2.ButtonEnt{label="X", onButton = function(self) -- Die
			self.swap:swap( Home() )
		end},
		ui2.UiEnt{label=self.name},
		ui2.ButtonEnt{label="Reload", onButton = function(_self) -- Die
			self:modelLoad()
		end},
		ui2.UiEnt{label="Shader:"},
		ui2.ButtonEnt{label="Standard", onButton = function(_self) -- Die
			self.shader = standardShader()
		end},
		ui2.ButtonEnt{label="Simple", onButton = function(_self) -- Die
			self.shader = simpleShader
		end},
		ui2.ButtonEnt{label="Flat", onButton = function(_self) -- Die
			self.shader = nil
		end},
	}

	local layout = ui2.PileLayout{managed=ents, parent=self, pass={swap=self}}
	layout:layout()

	self.shader = standardShader()
	self:modelLoad()
end

function ModelViewUi:modelLoad()
	-- TODO: Would be good to force unload the model here and on onBury
	model = lovr.graphics.newModel(self.path)
end

function ModelViewUi:onDraw()
  lovr.graphics.setShader(self.shader)
  lovr.graphics.setColor(1,1,1)
  model:draw(0, 1.7, -3, 1, lovr.timer.getTime() * .25)
end

return ModelViewUi

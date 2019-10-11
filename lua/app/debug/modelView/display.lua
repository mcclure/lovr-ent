-- Show 3D model

namespace "standard"

local flat = require "engine.flat"
local ui2 = require "ent.ui2"
local ModelDrawer = require "app.debug.modelView.modelDrawer"

local ModelViewUi = classNamed("ModelViewUi", ModelDrawer)

local _standardShader 

local simpleShader = require "shader.shader"

local function drawLabel(x) return string.format("%s draw calls", x) end
local function shaderLabel(x) return string.format("%s shader switches", x) end

function ModelViewUi:standardShader()
	if not _standardShader then
		_standardShader = lovr.graphics.newShader('standard', { flags = {
			emissive = true, tonemap = true, animated=true
		} })
		for k,v in pairs(self.shaderProps) do
			_standardShader:send(k, v)
		end
	end
	return _standardShader -- Notice: Global
end

function ModelViewUi:onLoad()
	local Home = require "app.debug.modelView"
	local function back() return {ModelViewUi, tableSkim(self, {"model", "shader", "name", "shaderProps"})} end
	lovr.graphics.setBackgroundColor(0.1,0.1,0.1)
	print("Model", self.name)

	self.shaderProps = {
		lovrLightDirection = {-1,-1,-1},
		lovrLightColor = {1,1,1,2},
		lovrExposure = 1,
	}

	ui2.routeMouse()
	local ents = {
		ui2.ButtonEnt{label="X", onButton = function(_self) -- Die
			self:swap( Home() )
		end},
		ui2.UiEnt{label=self.name},
		ui2.ButtonEnt{label="Reload", onButton = function(_self)
			self:modelLoad(true)
		end},
		ui2.ButtonEnt{label="Edit...", onButton = function(_self)
			local EditSelect = require "app.debug.modelView.editSelect"
			self:swap( EditSelect{model=self.model, shader=self.shader, back=back()} )
		end},
		ui2.UiEnt{label="Shader:"},
		ui2.ButtonEnt{label="Standard...", onButton = function(_self)
			self.shader = self:standardShader()
			local EditShader = require "app.debug.modelView.editShader"
			self:swap( EditShader{model=self.model, shader=self.shader, shaderProps=self.shaderProps, back=back()} )
		end},
		ui2.ButtonEnt{label="Simple", onButton = function(_self)
			self.shader = simpleShader
		end},
		ui2.ButtonEnt{label="Flat", onButton = function(_self)
			self.shader = nil
		end},
	}

	local layout = ui2.PileLayout{managed=ents, parent=self}
	layout:layout()

	-- Vertical
	self.drawEnt = ui2.UiEnt{label=drawLabel("XXX")}
	self.shaderEnt = ui2.UiEnt{label=shaderLabel("XXX")}
	ents = {
		self.drawEnt,
		self.shaderEnt
	}

	local layout = ui2.PileLayout{managed=ents, parent=self, face="y", anchor="tl"}
	layout:layout()

	self.shader = self:standardShader()
	self:modelLoad()
end

function ModelViewUi:modelLoad(force)
	if force then self.model = nil end
	-- TODO: Would be good to force unload the model here and on onBury
	self.model = self.model or lovr.graphics.newModel(self.path)
end

local statKeys = {"drawcalls", "shaderswitches"}

-- On this screen draw with a flush() wrapper to show stats
function ModelViewUi:onDraw() -- KLUDGE: Labels will be one frame off if onMirror() is ever called before onDraw()
	lovr.graphics.flush()
	local drawcalls1, shaderswitches1 = tableSkimUnpack(lovr.graphics.getStats(), statKeys)
	ModelDrawer.onDraw(self) -- Actual draw implementation
	lovr.graphics.flush()
	local drawcalls2, shaderswitches2 = tableSkimUnpack(lovr.graphics.getStats(), statKeys)
	self.drawEnt.label=drawLabel(drawcalls2-drawcalls1)
	self.shaderEnt.label=shaderLabel(shaderswitches2-shaderswitches1)
end

return ModelViewUi

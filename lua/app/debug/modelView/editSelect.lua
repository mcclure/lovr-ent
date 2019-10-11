-- Select a material, node or animation to edit

namespace "standard"

local flat = require "engine.flat"
local ui2 = require "ent.ui2"
local ModelDrawer = require "app.debug.modelView.modelDrawer"

local ModelEditSelectItemUi = classNamed("ModelEditSelectItemUi", ModelDrawer)

function ModelEditSelectItemUi:onLoad()
	local function Home() return self.back[1](self.back[2]) end
	local function Back() return {ModelEditSelectItemUi, tableSkim(self, {"model", "shader", "back", "select"})} end
	local name, count, getName, nextUi = unpack(self.select)

	local ents = {
		ui2.ButtonEnt{label="<", onButton = function(_self) -- Die
			self:swap( Home() )
		end},
		ui2.UiEnt{label=name .. ":"},
	}

	print(name .. ":")
	for i=1,self.model[count](self.model) do
		local name = self.model[getName](self.model, i)
		print(i, name)
		table.insert(ents, ui2.ButtonEnt{label=name or string.format("[%d]", i), onButton = function(_self)
			self:swap(
				nextUi(){shader=self.shader, model=self.model, back=Back(), target=name or i}
			)
		end})
	end

	local layout = ui2.PileLayout{managed=ents, parent=self}
	layout:layout()
end

local ModelEditSelectKindUi = classNamed("ModelEditSelectKindUi", ModelDrawer)

function ModelEditSelectKindUi:onLoad()
	local function Home() return self.back[1](self.back[2]) end
	local function Back() return {ModelEditSelectKindUi, tableSkim(self, {"model", "shader", "back"})} end

	local ents = {
		ui2.ButtonEnt{label="<", onButton = function(_self) -- Die
			self:swap( Home() )
		end},
		ui2.UiEnt{label="Edit:"}
	}

	local selects = {
		{"Animations", "getAnimationCount", "getAnimationName", function() return require "app.debug.modelView.editAnimation" end},
		{"Nodes",      "getNodeCount",      "getNodeName",      function() return require "app.debug.modelView.editNode" end},
		{"Materials",  "getMaterialCount",  "getMaterialName",  function() return require "app.debug.modelView.editMaterial" end},
	}

	for i, v in ipairs(selects) do
		table.insert(ents, ui2.ButtonEnt{label=v[1], onButton = function(_self)
			self:swap(
				ModelEditSelectItemUi{shader=self.shader, model=self.model, back=Back(), select=v}
			)
		end})
	end

	local layout = ui2.PileLayout{managed=ents, parent=self}
	layout:layout()
end

return ModelEditSelectKindUi
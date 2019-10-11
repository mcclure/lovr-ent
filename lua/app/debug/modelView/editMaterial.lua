-- Edit properties of a material

namespace "standard"

local flat = require "engine.flat"
local ui2 = require "ent.ui2"
local ModelDrawer = require "app.debug.modelView.modelDrawer"

local ModelEditMaterialUi = classNamed("ModelEditMaterialUi", ModelDrawer)

function ModelEditMaterialUi:onLoad()
	local function Home() return self.back[1](self.back[2]) end

	local function makeTriplet(spec)
		local label, field, startValue, propIndex, index = unpack(spec)
		local props = self.allMaterials[self.target]
		local material = props[1]
		if index then startValue = startValue[index] end

		return ui2.SliderTripletEnt{startLabel=label, value=startValue,
			sliderSpec={minRange=spec.minRange, maxRange=spec.maxRange},
			onChange=function(_self, value)
			if propIndex and index then
				local send = props[propIndex]
				send[index] = value
				material:setColor(field, send)
			else
				material:setScalar(field, value)
			end
		end}
	end

	local vents = {}

	self.allMaterials = {}
	for i=1,self.model:getMaterialCount() do
		local name = self.model:getMaterialName(i)
		local material = self.model:getMaterial(name)
		local diffuse = {material:getColor("diffuse")}
		local emissive = {material:getColor("emissive")}
		self.allMaterials[name] = {material, diffuse, emissive}
		if name == self.target then
			local metalness = material:getScalar("metalness")
			local roughness = material:getScalar("roughness")
			print(self.target .. ":")
			print("Diffuse color:", unpack(diffuse))
			print("Emissive color:", unpack(emissive))
			print("Metalness:", metalness)
			print("Roughness:", roughness)
			table.insert(vents, makeTriplet{"Diffuse R", "diffuse", diffuse, 2, 1})
			table.insert(vents, makeTriplet{"Diffuse G", "diffuse", diffuse, 2, 2})
			table.insert(vents, makeTriplet{"Diffuse B", "diffuse", diffuse, 2, 3})
			table.insert(vents, makeTriplet{"Emissive R", "emissive", emissive, 3, 1})
			table.insert(vents, makeTriplet{"Emissive G", "emissive", emissive, 3, 2})
			table.insert(vents, makeTriplet{"Emissive B", "emissive", emissive, 3, 3})
			table.insert(vents, makeTriplet{"Metalness", "metalness", metalness})
			table.insert(vents, makeTriplet{"Roughness", "roughness", roughness})
		end
	end

	local function unhighlight()
		for k,v in pairs(self.allMaterials) do
			local material, diffuse, emissive = unpack(v)
			material:setColor("diffuse", unpack(diffuse))
			material:setColor("emissive", unpack(emissive))
		end
	end

	-- Horizontal
	local ents = {
		ui2.ButtonEnt{label="<", onButton = function(_self) -- Die
			if self.highlighted then unhighlight() end
			self:swap( Home() )
		end},
		ui2.UiEnt{label=self.target},
		ui2.ButtonEnt{label="Highlight", onButton = function(_self)
			self.highlighted = not self.highlighted
			if self.highlighted then
				_self.label = "Unhighlight"
				for k,v in pairs(self.allMaterials) do
					local material = unpack(v)
					if k == self.target then
						material:setColor("diffuse", 1, 0xD/0xF, 0)
						material:setColor("emissive", 1, 0xD/0xF, 0)
					else
						material:setColor("diffuse", 0.25, 0.25, 0.25)
						material:setColor("emissive", 0, 0, 0)
					end
				end
			else
				_self.label = "Highlight"
				unhighlight()
			end
			for _,v in ipairs(vents) do
				v:setDisabled(self.highlighted)
			end
		end},
	}

	local layout = ui2.PileLayout{managed=ents, parent=self}
	layout:layout()

	-- Vertical
	local layout = ui2.PileLayout{managed=vents, parent=self, face="y", anchor="tr"}
	layout:layout()
end

return ModelEditMaterialUi

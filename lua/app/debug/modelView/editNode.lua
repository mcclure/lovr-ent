-- View and edit the pose of a skeleton node

namespace "standard"

local flat = require "engine.flat"
local ui2 = require "ent.ui2"
local ModelDrawer = require "app.debug.modelView.modelDrawer"

local ModelEditNodeUi = classNamed("ModelEditNodeUi", ModelDrawer)

function ModelEditNodeUi:onLoad()
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
	ents = {}
	local sliders = {}
	local sliderNames = {"X", "Y", "Z", "AX", "AY", "AZ"}
	local sliderIsAngle = {false, false, false, true, true, true}
	local axes = {AX=vec3(1,0,0), AY=vec3(0,1,0), AZ=vec3(0,0,1)}
	local pose = {self.model:getNodePose(self.target, "local")}
	local origV = vec3(pose[1], pose[2], pose[3])
	local origQ = quat.from_angle_axis(pose[4], pose[5], pose[6], pose[7])
	pose = nil

	local function val(name) return sliders[name]:getValue() end
	local function sliderChange(_self) -- Warning: Does not work
		local v = origV + vec3(val("X"), val("Y"), val("Z"))
		local q = origQ
		for _,axis in ipairs{"AX", "AY", "AZ"} do
			local value = val(axis) / 180 * math.pi
			if value ~= 0 then
				q = q * quat.from_angle_axis(value, axes[axis]:unpack())
			end
		end
		self.model:pose(self.target)
		self.model:pose(self.target, v.x, v.y, v.z, q:to_angle_axis_unpack())
	end

	for i,v in ipairs(sliderNames) do
		local isAngle = sliderIsAngle[i]
		local e = ui2.SliderTripletEnt{startLabel=v, onChange=sliderChange, sliderSpec={minRange=isAngle and 0 or -1, maxRange = isAngle and 360 or 1}}
		sliders[v] = e
		table.insert(ents, e)
	end

	local layout = ui2.PileLayout{managed=ents, parent=self, face="y", anchor="tr"}
	layout:layout()
end

return ModelEditNodeUi
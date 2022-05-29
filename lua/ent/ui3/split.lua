namespace "standard"

local DebugHand = require "app.debug.hand"

local split = {}
local split2
local ui3

function split.makeSplitScreen(spec, force2d)
	if force2d then
		if not split2 then split2 = require "ent.ui2.split" end
		return split2.SplitScreenEnt(spec)
	else
		if not ui3 then ui3 = require "ent.ui3" end

		local pages = spec.pages or {}
		local pagesn = #spec.pages

		local e = Ent{}
		local hand = ui3.Hand{doHover=true}:insert(e)

		for i,v in ipairs(spec.pages) do
			v.hand = hand
			v.surface3 = ui3.SurfaceEnt{}
			v:insert(e)

			local oneRotate = math.pi/3 -- Hand tune. TODO try with more screen sizes
			local rotateIndexOffset = math.floor(pagesn/2) - 2.5
			local offset = Loc(vec3((i*2-2-pagesn/2)*1,0,0), quat.from_angle_axis(-(i + rotateIndexOffset)*oneRotate, 0,1,0))
			
			v.surface3.transform = v.surface3.transform:compose(offset)
			v.surface3:insert(v)
		end

		return e
	end
end

return split
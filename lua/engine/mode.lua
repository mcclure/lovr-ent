-- The "Modes" are a loose, unsafe way of resetting global state.
-- IMPORTS ALL ON REQUIRE

namespace "standard"

-- Assume this to be called once at the start of draw().
-- It doesn't set anything up, only undoes any global settings left behind by other modes.
function drawMode()
	if ent.mode ~= "draw" then
		ent.mode = "draw"
		lovr.graphics.setDepthTest('lequal', true) -- TODO: Test if necessary
	end
end

-- Set up camera and collisions for any kind of ui work (see "flat")
local flat
function uiMode()
	if ent.mode ~= "ui" then
		flat = flat or require("engine.flat")
		ent.mode = "ui"
		lovr.graphics.setDepthTest(nil) -- TODO: Test if necessary
		lovr.graphics.origin()
		lovr.graphics.setProjection(flat.matrix) -- Switch to screen space coordinates
		lovr.graphics.setShader()
	end
end

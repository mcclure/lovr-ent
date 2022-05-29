-- Constants for a head-on screensized 2D camera

local flat = {}

-- FIXME: This is so ui3 can work on Quest. Is this desirable?
local function zeroDefault(x, default) if x > 0 then return x else return default end end

flat.pixwidth = zeroDefault(lovr.graphics.getWidth(), 1280)   -- Window pixel width and height
flat.pixheight = zeroDefault(lovr.graphics.getHeight(), 720)
flat.dpi = zeroDefault(lovr.graphics.getPixelDensity(), 1)
flat.aspect = flat.pixwidth/flat.pixheight -- Window aspect ratio
flat.yspan = 1                             -- Vertical distance center to one edge
flat.height = flat.yspan*2                  -- Height of window
flat.xspan = flat.aspect                   -- Horizontal distance center to one edge
flat.width = flat.xspan*2                 -- Width of window

flat.font = lovr.graphics.newFont(16*flat.dpi)  -- Font appropriate for screen-space usage
flat.font:setPixelDensity(1)
flat.fontscale = flat.height/flat.pixheight -- Use as scale when drawing with this font

flat.matrix = lovr.math.newMat4():orthographic(-flat.aspect, flat.aspect, 1, -1, -64, 64)

return flat

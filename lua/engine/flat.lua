-- Constants for a head-on screensized 2D camera

local flat = {}

flat.pixwidth = lovr.graphics.getWidth()   -- Window pixel width and height
flat.pixheight = lovr.graphics.getHeight()
flat.dpi = lovr.graphics.getPixelDensity()
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

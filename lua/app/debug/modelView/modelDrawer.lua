-- Show 3D model

namespace "standard"

local ui2 = require "ent.ui2"

local ModelDrawerEnt = classNamed("ModelDrawerEnt", ui2.ScreenEnt)

function ModelDrawerEnt:onDraw()
  lovr.graphics.setShader(self.shader)
  lovr.graphics.setColor(1,1,1)
  self.model:draw(0, 1.7, -3, 1, lovr.timer.getTime() * .25)
end

return ModelDrawerEnt

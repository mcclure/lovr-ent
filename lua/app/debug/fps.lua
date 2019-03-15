namespace "standard"

local flat = require "engine.flat"

local FpsCounter = classNamed("FpsCounter", Ent)

local margin = .05

function FpsCounter:onMirror()
	uiMode()

	lovr.graphics.setShader(nil)
	lovr.graphics.setColor(1,1,1,1)
	lovr.graphics.setFont(flat.font)
	lovr.graphics.print(string.format("%.1f fps", lovr.timer.getFPS()),
		flat.aspect-margin, -1+margin, 0, flat.fontscale*2, 0,0,1,0,0, 'right','bottom')
end

return FpsCounter
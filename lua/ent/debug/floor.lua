-- Draw a basic floor plane just so the world isn't invisible
namespace "standard"

local Floor = classNamed("Floor", Ent)

function Floor:_init(spec)
	self:super(spec)
	self.floorPixels = self.floorPixels or 24
	self.floorSize = self.floorSize or 20
end

function Floor:onLoad()
	local data = lovr.data.newImage(self.floorPixels, self.floorPixels, "rgba")
	for x=0,(self.floorPixels-1) do
		for y=0,(self.floorPixels-1) do
			local bright = (x+y)%2 == 0 and 0.5 or 0.75
			local function sq(x) return x*x end
			local alpha = math.min(1, (1-math.max(0, math.min(1, 2*math.sqrt(sq(0.5-x/(self.floorPixels-1))+sq(0.5-y/(self.floorPixels-1))))))*1.2)
			data:setPixel(x,y,bright,bright,bright,alpha)
		end
	end
	local texture = lovr.graphics.newTexture(data, {mipmaps=false})
	texture:setFilter("nearest")
	self.floorMaterial = lovr.graphics.newMaterial(texture)
end

function Floor:onDraw()
	lovr.graphics.setShader(self.shader) -- Probably nil
	lovr.graphics.setBlendMode("alpha", "alphamultiply")
	lovr.graphics.setColor(1,1,1,1)

	-- Draw ever so slightly underneath the 0,0,0 point so as to avoid clipping into anything that other apps may be drawing at 0,0,0.
	lovr.graphics.plane(self.floorMaterial, 0,-1/4096,0, self.floorSize, self.floorSize, -math.pi/2,1,0,0)
end

return Floor

-- Underlying behavior for the Loader class

namespace "minimal"

lovrRequire("data")

local loadAction = {}

loadAction.modelData = lovr.data.newModelData

loadAction.textureData = lovr.data.newTextureData

setmetatable(loadAction, {__index = function(self, key)
	error(string.format("Loader type not recognized: %s", key or "[nil]"), 2)
end})

return loadAction

-- Class that can fetch a resource with the loading happening off-thread

namespace "standard"

local Loader = classNamed("Loader")

local singleThread = ent and ent.singleThread
local newLoaderConnection
local baseKey
local loaderConnections -- Connection logic is complex because Loader can potentially be managing multiple threads
local loaderAction

if singleThread then
	loaderAction = require "engine.thread.action.loader"
else
	baseKey = {}
	loaderConnections = {}

	local PumpEnt = require "engine.thread.connection.pump"
	newLoaderConnection = function(tag)
		return PumpEnt{
			loaders=Queue(),
			boot="engine/thread/helper/loader.lua",
			name="loader", tag=tag,
			handler={
				load={1, function (self, value)
					local loader = self.loaders:pop()
					if loader.filter then
						value = loader.filter(value)
						loader.filter = nil
					end
					loader.content = value
				end}
			},
			load=function(self, loader, args)
				self.loaders:push(loader)
				self:send("load", unpack(args))
			end
		}
	end
end

function Loader:_init(kind, path, filter, channelTag)
	self.channel = self:connect(channelTag)
	if self.channel then
		self.filter = filter
		self.channel:load(self, {kind, path})
	else
		self.content = filter(loaderAction[kind](path))
	end
end

function Loader:get()
	-- Assume self.content is always set by this point if threading is off
	if not self.content then
		while not self.content do
			self.channel:drain(true)
		end
		self.channel = nil
	end

	return self.content
end

function Loader:connect(tag)
	if singleThread then return null end
	local key = tag or baseKey
	local connection = loaderConnections[key]
	if not connection then
		connection = newLoaderConnection(tag)
		connection:insert(ent.root)
		loaderConnections[key] = connection
	end
	return connection
end

Loader.dataToModel = lovr.graphics.newModel
Loader.dataToTexture = lovr.graphics.newTexture
function Loader.dataToMaterial(data) return lovr.graphics.newMaterial( lovr.graphics.newTexture(data) ) end

return Loader
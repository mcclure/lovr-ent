
namespace = require "engine.namespace"

local singleThread = false -- Set to true to force everything to a single thread

-- Load namespace basics
do
	-- This should be only used in helper threads. Make sure this matches thread/helper/boot.lua
	local space = namespace.space("minimal")

	-- Penlight classes missing? add here:
	for _,v in ipairs{"class", "pretty", "stringx", "tablex"} do
		space[v] = require("pl." .. v)
	end
	space.ugly = require "engine.ugly"

	require "engine.types"
end
do
	-- This is the basic namespace most files should use
	local space = namespace.space("standard", "minimal")

	space.cpml = require "cpml"
	for _,v in ipairs{"bound2", "bound3", "vec2", "vec3", "quat", "mat4", "intersect", "color", "utils"} do
		space[v] = space.cpml[v]
	end
	require "engine.loc"

	require "engine.ent"
	space.ent.singleThread = singleThread
	require "engine.common_ent"
	require "engine.lovr"
	require "engine.mode"
end

--[[
-- Suggest you create a namespace for your game here, like:
namespace.prepare("gamename", "standard", function(space)
	require "engine.gamename.types"
	require "engine.gamename.level"
end)
--]]

-- Ent driver
-- Pass an app load point or a list of them as cmdline args or defaultApp will run

namespace "standard"

local defaultApp = "app/test/cube"

function lovr.load()
	ent.root = LoaderEnt(arg, defaultApp)
	ent.root:route("onBoot") -- This will only be sent once
	ent.root:insert()        -- Will route onLoad
end

function lovr.update(dt)
	ent.root:route("onUpdate", dt)
	entity_cleanup()
end

function lovr.draw()
	drawMode()
	ent.root:route("onDraw")
end

local mirror = lovr.mirror
function lovr.mirror()
	mirror()
	ent.root:route("onMirror")
end

if not singlethread then -- Kludge: Currently only threading uses onQuit. Instead make it onThreadCleanup or something
	function lovr.quit()
		ent.root:route("onQuit")
	end

	function lovr.threaderror(thread, message)
		error(string.format("Error on thread:\n%s", (message or "[nil]")))
	end
end

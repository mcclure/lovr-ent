-- main.lua replacement for a helper thread. helpers should require this on their first line

namespace = require "engine.namespace"

do
	-- Make sure this matches main.lua
	local space = namespace.space("minimal")

	for _,v in ipairs{"class", "pretty", "stringx", "tablex"} do
		space[v] = require("pl." .. v)
	end
	space.ugly = require "engine.ugly"

	require "engine.types"
end

do
	for _,name in ipairs {"standard", "skategirl", "halfjump"} do
		namespace.prepare(name, nil, function()
			error("This file currently cannot be used in a helper thread.")
		end)
	end
end

-- TODO: Make this the entry point and take the item to require as an arg?

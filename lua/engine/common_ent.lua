-- Run Hello autonomous entities, adapted for Lovr
-- Assumes in namespace: "ent", pl "class" and "stringx"
-- IMPORTS ALL ON REQUIRE

namespace "standard"
require "engine.types"
require "engine.ent"

-- Ent that loads a series of classes, creates them and sets them as children
-- Constructor treats its positional arguments as classes to load on onLoad

class.LoaderEnt(OrderedEnt)

function LoaderEnt:_init(spec)
	self.spec = spec
	self:super() -- spec not passed through. This class is "sealed"
end

-- Call to load and insert one class by name
function LoaderEnt:load(name)
	if stringx.endswith(name, ".txt") then
		local liststring = lovr.filesystem.load(v)
		local list = stringx.split("\n")
		for i,v in list do
			v = stringx.partition(v, "#")
			v = stringx.strip(v, " \r\t")
			self:load(v)
		end
	else
		local CLS = require(name)
		if type(CLS) ~= "table" then
			error(string.format("Loaded \"%s\" but it didn't return an entity", name))
		end
		CLS():insert(self)
	end
end

function LoaderEnt:onLoad()
	local spec = self.spec
	self.spec = nil
	for i,v in ipairs(spec) do self:load(v) end
end

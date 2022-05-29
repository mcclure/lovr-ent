-- Run Hello autonomous entities, adapted for Lovr
-- Assumes in namespace: "ent", pl "class" and "stringx"
-- IMPORTS ALL ON REQUIRE

namespace "standard"
require "engine.types"
require "engine.ent"

-- Ent that loads a series of classes, creates them and sets them as children
-- Constructor treats its positional arguments as paths to load on onLoad
-- These arguments will be treated as paths to .lua files that eval to classes
-- Or .txt files containing lists of paths of .lua files that eval to classes
-- Args proper (positional arguments beginning with : or -) may be interspersed;
-- These are treated as arguments to the ent immediately preceding it
-- (or the default app, if no ent path is preceding)
-- Every argument prefixed with : will be treated as a positional arg
-- Every argument of form --x or --x=v will be set as a named key

-- TODO: Support a mode where class names are not accepted and : args become normal args

class.LoaderEnt(OrderedEnt)

local function isPos(s) return s:sub(1,1) == ":" end
local function isFlag(s) return s:sub(1,1) == "-" end

function LoaderEnt:_init(spec, defaultApp)
	self.spec = spec
	self.defaultApp = defaultApp
	self:super() -- spec not passed through. This class is "sealed"
end

-- Call to load and insert one class by name
function LoaderEnt:load(name, arg)
	if stringx.endswith(name, ".txt") then
		if arg then print("Warning: Argument to txt file ignored") end
		local liststring = lovr.filesystem.load(v)
		local list = stringx.split("\n")
		for i,v in list do
			v = stringx.partition(v, "#")
			v = stringx.strip(v, " \r\t")
			self:load(v)
		end
	else
		-- Allow (by removing) any accidental .lua files.
		-- FIXME?: This means that it is naturally impossible to include a file named lua/init.lua. Oh well.
		if stringx.endswith(name, ".lua") then
			name = name:sub(1,-5)
		end

		local CLS = require(name)
		if arg then arg = {arg=arg} end
		if type(CLS) ~= "table" then
			error(string.format("Loaded \"%s\" but it didn't return an entity", name))
		end
		CLS(arg):insert(self)
	end
end

function LoaderEnt.argNormalize(s) -- Notice class method
	return s:gsub("-",""):lower()
end

function LoaderEnt:onLoad()
	local spec = self.spec
	self.spec = nil
	local i = 1
	while true do -- Iterate over spec
		local v = spec[i]
		if i==1 and (not v or isPos(v) or isFlag(v)) then -- Handle very special case of first arg being a flag
			if not v then i = i + 1 end -- But don't special-handle the "no args at all" case
			v = self.defaultApp
		else
			if not v then break end
			i = i + 1
		end
		-- Handle interstital args
		local arg
		while spec[i] do
			local argi = spec[i]
			local posArg = isPos(argi)
			local flagArg = isFlag(argi)
			if not posArg and not flagArg then break end
			if not arg then arg = {} end
			if posArg then
				table.insert(arg, argi:sub(2))
			else -- Kludge: This will accept ----arg
				local k,_,v = stringx.partition(stringx.lstrip(argi, "-"), "=")
				if #v == 0 then v = true end
				k = LoaderEnt.argNormalize(k) -- intentionally collapse --anarg, --anArg and --an-arg
				arg[k] = v
			end
			i = i + 1
		end
		self:load(v, arg)
	end
end

-- Run Hello autonomous entity lib, adapted for Lovr
-- Assumes pl "class" in namespace
-- IMPORTS ALL ON REQUIRE

namespace "standard"
require "engine.types"

-- Entity state

ent = {inputLevel = 1} -- Entity machine
route_terminate = {}

local doomed = {}

function entity_cleanup()
	if tableTrue(doomed) then
		for i,v in ipairs(doomed) do
			if type(v) ~= "function" then
				v:bury()
			else
				v()
			end
		end
		doomed = {}
	end
end

function queueDoom(f)
	table.insert(doomed, f)
end

function queueBirth(e, parent)
	table.insert(doomed, function()
		e:insert(parent)
	end)
end

-- Ents

local ent_id_generator = 1

class.Ent()
function Ent:_init(spec)
	pull(self, {id=ent_id_generator,kids={}})
	pull(self, spec)
	ent_id_generator = ent_id_generator + 1
end

function Ent:route(key, payload)
	local result
	if self[key] then
		result = self[key](self, payload)
	end
	if result ~= route_terminate then
		for k,v in pairs(self.kids) do
			v:route(key, payload)
		end
	end
end

function Ent:insert(parent)
	if self.parent then error("Reparenting not currently supported") end
	self.parent = parent
	if parent then
		parent:register(self)
	end
	-- There's an annoying special case to get onLoad to fire the very first boot.
	-- FIXME: Figure out a better way of detecting roothood?
	if not self.loaded and ((parent and parent.loaded) or self == ent.root) then
		self:route("onLoad")
		self:route("_setLoad")
	end
	return self
end

function Ent:_setLoad()
	self.loaded = true
end

function Ent:die()
	if self.dead then return end -- Don't die twice
	self.dead = true
	self:route("onDie")
	
	table.insert(doomed, self)
end

function Ent:register(child)
	self.kids[child.id] = child
end

function Ent:unregister(child)
	self.kids[child.id] = nil
end

function Ent:bury()
	if self.parent then
		self.parent:unregister(self)
	end
	self:route("onBury")
end

-- Children are routed in the order they are added, but unegistration is inefficent
class.OrderedEnt(Ent)
function OrderedEnt:_init(spec)
	pull(self, {kidOrder={}})
	self:super(spec)
end

function OrderedEnt:register(child)
	table.insert(self.kidOrder, child.id)
	Ent.register(self, child)
end

function OrderedEnt:unregister(child) -- TODO: Remove maybe?
	local kidOrder = {}
	for i,v in ipairs(self.kidOrder) do
		if v ~= child.id then
			table.insert(kidOrder, v)
		end
	end
	self.kidOrder = kidOrder
	Ent.unregister(self, child)
end

function OrderedEnt:route(key, payload) -- TODO: Repetitive with Ent:route()?
	local result
	if self[key] then
		result = self[key](self, payload)
	end
	if result ~= route_terminate then
		for _,id in ipairs(self.kidOrder) do
			local v = self.kids[id]
			if v then v:route(key, payload) end
		end
	end
end

-- Remember the inputLevel on the day you were born
class.InputEnt()
function InputEnt:_init(spec)
	pull(self, {inputLevel = ent.inputLevel})
end

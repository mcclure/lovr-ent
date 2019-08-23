-- Run Hello autonomous entity lib, adapted for Lovr
-- Assumes pl "class" in namespace
-- IMPORTS ALL ON REQUIRE

namespace "standard"
require "engine.types"

-- Entity state

ent = {inputLevel = 1} -- State used by ent class
route_terminate = {} -- A special value, return from an event and your children will not be called

local doomed = {}

-- Should be called once at the end of each update. **User code should not call this.**
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

-- Call this with a function and it will be run at the end of the next update, when dead entities are buried.
function queueDoom(f)
	table.insert(doomed, f)
end

-- Call this with an object and a parent and it will be inserted at the end of the next udpate, when dead entities are buried.
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

-- Call with a function name and an argument and it will be called first on this object, then all its children
function Ent:route(key, ...)
	local result
	if self[key] then
		result = self[key](self, ...)
	end
	if result ~= route_terminate then
		for k,v in pairs(self.kids) do
			v:route(key, ...)
		end
	end
end

-- Call with a parent object and the object will be inserted into the entity tree at that point
function Ent:insert(parent)
	if self.parent then error("Reparenting not currently supported") end
	if not parent and self ~= ent.root then -- Default to ent.root
		if ent.strictInsert then error("insert() with no parent") end -- Set this flag for no default
		if not ent.root then error("Tried to insert to the root entity, but there isn't one") end
		parent = ent.root
	end
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

-- Used to set self.loaded and self.dead properly. **User code should not call these.**
function Ent:_setLoad() self.loaded = true end
function Ent:_setDead() self.dead = true end

-- Call and the object will have self.dead set and then be deleted at the end of the next frame.
function Ent:die()
	if self.dead then return end -- Don't die twice
	self:route("onDie")
	self:route("_setDead")
	
	table.insert(doomed, self)
end

-- The entity is being inserted. **User code can overload this, but probably should not call it.**
function Ent:register(child)
	self.kids[child.id] = child
end

-- The entity is being buried. **User code can overload this, but probably should not call it.**
function Ent:unregister(child)
	self.kids[child.id] = nil
end

-- It is the end of the frame. This object was die()d and it's time to delete it. **User code can overload this, but probably should not call it.**
function Ent:bury()
	if self.parent then
		self.parent:unregister(self)
	end
	self:route("onBury")
end

-- For this class, are routed in the order they are added, but unegistration is inefficent
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

-- This class remembers the inputLevel at the moment it was constructed
class.InputEnt(Ent)
function InputEnt:_init(spec)
	pull(self, {inputLevel = ent.inputLevel})
	self:super(spec)
end

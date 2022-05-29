-- Run Hello autonomous entity lib, adapted for Lovr
-- Assumes pl "class" in namespace
-- IMPORTS ALL ON REQUIRE

namespace "standard"
require "engine.types"

-- Entity state

ent = {inputLevel = 1} -- State used by ent class
route_terminate = {} -- A special value, return from an event and your children will not be called
route_poison = {} -- A special value, return from an event and no more functions will be called this entire route() tree

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
	if not e then error("Asked to queue birth on nil entity") end
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

-- We are "route counting" and need to de-route-count and also handle any pending inserts.
-- This ugly workaround is necessary to prevent a bug where a child is inserted during a route; in that case undefined behavior occurs.
-- FIXME: An alternate, terser solution might be to make all ents OrderedEnts.
function Ent:_routeEnd(result, returnFirst, key, ...)
	if self._routePendingInserts then
		for i,v in ipairs(self._routePendingInserts) do
			if result == route_poison or result == route_terminate or (returnFirst and result ~= nil) then break end
			result = v:route(key, ...)
		end
		if self._routeCount == 1 then
			for i,v in ipairs(self._routePendingInserts) do
				self:register(v)
			end
			self._routePendingInserts = nil
		end
	end

	self._routeCount = self._routeCount - 1

	if result == route_poison or (returnFirst and result ~= route_terminate) then return result end
end

-- Call with a function name and an argument and it will be called first on this object, then all its children
function Ent:route(key, ...)
	local result
	if self[key] then
		result = self[key](self, ...)
	end
	if result == route_poison then return route_poison end
	if result ~= route_terminate and self.kids then -- Notice: we don't have to check _routePendingInserts becuase there's no way to add to it above
		self._routeCount = (self._routeCount or 0) + 1
		for k,v in pairs(self.kids) do
			result = v:route(key, ...)

			if result == route_poison or result == route_terminate then break end
		end
		return self:_routeEnd(result, false, key, ...)
	end
end

-- Call with a function name and an argument and it will be called first on this object, then all its children
-- The first function to return a non-nil value will return its value all the way up the chain
-- FIXME: Call _routeEnd
function Ent:routeFirstValue(key, ...)
	local result
	if self[key] then
		result = self[key](self, ...)
	end
	if result ~= nil then return result end
	for k,v in pairs(self.kids) do
		local result2 = v:routeFirstValue(key, ...)

		if result2 ~= nil then return result2 end
	end
	return nil
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
		if parent._routeCount and parent._routeCount > 0 then -- FIXME swap order -- see _routeEnd
			if self._routePendingInserts then
				table.insert(parent._routePendingInserts, self)
			else
				parent._routePendingInserts = {self}
			end
		else
			parent:register(self)
		end
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

function OrderedEnt:route(key, ...) -- TODO: Repetitive with Ent:route()?
	local result
	if self[key] then
		result = self[key](self, ...)
	end
	if result == route_poison then return route_poison end
	if result ~= route_terminate then
		for _,id in ipairs(self.kidOrder) do
			local v = self.kids[id]
			if v then
				local result2 = v:route(key, ...)

				if result2 == route_poison then return route_poison end
			end
		end
	end
end

function OrderedEnt:routeFirstValue(key, ...) -- TODO: Super repetitive with Ent:route()?
	local result
	if self[key] then
		result = self[key](self, ...)
	end
	if result ~= nil then return result end
	for _,id in ipairs(self.kidOrder) do
		local v = self.kids[id]
		if v then
			local result2 = v:routeFirstValue(key, ...)

			if result2 ~= nil then return result2 end
		end
	end
	return nil
end

-- This class remembers the inputLevel at the moment it was constructed
class.InputEnt(Ent)
function InputEnt:_init(spec)
	pull(self, {inputLevel = ent.inputLevel})
	self:super(spec)
end

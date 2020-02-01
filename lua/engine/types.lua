-- Run Hello lua utilities
-- Assumes pl "class" in namespace
-- IMPORTS ALL ON REQUIRE

namespace "minimal"

function pull(dst, src) -- Insert all members of a into b
	if dst and src then
		for k,v in pairs(src) do
			dst[k] = v
		end
	end
end

function tableInvert(t_) -- Reverse (swap keys and values of) a table
	local t = {}
	for k,v in pairs(t_) do
		t[v] = k
	end
	return t
end

function tableConcat(a, b) -- Concatenate two tables into a third
	local result = {}
	pull(result, a)
	pull(result, b)
	return result
end

function tableSkim(a, keys) -- Extract only these keys from a table
	local t = {}
	for _,v in ipairs(keys) do
		t[v] = a[v]
	end
	return t
end

function tableSkimUnpack(a, keys) -- Extract only these keys from a table (unpacked list)
	local t = {}
	for _,v in ipairs(keys) do
		table.insert(t, a[v])
	end
	return unpack(t)
end

function tableTrue(t) -- True if table nonempty
	return next(t) ~= nil
end

function tableCount(t) -- Number of values in table (not just array part)
	local keys = 0
	for _,_2 in pairs(t) do
		keys = keys + 1
	end
	return keys
end

function toboolean(v) -- As named
	return v and true or false
end

local function ipairsReverseIter(t, i) -- (Helper for ipairsReverse)
	i = i - 1
	if i > 0 then
		return i, t[i]
	end
end

function ipairsReverse(t) -- ipairs() but in reverse order
	return ipairsReverseIter, t, #t+1
end

local function charIter(s, i) -- (Helper for ichars)
	i = i + 1
	if i <= #s then
		return i, s:sub(i, i)
	end
end

function ichars(s) -- ipairs() but for characters of an array
	return charIter, s, 0
end

function mapRange(count, f) -- Return a table prepopulated either with a range of ints or with the return values of a (optional) constructor function f
	local t = {}
	for i=1,count do
		table.insert(t, f and f(i) or i)
	end
	return t
end

function classNamed(name, parent) -- create dynalloc class with name
	local cls = class(parent)
	cls._name = name
	return cls
end

function stringTag(s, tag)
	if tag then return s .. "-" .. tag end
	return s
end

function lovrRequire(module) -- call with for example lovrRequire("thread") to load lovr.thread, if you might be in a file
	local callerNamespace = getfenv(2)
	local lovrTable = callerNamespace.lovr
	if not lovrTable then lovrTable = {} callerNamespace.lovr = lovrTable end
	if not lovrTable[module] then lovrTable[module] = require( "lovr."..module ) end
end

class.Queue() -- Queue w/operations push, pop, peek
function Queue:_init()
	self.low = 1 self.count = 0
end
function Queue:push(x)
	self[self.low + self.count] = x
	self.count = self.count + 1
end
function Queue:pop()
	if self.count == 0 then
		return nil
	end
	local move = self[self.low]
	self[self.low] = nil
	self.count = self.count - 1
	self.low = self.low + 1
	return move
end
function Queue:peek()
	if self.count == 0 then
		return nil
	end
	return self[self.low]
end
function Queue:empty()
	return self.count == 0
end
function Queue:at(i)
	return self[self.low + i - 1]
end
function Queue:ipairs()
  local function ipairs_it(t, i)
    i = i+1
    local v = t:at(i)
    if v ~= nil then
      return i,v
    else
      return nil
    end
  end
  return ipairs_it, self, 0
end

class.Stack() -- Stack w/operations push, pop, peek
function Stack:_init()
	self.count = 0
end
function Stack:push(x)
	self.count = self.count + 1
	self[self.count] = x
end
function Stack:pop()
	if self.count == 0 then
		return nil
	end
	local move = self[self.count]
	self[self.count] = nil
	self.count = self.count - 1
	return move
end
function Stack:peek()
	if self.count == 0 then
		return nil
	end
	return self[self.count]
end
function Stack:empty()
	return self.count == 0
end

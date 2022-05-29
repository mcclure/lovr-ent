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

-- Simulate a function argument list with "keyword arguments":
-- "from" and "into" are tables. "keys" is a list of key names.
-- pull all keys in "keys" from from into into-- and if missing, try the index instead of the keyname.
-- At the end you get a table with no positional values, only named keys
function pullNamed(keys, into, from)
    for i,v in ipairs(keys) do
        if from[v] ~= nil then into[v] = from[v] else into[v] = from[i] end
    end
end

function ipull(dst, src)
	if dst and src then
		for _,v in ipairs(src) do
			table.insert(dst, v)
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

function tableMerge(a, b) -- Merge two tables (dictionaries; shadow on key collision) into a third
	local result = {}
	pull(result, a)
	pull(result, b)
	return result
end

function tableConcat(a, b) -- Concatenate two tables (lists; append integer keys in order) into a third
	local result = {}
	ipull(result, a)
	ipull(result, b)
	return result
end

function tableSkim(a, keys) -- Extract only these keys from a table
	local t = {}
	for _,v in ipairs(keys) do
		t[v] = a[v]
	end
	return t
end

function tableSkimErase(a, keys) -- Extract only these keys from a table, erase afterward
	local t = tableSkim(a, keys)
	for _,v in ipairs(keys) do
		a[v] = nil
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

function tableSkimNumeric(a) -- Extract only numeric keys from a table
	local t = {}
	for i,v in ipairs(a) do
		t[i]=v
	end
	return t
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

function tableKeys(t)
	local t2 = {}
	for k,v in pairs(t) do
		table.insert(t2, k)
	end
	return t2
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

local function ipairsSingleIter(v, i)
	if i == 1 then
		return 2, v
	end
end

function ipairsOrSingle(v) -- ipairs for a table or iterate-single for a single value
	if type(v) == "table" then
		return ipairs(v)
	else
		return ipairsSingleIter, v, 1
	end
end

local function returnNull() end

function ipairsIf(v) -- ipairs that treats nil as an empty table
	if v then
		return ipairs(v)
	else
		return returnNull
	end
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

-- Loose array, sparse data, no bounds checking
-- members:
--     bound: or nil
--     data: 2d sparse array
class.A2()
function A2:_init(w,h)
	self.data = {}
end
-- TODO: Add isEmpty() function before merging back to lovr-ent
function A2:get(x, y)
	local t = self.data[x]
	if t then
		return t[y]
	end
	return nil
end
function A2:set(x, y, v)
	local t = self.data[x]
	if not t then
		t = {}
		self.data[x] = t
	end
	t[y] = v
end
function A2:iter()
	local i, seq, x = pairs(self.data) -- x-axis iterator
	local ti, tseq, y                  -- y-axis iterator
	return function()
		local result
		while result == nil do
			if ti == nil then
				local t
				x,t = i(seq, x)        -- follow stateless iterator protocol "by hand" here,
				if not x then return nil end
				ti, tseq, y = pairs(t)
			end
			local v
			y,v = ti(tseq, y)          -- and here
			if v then
				return x, y, v
			end
			ti = nil
		end
	end
end
function A2:gridIter()
	local x, y = 1,0
	return function ()
		y = y + 1
		if y > self.height then
			x = x + 1
			if x > self.width then
				return nil
			end
			y = 1
		end
		return x, y
	end
end
function A2:clear()
	self.data = {}
end
-- Add all values from another A2
function A2:addAll(addFrom, filter)
	for x,y,v in addFrom:iter() do
		if filter then x,y,v = filter(x,y,v) end
		self:set(x,y,v)
	end
end
-- Clear all values from another A2
function A2:removeAll(a, filter)
	for x,y,v in a:iter() do
		if filter then x,y = filter(x,y,z) end
		self:set(x,y,nil)
	end
end
-- Copy entire A2, pass in filter to act as map
function A2:clone(filter)
	local result = A2(self.width, self.height)
	result:addAll(self, filter)
	return result
end

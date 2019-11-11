-- Run Hello lua utilities
-- Assumes pl "class" in namespace
-- IMPORTS ALL ON REQUIRE

namespace "standard"

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

function tableTrue(e) -- True if table nonempty
	return next(e) ~= nil
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

-- Rigid body transform class based on CPML
local plMetatable = {__tostring = function(o) return o:to_string() end}
class.Loc(nil, nil, plMetatable)
function Loc:_init(at, rotate, scale) -- Warning treat contents as const
	self.at = at or vec3()
	self.rotate = rotate or quat()
	self.scale = scale or 1
end
function Loc.fromPose(x,y,z, angle,ax,ay,az)
	return Loc(vec3(x,y,z), quat.from_angle_axis(angle,ax,ay,az))
end
function Loc:toPose()
	return self.at.x, self.at.y, self.at.z, self.rotate:to_angle_axis_unpack()
end
function Loc:clone()
	return Loc(self.at, self.rotate, self.scale)
end
function Loc:assign(loc)
	self.at = loc.at
	self.rotate = loc.rotate
	self.scale = loc.scale
end
function Loc:scaleUnpack() -- Return scale in 3-component form
	return self.scale, self.scale, self.scale
end
function Loc:apply(v) -- The following methods are untested
    return self.rotate * (v * self.scale) + self.at
end
function Loc:applyToVector(v)
    return self.rotate * (v * self.scale)
end
function Loc:compose(v)
    return Loc(self:apply(v.at), v.rotate * self.rotate, self.scale * v.scale)
end
function Loc:inverse(v)
	local unrotate = self.rotate:inverse()
	local unscale = self.scale ~= 0 and 1/self.scale or 0
    return Loc(unrotate * -self.at * unscale, unrotate, unscale)
end
function Loc:pow(s)
	return Loc(self.at * s, self.rotate:pow(s), math.pow(self.scale, s))
end
function Loc:lerp(v, s)
	return Loc(self.at:lerp(v.at, s), self.rotate:slerp(v.rotate, s), self.scale + (v.scale - self.scale) * s)
end
function Loc:to_string()
	local s = "(at:" .. tostring(self.at) .. " rot:" .. tostring(self.rotate)
	if self.scale ~= 1 then s = s .. " scale:" .. tostring(self.scale) end
	s = s .. ")"
	return s
end

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

function tableTrue(e) -- True if table nonempty
	return next(e) ~= nil
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

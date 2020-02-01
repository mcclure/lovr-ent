-- Base class for main-thread managing a helper thread and sending back and forth messages

namespace "standard"

local PumpEnt = classNamed("PumpEnt", Ent)

-- Note: Will malfunction if "nil" is sent
-- spec:
--     name:
--     handler: map of message name -> {num args, function}
-- methods:
--     send(kind, ...): send message to the other side

function read(channel, force)
	if not force then return channel:pop(false) end
	while true do
		local v = channel:pop(0.1)
		if v ~= nil then return v end
	end
end

function PumpEnt:args() end

function PumpEnt:insert(parent)
	self.thread = lovr.thread.newThread(self.boot)
	self.thread:start(self.tag, self:args())

	self.boot = nil
	Ent.insert(self, parent)
end

function PumpEnt:connect()
	if ent.singleThread then error("Doing thread ops but threading is disabled...") end
	if not self.channelSend then
		local name = stringTag(self.name, self.tag)

		self.channelSend = lovr.thread.getChannel(name.."-up")
		self.channelRecv = lovr.thread.getChannel(name.."-dn")
		self.responseHandlers = Queue()
	end
	return self.channelSend, self.channelRecv
end

function PumpEnt:drain(force)
	local channelSend, channelRecv = self:connect()
	while not self.responseHandlers:empty() do
		local result1 = read(channelRecv, force)
		if not result1 then break end

		local kind = self.responseHandlers:pop()
		local handler = self.handler[kind]
		if not handler then error(string.format("Don't understand message %s", kind or "[nil]")) end
		local argc, fn = unpack(handler)

		if argc<=1 then
			fn(self, result1)
		else
			local arg = {}
			for i=2,argc do table.insert(arg, read(channelRecv, true)) end
			fn(self, result1, unpack(arg))
		end

		force = false
	end
	if force then error("Demanding data from channel but nothing is pending") end
end

function PumpEnt:onUpdate()
	self:drain()
end

function PumpEnt:send(kind, ...)
	local handler = self.handler[kind]
	local needHandleResponse = handler and handler[1] > 0

	local arg = {...}
	local channelSend, channelRecv = self:connect()
	channelSend:push(kind, false)
	for i,v in ipairs(arg) do
		channelSend:push(v, false)
	end
	if needHandleResponse then 
		self.responseHandlers:push(kind)
	end
end

-- FIXME should threads be killed on error?
function PumpEnt:onBury()
	if self.thread then
		self:connect():push("die")
	end
end

PumpEnt.onQuit = PumpEnt.onBury

return PumpEnt

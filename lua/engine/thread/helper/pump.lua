-- Base class for helper-thread main loop sending back and forth messages

namespace "minimal"

lovrRequire("thread")

local Pump = classNamed("Pump")

-- Note: Will malfunction if "nil" is sent
-- spec:
--     name: channel name
--     handler: map of message name -> {num args, function}
function Pump:_init(spec)
	pull(self, spec)
	local name = stringTag(self.name, self.tag)

	self.channelSend = self.channelSend or lovr.thread.getChannel(name.."-dn")
	self.channelRecv = self.channelRecv or lovr.thread.getChannel(name.."-up")
end

function Pump:run()
	while true do
		local kind = self.channelRecv:pop(true) -- TODO: id first, to support cancel?
		if kind == "die" then return end

		local handler = self.handler[kind]
		if not handler then error(string.format("Don't understand message %s", kind or "[nil]")) end
		local argc, fn = unpack(handler)

		local result
		if argc==0 then
			result = {fn(self)}
		else
			local arg = {}
			for i=1,argc do table.insert(arg, self.channelRecv:pop(true)) end
			result = {fn(self, unpack(arg))}
		end

		for _,v in ipairs(result) do
			self.channelSend:push(v, false)
		end
	end
end

return Pump

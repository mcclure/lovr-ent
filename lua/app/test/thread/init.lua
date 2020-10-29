-- Execute this, demonstrates using the lovr-ent thread classes

namespace "standard"

-- This is a demo of the lovr-ent thread features, but it works in single thread mode;
-- one of the main advantages of using the lovr-ent thread model over lovr's objects only
-- is it makes it easier to degrade to singlethreaded when this switch in main.lua is flipped.
local singleThread = ent and ent.singleThread

local workerConnection
local workerAction

-- The lovr-ent thread model is to create two files: an "action" and a "helper".
-- The "helper" is the event loop that runs in the worker thread, probably implemented with the Pump class.
-- The "action" is... whatever it is your worker thread does.
-- In singleThread mode, you include the action directly from your main-thread code, and call it.
-- In non-singleThread mode, your helper includes the action,
--     and you make a PumpEnt in main thread to handle the helper's response.
if singleThread then
	workerAction = require "app.test.thread.action"
end

local ThreadTest = classNamed("ThreadTest", Ent)

function ThreadTest:_init(...)
	if not singleThread then
		if not workerConnection then
			local PumpEnt = require "engine.thread.connection.pump"

			workerConnection = PumpEnt{
				requests=Queue(), -- This is to allow multiple requests to be inflight but demuxed properly afterward
				boot="app/test/thread/helper.lua",
				name="ThreadTestWorker", -- Notice no tag
				handler={
					add={1, function (self, value)
						local request = self.requests:pop()
						request.value = value
					end}
				},
				add=function(self, request, ...)
					self.requests:push(request)
					self:send("add", ...)
				end
			}:insert(ent.root)
		end
	end
	self:super(...)
end

-- Fork a request either to the connection, or directly to the action
function issueRequest(value)
	local request = {}
	if workerConnection then
		workerConnection:add(request, value)
	else
		request.value = workerAction(value)
	end
	return request
end

function ThreadTest:onUpdate()
	if not self.request then
		self.lastValue = self.value or 0
		self.request = issueRequest(self.lastValue)
	end
	-- If you want to force the main thread to wait until the response comes a thing you can do is:
	-- while not self.request.value do workerConnection:drain(true) end
	if self.request and self.request.value then
		self.value = self.request.value
		self.request = nil
	end
end

function ThreadTest:onDraw()
	lovr.graphics.print(self.lastValue, -0.5, 2, -2) -- Most recent "sent" value
	if self.value then
		lovr.graphics.print(self.value, 0.5, 2, -2)  -- Most recent "received" value
	end
end

return ThreadTest

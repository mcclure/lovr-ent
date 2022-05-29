-- Helper thread impl app.test.thread test
-- This is a minimal helper consisting of boilerplate, and a Pump with one RPC
-- that just invokes and returns the function in app.test.thread.action.
-- Notice the "name" in the pump construction *must* be the same as in the PumpEnt

local tag = ...

require 'lovr.filesystem'
require "engine.thread.helper.boot"
namespace "minimal"

local Pump = require "engine.thread.helper.pump"
local action = require "app.test.thread.action"

Pump{
	name="ThreadTestWorker", tag=tag,
	handler={
		add={1, function(self, value)
			return action(value)
		end}
	}
}:run()

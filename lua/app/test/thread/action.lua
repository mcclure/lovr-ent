-- Thread action for app.test.thread test. It is just a function.
-- The function takes an argument, adds one,
--     and sometimes randomly sleeps for up to 1.5 seconds before returning
--     (to simulate some sort of actually costly process).

namespace "minimal"

lovrRequire("timer")

-- Random time between 0 and 1.5
-- Doing this for now instead of loading lovr.math because of lovr issue #316
local randomMax = 1.5
local accumulator = 1
local function randomDuration()
	accumulator = ( (accumulator * 6389.75591401 + 15581.1442314) / 311.155434 ) % randomMax
	return accumulator
end
randomDuration() randomDuration()

return function(x)
	local doSleep = randomDuration() > randomMax/2
	if doSleep then
		local duration = randomDuration()
		print(string.format("Sleeping %0.02f sec", duration))
		lovr.timer.sleep(duration)
	end
	return x+1
end

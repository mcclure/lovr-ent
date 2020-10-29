-- Thread action for app.test.thread test. It is just a function.
-- The function takes an argument, adds one,
--     and sometimes randomly sleeps for up to 1.5 seconds before returning
--     (to simulate some sort of actually costly process).

namespace "minimal"

lovrRequire("math")
lovrRequire("timer")

return function(x)
	local doSleep = lovr.math.random() > 0.5
	if doSleep then
		local duration = lovr.math.random()*1.5
		print(string.format("Sleeping %0.02f sec", duration))
		lovr.timer.sleep(duration)
	end
	return x+1
end

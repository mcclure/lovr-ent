
function lovr.conf(t)
	-- Pass --desktop at startup (after asset path) to force desktop/fake driver
	if arg[1] == "--desktop" then
		t.headset.drivers = {"desktop"}

		local argn = #arg -- Move other args over to replace missing one
		for i=1,argn do
			arg[i] = arg[i+1]
		end
	end
end


function lovr.conf(t)
  -- Pass --desktop at startup (after asset path) to force desktop/fake driver
  if arg[1] == "--desktop" then
    local argn = #arg
    t.headset.drivers = {"desktop"}
    for i=1,argn do
      arg[i] = arg[i+1]
    end
  end
end

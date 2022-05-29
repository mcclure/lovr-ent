-- Show command-line arguments

namespace "standard"

local ArgTest = classNamed("ArgTest", Ent)

function ArgTest:onDraw()
	local display
	if not self.arg then
		display = "No command-line arguments."
	else
		display = "Command-line arguments:"

		local first = true
		for i,v in ipairs(self.arg) do
			if first then  display = display.."\n\nPositional args: "  first = false
			else  display = display..", "  end

			display = display.."\""..v.."\""
		end

		first = true
		for k,v in pairs(self.arg) do
			if type(k) ~= "number" then
				if first then  display = display.."\n\nKeyword args: "  first = false
				else  display = display..", "  end

				display = display..k..": "
				if type(v) == "string" then
					display = display.."\""..v.."\""
				else -- Could be a boolean
					display = display..tostring(v)
				end
			end
		end
	end
	lovr.graphics.print(display, 0, 1.7, -3, .2, 0,1,0,0, 12)
end

return ArgTest

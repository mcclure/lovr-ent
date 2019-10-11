-- File selector for modelView app

namespace "standard"

local flat = require "engine.flat"
local ui2 = require "ent.ui2"
local DisplayUi = require "app.debug.modelView.display"

local FileListUi = classNamed("FileListUi", ui2.ScreenEnt)

function FileListUi:fileSearch(ents, dirpath)
	for i,filename in ipairs(lovr.filesystem.getDirectoryItems(dirpath)) do
		local filepath = dirpath .. (dirpath == "/" and "" or "/") .. filename
		if stringx.endswith(filename, ".gltf") or stringx.endswith(filename, ".obj") or stringx.endswith(filename, ".glb") then
			table.insert(ents, ui2.ButtonEnt{label=filepath, onButton = function(self) -- Give this ui some state
				self.swap:swap( DisplayUi{name=filename, path=filepath} )
			end})
		elseif lovr.filesystem.isDirectory(filepath) then
			self:fileSearch(ents, filepath)
		end
	end
end

function FileListUi:onLoad()
	lovr.graphics.setBackgroundColor(0,0,0)
	ui2.routeMouse()
	local ents = {}
	self:fileSearch(ents, "/")
	if not tableTrue(ents) then
		table.insert(ents, ui2.UiEnt{label="No GLTFs, GLBs or OBJs found in project."})
	end

	local layout = ui2.PileLayout{managed=ents, parent=self, pass={swap=self}}
	layout:layout()
end

return FileListUi

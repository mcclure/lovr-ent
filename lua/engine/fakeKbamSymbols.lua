if type(jit) ~= 'table' or lovr.system.getOS() == 'Android' then return false end

local ffi = require 'ffi'
local C = ffi.C

local allowKbamSymbols = true

if allowKbamSymbols then
	ffi.cdef [[
      bool lovrHeadsetGetFakeKbamBlocked();
      void lovrHeadsetFakeKbamBlock(bool block, bool silent);
    ]]
    return {C.lovrHeadsetFakeKbamBlock, C.lovrHeadsetGetFakeKbamBlocked} -- FIXME: This is not as convenient as it could be.
end

return false
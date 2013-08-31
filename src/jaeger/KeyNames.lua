-- A table which map key codes to key names

local KeyCodes = require "jaeger.KeyCodes"
local KeyNames = {}

for name, code in pairs(KeyCodes) do
	KeyNames[code] = name
end

return KeyNames

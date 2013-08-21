return function(name, config, assetManager, oldInstance)
	local backSlashPos = name:find("/")
	local bankName = name:sub(1, backSlashPos - 1)
	local spriteName = name:sub(backSlashPos + 1)
	local bank = assetManager:getAsset("spriteBank:"..bankName)
	if bank == nil then return end
	return assert(bank.sprites[spriteName], "Unknown sprite '"..name.."'")
end

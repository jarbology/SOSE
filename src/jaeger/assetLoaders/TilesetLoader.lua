local StringUtils = require "jaeger.utils.StringUtils"

return function(name, config, assetManager, oldInstance)
	local dataFileName = config.tilesetPath..name..".lua"
	local tilesetData = assert(dofile(dataFileName), "Can't load data file for '"..name.."'")

	local sourceName = tilesetData.source
	local sourceType = StringUtils.split(tilesetData.source, ":")[1]
	if sourceType == "texture" then
		local texture = assetManager:getAsset(sourceName)
		local deck = oldInstance or MOAITileDeck2D.new()
		deck:setTexture(texture)
		deck:setSize(tilesetData.width, tilesetData.height)
		return deck, {dataFileName}
	else
		return nil, "Unsupported source type for tileset: "..sourceType
	end
end

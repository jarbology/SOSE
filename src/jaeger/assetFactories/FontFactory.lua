local StringUtils = require "jaeger.utils.StringUtils"

return function(name, config, assetManager, oldInstance)
	local fontFileName = config.fontPath..name
	assert(MOAIFileSystem.checkFileExists(fontFileName), "Can't find font file "..fontFileName)

	local font = oldInstance or MOAIFont.new()

	if StringUtils.endsWith(name, ".fnt") then
		font:loadFromBMFont(fontFileName)
	elseif StringUtils.endsWith(name, ".ttf") then
		font:load(fontFileName)
	else
		error("Unknown font type for: "..name)
	end

	return font, {fontFileName}
end

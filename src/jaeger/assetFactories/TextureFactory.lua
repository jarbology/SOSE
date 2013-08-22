return function(name, config, assetManager, oldInstance)
	local texture = oldInstance or MOAITexture.new()
	local texturePath = config.texturePath..name
	texture:load(texturePath)
	texture:setFilter(MOAITexture.GL_LINEAR)
	texture:setWrap(true)

	local w, h = texture:getSize() -- A size of 0 means failure
	if w * h ~= 0 then
		return texture, {texturePath}
	else
		return nil, "Can't load texture "..name
	end
end

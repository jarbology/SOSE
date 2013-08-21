return function(name, config, assetManager, oldInstance)
	local texture = oldInstance or MOAITexture.new()
	texture:load(config.texturePath .. name)
	texture:setFilter(MOAITexture.GL_LINEAR)
	texture:setWrap(true)
	local w, h = texture:getSize()
	if w * h ~= 0 then
		return texture
	else
		return nil, "Can't load texture "..name
	end
end

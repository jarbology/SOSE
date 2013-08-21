return function(name, config, assetManager, oldInstance)
	local dataFileName = config.spriteBankPath..name..".lua"
	if not MOAIFileSystem.checkFileExists(dataFileName) then
		return nil, "Can't find data file for "..name
	end
	local spriteBankData = assert(dofile(dataFileName), "Can't load data file for '"..name.."'")

	local atlas = assetManager:getAsset("atlas:"..spriteBankData.atlas)
	if not atlas then
		return nil, "Can't find atlas for "..atlas
	end

	local deck = oldInstance or MOAIGfxQuadDeck2D.new()
	deck:setTexture(atlas.texture)

	local numIndicies = 0
	for spriteName, spriteDef in pairs(spriteBankData.sprites) do
		local numFrames = spriteDef.numFrames or 1
		numIndicies = numIndicies + numFrames
	end
	deck:reserve(numIndicies)

	local frameDefs = atlas.frames
	local currentIndex = 1
	local sprites = {}
	for spriteName, spriteDef in pairs(spriteBankData.sprites) do
		local numFrames = spriteDef.numFrames or 1
		local xOrigin = spriteDef.xOrigin or 0
		local yOrigin = spriteDef.yOrigin or 0
		local frameFormat = spriteDef.frameFormat
		if type(frameFormat) ~= "string" then
			return nil, "Sprite "..spriteName.." of bank "..name.." has invalid frameFormat\n"
		end

		--define frames
		local firstIndex = currentIndex
		for frameIndex = 1, numFrames do
			local frameName = frameFormat:format(frameIndex)
			local frameDef = frameDefs[frameName]
			if frameDef == nil then
				return nil, "Sprite "..spriteName.." of bank "..name.." has an undefined frame: "..frameName.."\n"
			end

			local uvQuad = frameDef.uvQuad
			deck:setUVQuad(currentIndex, uvQuad.x0, uvQuad.y0, uvQuad.x1, uvQuad.y1, uvQuad.x2, uvQuad.y2, uvQuad.x3, uvQuad.y3)
			local frameHeight = frameDef.size.height
			local geomRect = frameDef.rect
			deck:setRect(currentIndex, geomRect.x0 - xOrigin, geomRect.y0 - frameHeight + yOrigin, geomRect.x1 - xOrigin, geomRect.y1 - frameHeight + yOrigin)
			currentIndex = currentIndex + 1
		end

		--create animation curve
		local animCurve = MOAIAnimCurve.new()
		local animSpeed = spriteDef.speed or 1
		local timeStep = 1 / animSpeed
		local curveMode
		local animMode = spriteDef.mode or "once"
		animCurve:setWrapMode(MOAIAnimCurve.WRAP)
		if animMode == "once" then
			animCurve:reserveKeys(numFrames)
			local time = 0
			for frameIndex = 1, numFrames do
				animCurve:setKey(frameIndex, time, firstIndex - 1 + frameIndex, MOAIEaseType.FLAT)
				time = time + timeStep
			end
			curveMode = MOAITimer.NORMAL
		elseif animMode == "pingpong" then
			animCurve:reserveKeys(numFrames * 2 - 2)
			local time = 0
			for frameIndex = 1, numFrames do
				animCurve:setKey(frameIndex, time, firstIndex - 1 + frameIndex, MOAIEaseType.FLAT)
				time = time + timeStep
			end
			for frameIndex = 1, numFrames - 2 do
				animCurve:setKey(numFrames + frameIndex, time, numFrames - frameIndex, MOAIEaseType.FLAT)
				time = time + timeStep
			end
			curveMode = MOAITimer.LOOP
		elseif animMode == "loop" then
			animCurve:reserveKeys(numFrames + 1)
			local time = 0
			for frameIndex = 1, numFrames do
				animCurve:setKey(frameIndex, time, firstIndex - 1 + frameIndex, MOAIEaseType.FLAT)
				time = time + timeStep
			end
			animCurve:setKey(numFrames + 1, time, firstIndex, MOAIEaseType.FLAT)
			curveMode = MOAITimer.LOOP
		else
			return nil, "Sprite "..spriteName.." of bank "..name.." use unknown play mode: "..tostring(animMode).."\n"
		end

		sprites[spriteName] = {
			firstFrame = firstIndex,
			speed = animSpeed,
			animCurve = animCurve,
			mode = curveMode,
			bank = deck
		}
	end

	deck.sprites = sprites

	return deck
end

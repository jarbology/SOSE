return function(name, config, assetManager, oldInstance)
	local dataFileName = config.spriteBankPath..name..".lua"
	local spriteBankData = assert(dofile(dataFileName), "Can't load data file for '"..name.."'")

	local atlas = assetManager:getAsset("atlas:"..spriteBankData.atlas)

	local deck = oldInstance or MOAIGfxQuadDeck2D.new()
	deck:setTexture(atlas.texture)

	-- Since assertion messages for this factory is quite long
	local function assert(cond, spriteName, msg)
		return _G.assert(cond, "Sprite "..spriteName.." of bank "..name.." "..msg)
	end

	-- Count the number of frames
	local numIndicies = 0
	for spriteName, spriteDef in pairs(spriteBankData.sprites) do
		local numFrames = assert(spriteDef.numFrames, spriteName, "does not provide number of frames")
		numIndicies = numIndicies + numFrames
	end
	deck:reserve(numIndicies)

	local frameDefs = atlas.frames
	local currentIndex = 1
	local sprites = deck.sprites or {}
	for spriteName, spriteDef in pairs(spriteBankData.sprites) do
		local numFrames = spriteDef.numFrames or 1
		local xOrigin = spriteDef.xOrigin or 0
		local yOrigin = spriteDef.yOrigin or 0
		local frameFormat = spriteDef.frameFormat
		assert(type(frameFormat) == "string", spriteName, "has invalid frame format")

		--define frames
		local firstIndex = currentIndex
		for frameIndex = 1, numFrames do
			local frameName = frameFormat:format(frameIndex)
			local frameDef = assert(frameDefs[frameName], spriteName, "has an undefined frame: "..frameName)

			local uvQuad = frameDef.uvQuad
			deck:setUVQuad(
				currentIndex,
				uvQuad.x0,
				uvQuad.y0,
				uvQuad.x1,
				uvQuad.y1,
				uvQuad.x2,
				uvQuad.y2,
				uvQuad.x3,
				uvQuad.y3
			)
			local frameHeight = frameDef.size.height
			local geomRect = frameDef.rect
			deck:setRect(
				currentIndex,
				geomRect.x0 - xOrigin,
				geomRect.y0 - frameHeight + yOrigin,
				geomRect.x1 - xOrigin,
				geomRect.y1 - frameHeight + yOrigin
			)
			currentIndex = currentIndex + 1
		end

		--create animation curve
		local sprite = sprites[spriteName] or {}
		local animCurve = sprite.animCurve or MOAIAnimCurve.new()
		local animTime = assert(spriteDef.time, spriteName, "does not provide animation time")
		local timeStep = 1 / numFrames
		local curveMode
		local animMode = spriteDef.mode or "once"
		animCurve:setWrapMode(MOAIAnimCurve.WRAP)
		animCurve:reserveKeys(numFrames + 1)
		local time = 0
		for frameIndex = 1, numFrames do
			animCurve:setKey(frameIndex, time, firstIndex - 1 + frameIndex, MOAIEaseType.FLAT)
			time = time + timeStep
		end
		animCurve:setKey(numFrames + 1, time, firstIndex, MOAIEaseType.FLAT)

		if animMode == "once" then
			curveMode = MOAITimer.NORMAL
		elseif animMode == "pingpong" then
			curveMode = MOAITimer.PING_PONG
		elseif animMode == "loop" then
			curveMode = MOAITimer.LOOP
		else
			return nil, "Sprite "..spriteName.." of bank "..name.." use unknown play mode: "..tostring(animMode).."\n"
		end

		sprite.firstFrame = firstIndex
		sprite.animTime = animTime
		sprite.numFrames = numFrames
		sprite.animCurve = animCurve
		sprite.mode = curveMode
		sprite.bank = deck

		sprites[spriteName] = sprite
	end

	deck.sprites = sprites

	return deck, {dataFileName}
end

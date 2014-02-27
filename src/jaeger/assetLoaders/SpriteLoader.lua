return function(name, config, assetManager, oldInstance)
	local dataFileName = config.spriteBankPath..name..".lua"
	local spriteDef = assert(dofile(dataFileName), "Can't load data file for '"..name.."'")

	local atlas = assetManager:getAsset("atlas:"..spriteDef.atlas)

	local deck = oldInstance or MOAIGfxQuadDeck2D.new()
	deck:setTexture(atlas.texture)

	local numFrames = spriteDef.numFrames or 1
	deck:reserve(numFrames)

	local xOrigin = spriteDef.xOrigin or 0
	local yOrigin = spriteDef.yOrigin or 0
	local frameFormat = assert(spriteDef.frameFormat, "Sprite "..name.." does not provide frame format")
	assert(type(frameFormat) == "string", "Sprite "..name.. " has invalid frame format")

	--define frames
	local frameDefs = atlas.frames
	for frameIndex = 1, numFrames do
		local frameName = frameFormat:format(frameIndex)
		local frameDef = assert(frameDefs[frameName], "Sprite "..name.." has an undefined frame: "..frameName)

		local uvQuad = frameDef.uvQuad
		deck:setUVQuad(
			frameIndex,
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
			frameIndex,
			geomRect.x0 - xOrigin,
			geomRect.y0 + yOrigin,
			geomRect.x1 - xOrigin,
			geomRect.y1 + yOrigin
		)
	end

	--create animation curve
	local animCurve = deck.animCurve or MOAIAnimCurve.new()
	local animTime = spriteDef.time or 1.0
	local timeStep = 1 / numFrames
	local curveMode
	local animMode = spriteDef.mode or "once"
	animCurve:setWrapMode(MOAIAnimCurve.WRAP)
	animCurve:reserveKeys(numFrames + 1)
	local time = 0
	for frameIndex = 1, numFrames do
		animCurve:setKey(frameIndex, time, frameIndex, MOAIEaseType.FLAT)
		time = time + timeStep
	end
	animCurve:setKey(numFrames + 1, time, 1, MOAIEaseType.FLAT)

	if animMode == "once" then
		curveMode = MOAITimer.NORMAL
	elseif animMode == "pingpong" then
		curveMode = MOAITimer.PING_PONG
	elseif animMode == "loop" then
		curveMode = MOAITimer.LOOP
	else
		return nil, "Sprite "..spriteName.." of bank "..name.." use unknown play mode: "..tostring(animMode).."\n"
	end

	deck.animTime = animTime
	deck.numFrames = numFrames
	deck.animCurve = animCurve
	deck.mode = curveMode

	return deck, {dataFileName}
end

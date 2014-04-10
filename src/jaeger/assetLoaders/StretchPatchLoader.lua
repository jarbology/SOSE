return function(name, config, assetManager, oldInstance)
	local dataFileName = config.stretchPatchPath..name..".lua"
	local stretchPatchData = assert(dofile(dataFileName), "Can't load data file for "..name)

	local atlas = assetManager:getAsset("atlas:"..stretchPatchData.atlas)
	local deck = oldInstance or MOAIStretchPatch2D.new()
	deck:setTexture(atlas.texture)

	local cols = stretchPatchData.cols
	deck:reserveColumns(#cols)
	for colIndex, colSpecs in ipairs(cols) do
		deck:setColumn(colIndex, unpack(colSpecs))
	end

	local rows = stretchPatchData.rows
	deck:reserveRows(#rows)
	for rowIndex, rowSpecs in ipairs(rows) do
		deck:setRow(rowIndex, unpack(rowSpecs))
	end

	local frameName = stretchPatchData.frameName
	local frameDef = assert(atlas.frames[frameName], "StretchPatch "..name.." refers to an undefined frame: "..frameName)
	assert(not frameDef.textureRotated, "StretchPatch "..name.." uses a rotated frame")
	deck:reserveUVRects(1)
	local uvRect = frameDef.uvRect
	deck:setUVRect(1, uvRect.u0, uvRect.v1, uvRect.u1, uvRect.v0)

	local geomRect = frameDef.rect
	local xOriginName, yOriginName = stretchPatchData.xOrigin, stretchPatchData.yOrigin
	local xOrigin, yOrigin
	if xOriginName == "left" then
		xOrigin = 0
	elseif xOriginName == "center" then
		xOrigin = (geomRect.x0 + geomRect.x1) / 2
	elseif xOriginName == "right" then
		xOrigin = geomRect.x1
	else
		error("StretchPatch "..name.." has unknown xOrigin:"..xOriginName)
	end

	if yOriginName == "top" then
		yOrigin = 0
	elseif yOriginName == "center" then
		yOrigin = (geomRect.y0 + geomRect.y1) / 2
	elseif yOriginName == "bottom" then
		yOrigin = geomRect.y0
	else
		error("StretchPatch "..name.." has unknown yOrigin:"..yOriginName)
	end

	deck:setRect(
		geomRect.x0 - xOrigin,
		geomRect.y0 - yOrigin,
		geomRect.x1 - xOrigin,
		geomRect.y1 - yOrigin
	)

	return deck, {dataFileName}
end

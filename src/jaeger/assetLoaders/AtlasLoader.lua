return function(name, config, assetManager, oldInstance)
	local dataFileName = config.atlasPath..name..".lua"
	local atlasData = assert(dofile(dataFileName), "Can't load data file for "..name)

	local texture = assetManager:getAsset("texture:"..atlasData.texture)

	local frames = {}
	for _, frame in ipairs(atlasData.frames) do
		-- convert frame.uvRect to frame.uvQuad to handle rotation
		local uv = frame.uvRect
		local q = {}
		if not frame.textureRotated then
			-- From Moai docs: "Vertex order is clockwise from upper left (xMin, yMax)"
			q.x0, q.y0 = uv.u0, uv.v0
			q.x1, q.y1 = uv.u1, uv.v0
			q.x2, q.y2 = uv.u1, uv.v1
			q.x3, q.y3 = uv.u0, uv.v1
		else
			-- Sprite data is rotated 90 degrees CW on the texture
			-- u0v0 is still the upper-left
			q.x3, q.y3 = uv.u0, uv.v0
			q.x0, q.y0 = uv.u1, uv.v0
			q.x1, q.y1 = uv.u1, uv.v1
			q.x2, q.y2 = uv.u0, uv.v1
		end

		-- convert frame.spriteColorRect and frame.spriteSourceSize
		-- to frame.geomRect.  Origin is at x0,y0 of original sprite
		local cr = frame.spriteColorRect
		local r = {}
        r.x0 = cr.x
        r.y0 = -cr.y - cr.height
        r.x1 = cr.x + cr.width
        r.y1 = -cr.y

		frames[frame.name] = { uvQuad = q, rect = r, size = frame.spriteSourceSize  }
	end

	local asset = oldInstance or {}
	asset.texture = texture
	asset.frames = frames
	return asset, {dataFileName}
end

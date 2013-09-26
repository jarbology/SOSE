local class = require "jaeger.Class"
local Grid = require "jaeger.Grid"
local Set = require "jaeger.Set"

-- A zone for a player
return class(..., function(i, c)
	local MAP_PADDING = 20

	-- params is a table with the following keys:
	-- * suffix: 1 or 2
	-- * viewport: viewport for this zone
	-- * map: an ascii map of this zone
	-- * renderTable: the render table to populate
	-- * layerMap: the layer map to populate
	function i:__constructor(params)
		local layerNames = {
			"background",
			"ground",
			"building",
			"projectile",
			"artificialFog",
			"fog"
		}

		local layers = {}
		local layerMap = params.layerMap
		local renderTable = params.renderTable
		local viewport = params.viewport
		local suffix = params.suffix
		local camera = MOAICamera2D.new()
		for _, layerName in ipairs(layerNames) do
			local layer = MOAILayer2D.new()
			layer:setSortMode(MOAILayer2D.SORT_NONE)
			layer:setViewport(viewport)
			layer:setCamera(camera)
			table.insert(renderTable, layer)
			layerMap[layerName..suffix] = layer
			layers[layerName] = layer
		end

		self.camera = camera
		self.suffix = suffix
		self.layers = layers

		local map = params.map
		local mapWidth, mapHeight = c.getMapSize(map)
		local zoneWidth, zoneHeight = mapWidth + MAP_PADDING * 2, mapHeight + MAP_PADDING * 2
		self.objectGrids = {
			missiles = c.newSetGrid(zoneWidth, zoneHeight),
			bots = c.newSetGrid(zoneWidth, zoneHeight)
		}
		self.buildingGrid = Grid.new(zoneWidth, zoneHeight)
		self.groundGrid = Grid.new(zoneWidth, zoneHeight)
		self.zoneWidth = zoneWidth
		self.zoneHeight = zoneHeight
		self.map = map

		c.forEachCellInMap(map, function(x, y, filled)
			self.groundGrid:set(x, y, true)
		end)
	end

	-- Initialize the tilemaps using an entity manager
	function i:init(entityMgr)
		local map = self.map
		entityMgr:createEntity{
			["jaeger.Renderable"] = {
				layer = "background"..self.suffix
			},

			["jaeger.Background"] = {
				texture = "bg1.png",
				width = 4000,
				height = 4000
			}
		}

		local zoneWidth, zoneHeight = self.zoneWidth, self.zoneHeight
		local grid = MOAIGrid.new()
		grid:setSize(zoneWidth, zoneHeight, 64, 64)
		c.setGrid(grid, self.map, 5)
		local centerX, centerY = grid:getTileLoc(self.zoneWidth / 2, self.zoneHeight / 2)

		local ground = entityMgr:createEntity{
			["jaeger.Renderable"] = {
				layer = "ground"..self.suffix,
				x = -centerX,
				y = -centerY
			},

			["jaeger.Tilemap"] = {
				tileset = "ground",
				grid = grid
			}
		}

		local grid = MOAIGrid.new()
		local suffix = self.suffix
		grid:setSize(zoneWidth, zoneHeight, 64, 64)
		c.setGrid(grid, self.map, 2)

		local fog = entityMgr:createEntity{
			["jaeger.Renderable"] = {
				layer = "ground"..self.suffix,
				x = -centerX,
				y = -centerY
			},

			["jaeger.Tilemap"] = {
				tileset = "fog",
				grid = grid
			}
		}
	end

	function i:addBuilding(x, y, building)
		assert(self.buildingGrid:get(x, y) == nil, "There is already a building at ("..x..","..y..")")
		self.buildingGrid:set(x, y, building)
	end

	function i:removeBuildingAt(x, y)
		self.buildingGrid:set(x, y)
	end

	function i:getBuildingAt(x, y)
		return buildingGrid:get(x, y)
	end

	function i:addGridWalker(gridName, x, y, obj)
		local grid = assert(self.objectGrids[gridName], "Unknown grid: "..gridName)
		grid:get(x, y):add(obj)
	end

	function i:removeGridWalker(gridName, x, y, obj)
		local grid = assert(self.objectGrids[gridName], "Unknown grid: "..gridName)
		grid:get(x, y):remove(obj)
	end

	function i:moveGridWalker(gridName, oldX, oldY, newX, newY, obj)
		self:removeGridWalker(gridName, oldX, oldY, obj)
		self:addGridWalker(gridName, newX, newY, obj)
	end

	function i:pickFirstObjectAt(gridName, x, y, predicate)
		local set = self.objectGrids[gridName]:get(x, y)
		set:beginIteration()
		for _, object in set:iterator() do
			if predicate(object) then
				return object
			end
		end
		set:endIteration()
	end

	function i:isCellVisible(x, y)
		return self.layers.fog:getTile(x, y) == 0
	end

	-- Remove fog around an area
	function i:reveal(xMin, xMax, yMin, yMax)
		local fog = self.layers.fog
		for x = xMin, xMax do
			for y = yMin, yMax do
				-- Clear fog
				fog:setTile(x, y, 0)

				-- Make buildings visible
				local building = self:getBuildingAt(x, y)
				if building then
					building:sendMessage("msgReveal")
				end
			end
		end
	end

	function i:getCamera()
		return self.camera
	end

	-- Private
	
	function c.getMapSize(map)
		return #(map[1]), #map
	end

	function c.newSetGrid(width, height)
		local grid = Grid.new(width, height)
		for x = 1, width do
			for y = 1, height do
				grid:set(x, y, Set.new())
			end
		end
		return grid
	end

	function c.forEachCellInMap(map, func)
		local o = ("o"):byte()
		for y, row in ipairs(map) do
			local rowWidth = #row
			for x = 1, rowWidth do
				local filled = row:byte(x) == o
				func(x + MAP_PADDING, y + MAP_PADDING, filled)
			end
		end
	end

	function c.setGrid(grid, map, oValue)
		c.forEachCellInMap(map, function(x, y, filled)
			if filled then
				grid:setTile(x, y, oValue)
			end
		end)
	end
end)
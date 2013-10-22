local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local Grid = require "jaeger.Grid"
local Set = require "jaeger.Set"

-- A zone for a player
return class(..., function(i, c)
	local MAP_PADDING = 20
	local TILE_WIDTH = 64
	local TILE_HEIGHT = 64

	-- params is a table with the following keys:
	-- * suffix: 1 or 2
	-- * viewport: viewport for this zone
	-- * map: an ascii map of this zone
	-- * renderTable: the render table to populate
	-- * layerMap: the layer map to populate
	function i:__constructor(params)
		self.tileClicked = Event.new()

		local layerNames = {
			"background",
			"ground",
			"building",
			"projectile",
			"artificialFog",
			"fog"
		}

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
		end
		self.refLayer = layerMap["ground"..suffix]--for object picking

		self.camera = camera
		self.suffix = suffix

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

		c.forEachTileInMap(map, function(x, y, filled)
			self.groundGrid:set(x, y, filled)
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
		grid:setSize(zoneWidth, zoneHeight, TILE_WIDTH, TILE_HEIGHT)
		c.setGrid(grid, self.map, 5)
		local centerX, centerY = grid:getTileLoc(self.zoneWidth / 2, self.zoneHeight / 2)
		self.centerX = centerX
		self.centerY = centerY
		self.refGrid = grid -- for object picking

		local ground = entityMgr:createEntity{
			"jaeger.InputReceiver",
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
		self.groundProp = ground:query("getProp")

		local grid = MOAIGrid.new()
		local suffix = self.suffix
		grid:setSize(zoneWidth, zoneHeight, TILE_WIDTH, TILE_HEIGHT)
		--c.setGrid(grid, self.map, 2)
		self.fogGrid = grid

		local fog = entityMgr:createEntity{
			["jaeger.Renderable"] = {
				layer = "fog"..self.suffix,
				x = -centerX,
				y = -centerY
			},

			["jaeger.Tilemap"] = {
				tileset = "fog",
				grid = grid
			}
		}
	end

	function i:wndToTile(wndX, wndY)
		local worldX, worldY = self.refLayer:wndToWorld(wndX, wndY)
		return self.refGrid:locToCoord(
			self.groundProp:worldToModel(worldX, worldY)
		)
	end

	function i:getTileLoc(x, y)
		local x, y = self.refGrid:getTileLoc(x, y)
		return x - self.centerX, y - self.centerX
	end

	function i:addBuilding(x, y, building)
		assert(self.buildingGrid:get(x, y) == nil, "There is already a building at ("..x..","..y..")")
		self.buildingGrid:set(x, y, building)
	end

	function i:removeBuildingAt(x, y)
		self.buildingGrid:set(x, y)
	end

	function i:getBuildingAt(x, y)
		return self.buildingGrid:get(x, y)
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

	function i:isTileVisible(x, y)
		return self.fogGrid:getTile(x, y) == 0
	end

	function i:isTileGround(x, y)
		return self.groundGrid:get(x, y) == true
	end

	-- Remove fog around an area
	function i:reveal(xMin, xMax, yMin, yMax)
		local fog = self.fogGrid
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
	
	function i:onTileClicked(x, y)
		local x, y = self.refGrid:locToCoord(
			self.groundProp:worldToModel(x, y)
		)
		self.tileClicked:fire(self, x, y)
	end
	
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

	function c.forEachTileInMap(map, func)
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
		c.forEachTileInMap(map, function(x, y, filled)
			if filled then
				grid:setTile(x, y, oValue)
			end
		end)
	end
end)

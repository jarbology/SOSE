local class = require "jaeger.Class"
local Event = require "jaeger.Event"
local Grid = require "jaeger.Grid"
local Set = require "jaeger.Set"
local Property = require "jaeger.Property"
local NetworkCommand = require "NetworkCommand"
local BuildingType = require "BuildingType"
local BuildingSpecs = require "buildingSpecs"
local WeaponQueue = require "WeaponQueue"
local WeaponType = require "WeaponType"
local Quadrant = require "Quadrant"

-- A zone for a player
return class(..., function(i, c)
	local MAP_PADDING = 20
	local TILE_WIDTH = 64
	local TILE_HEIGHT = 64
	local LAYERS = {
		"ground",
		"building",
		"overlay",
		"fog",
		"projectile"
	}

	--map: an ascii map of this zone
	function i:__constructor(data)
		local viewport = data.viewport
		local map = data.map

		local renderTable = {}
		local layers = {}
		local camera = MOAICamera2D.new()

		for index, layerName in ipairs(LAYERS) do
			local layer = MOAILayer2D.new()
			layer:setViewport(viewport)
			layer:setCamera(camera)
			layer:setSortMode(MOAILayer2D.SORT_Y_DESCENDING)
			layers[layerName] = layer
			renderTable[index] = layer
		end

		self.resource = Property.new(2000)
		self.layers = layers
		self.renderTable = renderTable
		self.refLayer = layers.ground -- for object picking
		self.camera = camera
		self.map = map

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

		c.forEachTileInMap(map, function(x, y, filled)
			self.groundGrid:set(x, y, filled)
		end)

		--Weapon queues
		self.weaponQueues = {
			rocket = WeaponQueue.new(),
			rocket2 = WeaponQueue.new(),
			robot = WeaponQueue.new(),
			robot2 = WeaponQueue.new()
		}
	end

	function i:msgLinkZone(opposingZone)
		self.opposingZone = opposingZone:query("getZoneComponent")
		local map = self.map

		local zoneWidth, zoneHeight = self.zoneWidth, self.zoneHeight
		local grid = MOAIGrid.new()
		grid:setSize(zoneWidth, zoneHeight, TILE_WIDTH, TILE_HEIGHT)
		c.setGrid(grid, self.map, 5)
		local centerX, centerY = grid:getTileLoc(self.zoneWidth / 2, self.zoneHeight / 2)
		self.refGrid = grid -- for object picking

		local ground = createEntity{
			{"jaeger.Renderable", layer=self.layers.ground, x=-centerX, y=-centerY},
			{"jaeger.Tilemap", tileset="ground", grid=grid},
			{"jaeger.Widget"},
			{"Ground", zone=self.entity}
		}
		self.groundProp = ground:query("getProp")

		local grid = MOAIGrid.new()
		grid:setSize(zoneWidth, zoneHeight, TILE_WIDTH, TILE_HEIGHT)
		c.setGrid(grid, self.map, 2)
		self.fog = createEntity{
			{"jaeger.Renderable", layer=self.layers.fog, x=-centerX, y=-centerY},
			{"jaeger.Tilemap", tileset="fog", grid=grid},
			{"Fog", zone=self.entity}
		}
		self.fogGrid = grid
	end

	function i:msgNetworkCommand(cmdCode, ...)
		local cmdName = NetworkCommand.codeToName(cmdCode)
		local handler = assert(self[cmdName], "Unknown command "..tostring(cmdCode))
		return handler(self, ...)
	end

	function i:getWeaponQueue(name)
		return self.weaponQueues[name]
	end

	-- Return how much resources this zone have
	function i:getResource()
		return self.resource
	end

	-- Add or remove resource
	function i:changeResource(delta)
		local res = self.resource
		res:set(res:get() + delta)
	end

	-- Return (width, height) of the zone
	function i:getSize()
		return self.zoneWidth, self.zoneHeight
	end

	-- Return the zone's render table
	function i:getRenderTable()
		return self.renderTable
	end

	-- Convert window coordinate to tile coordinate
	function i:wndToTile(wndX, wndY)
		local worldX, worldY = self.refLayer:wndToWorld(wndX, wndY)
		return self.refGrid:locToCoord(
			self.groundProp:worldToModel(worldX, worldY)
		)
	end

	function i:getLayer(name)
		return assert(self.layers[name], "Unknown layer "..tostring(name))
	end

	-- Convert tile coordinate to world coordinate
	function i:getTileLoc(x, y)
		local x, y = self.refGrid:getTileLoc(x, y)
		return self.groundProp:modelToWorld(x, y)
	end

	-- Convert world coordinate to window coordinate
	function i:worldToWnd(x, y)
		return self.refLayer:worldToWnd(x, y)
	end

	-- Add a building at a given location
	function i:addBuilding(x, y, building)
		assert(self.buildingGrid:get(x, y) == nil, "There is already a building at ("..x..","..y..")")
		self.buildingGrid:set(x, y, building)
	end

	-- Remove a building at a given location
	function i:removeBuildingAt(x, y)
		self.buildingGrid:set(x, y)
	end

	-- Return a building at a given location (or nil)
	function i:getBuildingAt(x, y)
		return self.buildingGrid:get(x, y)
	end

	-- Add a projectile to a given grid
	-- Valid values for gridName: missiles, bots
	function i:addProjectile(gridName, x, y, obj)
		local grid = assert(self.objectGrids[gridName], "Unknown grid: "..gridName)
		grid:get(x, y):add(obj)
	end

	-- Remove a projectile from a grid
	function i:removeProjectile(gridName, x, y, obj)
		local grid = assert(self.objectGrids[gridName], "Unknown grid: "..gridName)
		grid:get(x, y):remove(obj)
	end

	-- Move a projectile in a grid
	function i:moveProjectile(gridName, oldX, oldY, newX, newY, obj)
		self:removeProjectile(gridName, oldX, oldY, obj)
		self:addProjectile(gridName, newX, newY, obj)
	end

	-- Return the firt object at a grid which satisfies a predicate
	-- gridName: "bots" | "projectile"
	-- x, y: coordinate to pick
	-- predicate: function(obj) -> boolean
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

	-- Check whether a tile is visible
	function i:isTileVisible(x, y)
		return self.fogGrid:getTile(x, y) == 0
	end

	-- Check whether a tile is ground (or space)
	function i:isTileGround(x, y)
		return self.groundGrid:get(x, y) == true
	end

	-- Remove fog around an area and reveal all buildings
	function i:msgReveal(xMin, xMax, yMin, yMax)
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

	function i:getZoneComponent()
		return self
	end

	function i:getCamera()
		return self.camera
	end

	-- Private
	-- Network commands
	function i:cmdBuild(buildingCode, tileX, tileY)
		local buildingName = BuildingType.codeToName(buildingCode)
		local buildingSpec = BuildingSpecs[buildingName]
		print("Build", buildingName, tileX, tileY)

		local hasEnoughResource = self.resource:get() >= buildingSpec.cost
		local isGround = self:isTileGround(tileX, tileY)
		local tileEmpty = self:getBuildingAt(tileX, tileY) == nil

		if hasEnoughResource and isGround and tileEmpty then
			self:changeResource(-buildingSpec.cost)
			local building = createEntity(buildingSpec.entitySpec, {
				["jaeger.Renderable"] = {layer=self.layers.building},
				["Building"] = {zone=self, x=tileX, y=tileY}
			})

			--Create health bar for building
			createEntity{
				{"jaeger.Renderable", layer=self.layers.overlay},
				{"ProgressBar", width=44, height=6, backgroundColor={1, 0, 0}, foregroundColor={0, 1, 0}, borderThickness=1},
				{"HealthBar", subject=building}
			}
		end
	end

	function i:cmdAttack(weaponCode, targetX, targetY, quadrantCode)
		local queueName = WeaponType.codeToName(weaponCode)
		local weaponQueue = self.weaponQueues[queueName]
		local quadrant = Quadrant.codeToName(quadrantCode)
		if weaponQueue:getSize():get() > 0 then--enough weapon
			local building = weaponQueue:dequeue()
			building:sendMessage("msgAttack", self.opposingZone, targetX, targetY, quadrant)
		end
	end

	-- Static
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

local class = require "jaeger.Class"
local Grid = require "jaeger.Grid"
local Set = require "jaeger.Set"

-- A zone for a player
return class(..., function(i, c)
	-- suffix: 1 or 2
	-- viewport: viewport
	-- zoneWidth
	-- zoneHeight
	-- map
	-- renderTable
	-- layerMap
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
		self.map = params.map
		self.zoneWidth = params.zoneWidth
		self.zoneHeight = params.zoneHeight
		self.layers = layers
		self.grids = {
			buildings = Grid.new(),
			projectiles = Grid.new(),
			bots = Grid.new()
		}
	end

	function i:init(entityMgr)
		local map = self.map
		local zoneWidth, zoneHeight = 36, 36
		local xOffset = math.floor((self.zoneWidth - #(map[1]))/ 2)
		local yOffset = math.floor((self.zoneHeight - #map)/ 2)
		entityMgr:createEntity{
			components = {
				["jaeger.Renderable"] = {
					layer = "background"..self.suffix
				},

				["jaeger.Background"] = {
					texture = "bg1.png",
					width = 4000,
					height = 4000
				}
			}
		}

		local grid = MOAIGrid.new()
		grid:setSize(zoneWidth, zoneHeight, 64, 64)
		c.setGrid(grid, self.map, xOffset, yOffset, 5)

		local ground = entityMgr:createEntity{
			components = {
				["jaeger.Renderable"] = {
					layer = "ground"..self.suffix,
					xScale = 1,
					yScale = 1
				},

				["jaeger.Tilemap"] = {
					tileset = "ground",
					grid = grid
				}
			}
		}

		local grid = MOAIGrid.new()
		local suffix = self.suffix
		grid:setSize(zoneWidth, zoneHeight, 64, 64)
		c.setGrid(grid, self.map, xOffset, yOffset, 2)

		local fog = entityMgr:createEntity{
			components = {
				["jaeger.Renderable"] = {
					layer = "ground"..self.suffix,
					xScale = 1,
					yScale = 1
				},

				["jaeger.Tilemap"] = {
					tileset = "fog",
					grid = grid
				}
			}
		}

		self.camera:setLoc(grid:getTileLoc(self.zoneWidth / 2, self.zoneHeight / 2))
	end

	function i:getCamera()
		return self.camera
	end

	function c.setGrid(grid, map, xOffset, yOffset, oValue)
		local o = ("o"):byte()
		for y, row in ipairs(map) do
			local rowWidth = #row
			for x = 1, rowWidth do
				local value
				if row:byte(x) == o then
					value = oValue
				else
					value = 0
				end
				grid:setTile(x + xOffset, y + yOffset, value)
			end
		end
	end
end)

local class = require "jaeger.Class"

-- A menu which arranges its entries in a circle
-- Parameters:
-- * radius: radius of the menu
-- * itemRadius: radius of each item
-- * receiver: the entity which receives click event, default to the owner of this component
-- * message: the message to send when an item is chosen, default to "msgItemClicked"
-- * id: arbitrary value to identify this menu
-- * backgroundSprite: what to draw in the background
return class(..., function(i, c)
	function i:__constructor(data)
		self.radius = data.radius
		self.itemRadius = data.itemRadius
		self.receiver = data.receiver
		self.message = data.message
		self.id = data.id
		self.backgrounds = {}
		self.items = {}
		self.numItems = 0
		self.backgroundSprite = assert(data.backgroundSprite, "No backgroundSprite")
	end

	function i:msgActivate()
		local prop = self.entity:query("getProp")
		prop:setPriority(2)
		prop:setVisible(false)
		self.prop = prop
	end

	local LINK_SPEC = {
		{ MOAIProp2D.INHERIT_LOC,    MOAIProp2D.TRANSFORM_TRAIT },
		{ MOAIColor.INHERIT_COLOR,  MOAIColor.COLOR_TRAIT },
		{ MOAIProp2D.INHERIT_VISIBLE,   MOAIProp2D.ATTR_VISIBLE }
	}

	-- Make the menu display a list of items
	-- itemDescs(table): Description of each item
	--     * id: arbitrary value to identify an entry
	--     * sprite: icon for the entry
	function i:msgSetItems(itemDescs)
		local layer = self.entity:query("getLayer")
		local numItems = #itemDescs
		local angleStep = - math.pi * 2 / numItems
		local angle = math.pi / 2
		local radius = self.radius
		local items = self.items
		local backgrounds = self.backgrounds

		-- destroy old items
		for i = 1, self.numItems do
			destroyEntity(items[i])
			destroyEntity(backgrounds[i])
		end
		self.numItems = 0

		for i, itemDesc in ipairs(itemDescs) do
			local x = radius * math.cos(angle)
			local y = radius * math.sin(angle)

			local itemBackground = createEntity{
				{"jaeger.Actor", phase = "gui"},
				{"jaeger.Renderable", layer = layer, x = x, y = y},
				{"jaeger.Sprite", spriteName = self.backgroundSprite},
				{"jaeger.Widget"},
				{"Button", id = itemDesc.id, receiver = self.entity, message = "msgItemClicked"}
			}
			itemBackground:query("getProp"):setPriority(3)
			self.entity:sendMessage("msgAttach", itemBackground, LINK_SPEC)

			local item = createEntity{
				{"jaeger.Renderable", layer = layer},
				{"jaeger.Sprite", spriteName = itemDesc.sprite}
			}
			item:query("getProp"):setPriority(4)
			itemBackground:sendMessage("msgAttach", item, LINK_SPEC)

			items[i] = item
			backgrounds[i] = itemBackground
			angle = angle + angleStep
		end

		self.numItems = numItems
	end

	-- Show the menu at a given coordinate
	function i:msgShow(x, y, items)
		if items ~= nil then self:msgSetItems(items) end

		local prop = self.prop
		prop:setLoc(x, y)
		prop:setColor(1, 1, 1, 0)
		prop:setScl(0)
		prop:setVisible(true)

		self.entity:sendMessage("msgPerformAction", self.prop:seekColor(1, 1, 1, 1, 0.4))
		self.entity:sendMessage("msgPerformAction", self.prop:seekScl(1, 1, 0.4))
	end

	-- Hide the menu
	function i:msgHide()
		self.entity:sendMessage("msgPerformAction", self.prop:seekColor(1, 1, 1, 0, 0.4))
		local action = self.prop:seekScl(0, 0, 0.4)
		self.entity:sendMessage("msgPerformAction", action)
		action:setListener(MOAIAction.EVENT_STOP,
			function()
				self.prop:setVisible(false)
				self.prop:setLoc(2000, 2000)
			end)
	end

	function i:msgItemClicked(id)
		local receiver = self.receiver or self.entity
		receiver:sendMessage(self.message, id, self.id)
		self:msgHide()
	end
end)

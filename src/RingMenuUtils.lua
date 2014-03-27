local class = require "jaeger.Class"

return class(..., function(i, c)
	local instance
	local layer

	function c.create(entityMgr, GUILayer)
		instance = entityMgr:createEntity{
			{"jaeger.Renderable", layer=GUILayer, x=2000, y=2000},
			{"jaeger.Sprite", spriteName="ui/radialMenu/ring"},
			{"jaeger.Widget"},
			{"RingMenu",
				radius=122,
				itemRadius=35,
				backgroundSprite="ui/radialMenu/button",
				message="msgItemChosen"
			}
		}
		layer = GUILayer
	end

	function c.show(entries, wndX, wndY, receiver)
		instance:sendMessage("msgSetEventReceiver", receiver)
		local worldX, worldY = layer:wndToWorld(wndX, wndY)
		instance:sendMessage("msgShow", worldX, worldY, entries)
	end
	
	function c.hide()
		instance:sendMessage("msgHide")
	end
end)

local class = require "jaeger.Class"

return class(..., function(i, c)
	local currentWindow
	local entityMgr

	function c.init(entityManager)
		entityMgr = entityManager
	end

	function c.createWindow(layer)
		local window = entityMgr:createEntity{
			{"jaeger.Renderable", layer=layer, y = -10, xScale = 1.2, yScale=1.3},
			{"jaeger.StretchPatch", name="dialog"},
			{"jaeger.Widget"}
		}
		window:query("getProp"):setBounds(-1000, -1000, -1, 1000, 1000, 1)

		return window
	end

	function c.showInfoPopup(layer, text, callback)
		currentWindow = c.createWindow(layer)
		local contentText = entityMgr:createEntity{
			{"jaeger.Renderable", layer=layer},
			{"jaeger.Text", text=text,
			                rect={-85, -25, 85, 25},
			                font="karmatic_arcade.ttf",
			                alignment = {MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY},
			                size=15},
			{"Button"},
			{"jaeger.InlineScript",
				msgOnClick = function()
					if callback then
						callback()
					end
				end
			}
		}
		contentText:link(currentWindow)
	end

	function c.hidePopup()
		if currentWindow then
			entityMgr:destroyEntity(currentWindow)
			currentWindow = nil
		end
	end
end)

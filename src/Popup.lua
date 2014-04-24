local class = require "jaeger.Class"

return class(..., function(i, c)
	local currentWindow
	local entityMgr
	local layer

	function c.init(entityManager, guiLayer)
		entityMgr = entityManager
		layer = guiLayer
	end

	function c.createWindow(callback)
		local window = entityMgr:createEntity{
			{"jaeger.Renderable", layer=layer, y = -10, xScale = 1.2, yScale=1.3},
			{"jaeger.StretchPatch", name="dialog"},
			{"jaeger.Widget"},
			{"Button"},
			{"jaeger.InlineScript",
				msgOnClick = function()
					if callback then
						callback()
					end
				end
			}
		}
		window:query("getProp"):setBounds(-1000, -1000, -1, 1000, 1000, 1)

		return window
	end

	function c.showInfoPopup(text, callback)
		currentWindow = c.createWindow(callback)
		local contentText = entityMgr:createEntity{
			{"jaeger.Renderable", layer=layer},
			{"jaeger.Text", text=text,
			                rect={-85, -25, 85, 25},
			                font="karmatic_arcade.ttf",
			                alignment = {MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY},
			                size=15}
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

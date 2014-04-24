local class = require "jaeger.Class"
local RenderUtils = require "jaeger.utils.RenderUtils"

return class(..., function(i, c)
	function i:__constructor()
		local defaultLayer = RenderUtils.newLayer()
		self.renderTable = {
			defaultLayer
		}
		self.defaultLayer = defaultLayer
	end

	function i:start()
		local moaiLogo = createEntity{
			{"jaeger.Renderable", layer=self.defaultLayer},
			{"jaeger.Sprite", spriteName="ui/moai"},
			{"jaeger.Actor", phase="gui"}
		}

		moaiLogo:sendMessage("msgPerformWithDelay", 1.5, function()
			local bgm = getAsset("audio:bgm.mp3")
			bgm:setLooping(true)
			bgm:play()
			changeScene("scenes.MainMenu")
		end)
	end

	function i:stop()
	end

	function i:getRenderTable()
		return self.renderTable
	end
end)

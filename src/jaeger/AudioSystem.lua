local class = require "jaeger.Class"

-- Manages audio
return class(..., function(i)
	-- Private
	function i:start(engine, config)
		MOAIUntzSystem.initialize(44100, 1000)
		self.assetMgr = engine:getSystem("jaeger.AssetManager")
		print(engine:getSystem("jaeger.AssetManager"))
	end

	function i:playOnce(name)
		local audio = self.assetMgr:getAsset("audio:"..name)
		if not audio:isPlaying() then
			audio:play()
		end
	end
end)

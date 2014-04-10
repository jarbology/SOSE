local class = require "jaeger.Class"

-- Creation parameters:
-- * name: name of the stretch patch
return class(..., function(i)
	function i:__constructor(data)
		self.stretchPatchName = data.name
	end

	function i:msgActivate()
		local prop = assert(self.entity:query("getProp"), "Need a prop to display stretch patch")
		local stretchPatch = getAsset("stretchPatch:"..self.stretchPatchName)
		prop:setDeck(stretchPatch)
	end
end)

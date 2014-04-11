local class = require "jaeger.Class"

-- A health bar for a "Destructible" entity
-- Parameters:
-- * subject: the entity with a Destructible component
return class(..., function(i)
	local LINK_SPEC = {
		{ MOAIProp2D.INHERIT_LOC, MOAIProp2D.TRANSFORM_TRAIT },
		{ MOAIProp2D.INHERIT_VISIBLE, MOAIProp2D.ATTR_VISIBLE }
	}
	function i:__constructor(data)
		self.subject = data.subject
	end

	function i:msgActivate()
		local subject = self.subject
		self.entity:link(subject)
		local hp = subject:query("getHP").changed:addListener(self, "adjustBar")
		self.maxHP = subject:query("getMaxHP"):get()

		local prop = self.entity:query("getProp")
		local subjectX, subjectY = subject:query("getProp"):getLoc()
		self.prop = prop
		subject:sendMessage("msgAttach", self.entity, LINK_SPEC)
	end

	function i:adjustBar(hp)
		self.prop:setVisible(true)
		self.entity:sendMessage("msgSetProgress", hp/self.maxHP)
	end
end)

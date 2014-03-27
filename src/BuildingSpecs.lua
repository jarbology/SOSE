return {
	core = {
		cost = 0,
		entitySpec = {
			{"jaeger.Actor", phase="buildings"},
			{"jaeger.Renderable"},
			{"jaeger.Sprite", spriteName="buildings/core", autoPlay=true},
			{"jaeger.Widget"},
			{"Destructible", hp=5},
			{"Building"},
			{"Core"}
		}
	},
	mechBay = {
	},
	rocketLauncher = {
		cost = 100,
		entitySpec = {
			{"jaeger.Actor", phase="buildings"},
			{"jaeger.Renderable"},
			{"jaeger.Sprite", spriteName="buildings/core", autoPlay=true},
			{"jaeger.Widget"},
			{"Destructible", hp=5},
			{"Building"},
			{"MissileLauncher", damage=2}
		}
	},
	interceptor = {
	},
	generator = {
		cost = 200,
		entitySpec = {
			{"jaeger.Actor", phase="buildings"},
			{"jaeger.Renderable"},
			{"jaeger.Sprite", spriteName="buildings/generator", autoPlay=true},
			{"jaeger.Widget"},
			{"Destructible", hp=5},
			{"Building"},
			{"Generator", yield=2, interval=60}
		}
	},
	wall = {
	}
}

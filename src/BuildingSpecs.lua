return {
	core = {
		cost = 0,
		entitySpec = {
			{"jaeger.Actor", phase="buildings"},
			{"jaeger.Renderable"},
			{"jaeger.Sprite", spriteName="buildings/core", autoPlay=true},
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
			{"jaeger.Sprite", spriteName="buildings/rocket", autoPlay=true},
			{"Destructible", hp=5},
			{"Building"},
			{"MissileLauncher", damage=2}
		}
	},
	interceptor = {
		cost = 50,
		entitySpec = {
			{"jaeger.Actor", phase="buildings"},
			{"jaeger.Renderable"},
			{"jaeger.Sprite", spriteName="buildings/interceptor", autoPlay=true},
			{"Destructible", hp=15},
			{"Building"},
			{"Interceptor"}
		}
	},
	generator = {
		cost = 200,
		entitySpec = {
			{"jaeger.Actor", phase="buildings"},
			{"jaeger.Renderable"},
			{"jaeger.Sprite", spriteName="buildings/generator", autoPlay=true},
			{"Destructible", hp=5},
			{"Building"},
			{"Generator", yield=2, interval=60}
		}
	},
	turret = {
	}
}

return {
	core = {
		cost = 0,
		entitySpec = {
			{"jaeger.Actor", phase="buildings"},
			{"jaeger.Renderable"},
			{"jaeger.Sprite", spriteName="buildings/core", autoPlay=true},
			{"Destructible", hp=20},
			{"Building"},
			{"Generator", yield=5, interval=120},
			{"Core"}
		}
	},
	fakeCore = {
		cost = 100,
		entitySpec = {
			{"jaeger.Actor", phase="buildings"},
			{"jaeger.Renderable"},
			{"jaeger.Sprite", spriteName="buildings/core", autoPlay=true},
			{"Destructible", hp=20},
			{"Building"}
		}
	},
	mechBay = {
		cost = 150,
		entitySpec = {
			{"jaeger.Actor", phase="buildings"},
			{"jaeger.Renderable"},
			{"jaeger.Sprite", spriteName="buildings/mech", autoPlay=true},
			{"Destructible", hp=5},
			{"Building"},
			{"RobotBase", damage=2}
		}
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
		},
		attachmentSpec = {
			{"jaeger.Actor", phase="visual"},
			{"jaeger.Renderable"},
			{"jaeger.Sprite", spriteName="buildings/rocket", autoPlay=true}
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
		},
		attachmentSpec = {
			{"jaeger.Actor", phase="visual"},
			{"jaeger.Renderable"},
			{"jaeger.Sprite", spriteName="buildings/rocket", autoPlay=true}
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
			{"Generator", yield=5, interval=60}
		}
	},
	turret = {
		cost = 100,
		entitySpec = {
			{"jaeger.Actor", phase="buildings"},
			{"jaeger.Renderable"},
			{"jaeger.Sprite", spriteName="buildings/turret", autoPlay=true},
			{"Destructible", hp=5},
			{"Building"},
			{"Turret"}
		}
	}
}

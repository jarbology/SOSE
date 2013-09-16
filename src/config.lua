return {
	graphics = {
		title = "BattleshipRT",
		windowWidth = 640,
		windowHeight = 480
	},

	assets = {
		assetsPath = "../assets",

		texturePath = "../assets/gfx/textures/",
		spriteBankPath = "../assets/gfx/sprites/",
		atlasPath = "../assets/gfx/atlases/",
		fontPath = "../assets/fonts/",

		factories = {
			texture = "jaeger.assetFactories.TextureFactory",
			spriteBank = "jaeger.assetFactories.SpriteBankFactory",
			sprite = "jaeger.assetFactories.SpriteFactory",
			atlas = "jaeger.assetFactories.AtlasFactory",
			font = "jaeger.assetFactories.FontFactory"
		}
	},

	console = {
		port = 9001, --over 9000
		setupScript = "setupConsole.lua"
	},

	updatePhases = {
		"gui",
		"gamelogic"
	},

	sceneManager = {
		reloadKey = "F5"
	},

	lockstepSim = {
		lockedPhase = "gamelogic",
		streams = {1, 2},
		samplingInterval = 3
	},

	systems = {
		"jaeger.widget.WidgetManager",

		"jaeger.InputSystem",
		"jaeger.TaskManager",
		"jaeger.GraphicsSystem",
		"jaeger.SceneManager",
		"jaeger.EntityManager",
		"jaeger.RemoteConsole",
		"jaeger.LockstepSim",
		"jaeger.InlineScriptSystem",

		"MovableController"
	},

	tasks = {
		{"jaeger.SceneManager", "update"},
		{"jaeger.LockstepSim", "update"},-- LockstepSim:update must be before EntityManager:update
		{"jaeger.EntityManager", "update"},
		--{"jaeger.RemoteConsole", "update"},

		-- These tasks must be the last
		{"jaeger.EntityManager", "cleanUp"}
	}
}

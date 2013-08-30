return {
	graphics = {
		title = "BattleshipRT",
		windowWidth = 640,
		windowHeight = 480
	},

	firstScene = {
		name = "scenes.DemoScene",
		data = false
	},

	assets = {
		assetsPath = "../assets",

		texturePath = "../assets/gfx/textures/",
		spriteBankPath = "../assets/gfx/sprites/",
		atlasPath = "../assets/gfx/atlases/",

		factories = {
			texture = "jaeger.assetFactories.TextureFactory",
			spriteBank = "jaeger.assetFactories.SpriteBankFactory",
			sprite = "jaeger.assetFactories.SpriteFactory",
			atlas = "jaeger.assetFactories.AtlasFactory",
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

	lockstepSim = {
		lockedPhase = "gamelogic",
		queues = {
			"test"
		},
		interpreter = "CmdInterpreter"
	},

	systems = {
		"jaeger.InputSystem",
		"jaeger.TaskManager",
		"jaeger.GraphicsSystem",
		"jaeger.SceneManager",
		"jaeger.EntityManager",
		"jaeger.RemoteConsole",
		"jaeger.LockstepSim",
		"jaeger.InlineScriptSystem",

		"CmdInterpreter"
	},

	tasks = {
		{"jaeger.LockstepSim", "update"},-- LockstepSim:update must be before EntityManager:update
		{"jaeger.EntityManager", "update"},
		{"jaeger.RemoteConsole", "update"},

		-- These tasks must be the last
		{"jaeger.EntityManager", "cleanUp"}
	}
}

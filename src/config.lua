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
		"gameplay"
	},

	systems = {
		"jaeger.GraphicsSystem",
		"jaeger.SceneManager",
		"jaeger.EntityManager",
		"jaeger.TaskManager",
		"jaeger.RemoteConsole"
	},

	tasks = {
		{"jaeger.EntityManager", "update"},
		{"jaeger.RemoteConsole", "update"},

		-- These tasks must be the last
		{"jaeger.EntityManager", "cleanUp"}
	}
}

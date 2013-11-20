return {
	graphics = {
		title = "SoSE",
		windowWidth = 800,
		windowHeight = 480
	},

	assets = {
		assetsPath = "../assets",

		texturePath = "../assets/gfx/textures/",
		spriteBankPath = "../assets/gfx/sprites/",
		atlasPath = "../assets/gfx/atlases/",
		fontPath = "../assets/fonts/",
		tilesetPath = "../assets/gfx/tilesets/",

		factories = {
			texture = "jaeger.assetFactories.TextureFactory",
			spriteBank = "jaeger.assetFactories.SpriteBankFactory",
			sprite = "jaeger.assetFactories.SpriteFactory",
			atlas = "jaeger.assetFactories.AtlasFactory",
			font = "jaeger.assetFactories.FontFactory",
			tileset = "jaeger.assetFactories.TilesetFactory"
		}
	},

	console = {
		port = 9001, --over 9000
		setupScript = "setupConsole.lua"
	},

	updatePhases = {
		"gui",
		{"gamelogic", {
			"buildings",
			"missiles",
			"robots",
			"visual"
		}}
	},

	sceneManager = {
		reloadKey = "F5"
	},

	systems = {
		"jaeger.widget.WidgetManager",
		"jaeger.InputSystem",
		"jaeger.GraphicsSystem",
		"jaeger.SceneManager",
		"jaeger.ActorManager",
		"jaeger.NameManager",
		"jaeger.ScriptShortcut",
		"jaeger.EntityManager",
		"jaeger.RemoteConsole",
		"jaeger.TaskManager"
	},

	tasks = {
		"jaeger.SceneManager/Update",
		"jaeger.ActorManager/Update",

		-- These tasks must be the last
		"jaeger.EntityManager/CleanUp"
	}
}

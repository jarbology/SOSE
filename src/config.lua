return {
	graphics = {
		title = "SoSE",
		windowWidth = 1024,
		windowHeight = 576
	},

	assets = {
		assetsPath = "../assets",

		texturePath = "../assets/gfx/textures/",
		spriteBankPath = "../assets/gfx/sprites/",
		atlasPath = "../assets/gfx/atlases/",
		fontPath = "../assets/fonts/",
		tilesetPath = "../assets/gfx/tilesets/",

		loaders = {
			texture = "jaeger.assetLoaders.TextureLoader",
			sprite = "jaeger.assetLoaders.SpriteLoader",
			atlas = "jaeger.assetLoaders.AtlasLoader",
			font = "jaeger.assetLoaders.FontLoader",
			tileset = "jaeger.assetLoaders.TilesetLoader"
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
		"jaeger.WidgetManager",
		"jaeger.InputManager",
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

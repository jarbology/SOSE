return {
	graphics = {
		title = "SoSE",
		windowWidth = 1024,
		windowHeight = 576
	},

	assets = {
		assetsPath = ASSET_PATH,

		texturePath = ASSET_PATH.."/gfx/textures/",
		spriteBankPath = ASSET_PATH.."/gfx/sprites/",
		atlasPath = ASSET_PATH.."/gfx/atlases/",
		fontPath = ASSET_PATH.."/fonts/",
		tilesetPath = ASSET_PATH.."/gfx/tilesets/",
		audioPath = ASSET_PATH.."/sfx/",
		stretchPatchPath = ASSET_PATH.."/gfx/stretchPatches/",

		loaders = {
			texture = "jaeger.assetLoaders.TextureLoader",
			sprite = "jaeger.assetLoaders.SpriteLoader",
			atlas = "jaeger.assetLoaders.AtlasLoader",
			font = "jaeger.assetLoaders.FontLoader",
			tileset = "jaeger.assetLoaders.TilesetLoader",
			audio = "jaeger.assetLoaders.AudioLoader",
			stretchPatch = "jaeger.assetLoaders.StretchPatchLoader"
		}
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
		"jaeger.ScriptShortcut",
		"jaeger.EntityManager",
		"jaeger.TaskManager",
		"jaeger.AudioSystem"
	},

	tasks = {
		"jaeger.SceneManager/Update",
		"jaeger.ActorManager/Update",

		-- These tasks must be the last
		"jaeger.EntityManager/CleanUp"
	}
}

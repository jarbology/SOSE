return {
	graphics = {
		title = "BattleshipRT",
		windowWidth = 640,
		windowHeight = 480
	},

	firstScene = {
		name = "scenes.DemoScene",
		data = "test"
	},

	assets = {
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

	updatePhases = {
		"gui",
		"gameplay"
	},

	systems = {
		"jaeger.GraphicsSystem",
		"jaeger.SceneManager",
		"jaeger.EntityManager",
		"jaeger.TaskManager"
	},

	tasks = {
		{"jaeger.EntityManager", "update"}
	}
}

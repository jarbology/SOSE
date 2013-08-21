local engine = require "jaeger.Engine"
local config = require "config"
local systems = engine.start(config)

local scene = config.firstScene
systems["jaeger.SceneManager"]:changeScene(scene.name, scene.data)

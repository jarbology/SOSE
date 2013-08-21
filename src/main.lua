local config = require "config"
local Engine = require "jaeger.Engine"
local engine = Engine.new()
engine:start(config)

local scene = config.firstScene
local sceneMgr = engine:getSystem("jaeger.SceneManager")
sceneMgr:changeScene(scene.name, scene.data)

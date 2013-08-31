local config = require "config"
local Engine = require "jaeger.Engine"
local engine = Engine.new()
engine:start(config)

local firstScene = os.getenv("FIRST_SCENE")
local sceneData = os.getenv("SCENE_DATA")
local sceneMgr = engine:getSystem("jaeger.SceneManager")
sceneMgr:changeScene(firstScene, sceneData)

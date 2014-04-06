local config = require "config"
local Engine = require "jaeger.Engine"
local engine = Engine.new()
engine:start(config)

local sceneMgr = engine:getSystem("jaeger.SceneManager")
sceneMgr:changeScene(FIRST_SCENE, SCENE_DATA)

entityMgr = engine:getSystem("jaeger.EntityManager")
sceneMgr = engine:getSystem("jaeger.SceneManager")

function changeScene(scene, data)
	sceneMgr:changeScene(scene, data)
end

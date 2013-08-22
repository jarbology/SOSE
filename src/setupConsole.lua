entityMgr = engine:getSystem("jaeger.EntityManager")
sceneMgr = engine:getSystem("jaeger.SceneManager")
assetMgr = engine:getSystem("jaeger.AssetManager")

function changeScene(scene, data)
	sceneMgr:changeScene(scene, data)
end

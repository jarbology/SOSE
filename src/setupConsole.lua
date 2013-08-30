entityMgr = engine:getSystem("jaeger.EntityManager")
sceneMgr = engine:getSystem("jaeger.SceneManager")
assetMgr = engine:getSystem("jaeger.AssetManager")

function changeScene(scene, data)
	sceneMgr:changeScene(scene, data)
end

function testCmd(...)
	local lockstepSim = engine:getSystem("jaeger.LockstepSim")
	lockstepSim:getCmdQueue("test"):enqueue({"cmdTest", ...})
end

return function(name, config, assetManager, oldInstance)
	local audio = oldInstance or MOAIUntzSound.new()
	local audioPath = config.audioPath..name
	audio:load(audioPath)

	local length = audio:getLength() -- A size of 0 means failure
	if length ~= 0 then
		return audio, {audioPath}
	else
		return nil, "Can't load audio "..name
	end
end

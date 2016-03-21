require 'batcher.BatchCmdLine'
do
	local tokenFile = nil
	function batcher.set_token(file)
		tokenFile = file
	end
	function batcher.grab_token()
		if not tokenFile then
			print("No token file")
			error()
		end
		local tokenVal = not path.exists(tokenFile)
		if not tokenVal then 
			tokenVal = torch.load(tokenFile)
		end
		if tokenVal ~= false then
			if tokenVal == "done" then
				batcher.stop()
			else
				torch.save(tokenFile, false)
			end
			return true
		end
		return false
	end
	function batcher.release_token(done)
		if tokenFile then
			if done ~= "done" then
				torch.save(tokenFile, true)
			else
				torch.save(tokenFile, "done")
			end
		end
	end
end
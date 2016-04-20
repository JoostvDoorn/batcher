batcher = {}
require 'batcher.helpers'
do
	if batcher.type ~= nil then
		print "Only call require 'batcher' or require 'batcher.batch' not both"
		error()
	end
	batcher.type = 'batch'
	local cmd = torch.BatchCmdLine()
	cmd:text()
	cmd:text()
	cmd:text('Batcher options, note that these are mostly internally used arguments')
	cmd:text()
	cmd:text('Options')
	cmd:option('-batcher',false,'If false batcher does nothing')
	cmd:option('-batcherBackupDuringRun',false,'If true backups are automatically generated')
	cmd:option('-batcherSaveDuringContinue',-1,'If >=0 checkpoints are saved every x seconds on continue calls')
	cmd:option('-batcherTimelimit',900,'The timelimit of the batch')
	cmd:option('-batcherCheckpoint','batcher-checkpoint.t7','The path to the checkpoint')
	cmd:option('-batcherToken','batcher-token.t7','Token to release')
	cmd:text()
	-- parse input params
	local params = cmd:parse(arg ~= nil and arg or {})
	local loaded = nil
	local modules = {}
	local end_time = sys.clock()+params.batcherTimelimit
	local firstIteration = true
	batcher.set_token(params.batcherToken)

	-- Used for in place copy
	function copy_table(table1, table2)
		for key, value in pairs(table1) do
			table1[key] = nil
		end
		for key, value in pairs(table2) do
			table1[key] = table2[key]
		end
	end

	function batcher.targets(targets)
	end
	
	function batcher.add(targets)
		-- modules = targets
	end

	function batcher.hasCheckpoint()
		return path.exists(params.batcherCheckpoint)
	end

	local hasToSave_calls = 0
	local last_save = sys.clock()

	function batcher.hasToSave()
		hasToSave_calls = hasToSave_calls + 1
		local duration = sys.clock() - last_save
		if params.batcherSaveDuringContinue > 0 and duration > params.batcherSaveDuringContinue then
			hasToSave_calls = 0
			last_save = sys.clock()
		end
		return hasToSave_calls == 0
	end

	function batcher.hasToStop()
		return end_time < sys.clock()
	end

	function batcher.save()
		local save_modules = {}
		for i=1,#modules do
			save_modules[i] = modules[i]
		end
		torch.save(params.batcherCheckpoint, modules)
		if params.batcherBackupDuringRun then
			torch.save(params.batcherCheckpoint .. '_backup', modules) -- Make sure there is at least one file not corrupted by abort
		end
	end

	function batcher.done()
		batcher.save()
		batcher.release_token("done")
		os.exit()
	end

	function batcher.stop()
		batcher.save()
		batcher.release_token()
		os.exit()
	end

	
	function batcher.continue(targets)
		for i=1,#targets do
			if type(targets[i]) ~= "table" then
				modules[i] = targets[i]
			end
		end
		if params.batcher and batcher.hasToStop() then
			batcher.stop()
		elseif params.batcher then
			if firstIteration then
				-- Init
				for i=1,#targets do
					modules[i] = targets[i]
				end
				if batcher.hasCheckpoint() then
					loaded = torch.load(params.batcherCheckpoint)
					for i=1,#modules do
						if type(targets[i]) == "table" then
							copy_table(modules[i], loaded[i])
						else
							modules[i] = loaded[i]
						end
					end
				end
				firstIteration = false
			elseif batcher.hasToSave() then
				batcher.save()
			end
			local return_values = {}
			for i=1,#modules do
				if type(modules[i]) ~= "table" then
					return_values[#return_values+1] = modules[i]
				end
			end
			return unpack(return_values)
		else
			-- Loop back values that need to be returned
			local return_values = {}
			for i=1,#targets do
				if type(targets[i]) ~= "table" then
					return_values[#return_values+1] = targets[i]
				end
			end
			return unpack(return_values)
		end
	end

end
require 'sys'

batcher = {}
require 'batcher.helpers'

do
	if batcher.type ~= nil then
		print "Only call require 'batcher' or require 'batcher.batch' not both"
		error()
	end
	batcher.type = 'init'
	local timelimit = function() return 900 end
	local i = 0
	local done = false
	local tokenWait = 10
	local waitLimit = 7200
	local backupDuringRun = false
	local waitForLimit = false -- Wait for limit before trying to grab the token
	local cmd = function(arguments) return 'th ' .. arguments end
	local checkpointFile = 'batcher-checkpoint.t7'
	local tokenFile = 'batcher-token.t7'
	batcher.set_token(tokenFile)

	if tokenWait <= 0 then
		print("Token wait time should be positive")
		error()
	end

	function batcher.cmd(batch_cmd)
		if type(batch_cmd) ~= "function" then
			cmd = function(arguments) return batch_cmd .. ' ' .. arguments end
		else
			cmd = batch_cmd
		end
	end

	function batcher.backupDuringRun(value)
		backupDuringRun = value
	end

	function batcher.timelimit(limit)
		if type(limit) ~= "function" then
			timelimit = function() return limit end
		else
			timelimit = limit
		end
	end

	function batcher.checkpointFile(file)
		checkpointFile = file
	end

	function batcher.tokenFile(file)
		batcher.set_token(file)
	end

	function batcher.stop()
		done = true
	end

	function batcher.arguments(limit)
		return string.format("-batcher -batcherBackupDuringRun -batcherTimelimit %f -batcherCheckpoint %s -batcherToken %s", limit, checkpointFile, tokenFile)
	end

	function batcher.launch()
		if not batcher.grab_token() then
			print("Cannot start: token not free")
			error()
		end
		if done then
			print("Previous process results still stored in location")
			error()
		end
		while not done do
			local start = sys.clock()
			local limit = timelimit()
			local command = cmd(batcher.arguments(limit))
			print(string.format("Run batch %i", i))
			print(command)
			res = sys.execute(command)
			print(res) -- Print result
			while waitForLimit and limit > sys.clock()-start do
				sys.sleep(limit-(sys.clock()-start))
			end
			start = sys.clock()
			while not batcher.grab_token() do
				if (waitForLimit and waitLimit < sys.clock()-start) or limit+waitLimit < sys.clock()-start then
					print("Waiting too long")
					error() -- End if we're waiting for too long
				end
				sys.sleep(tokenWait)
			end
			i = i + 1
		end
	end
end
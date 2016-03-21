# Torch Batcher

Torch Batcher allows automatic checkpoint creation for use on time restricted computational resources. Torch Batcher was originally created for my personal need to run jobs on the computing cluster DAS-5, which enforces a 15 minute time limit during daytime.

*Please note: Torch Batcher may not be bug free so please check if it works for you, and report any issues you have*

## Usage
Torch Batcher is composed of two components, the headnode component that initiates runs, and the checkpointing component.

To allow checkpoints to be created of your jobs execution use `batcher.batch`. It can be run without the headnode script by calling `batcher.enable()` or calling your script with `-batcher`.

To create checkpoints inside a for loop, you need to rewrite it to a while loop, Torch Batcher can save anything from models to loop parameters
```lua
require 'batcher.batch'

-- ... your setup code here

local epoch = 0
while epoch<100 do
	epoch = batcher.continue{model, opts, epoch} -- loads on first call, saves at time limit, returns only non table values
	train_epoch() -- Include your code here
end
batcher.done() -- Important

```

## Usage on DAS-5
Here is an example headnode script that enforces the DAS-5 usage policy. Jobs will have a different time limit during the weekend, and in the evening. It may be desirable to modify this if you plan to use multiple nodes.

```lua
require 'batcher'

do
	local job_file = 'temp.job'
	function sbatch_launcher(arguments)
		local batch_def = [[
#!/bin/bash
#SBATCH --time=00:15:00
#SBATCH -N 1
#SBATCH -o log.out
#SBATCH -e log.err
#SBATCH -J batch

export LUA_PATH="$LUA_PATH;$ABS/?.lua"

/home/jvdoorn/torch/install/bin/th train.lua \
]] .. arguments
		local f = io.open(job_file, "w+")
		f:write(batch_def)
		f:close()
		local cmd = 'sbatch ' .. job_file
		return cmd
	end

	function timelimit()
		-- Enforce the das5 policy
		local now = os.date("*t")
		local stop = os.date("*t")
		if now.wday <= 1 or now.wday > 6 or (now.wday == 6 and now.hour >= 20) then
			-- Weekend
			stop.day = stop.day + 8-now.wday
			stop.hour = 7
			stop.min = 55
		else
			-- Weekday
			if now.hour >= 20 then
				stop.day = stop.day + 1
				stop.hour = 7
				stop.min = 55
			elseif now.hour <= 7 then
				stop.hour = 7
				stop.min = 55
			end
		end
		return math.max(os.time(stop)-os.time(now), 14*60)
	end
	batcher.cmd(sbatch_launcher)
	batcher.timelimit(timelimit)
	batcher.launch()
	os.remove(job_file)
end
```
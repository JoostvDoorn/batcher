local BatchCmdLine, parent = torch.class('torch.BatchCmdLine', 'torch.CmdLine')

local CmdLine = torch.CmdLine

function BatchCmdLine:__readArgument__(params, arg, i, nArgument)
   local argument = self.arguments[nArgument]
   local value = arg[i]
   if string.sub(value,1,string.len("-batcher"))=="-batcher" then
      if nArgument > #self.arguments then
         self:error('invalid batcher argument: ' .. value)
      else
         if argument.type and type(value) ~= argument.type then
            self:error('invalid batcher argument type for argument ' .. argument.key .. ' (should be ' .. argument.type .. ')')
         end
         params[strip(argument.key)] = value
      end
   end
   return 1
end
function BatchCmdLine:__readOption__(params, arg, i)
   local result = parent.__readOption__(self, params, arg, i)
   for k=0,result-1 do
      arg[i+k] = "-batcherIgnore"
   end
   -- print(arg[i])
   return result
end

function CmdLine:__readArgument__(params, arg, i, nArgument)
   local argument = self.arguments[nArgument]
   local value = arg[i]
   if string.sub(value,1,string.len("-batcher"))~="-batcher" then
      if nArgument > #self.arguments then
         self:error('invalid argument: ' .. value)
      end
      if argument.type and type(value) ~= argument.type then
         self:error('invalid argument type for argument ' .. argument.key .. ' (should be ' .. argument.type .. ')')
      end
      params[strip(argument.key)] = value
   end
   return 1
end
function CmdLine:parse(arg)
   local i = 1
   local params = self:default()

   local nArgument = 0

   while i <= #arg do
      if arg[i] == '-help' or arg[i] == '-h' or arg[i] == '--help' then
         self:help(arg)
         os.exit(0)
      end

      if self.options[arg[i]] then
         i = i + self:__readOption__(params, arg, i)
      else
         nArgument = nArgument + 1
         i = i + self:__readArgument__(params, arg, i, nArgument)
      end
   end

   return params
end
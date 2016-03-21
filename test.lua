require 'batcher.batch'

cmd = torch.CmdLine()


cmd:option('-modelFilename', '', 'Model to test.')
cmd:option('-inputf',        '', 'Input article files. ')
cmd:option('-nbest',      false, 'Write out the nbest list in ZMert format.')
cmd:option('-length',         15, 'Maximum length of summary.')
opt = cmd:parse(arg)


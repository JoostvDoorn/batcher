 package = "batcher"
 version = "1.0-1"
 source = {
    url = "git://github.com/JoostvDoorn/batcher",
    tag = "v1.0-1"
 }
 description = {
    summary = "Sequential batch process script",
    detailed = [[
       Add additional output options to xlua progress.
    ]],
    homepage = "https://github.com/JoostvDoorn/batcher",
    license = "BSD"
 }
 dependencies = {
    "sys",
    "torch"
 }
 build = {
    type = "builtin",
    modules = {
      ['batcher.init'] = 'init.lua',
      ['batcher.batch'] = 'batch.lua',
      ['batcher.helpers'] = 'helpers.lua',
      ['batcher.BatchCmdLine'] = 'BatchCmdLine.lua',
    }
 }
{CompositeDisposable} = require 'atom'
helpers = require 'atom-linter'

'use babel'
module.exports = {
  config:
    pythonPath:
      type: 'string'
      default: '/usr/bin/python'
      order: 1
      description: 'Note for Windows/Mac OS X users: please ensure that  ' +
      'python is in your ```$PATH``` otherwise the linter might not work. ' +
      'If your path contains spaces, it needs to be enclosed in double quotes.'
    vendor:
      type: 'string'
      order: 2
      default: 'NVIDIA/Intel'
      enum: ['NVIDIA/Intel', 'AMD']
    openCL:
      title: 'OpenCL'
      type: 'object'
      order: 3
      properties:
        platformIndex:
          title: 'OpenCL Platform Index'
          type: 'integer'
          default: 0
    hybridGraphics:
      title: 'Hybrid Graphics (Linux only)'
      type: 'object'
      order: 4
      properties:
        enable:
          type: 'boolean'
          default: false
        offloadingPath:
          type: 'string'
          default: '/usr/bin/optirun'
          description: 'If the offloader is in your ```$PATH```, full path ' +
          'to the binary is not necessary. If your path contains spaces, it ' +
          ' needs to be enclosed in double quotes.'
    compilerFlags:
      type: 'string'
      order: 5
      default: ' '
      description: 'Specifie additional flags for the OpenCL compiler like ' +
                   'include paths or optimization flags'
    debug:
      type: 'boolean'
      default: 'false'
      order: 6
      description: 'Prints command executed to compile OpenCL source to ' +
      'atoms  console. Go to View->Developer->Toggle Developer Tools. ' +
      'Observe the Console tab when you open/save a OpenCL file.'

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-opencl.pythonPath',
      (pythonPath) =>
        @pythonPath = pythonPath
    @subscriptions.add atom.config.observe 'linter-opencl.vendor',
      (vendor) =>
        @vendor = vendor
    @subscriptions.add atom.config.observe 'linter-opencl.openCL',
      (openCL) =>
        @openCL = openCL
    @subscriptions.add atom.config.observe 'linter-opencl.hybridGraphics',
      (hybridGraphics) =>
        @hybridGraphics = hybridGraphics
    @subscriptions.add atom.config.observe 'linter-opencl.compilerFlags',
      (compilerFlags) =>
        @compilerFlags = compilerFlags
    @subscriptions.add atom.config.observe 'linter-opencl.debug',
      (debug) =>
        @debug = debug

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    provider =
      grammarScopes: ['source.opencl']
      scope: 'file'
      lintOnFly: false,
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        args     = []
        debug    = @debug
        vendor   = @vendor
        if @hybridGraphics.enable
          executable = @hybridGraphics.offloadingPath
          args.push(@pythonPath)
        else
          executable = @pythonPath
        args.push(__dirname + '/clCompiler.py')
        args.push(filePath)
        if @compilerFlags.localeCompare(' ') != 0
          args.push('-f')
          args.push('\"' + @compilerFlags + '\"')
        args.push('-p')
        args.push(@openCL.platformIndex)
        if debug
          command   = executable
          for a in args
            command = command + ' ' + a
          console.log(command)
        return new Promise (resolve, reject) ->
          helpers.exec(executable, args, {stream: 'stderr'})
          .then (output) ->
            if debug
              console.log(output)
            lines         = output.split('\n')
            result        = []
            if vendor.localeCompare('AMD') == 0
              regex       = /[^,], line (\d+): ([^:]+): (.*)/
              #reges = /[^,], (.*)/
            else
              regex       = /[^:]:(\d+):(\d+): ([^:]+): (.*)/

            for line in lines
              match       = line.match(regex)
              if match
                console.log(line)
                row       = match[1] - 1
                if vendor.localeCompare('AMD') == 0
                  col     = 0
                  if match[2].localeCompare('catastrophic error') == 0
                    type  = 'error'
                  else
                    type    = match[2]
                  message = match[3]
                else
                  col     = match[2] - 1
                  if match[3].localeCompare('fatal error') == 0
                    type  = 'error'
                  else
                    type  = match[3]
                  message = match[4]
                result.push(
                  type:     type
                  text:     message
                  range:    [[row,col], [row,col]]
                  filePath: filePath
                )
            resolve result
}

{CompositeDisposable} = require 'atom'
helpers = require 'atom-linter'

xcache = new Map

'use babel'
module.exports = {
  config:
    pythonPath:
      type: 'string'
      default: '/usr/bin/python'
      description: 'Note for Windows/Mac OS X users: please ensure that python is in your ```$PATH``` otherwise the linter might not work. If your path contains spaces, it needs to be enclosed in double quotes.'
    hybridGraphics:
      type: 'object'
      properties:
        enable:
          type: 'boolean'
          default: false
        offloadingPath:
          type: 'string'
          default: '/usr/bin/optirun'
          description: 'Note for Windows/Mac OS X users: please ensure that the offloader is in your ```$PATH``` otherwise the linter might not work. If your path contains spaces, it needs to be enclosed in double quotes.'

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-opencl.pythonPath',
      (pythonPath) =>
        @pythonPath = pythonPath
    @subscriptions.add atom.config.observe 'linter-opencl.hybridGraphics',
      (hybridGraphics) =>
        @hybridGraphics = hybridGraphics
  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    provider =
      grammarScopes: ['source.opencl']
      scope: 'project'
      lintOnFly: false,
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        args     = []
        if @hybridGraphics.enable
          executable = @hybridGraphics.offloadingPath
          args.push(@pythonPath)
          args.push(__dirname + '/clCompiler.py')
        else
          executable = @pythonPath
          args.push(__dirname + '/clCompiler.py')
        args.push(filePath)
        return helpers.exec(executable, args, {stream: 'stderr'})
          .then (output) ->
            lines   = output.split('\n')
            result  = []
            regex   = /<kernel>:(\d+):(\d+): ([^ ]+): (.*)/
            for line in lines
              match = line.match(regex)
              if match
                row     = match[1] - 1
                col     = match[2] - 1
                type    = match[3]
                message = match[4]
                result.push(
                  type: type
                  text: message
                  range:    [[row,col], [row,col]]
                  filePath: filePath
                )
            return result
    return provider
}

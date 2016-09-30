{CompositeDisposable} = require 'atom'
helpers = require 'atom-linter'
XRegExp = require('xregexp').XRegExp

xcache = new Map

'use babel'
module.exports = {
  config:
    clccPath:
      type: 'string'
      default: '/usr/bin/clcc'
      description: 'Note for Windows/Mac OS X users: please ensure that CLCC is in your ```$PATH``` otherwise the linter might not work. If your path contains spaces, it needs to be enclosed in double quotes.'

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-clcc.clccPath',
      (clccPath) =>
        @clccPath = clccPath
  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    provider =
      name: 'clcc'
      grammarScopes: ['source.opencl']
      scope: 'project'
      lintOnFly: true,
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        return helpers.exec('optirun', [@clccPath, filePath], {stream: 'stderr'})
          .then (output) ->
            lines   = output.split('\n')
            result  = []
            regex   = /<kernel>:(\d+):(\d+): (.+): (.*)/
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

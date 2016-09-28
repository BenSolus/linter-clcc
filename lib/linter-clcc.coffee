{CompositeDisposable} = require 'atom'
helpers = require 'linter'

'use babel'
module.exports = {
  config:
    execPath:
      type: 'string'
      default: "/usr/bin/clcc"
      description: "Note for Windows/Mac OS X users: please ensure that CLCC is in your ```$PATH``` otherwise the linter might not work. If your path contains spaces, it needs to be enclosed in double quotes."

  activate: ->
    console.log('My package was activated')

  deactivate: ->
    console.log('My package was deactivated')

  provideLinter: ->
    provider =
      name: 'clcc'
      grammarScopes: ['source.cl']
      scope: 'file'
      lintOnFly: false,
      lint: (textEditor) =>
        return @linting textEditor.getPath()

  linting: (filePath) ->
    spawn  = require('child_process').spawn;
    args   = ['-a', filePath]
    child  = spawn('/usr/bin/clcc', args)
    output   = ''


    return helpers.exec('/usr/bin/clcc', args, options: {stream: 'stderr'}).then (output) ->
      console.log output
      result = []
      result.push(
        type: 'Error',
        text: 'Text',
        range:[[1,0], [1,1]],
        filePath: filePath
      )
      return result

  parsing: (output, filePath) ->
    result = []
    out    = ''

    result.push(
      type: 'Error',
      text: 'Text',
      range:[[1,0], [1,1]],
      filePath: filePath
    )

    return result
}

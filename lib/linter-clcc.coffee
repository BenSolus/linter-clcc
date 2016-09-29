{CompositeDisposable} = require 'atom'
helpers = require 'atom-linter'

'use babel'
module.exports = {
  config:
    clccPath:
      type: 'string'
      default: '/usr/bin/clcc'
      description: 'Note for Windows/Mac OS X users: please ensure that CLCC is in your ```$PATH``` otherwise the linter might not work. If your path contains spaces, it needs to be enclosed in double quotes.'

  activate: ->
    require('atom-package-deps').install('linter-clcc')
      .then ->
        console.log('linter-clcc loaded')
  deactivate: ->
    console.log('My package was deactivated')

  provideLinter: ->
    provider =
      name: 'clcc'
      grammarScopes: ['source.opencl']
      scope: 'file'
      lintOnFly: false,
      lint: (textEditor) =>
        return @linting textEditor.getPath()
          .then @parsing

  linting: (filePath) ->
    clccPath = atom.config.get('linter-clcc.clccPath')
    return helpers.exec('optirun', [clccPath, filePath], {stream: 'stderr'})

  parsing: (output, filePath) ->
    result = []
    console.log(output)
    result.push(
      type: 'Error',
      text: 'Text',
      range:[[1,0], [1,1]],
      filePath: filePath
    )

    return result
}

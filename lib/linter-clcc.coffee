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
        console.log('linter-clcc loaded')
  deactivate: ->
    console.log('My package was deactivated')

  provideLinter: ->
    provider =
      name: 'clcc'
      grammarScopes: ['source.opencl']
      scope: 'project'
      lintOnFly: true,
      lint: (textEditor) =>
        return @linting textEditor.getPath()
          .then @parsing
    return provider

  linting: (filePath) ->
    clccPath = atom.config.get('linter-clcc.clccPath')
    return helpers.exec('optirun', [clccPath, filePath], {stream: 'stderr'})

  parsing: (output, filePath) ->
    Regex = new RegExp('<kernel>:[0-9]+:[0-9]+: [a-z]+: .+', 'g')
    Position = new RegExp('[0-9]+:[0-9]+')
    matches = output.match(Regex)
    for match in matches
      position = match.match(Position)
      row      = match.match(new RegExp('[0-9]+(?=:[0-9]+)'))
      col      = match.match(new RegExp('(?<=[0-9]+:)[0-9]+'))
      console.log(row)
      result = []
      result.push(
        type: 'Error',
        text: 'Text',
        range:[[0,0], [0,1]],
        filePath: filePath
      )

    return result
}

'use babel'

lint = require('../lib/linter-opencl.coffee').provideLinter().lint

describe 'The OpenCL build provider for Atom Linter',  ->
  linter = require('../lib/linter-opencl.coffee').provideLinter().lint

  beforeEach ->
    waitsForPromise ->
      atom.config.set('linter-opencl.pythonPath', 'python')
      atom.config.set('linter-opencl.openCL.vendor', 'AMD')
      atom.config.set('linter-opencl.openCL.platformIndex', 0)
      # atom.config.set('linter-opencl.openCL.platformIndex', 1)
      atom.config.set('linter-opencl.hybridGraphics.enable', false)
      atom.config.set('linter-opencl.hybridGraphics.offloadingPath',
                      '/usr/bin/optirun')
      atom.config.set('linter-opencl.debug', true)
      atom.packages.activatePackage('language-opencl')
      atom.packages.activatePackage('linter-opencl')
      console.log(atom.packages.resolvePackagePath('linter-opencl'))
      return atom.packages.activatePackage("linter-opencl")

  it 'should be in the packages list', ->
    expect(atom.packages.isPackageLoaded('linter-opencl')).toBe(true)

  it 'should be an active package', ->
    expect(atom.packages.isPackageActive('linter-opencl')).toBe(true)

  it 'find an catastrophic error in error.cl', ->
    waitsForPromise ->
      file = __dirname + '/files/fatal-error.cl'
      expect(file).toExistOnDisk()
      atom.workspace.open(file).then((editor) -> lint(editor)).then (messages) ->
        expect(messages.length).toEqual(1)
        expect(messages[0].type).toEqual('error')
        expect(messages[0].text).toEqual('cannot open source file')

  it 'find errors and warnings in error.cl', ->
    waitsForPromise ->
      atom.config.set('linter-opencl.includePaths', [__dirname + '/spec/files'])
      file = __dirname + '/files/error.cl'
      expect(file).toExistOnDisk()
      atom.workspace.open(file).then((editor) -> lint(editor)).then (messages) ->
        expect(messages.length)
        expect(messages.length).toEqual(2)
        expect(messages[0].type).toEqual('error')
        expect(messages[0].text).toEqual('expected a ";"')
        expect(messages[1].type).toEqual('warning')
        expect(messages[1].text).toEqual('variable "a" was declared but ' +
                                         'never')

  it 'find no error in correct.cl', ->
    waitsForPromise ->
      file = __dirname + '/files/correct.cl'
      expect(file).toExistOnDisk()
      atom.workspace.open(file).then((editor) -> lint(editor)).then (messages) ->
        expect(messages.length).toEqual(0)

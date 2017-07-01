# Copyright (c) 2016-2017 Bennet Carstensen
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

'use babel'

lint = require('../lib/linter-opencl.coffee').provideLinter().lint

describe 'The OpenCL build provider for Atom Linter',  ->
  linter = require('../lib/linter-opencl.coffee').provideLinter().lint

  beforeEach ->
    waitsForPromise ->
      atom.config.set('linter-opencl.openCL.platformIndex', 0)
      # atom.config.set('linter-opencl.openCL.platformIndex', 1)
      atom.config.set('linter-opencl.debug', true)
      atom.packages.activatePackage('language-opencl')
      atom.packages.activatePackage('linter-opencl')
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
        expect(messages[0].severity).toEqual('error')
        expect(messages[0].excerpt).toEqual('cannot open source file')

  it 'find errors and warnings in error.cl', ->
    waitsForPromise ->
      atom.config.set('linter-opencl.includePaths', [__dirname + '/spec/files'])
      file = __dirname + '/files/error.cl'
      expect(file).toExistOnDisk()
      atom.workspace.open(file).then((editor) -> lint(editor)).then (messages) ->
        expect(messages.length)
        expect(messages.length).toEqual(2)
        expect(messages[0].severity).toEqual('error')
        expect(messages[0].excerpt).toEqual('expected a ";"')
        expect(messages[1].severity).toEqual('warning')
        expect(messages[1].excerpt).toEqual('variable "a" was declared but ' +
                                         'never')

  it 'find no error in correct.cl', ->
    waitsForPromise ->
      file = __dirname + '/files/correct.cl'
      expect(file).toExistOnDisk()
      atom.workspace.open(file).then((editor) -> lint(editor)).then (messages) ->
        expect(messages.length).toEqual(0)

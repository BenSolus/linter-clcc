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

'use strict'

path = require 'path'
fs   = require 'fs'

module.exports = () ->
  if atom.project.getPaths()[0] != undefined
    configFile = path.join(atom.project.getPaths()[0], '.opencl-config.json')

    if fs.existsSync(configFile)
      delete require.cache[configFile]

      configData = require(configFile)

      configs = {}
      if configData.compilerFlags != undefined
        configs.compilerFlags = configData.compilerFlags
      else
        configs.compilerFlags = atom.config.get('linter-opencl.compilerFlags')

      if configData.includePaths != undefined
        configs.includePaths  = configData.includePaths
      else
        configs.includePaths  = atom.config.get('linter-opencl.includePaths')

      return {
        compilerFlags: configs.compilerFlags,
        includePaths: configs.includePaths
      }

  return {
    compilerFlags: atom.config.get('linter-opencl.compilerFlags'),
    includePaths:  atom.config.get('linter-opencl.includePaths')
  }

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

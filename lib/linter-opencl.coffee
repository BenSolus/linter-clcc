{CompositeDisposable} = require 'atom'
helpers = require 'atom-linter'
path = require 'path'
fs = require 'fs'
cl = require 'node-opencl'

configs = exports ? this

configs.compilerFlags = -> ''

'use babel'
module.exports = {
  config:
    openCL:
      title: 'OpenCL'
      type: 'object'
      order: 1
      properties:
        vendor:
          title: 'OpenCL Vendor'
          type: 'string'
          order: 1
          default: 'NVIDIA'
          enum: ['NVIDIA', 'AMD']
        platformIndex:
          title: 'OpenCL Platform Index'
          type: 'integer'
          order: 2
          default: 0
          description: 'Letting linter-opencl compile the source code ' +
          'on the OpenCL Platform with the corresponding index.'
    hybridGraphics:
      title: 'Hybrid Graphics (Linux only)'
      type: 'object'
      order: 2
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
        pythonPath:
          title: 'Python Path'
          type: 'string'
          default: '/usr/bin/python'
          description: 'If the python binary is in your ```$PATH```, full ' +
          'patho is not necessary. If the path contains space, it needs to be' +
          'enclosed in double quotes.'
    compilerFlags:
      type: 'string'
      order: 3
      default: ''
      description: 'Specifie additional flags for the OpenCL compiler'
    includePaths:
      type: 'array'
      order: 4
      default: ['']
      items:
        type: 'string'
    debug:
      type: 'boolean'
      default: 'false'
      order: 5
      description: 'Prints command executed to compile OpenCL source to ' +
      'atoms  console. Go to View->Developer->Toggle Developer Tools. ' +
      'Observe the Console tab when you open/save a OpenCL file.'

  activate: ->
    require('atom-package-deps').install('linter-opencl')

    @subscriptions = new CompositeDisposable()

    if !atom.packages.getLoadedPackages('linter')
      atom.notifications.addError(
        "Linter package not found.",
        { detail: 'Please install the `linter` package.' }
      )
    if atom.project.getPaths()[0] != undefined
      configFile = path.join(atom.project.getPaths()[0], '.opencl-config.json')

      if fs.existsSync(configFile)
        delete require.cache[configFile]

        configData = require(configFile)

        if configData.vendor != undefined
          configs.vendor        = configData.vendor
        else
          configs.vendor        = atom.config.get('linter-opencl.openCL.vendor')

        if configData.platformIndex != undefined
          configs.platformIndex = configData.platformIndex
        else
          configs.platformIndex = \
            atom.config.get('linter-opencl.openCL.platformIndex')

        if configData.offloadingPath != undefined
          configs.offloadingPath = configData.offloadingPath
        else
          configs.offloadingPath = \
            atom.config.get('linter-opencl.hybridGraphics.offloadingPath')

        if configData.pythonPath != undefined
          configs.pythonPath = configData.pythonPath
        else
          configs.pythonPath = \
            atom.config.get('linter-opencl.hybridGraphics.pythonPath')

        if configData.compilerFlags != undefined
          configs.compilerFlags = configData.compilerFlags
        else
          configs.compilerFlags = atom.config.get('linter-opencl.compilerFlags')

        if configData.includePaths != undefined
          configs.includePaths  = configData.includePaths
        else
          configs.includePaths  = atom.config.get('linter-opencl.includePaths')

        return

    configs.vendor        = atom.config.get('linter-opencl.openCL.vendor')
    configs.platformIndex = \
      atom.config.get('linter-opencl.openCL.platformIndex')
    configs.offloadingPath = \
      atom.config.get('linter-opencl.hybridGraphics.offloadingPath')
    configs.pythonPath = \
      atom.config.get('linter-opencl.hybridGraphics.pythonPath')
    configs.compilerFlags = atom.config.get('linter-opencl.compilerFlags')
    configs.includePaths  = atom.config.get('linter-opencl.includePaths')

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    #return require './linter.coffee'
    provider =
      grammarScopes: ['source.opencl']
      scope: 'file'
      lintOnFly: true,
      # coffeelint: disable=no_unnecessary_fat_arrows
      lint: (textEditor) =>
        # coffeelint: enable=no_unnecessary_fat_arrows
        filePath = textEditor.getPath()
        source   = textEditor.getText()

        if filePath && source != ''

          buildLog = ''

          # Platform which where the source should be tested on
          platform =  cl.getPlatformIDs()[configs.platformIndex]

          devices  = cl.getDeviceIDs(platform, cl.DEVICE_TYPE_ALL)
          context  = cl.createContext([cl.CONTEXT_PLATFORM, platform], devices)
          program  = cl.createProgramWithSource(context, source)

          options  = configs.compilerFlags

          # Get include paths
          includePaths = configs.includePaths

          for i of includePaths
            if includePaths[i] != ''
              if includePaths[i].substring(0, 1) == '.'
                # Extend include paths if necessary
                includePaths[i] = path.join(atom.project.getPaths()[0], \
                                            includePaths[i])
              # Add include paths to compiler flags
              options += ' -I \"' + includePaths[i] + '\"'

          if atom.config.get('linter-opencl.debug')
            console.log('Using following compiler flags: ' + options)

          # Try to compile the source
          try
            cl.buildProgram(program, devices)
          catch error
            # Get build log if compilation failed
            buildLog = cl.getProgramBuildInfo(program, \
                                              devices[0], \
                                              cl.PROGRAM_BUILD_LOG)

          lintMessages = []

          if buildLog != ''
            if atom.config.get('linter-opencl.debug')
              console.log('Received following build log:')
              console.log(buildLog)

            vendor = configs.vendor

            if vendor.localeCompare('AMD') == 0
              regex = /[^,], line (\d+): ([^:]+): (.*)/
            else
              regex  = /[^:]:(\d+):(\d+): ([^:]+): (.*)/

            lines = buildLog.split('\n')

            for line in lines
              match = line.match(regex)

              if match
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
                lintMessages.push(
                  type: type
                  text: message
                  range:    [[row,col], [row,col]]
                  filePath: filePath
                )

          console.log(lintMessages.length)
          return lintMessages
}

#{CompositeDisposable} = require 'atom'

path    = null
fs      = null
helpers = null
cl      = null

configs = null

'use babel'
module.exports = {
  config:
    openCL:
      title: 'OpenCL Platform'
      type: 'object'
      order: 1
      properties:
        platformIndex:
          title:       'Platform Index'
          type:        'integer'
          order:       1
          default:     0
          description: 'Lint the source code for the OpenCL Platform with ' +
          'the corresponding index. Only change this value if you want to ' +
          'change the OpenCL Platform.'
        platformVersion:
          title:   'Platform Version'
          type:    'string'
          order:   2
          default: ''
        platformName:
          title:   'Platform Name'
          type:    'string'
          order:   3
          default: ''
        platformVendor:
          title:   'Platform Vendor'
          type:    'string'
          order:   4
          default: ''
    includePaths:
      type: 'array'
      order: 3
      default: ['']
      items:
        type: 'string'
      description: 'Paths which contain source code which are included ' +
      'by a linted source file.'
    compilerFlags:
      type: 'string'
      order: 4
      default: ''
      description: 'Additional flags for the OpenCL compiler'
    debug:
      type: 'boolean'
      default: 'false'
      order: 5
      description: 'Prints build log to toms console. Go to ' +
      'View->Developer->Toggle Developer Tools.'

  activate: ->
    require('atom-package-deps').install('linter-opencl')

    atom.config.observe 'linter-opencl.openCL.platformIndex', (platformIndex) ->
      cl ?= require 'node-opencl'

      try
        platform = cl.getPlatformIDs()[platformIndex]

        atom.config.set('linter-opencl.openCL.platformVersion',
                        cl.getPlatformInfo(platform, cl.PLATFORM_VERSION))
        atom.config.set('linter-opencl.openCL.platformName',
                        cl.getPlatformInfo(platform, cl.PLATFORM_NAME))
        atom.config.set('linter-opencl.openCL.platformVendor',
                        cl.getPlatformInfo(platform, cl.PLATFORM_VENDOR))
      catch
        atom.config.set('linter-opencl.openCL.platformVersion', '')
        atom.config.set('linter-opencl.openCL.platformName', '')
        atom.config.set('linter-opencl.openCL.platformVendor', '')

    atom.commands.add(
      'atom-workspace',
      'linter-opencl:Set Platform',
      ->
        if !this.platformListView
          PlatformListView = require './ui.coffee'

          platformListView = new PlatformListView()

        platformListView.toggle()
    )

  provideLinter: ->
    path    ?= require 'path'
    fs      ?= require 'fs'
    helpers ?= require 'atom-linter'
    cl      ?= require 'node-opencl'
    provider =
      grammarScopes: ['source.opencl']
      scope: 'file'
      lintOnFly: true,
      # coffeelint: disable=no_unnecessary_fat_arrows
      lint: (textEditor) =>
        # coffeelint: enable=no_unnecessary_fat_arrows
        configs ?= require('./config.coffee')()

        filePath = textEditor.getPath()
        source   = textEditor.getText()

        if filePath && source != ''

          options      = configs.compilerFlags

          includePaths = configs.includePaths

          for i of includePaths
            if includePaths[i] != ''
              if includePaths[i].substring(0, 1) == '.'
                # Extend include paths if necessary
                includePaths[i] = path.join(atom.project.getPaths()[0], \
                                            includePaths[i])
              # Add include paths to compiler flags
              options += ' -I \"' + includePaths[i] + '\"'

          buildLog = ''

          platformIndex = atom.config.get('linter-opencl.openCL.platformIndex')
          try
            platform = cl.getPlatformIDs()[platformIndex]
          catch
            conosle.log('TRERS')
            return

          devices  = cl.getDeviceIDs(platform, cl.DEVICE_TYPE_ALL)
          context  = cl.createContext([cl.CONTEXT_PLATFORM, platform],
                                        devices)
          program  = cl.createProgramWithSource(context, source)

          # Try to compile the source
          try
            cl.buildProgram(program, devices)
          catch error
            # Get build log if compilation failed
            buildLog =  cl.getProgramBuildInfo(program, \
                                               devices[0], \
                                               cl.PROGRAM_BUILD_LOG)

          lintMessages = []

          if (buildLog != '')
            if atom.config.get('linter-opencl.debug')
              console.log('Received following build log:')
              console.log(buildLog)

            oCLVersion = atom.config.get('linter-opencl.openCL.platformVersion')

            if oCLVersion.includes("AMD")
              regex = /[^,], line (\d+): ([^:]+): (.*)/
            else
              regex  = /[^:]:(\d+):(\d+): ([^:]+): (.*)/

            lines = buildLog.split('\n')

            for line in lines
              match = line.match(regex)

              if match
                row       = match[1] - 1
                if oCLVersion.includes("AMD")
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

          return lintMessages
}

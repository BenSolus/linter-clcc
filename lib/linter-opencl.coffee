{CompositeDisposable} = require 'atom'
helpers = require 'atom-linter'
path = require 'path'
fs = require 'fs'

'use babel'
module.exports = {
  config:
    pythonPath:
      type: 'string'
      default: '/usr/bin/python'
      order: 1
      description: 'Note for Windows/Mac OS X users: please ensure that  ' +
      'python is in your ```$PATH``` otherwise the linter might not work. ' +
      'If your path contains spaces, it needs to be enclosed in double quotes.'
    vendor:
      type: 'string'
      order: 2
      default: 'NVIDIA/Intel'
      enum: ['NVIDIA/Intel', 'AMD']
    openCL:
      title: 'OpenCL'
      type: 'object'
      order: 3
      properties:
        platformIndex:
          title: 'OpenCL Platform Index'
          type: 'integer'
          default: 0
    hybridGraphics:
      title: 'Hybrid Graphics (Linux only)'
      type: 'object'
      order: 4
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
    compilerFlags:
      type: 'string'
      order: 5
      default: ' '
      description: 'Specifie additional flags for the OpenCL compiler like ' +
                   'include paths or optimization flags'
    debug:
      type: 'boolean'
      default: 'false'
      order: 6
      description: 'Prints command executed to compile OpenCL source to ' +
      'atoms  console. Go to View->Developer->Toggle Developer Tools. ' +
      'Observe the Console tab when you open/save a OpenCL file.'

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-opencl.pythonPath',
      (pythonPath) =>
        @pythonPath = pythonPath
    @subscriptions.add atom.config.observe 'linter-opencl.vendor',
      (vendor) =>
        @vendor = vendor
    @subscriptions.add atom.config.observe 'linter-opencl.openCL',
      (openCL) =>
        @openCL = openCL
    @subscriptions.add atom.config.observe 'linter-opencl.hybridGraphics',
      (hybridGraphics) =>
        @hybridGraphics = hybridGraphics
    @subscriptions.add atom.config.observe 'linter-opencl.compilerFlags',
      (compilerFlags) =>
        @compilerFlags = compilerFlags
    @subscriptions.add atom.config.observe 'linter-opencl.debug',
      (debug) =>
        @debug = debug

  deactivate: ->
    @subscriptions.dispose()

  # Get compiler flags either from an '.opencl-flags.json' file or from global
  # settings
  getFlags: ->
    filePath = path.dirname(atom.workspace.getActiveTextEditor().getPath())
    config   = ''

    if atom.project.getPaths()[0] != undefined
      fileName      = '.opencl-flags.json' # File name searched for
      maxIterations = 32                   # Maximum number of folders checked
      currentPath   = filePath             # Current folder to check
      currentFile   = filePath + '/' + fileName  # Current full path to check

      # Check if the uppest directory contains an '.opencl-flags.json' file
      if fs.existsSync(currentFile)
        config = currentFile

      # Check next folders if not found already
      if config == ''
        projectPath  = atom.project.getPaths()[0] # Lowest path to check
        counter      = 0                          # Number of folders checked

        while path.relative(currentPath, projectPath) != '' && \
              counter < maxIterations
          # Check next folder
          currentPath = path.join(currentPath, '..')
          currentFile = path.join(currentPath, fileName)
          if fs.existsSync(currentFile)
            config = currentFile
            break
          ++counter

      if config != ''
        delete require.cache[config]

        configData = require(config) # Containing flags and include informations
        flags      = ''              # Will contain all flags

        if configData.flags != undefined
          # Add default flags
          flags += configData.flags

        if configData.includes != undefined
          for include in configData.includes
            # Expand paths if necessary
            if include.substring(0, 1) == '.'
              include = path.join(filePath, include)
            # Add include paths
            flags += ' -I \"' + include + '\"'

        # Return flags from an '.opencl-flags.json' file
        return flags

    # Return flags from global settings
    return atom.config.get('linter-opencl.compilerFlags')

  provideLinter: ->
    provider =
      grammarScopes: ['source.opencl']
      scope: 'file'
      lintOnFly: true,
      lint: (textEditor) =>
        filePath = textEditor.getPath() # Path to viewed file
        args     = []                   # Arguments given to linter
        debug    = @debug               # Wether debug log should pe printed
        vendor   = @vendor              # Activate vendor specific regex

        # Get offloader (on hybrid cards) and python executable
        if @hybridGraphics.enable
          executable = @hybridGraphics.offloadingPath
          args.push(@pythonPath)
        else
          executable = @pythonPath

        # Get OpenCL compiler
        args.push(__dirname + '/clCompiler.py')
        # File to lint
        args.push(filePath)
        # Get flags used during compiling
        flags = module.exports.getFlags()
        if flags.localeCompare(' ') != 0
          args.push('-f')
          args.push('\"' + flags + '\"')
        # Get platform to compile on
        args.push('-p')
        args.push(@openCL.platformIndex)

        if debug
          # Print full command
          command   = executable
          for a in args
            command = command + ' ' + a
          console.log(command)

        return new Promise (resolve, reject) ->
          helpers.exec(executable, args, {stream: 'stderr'})
          .then (output) ->
            if debug
              # Print full output of command
              console.log(output)
            lines         = output.split('\n')
            result        = []

            # Define vendor specific regex
            if vendor.localeCompare('AMD') == 0
              regex       = /[^,], line (\d+): ([^:]+): (.*)/
            else
              regex       = /[^:]:(\d+):(\d+): ([^:]+): (.*)/

            for line in lines
              # Retrive lines with e.g. warnings and errors
              match       = line.match(regex)
              if match
                console.log(line)
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
                result.push(
                  type:     type
                  text:     message
                  range:    [[row,col], [row,col]]
                  filePath: filePath
                )
            resolve result
}

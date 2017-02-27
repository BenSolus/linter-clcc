{SelectListView, $$} = require 'atom-space-pen-views'

cl = null

module.exports =
  class PlatformListView extends SelectListView
    viewForItem: (item) ->
      $$ -> @li(item)

    show: ->
      cl ?= require 'node-opencl'

      platformIDs = cl.getPlatformIDs()
      platforms   = []

      for platformID in platformIDs
        platforms.push(cl.getPlatformInfo(platformID, cl.PLATFORM_VERSION))

      super
      @addClass('overlay from-top')
      @setItems(platforms)
      @panel ?= atom.workspace.addModalPanel({ item: this })
      @panel.show()
      @focusFilterEditor()

    confirmed: (platform) ->
      cl ?= require 'node-opencl'

      platformIDs = cl.getPlatformIDs()

      index = 0

      for platformID in platformIDs
        if platform == cl.getPlatformInfo(platformID, cl.PLATFORM_VERSION)
          atom.config.set('linter-opencl.openCL.platformIndex', index)
          break
        ++index

      @panel.hide()

    toggle: ->
      super
      if @panel && @panel.isVisible()
        @cancel()
      else
        @show()

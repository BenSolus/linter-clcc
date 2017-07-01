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

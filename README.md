[![Build Status](https://travis-ci.org/BenSolus/linter-opencl.svg?branch=master)](https://travis-ci.org/BenSolus/linter-opencl)

# linter-opencl package

Linter plugin for [Linter](https://github.com/AtomLinter/Linter), provides an interface to the build functionality of OpenCL through
[node-opencl](https://github.com/mikeseven/node-opencl).

![linter-opencl gif](https://raw.githubusercontent.com/BenSolus/linter-opencl/master/linter-opencl.gif)

## Important info for user of hybrid graphics!

On systems with hybrid graphics, OpenCL will compile and lint for the
integrated graphics card by default. While Windows users just need to set the
platform index of the desired platform, Linux users who wants to use the
dedicated graphics card need to run atom through a GPU offloader like
```optirun```, e.g.

      $ optirun atom

and setting the platform index accordingly.

## Installation

1.  Install an OpenCL implementation for your device.
3.  Install [linter-opencl](https://github.com/BenSolus/linter-opencl) either
    through the settings window by searching and installing this package or
    through your command line by running
      apm install linter-opencl
4.  (Configure the OpenCL Platfrom, include paths and additional compiler flags
    preferences.)
5.  Restart Atom

## Project-Specific settings

When activating this package, it searches for a file called
```.opencl-flags.json``` in the project root directory using the following
syntax:

    {
      "compilerFlags": "-cl-mad-enable -cl-fast-relaxed-math",
      "includePaths": [".", "/opt/include"]
    }

If this file is present, it will replace the settings you specified in the
settings window. Relative paths (starting with ```.``` or ```..```) are
expanded with respect to the root folder.

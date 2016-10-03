# linter-opencl package

Linter plugin for [Linter](https://github.com/AtomLinter/Linter), provides an interface to the build functionality of OpenCL.

## Important info for user of hybrid graphics!

On systems with hybrid graphics, OpenCL will compile and lint for the integrated graphics card by default. While Windows users just need to set the platform index of the desired platform, Linux users who wants to use the dedicated graphics card need to enable the '''hybridGraphics''' option and provide the path to a GPU offloader like '''optirun''' to enable linting for those devices.

## Installation

1. Install [Python](https://www.python.org) and [PyOpenCL](https://mathema.tician.de/software/pyopencl/)
2. Install [linter](https://github.com/steelbrain/linter) and [linter-opencl](https://github.com/BenSolus/linter-opencl)
3. (Configure the path to Python in preferences.)
4. Go linting!

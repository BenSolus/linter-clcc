import pyopencl as cl
import numpy
import sys

if __name__ == "__main__":
    platforms = cl.get_platforms()
    ctx       = cl.Context(
        dev_type   = cl.device_type.ALL,
        properties = [(cl.context_properties.PLATFORM,
                       platforms[int(sys.argv[1])])]
    )
    f         = open(sys.argv[2], 'r')
    fstr      = "".join(f.readlines())
    program   = cl.Program(ctx, fstr).build()

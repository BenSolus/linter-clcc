import pyopencl as cl
import sys

if __name__ == "__main__":
    platformIndex = int(sys.argv[1])
    context = cl.Context(
        dev_type=cl.device_type.ALL,
        properties=[(cl.context_properties.PLATFORM,
                    cl.get_platforms()[platformIndex])]
    )
    source = "".join(open(sys.argv[2], 'r').readlines())
    flags = sys.argv[3]
    program = cl.Program(context, source)
    print('{:s}'.format(flags))
    if flags != '':
        program.build(options=[flags])
    else:
        program.build()

import pyopencl as cl
import sys
import getopt


def usage():
    print('Usage:')
    print('  clCompiler.py -h | --help')
    print('  clCompiler.py <path> [(-f <list> | --flags=<list>)] ' +
          '[(-p <index> | --platform=<index>)]\n')
    print('Options:')
    print('  -h --help                      Print this message and exit')
    print('  <path>                         Source file to compile')
    print('  -f <list> --flags=<list>       List of whitespace separeted ' +
          'compiler flags [default: ""]')
    print('  -p <index> --platform=<index>  Platform to compile on ' +
          '[default: 0]\n')
    print('Example:')
    print('  clCompiler.py -s "/path/to/sourcefile.cl" -p 1 ' +
          '-f "-cl-mad-enable -cl-fast-relaxed-math"\n')


if __name__ == "__main__":
    flags = ''
    platform = 0
    try:
        opts, args = getopt.getopt(
            sys.argv[2:],
            "f:hp:s:",
            ["flags=", "help", "platform=", "sourcefile="]
        )
    except getopt.GetoptError as err:
        print('\nError:')
        print('  \033[31m' + str(err) + '\033[0m\n')
        usage()
        sys.exit(1)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            print()
            print('  A front end for the OpenCL compiler, printing\n')
            usage()
            sys.exit(0)
        if opt in ('-f', '--flags'):
            flags = arg.replace('\"', '')
        if opt in ('-p', '--platform'):
            platform = int(arg)
    platforms = cl.get_platforms()
    ctx = cl.Context(
        dev_type=cl.device_type.ALL,
        properties=[(cl.context_properties.PLATFORM,
                    platforms[platform])]
    )
    f = open(sys.argv[1], 'r')
    fstr = "".join(f.readlines())
    program = cl.Program(ctx, fstr).build(options=[flags])

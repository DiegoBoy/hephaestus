#!/usr/bin/env python3

# Ś3ṣa: net BoF fuzz and exploit tool for py3
# https://en.wikipedia.org/wiki/Shesha

import argparse

def get_banner():
    return (
"################################################################\n"
"#                ,---,                    .____                #\n"
"#       ___    ,(0---0),    ___       _/_ |_  /  ___  __ _     #\n"
"#      /   \  / /\   /\ \  /   \     / __| |_ \ / __|/ _` |    #\n"
"#     |0| |0\ \-  \_/  -/ /0| |0|    \__ \,__) )\__ \ (_| |    #\n"
"#      \__/.----/  ^  \----.\__/     |___/\___/ |___/\__,_|.py #\n"
"# (x10k)^ /   ,   \ /   ,   \ ^                    °           #\n"
"#        /  /`\   / \   /'\, \                                 #\n" 
"#   ___  `\ \  \-  |  -/  /`/'       network buffer-overflow   #\n"
"#  /   \  |`\\\\_)`-- --'(_//           fuzzer & exploit tool    #\n"
"# |0| |0\ / | |_|`-- --'|_| _______                            #\n"
"#  \__/\____/,'`-   -'`.,-'/       `-.                         #\n"
"#            \---------/||            `-.      _,------.       #\n"
"#            \---------/`|    .--.       `----'   ___--.`--.   #\n"
"#             \---------/\. .\"    `.            ,'       `---' #\n"
"#             ``-._______.-'        `-._______.-'              #\n"
"################################################################\n")


def filler_type(value_string):
    if len(value_string) != 1:
        raise argparse.ArgumentTypeError("%s is not a valid char, check length" % value_string)
    value_int = ord(value_string)
    if value_int not in range(256):
        raise argparse.ArgumentTypeError("%s is not a valid char, choose in range [\\x00 - \\xFF]" % value_string)
    return value_string


def parse_args():
    print(get_banner())
    parser = argparse.ArgumentParser(prog='Ś3ṣa.py', formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    subparsers = parser.add_subparsers(title='sub-commands', required=True, metavar='MODE')
    add_fuzz_subparser(subparsers)
    add_offset_subparser(subparsers)
    add_badchars_subparser(subparsers)
    add_exploit_subparser(subparsers)
    
    add_global_parser(parser)
    parser.add_argument('target', help='target hostname or IP address', metavar='TARGET')
    parser.add_argument('port', help='target port', type=int, metavar='PORT')    

    return parser.parse_args()


def add_global_parser(parser):
    parser.add_argument('-t', '--timeout', help='connection timeout in seconds', type=int, default=5)
    parser.add_argument('-I', '--interactions', help='network messages sent previous to the payload', nargs='+', metavar='MSG', default=[])
    parser.add_argument('-p', '--prefix', help='prefix needed to trigger payload')
    parser.add_argument('-f', '--filler', help='char repeated to fill the buffer', type=filler_type, default='A')


def add_fuzz_subparser(subparsers):
    fuzz_parser = subparsers.add_parser('find-length', aliases=['fuzz'], help='for more options: fuzz -h')
    fuzz_parser.add_argument('-s', '--step', help='increase in buffer length per iteration', type=int, default=100)
    fuzz_parser.add_argument('-d', '--delay', help='wait time between iterations in seconds', type=int, default=1)
    fuzz_parser.set_defaults(func=fuzz)


def add_offset_subparser(subparsers):
    offset_parser = subparsers.add_parser('find-offset', aliases=['eip'], help='for more options: eip -h')
    offset_parser.set_defaults(func=lambda x: print('EIP parsed!'))


def add_badchars_subparser(subparsers):
    badchars_parser = subparsers.add_parser('find-bad', aliases=['bad'], help='for more options: bad -h')
    badchars_parser.set_defaults(func=lambda x: print('BadChars parsed!'))


def add_exploit_subparser(subparsers):
    exploit_parser = subparsers.add_parser('exploit', aliases=['pwn'], help='for more options: pwn -h')
    exploit_parser.set_defaults(func=lambda x: print('Exploit parsed!'))


def fuzz(args):
    print(vars(args))


def send_buffer(sock, overflow, prefix=None, retn=None, payload=None):
    buffer = prefix + overflow + retn + payload

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    try:
        s.connect((ip, port))
        print("Sending cyclic pattern...")
        s.send(bytes(buffer + "\r\n", "latin-1"))
        print("Done!")
    except:
        print("Could not connect.")

args = parse_args()
args.func(args)
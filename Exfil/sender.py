import ntpath
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])
filename = sys.argv[3]

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host, port))
print 'File sender connected to [%s:%d]' % (host, port)

filename_base = ntpath.basename(filename)
filename_len = len(filename_base)
s.send(str(chr(filename_len)))
s.send(filename_base)
print 'Sent target file name [%s]' % filename_base

total = 0
with open(filename, 'rb') as f:
    while True:
        file_content = f.read(1024)
        if not file_content:
            break

        total += s.send(file_content)

print 'Sent total [%d] bytes' % total
s.close()

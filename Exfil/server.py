import socket
import sys

port = int(sys.argv[1])

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(('', port))
s.listen(1)
print 'File receiver listening on port [%d]' % port

while True:
    conn, addr = s.accept()
    print 'Got connection from [%s:%d]' % (addr[0], addr[1])

    filename_len = ord(conn.recv(1))
    print 'Ready for filename of len [%d]' % filename_len
    filename = conn.recv(filename_len)
    print 'Ready for file [%s]' % filename

    total = 0
    with open(filename,'wb') as f:
        while True:
            data = conn.recv(1024)
            if not data:
                break

            total += len(data)
            f.write(data)
    
    print 'Received total [%d] bytes' % total
    conn.close()

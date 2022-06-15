import argparse
import ldap3

### vars ###
dc_server='192.168.156.100'
port=389
use_ssl=False
attributes='*'



### functions ###
# parse cmd line args
def parse_args():
    parser = argparse.ArgumentParser(prog='ldapsearch.py', formatter_class=argparse.ArgumentDefaultsHelpFormatter)

	# optional args
    parser.add_argument('-t', '--target', help='ldap hostname or IP address', type=str, required=True)
    parser.add_argument('-p', '--port', help='ldap/ldaps port', type=int, required=False, default=389)
    parser.add_argument('-s', '--use-ssl', help='Use SSL to connect to DC', required=False, default=False, action='store_true')
    parser.add_argument('-b', '--base', help='base dn for search', type=str, required=False)
    parser.add_argument('-f', '--filter', help='ldap query filter', type=str, required=False)
    parser.add_argument('-a', '--attributes', help='ldap attributes queried', type=str, required=False, default=['*'], nargs='*')
    parser.add_argument('-U', '--username', help='username for authentication', type=str, required=False)
    parser.add_argument('-P', '--password', help='password for authentication', type=str, required=False)
    
    return parser.parse_args()


# connect and bind to server
def connect(dc_server, port=389, use_ssl=False, user=None, password=None):
    server = ldap3.Server(dc_server, get_info=ldap3.ALL, port=port, use_ssl=use_ssl)
    connection = ldap3.Connection(server, user=user, password=password)

    if not connection.bind():
        exit("Could not bind to %s:%d (ssl=%s)" % (dc_server, port, str(use_ssl)))

    return connection


# execute ldap query
def search(connection, filter, attributes=['*'], base=None):
    if not base:
        base = connection.server.info.other['defaultNamingContext'][0]
        
    if not connection.search(search_base=base, search_filter=filter, search_scope='SUBTREE', attributes=attributes):
        exit("Could not search using base='%s', filter='%s', attributes='%s'" % (base, filter, attributes))

    return connection.entries


# connect and execute ldap query
def connect_and_search(dc_server, filter, base=None, use_ssl=False, port=389, attributes=['*'], user=None, password=None):
    connection = connect(dc_server, port, use_ssl, user, password)
    results = search(connection, base, filter, attributes)
    return results


# main
def main():
    args = parse_args()
    connection = connect(args.target, args.port, args.use_ssl, args.username, args.password)
        
    # if no filter arg, return server info instead of running query
    if not args.filter:
        print(connection.server.info)
    else:
        results = search(connection, args.filter, args.attributes, args.base)
        print(results)



### code ###
if __name__ == "__main__":
    main()
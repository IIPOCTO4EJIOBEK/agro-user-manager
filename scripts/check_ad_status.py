from ldap3 import Server, Connection, ALL, SUBTREE

AD_SERVER = '10.0.1.250'
AD_USER = 'Administrator@sync.rusagroeco.ru'
AD_PASS = 'Admin@2026Prostory!'
BASE_DN = 'DC=sync,DC=rusagroeco,DC=ru'

def main():
    print(f"Connecting to {AD_SERVER}...")
    server = Server(AD_SERVER, get_info=ALL)
    try:
        conn = Connection(server, user=AD_USER, password=AD_PASS, auto_bind=True)
        print("Connected successfully.")
        
        # Check users
        conn.search(BASE_DN, '(&(objectClass=user)(objectCategory=person))', SUBTREE, attributes=['sAMAccountName'])
        print(f"Total users in AD: {len(conn.entries)}")
        
        # Check OUs
        conn.search(BASE_DN, '(objectClass=organizationalUnit)', SUBTREE, attributes=['ou'])
        print(f"Total OUs in AD: {len(conn.entries)}")
        
        conn.unbind()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    main()

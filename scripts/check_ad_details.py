from ldap3 import Server, Connection, ALL, SUBTREE

AD_SERVER = '10.0.1.250'
AD_USER = 'Administrator@sync.rusagroeco.ru'
AD_PASS = 'Admin@2026Prostory!'
BASE_DN = 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru'

def main():
    server = Server(AD_SERVER, get_info=ALL)
    conn = Connection(server, user=AD_USER, password=AD_PASS, auto_bind=True)
    
    conn.search(BASE_DN, '(&(objectClass=user)(objectCategory=person))', SUBTREE, 
                attributes=['sAMAccountName', 'displayName', 'department', 'title', 'mail', 'userAccountControl'])
    
    print(f"Total users found in {BASE_DN}: {len(conn.entries)}")
    
    for entry in conn.entries[:10]:
        print(f"User: {entry.displayName}")
        print(f"  Login: {entry.sAMAccountName}")
        print(f"  Dept: {entry.department}")
        print(f"  Title: {entry.title}")
        print(f"  Mail: {entry.mail}")
        print(f"  UAC: {entry.userAccountControl}")
        print("-" * 20)

    conn.unbind()

if __name__ == '__main__':
    main()

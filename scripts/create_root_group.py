from ldap3 import Server, Connection, ALL, SUBTREE, MODIFY_ADD

AD_SERVER = '10.0.1.250'
AD_USER = 'Administrator@sync.rusagroeco.ru'
AD_PASS = 'Admin@2026Prostory!'
BASE_DN = 'DC=sync,DC=rusagroeco,DC=ru'
STRUCTURE_OU = 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru'
ROOT_GROUP_DN = f'CN=B24_Structure,{BASE_DN}'

def main():
    server = Server(AD_SERVER, get_info=ALL)
    conn = Connection(server, user=AD_USER, password=AD_PASS, auto_bind=True)

    # Create Group at the very root of the domain
    print(f"Creating Group: {ROOT_GROUP_DN}")
    conn.add(ROOT_GROUP_DN, 'group', {
        'cn': 'B24_Structure',
        'sAMAccountName': 'B24_Structure_Sync',
        'groupType': -2147483644 
    })

    # Find all users in B24_Structure OU
    conn.search(STRUCTURE_OU, '(&(objectClass=user)(objectCategory=person))', SUBTREE, attributes=['distinguishedName'])
    user_dns = [e.entry_dn for e in conn.entries]
    
    # Add users to group
    for u_dn in user_dns:
        conn.modify(ROOT_GROUP_DN, {'member': [(MODIFY_ADD, [u_dn])]})
    
    conn.unbind()
    print("Root group B24_Structure created.")

if __name__ == '__main__':
    main()

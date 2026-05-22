from ldap3 import Server, Connection, ALL, SUBTREE, MODIFY_ADD

AD_SERVER = '10.0.1.250'
AD_USER = 'Administrator@sync.rusagroeco.ru'
AD_PASS = 'Admin@2026Prostory!'
BASE_DN = 'DC=sync,DC=rusagroeco,DC=ru'
STRUCTURE_OU = 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru'
GROUP_DN = f'CN=B24_Structure_Group,{STRUCTURE_OU}'

def main():
    server = Server(AD_SERVER, get_info=ALL)
    conn = Connection(server, user=AD_USER, password=AD_PASS, auto_bind=True)

    # 1. Create Security Group
    print(f"Creating Group: {GROUP_DN}")
    conn.add(GROUP_DN, 'group', {
        'cn': 'B24_Structure_Group',
        'sAMAccountName': 'B24_Structure_Group',
        'groupType': -2147483644 # Global Security Group
    })

    # 2. Find all users in B24_Structure OU
    conn.search(STRUCTURE_OU, '(&(objectClass=user)(objectCategory=person))', SUBTREE, attributes=['distinguishedName'])
    user_dns = [e.entry_dn for e in conn.entries]
    print(f"Found {len(user_dns)} users to add to group.")

    # 3. Add users to group
    # We can do this in chunks or one by one
    for u_dn in user_dns:
        conn.modify(GROUP_DN, {'member': [(MODIFY_ADD, [u_dn])]})
    
    conn.unbind()
    print("Group created and users added.")

if __name__ == '__main__':
    main()

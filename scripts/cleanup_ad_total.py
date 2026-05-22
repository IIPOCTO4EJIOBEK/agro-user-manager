from ldap3 import Server, Connection, ALL, SUBTREE, LEVEL

AD_SERVER = '10.0.1.250'
AD_USER = 'Administrator@sync.rusagroeco.ru'
AD_PASS = 'Admin@2026Prostory!'
BASE_DN = 'DC=sync,DC=rusagroeco,DC=ru'

def delete_recursive(conn, dn):
    # Search for all objects under this DN (one level down)
    conn.search(dn, '(objectClass=*)', LEVEL, attributes=['distinguishedName', 'objectClass'])
    children = list(conn.entries)
    for child in children:
        child_dn = child.entry_dn
        if 'organizationalUnit' in child.objectClass:
            delete_recursive(conn, child_dn)
        else:
            print(f"Deleting user/object: {child_dn}")
            conn.delete(child_dn)
    
    print(f"Deleting OU: {dn}")
    conn.delete(dn)

def main():
    server = Server(AD_SERVER, get_info=ALL)
    conn = Connection(server, user=AD_USER, password=AD_PASS, auto_bind=True)
    
    # Get all Root OUs
    conn.search(BASE_DN, '(objectClass=organizationalUnit)', LEVEL, attributes=['ou', 'distinguishedName'])
    root_ous = [e.entry_dn for e in conn.entries]
    
    exclude_ous = [
        'OU=Domain Controllers,DC=sync,DC=rusagroeco,DC=ru',
        'OU=Microsoft Exchange Security Groups,DC=sync,DC=rusagroeco,DC=ru'
    ]
    
    for ou_dn in root_ous:
        if ou_dn in exclude_ous:
            print(f"Excluding OU: {ou_dn}")
            continue
        print(f"Processing Root OU: {ou_dn}")
        delete_recursive(conn, ou_dn)

    # Delete any users in other containers (except CN=Users)
    # Actually, root OUs should cover most.
    # Let's check for any remaining users not in CN=Users or OU=Domain Controllers
    conn.search(BASE_DN, '(&(objectClass=user)(objectCategory=person))', SUBTREE, attributes=['distinguishedName'])
    all_users = [e.entry_dn for e in conn.entries]
    for u_dn in all_users:
        if 'CN=Users,' in u_dn or 'OU=Domain Controllers,' in u_dn:
            continue
        print(f"Deleting loose user: {u_dn}")
        conn.delete(u_dn)

    conn.unbind()
    print("Cleanup Finished.")

if __name__ == '__main__':
    main()

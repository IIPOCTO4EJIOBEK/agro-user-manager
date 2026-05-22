import json
from ldap3 import Server, Connection, ALL, SUBTREE, MODIFY_REPLACE

AD_SERVER = '10.0.1.250'
AD_USER = 'Administrator@sync.rusagroeco.ru'
AD_PASS = 'Admin@2026Prostory!'
BASE_DN = 'DC=sync,DC=rusagroeco,DC=ru'
STRUCTURE_OU = 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru'

def get_manager_map(structure, parent_manager=None):
    mapping = {}
    if isinstance(structure, dict):
        current_name = structure.get('head')
        # All employees in this node report to current_name
        # If no head, they report to parent_manager
        manager_for_this_level = current_name if current_name else parent_manager
        
        if 'employees' in structure:
            for emp in structure['employees']:
                name = emp.get('name')
                if name and manager_for_this_level and name != manager_for_this_level:
                    mapping[name] = manager_for_this_level
        
        if 'sub' in structure:
            for sub in structure['sub']:
                sub_head = sub.get('head')
                # If sub_head exists, it reports to manager_for_this_level
                if sub_head and manager_for_this_level and sub_head != manager_for_this_level:
                    mapping[sub_head] = manager_for_this_level
                mapping.update(get_manager_map(sub, manager_for_this_level))
                
    elif isinstance(structure, list):
        for item in structure:
            mapping.update(get_manager_map(item, parent_manager))
    return mapping

def main():
    server = Server(AD_SERVER, get_info=ALL)
    conn = Connection(server, user=AD_USER, password=AD_PASS, auto_bind=True)

    # 1. Get all users in AD to map DisplayName -> DN
    print("Mapping users to DNs...")
    conn.search(STRUCTURE_OU, '(&(objectClass=user)(objectCategory=person))', SUBTREE, attributes=['displayName', 'distinguishedName'])
    name_to_dn = {e.displayName.value: e.entry_dn for e in conn.entries if e.displayName}

    # 2. Build Manager Map from JSON
    print("Building manager relations from structure...")
    with open('final_structure_mapped.json', 'r', encoding='utf-8') as f:
        structure = json.load(f)
    
    # The root of structure.json is the top-level entity
    # "head": "Дышлюк Борис Александрович"
    manager_names = get_manager_map(structure)
    
    # Special Case: Semerenko and others might have different parent in the hierarchy
    # But get_manager_map should handle it recursively.

    # 3. Update Users
    print("Activating users and setting managers...")
    updated = 0
    errors = 0
    no_manager = 0

    for name, dn in name_to_dn.items():
        # Step 1: Set Manager
        m_name = manager_names.get(name)
        if name == "Семеренко Алина Сергеевна":
             m_name = "Дышлюк Борис Александрович"
             
        if m_name and m_name in name_to_dn:
            conn.modify(dn, {'manager': [(MODIFY_REPLACE, [name_to_dn[m_name]])]})
        else:
            no_manager += 1

        # Step 2: Try to activate
        # First try to set pwdLastSet to -1 (user must NOT change password) or just activate
        # Many ADs require pwdLastSet to be non-zero to activate if there's a policy
        
        # Try setting 66048 directly
        success = conn.modify(dn, {'userAccountControl': [(MODIFY_REPLACE, [66048])]})
        if success:
            updated += 1
        else:
            # print(f"Failed to activate {name}: {conn.result}")
            errors += 1

    conn.unbind()
    print(f"Finished. Updated: {updated}, Errors: {errors}, Users without manager: {no_manager}")

if __name__ == '__main__':
    main()

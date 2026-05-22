"""
Active Directory Group Creation Script

This script creates a security group in Active Directory and adds all users
from the B24_Structure OU to it.
Configuration should be moved to environment variables or a config file.
"""

from ldap3 import Server, Connection, ALL, SUBTREE, MODIFY_ADD
import os
import sys
from typing import List, Optional


class ADConfig:
    """Active Directory configuration settings."""
    
    def __init__(self):
        self.server = os.getenv('AD_SERVER', '10.0.1.250')
        self.username = os.getenv('AD_USER', 'Administrator@sync.rusagroeco.ru')
        self.password = os.getenv('AD_PASS', 'Admin@2026Prostory!')
        self.structure_ou = os.getenv('AD_STRUCTURE_OU', 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru')
        self.group_name = os.getenv('AD_GROUP_NAME', 'B24_Structure_Group')


class ADGroupManager:
    """Active Directory group management operations."""
    
    def __init__(self, server: str, username: str, password: str):
        self.server = server
        self.username = username
        self.password = password
        self.conn: Optional[Connection] = None
    
    def connect(self) -> None:
        """Establish LDAP connection."""
        ldap_server = Server(self.server, get_info=ALL)
        self.conn = Connection(ldap_server, user=self.username, password=self.password, auto_bind=True)
    
    def disconnect(self) -> None:
        """Close LDAP connection."""
        if self.conn:
            self.conn.unbind()
    
    def create_group(self, group_dn: str, group_name: str) -> bool:
        """
        Create a security group in Active Directory.
        
        Args:
            group_dn: Distinguished Name for the new group
            group_name: Common name for the group
            
        Returns:
            True if successful, False otherwise
        """
        if not self.conn:
            raise RuntimeError("Not connected to AD")
        
        print(f"Creating Group: {group_dn}")
        
        # Global Security Group type
        group_type = -2147483644
        
        success = self.conn.add(group_dn, 'group', {
            'cn': group_name,
            'sAMAccountName': group_name,
            'groupType': group_type
        })
        
        if success:
            print(f"✓ Group '{group_name}' created successfully")
        else:
            print(f"✗ Failed to create group: {self.conn.result}")
        
        return success
    
    def get_users_in_ou(self, ou_dn: str) -> List[str]:
        """
        Get all users in an organizational unit.
        
        Args:
            ou_dn: Distinguished Name of the OU
            
        Returns:
            List of user distinguished names
        """
        if not self.conn:
            raise RuntimeError("Not connected to AD")
        
        self.conn.search(ou_dn, '(&(objectClass=user)(objectCategory=person))', 
                        SUBTREE, attributes=['distinguishedName'])
        
        return [e.entry_dn for e in self.conn.entries]
    
    def add_members_to_group(self, group_dn: str, member_dns: List[str]) -> int:
        """
        Add members to a group.
        
        Args:
            group_dn: Distinguished Name of the group
            member_dns: List of member distinguished names
            
        Returns:
            Number of members added successfully
        """
        if not self.conn:
            raise RuntimeError("Not connected to AD")
        
        added_count = 0
        
        for member_dn in member_dns:
            success = self.conn.modify(group_dn, {'member': [(MODIFY_ADD, [member_dn])]})
            if success:
                added_count += 1
            else:
                print(f"  Warning: Failed to add {member_dn}: {self.conn.result}")
        
        return added_count
    
    def create_and_populate_group(self, config: ADConfig) -> None:
        """
        Create a group and populate it with users from B24_Structure OU.
        
        Args:
            config: AD configuration object
        """
        self.connect()
        
        try:
            group_dn = f"CN={config.group_name},{config.structure_ou}"
            
            # Step 1: Create Security Group
            if not self.create_group(group_dn, config.group_name):
                print("Group creation failed or group already exists. Continuing with member addition...")
            
            # Step 2: Find all users in B24_Structure OU
            print(f"\nSearching for users in: {config.structure_ou}")
            user_dns = self.get_users_in_ou(config.structure_ou)
            print(f"Found {len(user_dns)} users to add to group.")
            
            # Step 3: Add users to group
            if user_dns:
                print("\nAdding users to group...")
                added = self.add_members_to_group(group_dn, user_dns)
                print(f"✓ Successfully added {added}/{len(user_dns)} users to group.")
            
            print("\n✓ Group operation completed.")
            
        finally:
            self.disconnect()


def main() -> None:
    """Main entry point."""
    config = ADConfig()
    
    print("=" * 60)
    print("Active Directory Group Creation")
    print("=" * 60)
    print(f"Server: {config.server}")
    print(f"Structure OU: {config.structure_ou}")
    print(f"Group Name: {config.group_name}")
    print("=" * 60)
    
    try:
        manager = ADGroupManager(config.server, config.username, config.password)
        manager.create_and_populate_group(config)
    except Exception as e:
        print(f"✗ Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()

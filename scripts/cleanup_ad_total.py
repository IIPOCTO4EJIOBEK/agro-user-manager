"""
Active Directory Cleanup Script

This script performs recursive cleanup of Active Directory OUs and users.
Configuration should be moved to environment variables or a config file.
WARNING: This script deletes data - use with extreme caution!
"""

from ldap3 import Server, Connection, ALL, SUBTREE, LEVEL
import os
import sys
from typing import List, Optional


class ADConfig:
    """Active Directory configuration settings."""
    
    def __init__(self):
        self.server = os.getenv('AD_SERVER', '10.0.1.250')
        self.username = os.getenv('AD_USER', 'Administrator@sync.rusagroeco.ru')
        self.password = os.getenv('AD_PASS', 'Admin@2026Prostory!')
        self.base_dn = os.getenv('AD_BASE_DN', 'DC=sync,DC=rusagroeco,DC=ru')
        
        # OUs to exclude from cleanup
        self.exclude_ous = [
            'OU=Domain Controllers,DC=sync,DC=rusagroeco,DC=ru',
            'OU=Microsoft Exchange Security Groups,DC=sync,DC=rusagroeco,DC=ru',
            'CN=Users,DC=sync,DC=rusagroeco,DC=ru',
        ]


class ADCleanup:
    """Active Directory cleanup operations."""
    
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
    
    def delete_recursive(self, dn: str) -> None:
        """
        Recursively delete all objects under a DN.
        
        Args:
            dn: Distinguished Name to clean up
        """
        if not self.conn:
            raise RuntimeError("Not connected to AD")
        
        # Search for all objects under this DN (one level down)
        self.conn.search(dn, '(objectClass=*)', LEVEL, attributes=['distinguishedName', 'objectClass'])
        children = list(self.conn.entries)
        
        for child in children:
            child_dn = child.entry_dn
            object_classes = child.objectClass.values if hasattr(child.objectClass, 'values') else []
            
            if 'organizationalUnit' in object_classes:
                print(f"Processing OU: {child_dn}")
                self.delete_recursive(child_dn)
            else:
                print(f"  Deleting user/object: {child_dn}")
                self.conn.delete(child_dn)
        
        print(f"Deleting OU: {dn}")
        self.conn.delete(dn)
    
    def get_root_ous(self, base_dn: str) -> List[str]:
        """
        Get all root-level OUs.
        
        Args:
            base_dn: Base DN for search
            
        Returns:
            List of OU distinguished names
        """
        if not self.conn:
            raise RuntimeError("Not connected to AD")
        
        self.conn.search(base_dn, '(objectClass=organizationalUnit)', LEVEL, 
                        attributes=['ou', 'distinguishedName'])
        return [e.entry_dn for e in self.conn.entries]
    
    def get_loose_users(self, base_dn: str, exclude_ous: List[str]) -> List[str]:
        """
        Find users not in excluded containers.
        
        Args:
            base_dn: Base DN for search
            exclude_ous: List of OU patterns to exclude
            
        Returns:
            List of user distinguished names
        """
        if not self.conn:
            raise RuntimeError("Not connected to AD")
        
        self.conn.search(base_dn, '(&(objectClass=user)(objectCategory=person))', 
                        SUBTREE, attributes=['distinguishedName'])
        
        all_users = [e.entry_dn for e in self.conn.entries]
        loose_users = []
        
        for u_dn in all_users:
            # Check if user is in any excluded container
            is_excluded = any(excl in u_dn for excl in exclude_ous)
            if not is_excluded:
                loose_users.append(u_dn)
        
        return loose_users
    
    def cleanup(self, config: ADConfig) -> None:
        """
        Perform full AD cleanup.
        
        Args:
            config: AD configuration object
        """
        self.connect()
        
        try:
            # Get all Root OUs
            root_ous = self.get_root_ous(config.base_dn)
            
            print(f"Found {len(root_ous)} root OUs")
            
            for ou_dn in root_ous:
                if ou_dn in config.exclude_ous:
                    print(f"Excluding OU: {ou_dn}")
                    continue
                
                print(f"\nProcessing Root OU: {ou_dn}")
                self.delete_recursive(ou_dn)
            
            # Check for any remaining users not in excluded containers
            print("\nChecking for loose users...")
            loose_users = self.get_loose_users(config.base_dn, config.exclude_ous)
            
            for u_dn in loose_users:
                print(f"Deleting loose user: {u_dn}")
                self.conn.delete(u_dn)
            
            print("\n✓ Cleanup finished.")
            
        finally:
            self.disconnect()


def main() -> None:
    """Main entry point."""
    config = ADConfig()
    
    print("=" * 60)
    print("WARNING: This script will DELETE Active Directory objects!")
    print("=" * 60)
    
    # Confirm before proceeding
    confirm = input("\nType 'DELETE' to confirm: ")
    if confirm != 'DELETE':
        print("Operation cancelled.")
        sys.exit(0)
    
    try:
        cleaner = ADCleanup(config.server, config.username, config.password)
        cleaner.cleanup(config)
    except Exception as e:
        print(f"✗ Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()

"""
Active Directory Status Checker

This script checks the status of Active Directory including user and OU counts.
Configuration should be moved to environment variables or a config file.
"""

from ldap3 import Server, Connection, ALL, SUBTREE
import os
import sys
from typing import Optional, Tuple


class ADConfig:
    """Active Directory configuration settings."""
    
    def __init__(self):
        self.server = os.getenv('AD_SERVER', '10.0.1.250')
        self.username = os.getenv('AD_USER', 'Administrator@sync.rusagroeco.ru')
        self.password = os.getenv('AD_PASS', 'Admin@2026Prostory!')
        self.base_dn = os.getenv('AD_BASE_DN', 'DC=sync,DC=rusagroeco,DC=ru')


class ADConnection:
    """Context manager for LDAP connections."""
    
    def __init__(self, server: str, username: str, password: str):
        self.server = server
        self.username = username
        self.password = password
        self.conn: Optional[Connection] = None
    
    def __enter__(self) -> Connection:
        ldap_server = Server(self.server, get_info=ALL)
        self.conn = Connection(ldap_server, user=self.username, password=self.password, auto_bind=True)
        return self.conn
    
    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        if self.conn:
            self.conn.unbind()


def count_users(conn: Connection, base_dn: str) -> int:
    """
    Count users in Active Directory.
    
    Args:
        conn: LDAP connection object
        base_dn: Base DN for search
        
    Returns:
        Number of users found
    """
    conn.search(
        base_dn, 
        '(&(objectClass=user)(objectCategory=person))', 
        SUBTREE, 
        attributes=['sAMAccountName']
    )
    return len(conn.entries)


def count_ous(conn: Connection, base_dn: str) -> int:
    """
    Count organizational units in Active Directory.
    
    Args:
        conn: LDAP connection object
        base_dn: Base DN for search
        
    Returns:
        Number of OUs found
    """
    conn.search(
        base_dn, 
        '(objectClass=organizationalUnit)', 
        SUBTREE, 
        attributes=['ou']
    )
    return len(conn.entries)


def check_ad_status(config: ADConfig) -> Tuple[int, int]:
    """
    Check Active Directory status.
    
    Args:
        config: AD configuration object
        
    Returns:
        Tuple of (user_count, ou_count)
    """
    with ADConnection(config.server, config.username, config.password) as conn:
        user_count = count_users(conn, config.base_dn)
        ou_count = count_ous(conn, config.base_dn)
        return user_count, ou_count


def main() -> None:
    """Main entry point."""
    config = ADConfig()
    
    print(f"Connecting to {config.server}...")
    
    try:
        user_count, ou_count = check_ad_status(config)
        
        print("✓ Connected successfully.\n")
        print("=" * 40)
        print(f"Total users in AD: {user_count}")
        print(f"Total OUs in AD: {ou_count}")
        print("=" * 40)
        
    except Exception as e:
        print(f"✗ Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()

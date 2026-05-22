"""
Active Directory User Details Checker

This script retrieves and displays user details from Active Directory.
Configuration should be moved to environment variables or a config file.
"""

from ldap3 import Server, Connection, ALL, SUBTREE
import os
from typing import List, Dict, Any, Optional


class ADConfig:
    """Active Directory configuration settings."""
    
    def __init__(self):
        self.server = os.getenv('AD_SERVER', '10.0.1.250')
        self.username = os.getenv('AD_USER', 'Administrator@sync.rusagroeco.ru')
        self.password = os.getenv('AD_PASS', 'Admin@2026Prostory!')
        self.base_dn = os.getenv('AD_BASE_DN', 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru')


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


def get_user_details(conn: Connection, base_dn: str, limit: int = 10) -> List[Dict[str, Any]]:
    """
    Retrieve user details from Active Directory.
    
    Args:
        conn: LDAP connection object
        base_dn: Base DN for search
        limit: Maximum number of users to retrieve
        
    Returns:
        List of user dictionaries
    """
    attributes = [
        'sAMAccountName', 'displayName', 'department', 
        'title', 'mail', 'userAccountControl'
    ]
    
    conn.search(
        base_dn, 
        '(&(objectClass=user)(objectCategory=person))', 
        SUBTREE, 
        attributes=attributes
    )
    
    users = []
    for entry in conn.entries[:limit]:
        user = {
            'display_name': str(entry.displayName) if entry.displayName else 'N/A',
            'login': str(entry.sAMAccountName) if entry.sAMAccountName else 'N/A',
            'department': str(entry.department) if entry.department else 'N/A',
            'title': str(entry.title) if entry.title else 'N/A',
            'email': str(entry.mail) if entry.mail else 'N/A',
            'account_control': entry.userAccountControl.value if entry.userAccountControl else 'N/A'
        }
        users.append(user)
    
    return users


def print_users(users: List[Dict[str, Any]], base_dn: str) -> None:
    """Print formatted user details."""
    print(f"\nTotal users found in {base_dn}: {len(users)}\n")
    print("=" * 60)
    
    for user in users:
        print(f"User: {user['display_name']}")
        print(f"  Login: {user['login']}")
        print(f"  Department: {user['department']}")
        print(f"  Title: {user['title']}")
        print(f"  Email: {user['email']}")
        print(f"  Account Control: {user['account_control']}")
        print("-" * 60)


def main() -> None:
    """Main entry point."""
    config = ADConfig()
    
    try:
        with ADConnection(config.server, config.username, config.password) as conn:
            users = get_user_details(conn, config.base_dn)
            print_users(users, config.base_dn)
    except Exception as e:
        print(f"Error connecting to Active Directory: {e}")
        raise


if __name__ == '__main__':
    main()

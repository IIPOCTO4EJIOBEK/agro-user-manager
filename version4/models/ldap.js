const ldap = require('ldapjs');
const config = require('../config/config');

class LDAPService {
  constructor() {
    this.client = null;
  }

  async connect() {
    return new Promise((resolve, reject) => {
      this.client = ldap.createClient({
        url: config.ldap.url
      });

      this.client.on('error', (err) => {
        console.error('LDAP Error:', err);
        reject(err);
      });

      this.client.bind(config.ldap.bindDN, config.ldap.bindPassword, (err) => {
        if (err) {
          console.error('LDAP Bind Error:', err);
          reject(err);
        } else {
          console.log('✓ Connected to LDAP');
          resolve();
        }
      });
    });
  }

  async authenticate(username, password) {
    return new Promise((resolve, reject) => {
      const searchFilter = `(sAMAccountName=${username})`;
      
      this.client.search(config.ldap.baseDN, {
        filter: searchFilter,
        scope: 'sub',
        attributes: ['dn', 'displayName', 'mail', 'memberOf']
      }, (err, res) => {
        if (err) {
          reject(err);
          return;
        }

        let userDN = null;
        let userAttrs = {};

        res.on('searchEntry', (entry) => {
          userDN = entry.dn;
          userAttrs = entry.attributes;
        });

        res.on('end', () => {
          if (!userDN) {
            reject(new Error('User not found'));
            return;
          }

          // Try to bind with user credentials
          const tempClient = ldap.createClient({ url: config.ldap.url });
          tempClient.bind(userDN, password, (bindErr) => {
            if (bindErr) {
              reject(new Error('Invalid credentials'));
            } else {
              const user = {
                dn: userDN,
                username: username,
                displayName: this._getAttribute(userAttrs, 'displayName'),
                email: this._getAttribute(userAttrs, 'mail'),
                memberOf: this._getAttribute(userAttrs, 'memberOf') || []
              };
              resolve(user);
            }
            tempClient.unbind();
          });
        });

        res.on('error', reject);
      });
    });
  }

  async checkGroupMembership(userDN, groupName) {
    return new Promise((resolve, reject) => {
      const groupCN = config.adGroups[groupName.toLowerCase()] || groupName;
      const searchFilter = `(&(objectClass=group)(cn=${groupCN}))`;

      this.client.search(config.ldap.baseDN, {
        filter: searchFilter,
        scope: 'sub',
        attributes: ['member']
      }, (err, res) => {
        if (err) {
          reject(err);
          return;
        }

        let isMember = false;

        res.on('searchEntry', (entry) => {
          const members = entry.attributes.find(a => a.type === 'member')?.values || [];
          isMember = members.some(member => 
            member.toLowerCase().includes(userDN.toLowerCase())
          );
        });

        res.on('end', () => resolve(isMember));
        res.on('error', reject);
      });
    });
  }

  async getUserGroups(userDN) {
    return new Promise((resolve, reject) => {
      const searchFilter = '(objectClass=group)';
      const userGroups = [];

      this.client.search(config.ldap.baseDN, {
        filter: searchFilter,
        scope: 'sub',
        attributes: ['cn', 'member']
      }, (err, res) => {
        if (err) {
          reject(err);
          return;
        }

        res.on('searchEntry', (entry) => {
          const members = entry.attributes.find(a => a.type === 'member')?.values || [];
          const cn = entry.attributes.find(a => a.type === 'cn')?.values?.[0];
          
          if (members.some(member => member.toLowerCase().includes(userDN.toLowerCase()))) {
            userGroups.push(cn);
          }
        });

        res.on('end', () => resolve(userGroups));
        res.on('error', reject);
      });
    });
  }

  _getAttribute(attributes, name) {
    const attr = attributes.find(a => a.type === name);
    if (!attr) return null;
    
    const values = attr.values;
    if (Array.isArray(values)) {
      return values.length === 1 ? values[0] : values;
    }
    return values;
  }

  async disconnect() {
    if (this.client) {
      return new Promise((resolve) => {
        this.client.unbind(() => {
          console.log('✓ Disconnected from LDAP');
          resolve();
        });
      });
    }
  }
}

module.exports = new LDAPService();

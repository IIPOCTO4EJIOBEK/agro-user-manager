const ldap = require('ldapjs');
const { exec } = require('child_process');
const util = require('util');
const config = require('../config/config');

const execPromise = util.promisify(exec);

class LDAPService {
  constructor() {
    this.client = null;
    this.primaryHost = config.ldap.primary;
    this.secondaryHost = config.ldap.secondary;
    this.baseDN = config.ldap.baseDN;
    this.adminDN = config.ldap.adminDN;
    this.adminPassword = config.ldap.adminPassword;
  }

  async connect(host = null, bindUser = null, bindPass = null) {
    const targetHost = host || process.env.LDAP_ACTIVE_HOST || this.primaryHost;
    const useUser = bindUser || this.adminDN;
    const usePass = bindPass || this.adminPassword;
    
    return new Promise((resolve, reject) => {
      const client = ldap.createClient({
        url: targetHost,
        tlsOptions: { rejectUnauthorized: false }
      });

      client.on('error', (err) => {
        console.error(`LDAP connection error to ${targetHost}:`, err.message);
        if (!client.connected) { reject(err); }
      });

      client.bind(useUser, usePass, (err) => {
        if (err) {
          console.error(`LDAP bind error: ${err.message}`);
          client.destroy();
          if (targetHost === this.primaryHost && this.secondaryHost) {
            console.log('Falling back to secondary LDAP server...');
            this.connect(this.secondaryHost, bindUser, bindPass).then(resolve).catch(reject);
          } else { reject(err); }
        } else {
          this.client = client;
          console.log(`Connected to LDAP: ${targetHost}`);
          resolve(client);
        }
      });

      setTimeout(() => {
        if (!this.client) { client.destroy(); reject(new Error('LDAP connection timeout')); }
      }, 10000);
    });
  }

  async ensureConnected(bindUser = null, bindPass = null) {
    if (!this.client) {
      await this.connect(null, bindUser, bindPass);
    }
    return this.client;
  }

  async searchUsers(filter, attributes = ['cn', 'sAMAccountName', 'mail', 'distinguishedName', 'userAccountControl', 'memberOf']) {
    const client = await this.ensureConnected(global.currentBindDN, global.currentBindPass);
    
    return new Promise((resolve, reject) => {
      const opts = {
        scope: 'sub',
        filter: filter,
        attributes: attributes,
        paged: true
      };

      const results = [];
      
      client.search(this.baseDN, opts, (err, res) => {
        if (err) {
          return reject(err);
        }

        res.on('searchEntry', (entry) => {
          results.push(entry.object);
        });

        res.on('error', (err) => {
          reject(err);
        });

        res.on('end', () => {
          resolve(results);
        });
      });
    });
  }

  async getUserBySAM(sAMAccountName) {
    const filter = `(&(objectClass=user)(sAMAccountName=${sAMAccountName}))`;
    const users = await this.searchUsers(filter);
    return users.length > 0 ? users[0] : null;
  }

  async getUserByDN(dn) {
    const filter = `(distinguishedName=${dn})`;
    const users = await this.searchUsers(filter);
    return users.length > 0 ? users[0] : null;
  }

  async authenticate(username, password) {
    try {
      const host = process.env.LDAP_ACTIVE_HOST || this.primaryHost;
      const upn = username.includes('@') ? username : username + '@rusagroeco.ru';
      
      return new Promise((resolve) => {
        const client = ldap.createClient({
          url: host,
          tlsOptions: { rejectUnauthorized: false }
        });

        client.bind(upn, password, (err) => {
          client.destroy();
          if (err) {
            resolve({ success: false, message: 'Invalid credentials' });
          } else {
            resolve({ success: true, user: { sAMAccountName: username, distinguishedName: upn } });
          }
        });

        setTimeout(() => {
          client.destroy();
          resolve({ success: false, message: 'Authentication timeout' });
        }, 10000);
      });
    } catch (error) {
      return { success: false, message: error.message };
    }
  }

  async checkGroupMembership(userDN, groupName) {
    try {
      const filter = `(&(objectClass=group)(cn=${groupName}))`;
      const groups = await this.searchUsers(filter, ['cn', 'member']);
      
      if (groups.length === 0) {
        return false;
      }

      const group = groups[0];
      if (!group.member) {
        return false;
      }

      const members = Array.isArray(group.member) ? group.member : [group.member];
      return members.some(member => member.toLowerCase() === userDN.toLowerCase());
    } catch (error) {
      console.error('Error checking group membership:', error);
      return false;
    }
  }

  async getUserGroups(userDN) {
    try {
      const user = await this.getUserByDN(userDN);
      if (!user || !user.memberOf) {
        return [];
      }

      const groups = Array.isArray(user.memberOf) ? user.memberOf : [user.memberOf];
      return groups.map(g => {
        const match = g.match(/CN=([^,]+)/);
        return match ? match[1] : g;
      });
    } catch (error) {
      console.error('Error getting user groups:', error);
      return [];
    }
  }

  async isUserInAnyGroup(userDN, groupNames) {
    for (const groupName of groupNames) {
      const isMember = await this.checkGroupMembership(userDN, groupName);
      if (isMember) {
        return true;
      }
    }
    return false;
  }

  // Enable/Disable user using UAC flags
  async setUserEnabled(dn, enabled) {
    const UAC_NORMAL_ACCOUNT = 512;
    const UAC_DISABLED = 514;
    
    const uacValue = enabled ? UAC_NORMAL_ACCOUNT : UAC_DISABLED;
    
    const ldif = `
dn: ${dn}
changetype: modify
replace: userAccountControl
userAccountControl: ${uacValue}
`;

    return await this.executeLDIF(ldif);
  }

  async addUserToGroup(userDN, groupDN) {
    const ldif = `
dn: ${groupDN}
changetype: modify
add: member
member: ${userDN}
`;

    return await this.executeLDIF(ldif);
  }

  async removeUserFromGroup(userDN, groupDN) {
    const ldif = `
dn: ${groupDN}
changetype: modify
delete: member
member: ${userDN}
`;

    return await this.executeLDIF(ldif);
  }

  async executeLDIF(ldifContent) {
    const tempFile = `/tmp/ldap_modify_${Date.now()}.ldif`;
    
    try {
      // Write LDIF to temp file
      await execPromise(`echo "${ldifContent.trim()}" > ${tempFile}`);
      
      // Execute ldapmodify
      const cmd = `ldapmodify -H ${this.primaryHost} -D "${this.adminDN}" -w "${this.adminPassword}" -f ${tempFile}`;
      const result = await execPromise(cmd);
      
      // Cleanup temp file
      await execPromise(`rm -f ${tempFile}`);
      
      return { success: true, message: 'Operation completed successfully' };
    } catch (error) {
      // Cleanup temp file on error
      await execPromise(`rm -f ${tempFile}`);
      return { success: false, message: error.stderr || error.message };
    }
  }

  async searchGroups(filter, attributes = ['cn', 'distinguishedName', 'member']) {
    const groupFilter = `(&(objectClass=group)${filter})`;
    return await this.searchUsers(groupFilter, attributes);
  }

  async getAllGroups() {
    return await this.searchGroups('(cn=*)');
  }

  close() {
    if (this.client) {
      this.client.unbind();
      this.client = null;
    }
  }
}

module.exports = new LDAPService();

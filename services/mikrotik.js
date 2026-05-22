const { Client } = require('ssh2');
const config = require('../config/config');

class MikroTikService {
  constructor() {
    this.connection = null;
    this.homeRouterConnection = null;
  }

  async connect(host = null, port = null) {
    const targetHost = host || config.mikrotik.host;
    const targetPort = port || config.mikrotik.port;
    const isHomeRouter = targetHost === config.homeRouter.host;
    
    const connConfig = {
      host: targetHost,
      port: targetPort,
      username: isHomeRouter ? config.homeRouter.user : config.mikrotik.user,
      password: isHomeRouter ? config.homeRouter.password : config.mikrotik.password,
      readyTimeout: 10000,
      keepaliveInterval: 10000
    };

    return new Promise((resolve, reject) => {
      const client = new Client();
      
      client.on('ready', () => {
        console.log(`Connected to MikroTik: ${targetHost}`);
        if (isHomeRouter) {
          this.homeRouterConnection = client;
        } else {
          this.connection = client;
        }
        resolve(client);
      });

      client.on('error', (err) => {
        console.error(`MikroTik connection error: ${err.message}`);
        reject(err);
      });

      client.on('close', () => {
        console.log(`MikroTik connection closed: ${targetHost}`);
        if (isHomeRouter) {
          this.homeRouterConnection = null;
        } else {
          this.connection = null;
        }
      });

      client.connect(connConfig);

      // Timeout handling
      setTimeout(() => {
        if (!this.connection && !this.homeRouterConnection) {
          client.end();
          reject(new Error('MikroTik connection timeout'));
        }
      }, 15000);
    });
  }

  async ensureConnected(isHomeRouter = false) {
    const targetConn = isHomeRouter ? this.homeRouterConnection : this.connection;
    
    if (!targetConn) {
      if (isHomeRouter) {
        await this.connect(config.homeRouter.host, 22);
      } else {
        await this.connect();
      }
    }
    
    return isHomeRouter ? this.homeRouterConnection : this.connection;
  }

  async executeCommand(command, isHomeRouter = false) {
    const client = await this.ensureConnected(isHomeRouter);
    
    return new Promise((resolve, reject) => {
      client.exec(command, (err, stream) => {
        if (err) {
          return reject(err);
        }

        let output = '';
        let errorOutput = '';

        stream.on('close', (code) => {
          resolve({
            success: code === 0,
            output: output.trim(),
            error: errorOutput.trim(),
            code: code
          });
        });

        stream.stderr.on('data', (data) => {
          errorOutput += data.toString();
        });

        stream.on('data', (data) => {
          output += data.toString();
        });
      });
    });
  }

  // Get hotspot stats
  async getHotspotStats() {
    try {
      const result = await this.executeCommand('/ip hotspot print stats');
      
      if (!result.success) {
        throw new Error(result.error);
      }

      // Parse the output
      const lines = result.output.split('\n').filter(line => line.trim());
      const stats = {};
      
      for (const line of lines) {
        const match = line.match(/(\w+):\s*(.+)/);
        if (match) {
          stats[match[1]] = match[2].trim();
        }
      }

      return stats;
    } catch (error) {
      console.error('Error getting hotspot stats:', error);
      return { error: error.message };
    }
  }

  // Get active hotspot sessions
  async getActiveSessions() {
    try {
      const result = await this.executeCommand('/ip hotspot active print detail');
      
      if (!result.success) {
        throw new Error(result.error);
      }

      // Parse sessions
      const sessions = [];
      const lines = result.output.split('\n');
      let currentSession = {};

      for (const line of lines) {
        if (line.includes('Flags:')) continue;
        
        if (line.startsWith(' *')) {
          if (Object.keys(currentSession).length > 0) {
            sessions.push(currentSession);
          }
          currentSession = { id: line.replace('*', '').trim() };
        } else {
          const match = line.match(/^\s*(\w+[-\w]*)=(.*)$/);
          if (match) {
            currentSession[match[1]] = match[2];
          }
        }
      }

      if (Object.keys(currentSession).length > 0) {
        sessions.push(currentSession);
      }

      return sessions;
    } catch (error) {
      console.error('Error getting active sessions:', error);
      return [];
    }
  }

  // Authorize MAC address
  async authorizeMAC(macAddress, comment = '') {
    try {
      const cmd = `/ip hotspot binding add mac-address=${macAddress} type=authorized${comment ? ` comment="${comment}"` : ''}`;
      const result = await this.executeCommand(cmd);
      
      return {
        success: result.success,
        message: result.success ? 'MAC адрес авторизован' : result.error
      };
    } catch (error) {
      return { success: false, message: error.message };
    }
  }

  // Remove MAC authorization
  async removeMACAuthorization(macAddress) {
    try {
      // First find the binding
      const findResult = await this.executeCommand(`/ip hotspot binding print where mac-address="${macAddress}"`);
      
      if (!findResult.success || !findResult.output) {
        return { success: false, message: 'Запись не найдена' };
      }

      const match = findResult.output.match(/\*(\d+)/);
      if (!match) {
        return { success: false, message: 'ID записи не найден' };
      }

      const bindingId = match[1];
      const removeResult = await this.executeCommand(`/ip hotspot binding remove ${bindingId}`);
      
      return {
        success: removeResult.success,
        message: removeResult.success ? 'Авторизация удалена' : removeResult.error
      };
    } catch (error) {
      return { success: false, message: error.message };
    }
  }

  // Get all MAC bindings
  async getMACBindings() {
    try {
      const result = await this.executeCommand('/ip hotspot binding print detail');
      
      if (!result.success) {
        throw new Error(result.error);
      }

      const bindings = [];
      const lines = result.output.split('\n');
      let currentBinding = {};

      for (const line of lines) {
        if (line.includes('Flags:')) continue;
        
        if (line.startsWith(' *')) {
          if (Object.keys(currentBinding).length > 0) {
            bindings.push(currentBinding);
          }
          currentBinding = { id: line.replace('*', '').trim() };
        } else {
          const match = line.match(/^\s*(\w+[-\w]*)=(.*)$/);
          if (match) {
            currentBinding[match[1]] = match[2];
          }
        }
      }

      if (Object.keys(currentBinding).length > 0) {
        bindings.push(currentBinding);
      }

      return bindings;
    } catch (error) {
      console.error('Error getting MAC bindings:', error);
      return [];
    }
  }

  // Kick user from hotspot
  async kickUser(macAddress) {
    try {
      const result = await this.executeCommand(`/ip hotspot kick where mac-address="${macAddress}"`);
      
      return {
        success: result.success,
        message: result.success ? 'Пользователь отключен' : result.error
      };
    } catch (error) {
      return { success: false, message: error.message };
    }
  }

  // Cleanup expired sessions
  async cleanupExpiredSessions() {
    try {
      const result = await this.executeCommand('/ip hotspot cleanup');
      
      return {
        success: result.success,
        message: result.success ? 'Сессии очищены' : result.error
      };
    } catch (error) {
      return { success: false, message: error.message };
    }
  }

  // Send SMS via script (Zabbix alert script)
  async sendSMS(phoneNumber, message) {
    try {
      // Connect to home router where SMS script is available
      const client = await this.ensureConnected(true);
      
      return new Promise((resolve) => {
        const cmd = `${config.sms.scriptPath} "${phoneNumber}" "${message}"`;
        
        client.exec(cmd, (err, stream) => {
          if (err) {
            return resolve({ success: false, message: err.message });
          }

          let output = '';
          let errorOutput = '';

          stream.on('close', (code) => {
            resolve({
              success: code === 0,
              message: code === 0 ? 'SMS отправлено' : errorOutput.trim() || 'Ошибка отправки',
              output: output.trim()
            });
          });

          stream.stderr.on('data', (data) => {
            errorOutput += data.toString();
          });

          stream.on('data', (data) => {
            output += data.toString();
          });
        });
      });
    } catch (error) {
      return { success: false, message: error.message };
    }
  }

  // Get interface stats
  async getInterfaceStats(interfaceName = 'all') {
    try {
      const cmd = interfaceName === 'all' 
        ? '/interface print stats' 
        : `/interface print stats where name="${interfaceName}"`;
      
      const result = await this.executeCommand(cmd);
      
      if (!result.success) {
        throw new Error(result.error);
      }

      return result.output;
    } catch (error) {
      console.error('Error getting interface stats:', error);
      return { error: error.message };
    }
  }

  close() {
    if (this.connection) {
      this.connection.end();
      this.connection = null;
    }
    if (this.homeRouterConnection) {
      this.homeRouterConnection.end();
      this.homeRouterConnection = null;
    }
  }
}

module.exports = new MikroTikService();

# AD Manager Portal v4.0

Modern web-based Active Directory management portal with role-based access control (RBAC) and beautiful UI.

## Features

- 🔐 **LDAP/AD Authentication** - Secure login via Active Directory
- 👥 **Role-Based Access Control** - Page access controlled by AD group membership
- 📊 **Beautiful Dashboard** - Modern, responsive interface with real-time metrics
- 📶 **WiFi & SMS Integration** - MikroTik hotspot and SMS voucher management
- 🖥 **System Monitoring** - Real-time server and network metrics
- ⚙️ **Settings Management** - Configure LDAP, security, and SMS gateway

## Role-Based Access

| Page | Required AD Group |
|------|------------------|
| Dashboard | All authenticated users |
| Users | AD Administrators |
| WiFi & SMS | Network Administrators OR WiFi Managers |
| Monitoring | Monitoring Group |
| Settings | AD Administrators |

## Installation

1. **Copy environment file:**
   ```bash
   cp config/.env.example config/.env
   ```

2. **Edit configuration:**
   ```bash
   nano config/.env
   ```
   
   Update LDAP settings and AD group names for your environment.

3. **Install dependencies:**
   ```bash
   npm install
   ```

4. **Start the server:**
   ```bash
   # Development mode
   npm run dev
   
   # Production mode
   npm start
   ```

5. **Access the portal:**
   Open http://localhost:3000 in your browser

## Project Structure

```
version4/
├── config/
│   ├── .env.example      # Environment template
│   └── config.js         # Configuration loader
├── controllers/          # Route controllers (future)
├── middleware/
│   └── auth.js           # Authentication & RBAC middleware
├── models/
│   └── ldap.js           # LDAP service
├── public/
│   ├── css/
│   │   └── style.css     # Beautiful custom styles
│   ├── js/               # Client-side scripts (future)
│   └── images/           # Static assets
├── routes/
│   ├── auth.js           # Login/logout routes
│   ├── index.js          # Dashboard routes
│   ├── users.js          # User management (Admin only)
│   ├── wifi.js           # WiFi & SMS (Network/WiFi groups)
│   ├── monitoring.js     # Monitoring (Monitor group)
│   └── settings.js       # Settings (Admin only)
├── views/
│   ├── layouts/
│   │   └── main.ejs      # Main layout template
│   └── pages/
│       ├── login.ejs     # Login page
│       ├── dashboard.ejs # Dashboard
│       ├── users.ejs     # User management
│       ├── wifi.ejs      # WiFi & SMS
│       ├── monitoring.ejs# System monitoring
│       ├── settings.ejs  # System settings
│       └── error.ejs     # Error page
├── server.js             # Main application entry
└── package.json          # Dependencies
```

## Configuration

### LDAP Settings
- `LDAP_URL` - Your AD/LDAP server URL
- `LDAP_BASE_DN` - Base DN for searches
- `LDAP_BIND_DN` - Service account DN
- `LDAP_BIND_PASSWORD` - Service account password

### AD Groups
Configure these to match your AD group CN names:
- `AD_GROUP_ADMINS` - Full administrators
- `AD_GROUP_NETWORK` - Network administrators
- `AD_GROUP_MONITOR` - Monitoring team
- `AD_GROUP_WIFI` - WiFi managers

### Security
- `SESSION_SECRET` - Change in production!
- `SESSION_TIMEOUT` - Session duration (ms)
- `RATE_LIMIT_*` - API rate limiting

## API Endpoints

All API endpoints require authentication and appropriate roles:

- `GET /users/api/list` - List users (Admins)
- `GET /wifi/api/stats` - WiFi statistics (Network/WiFi)
- `GET /monitoring/api/metrics` - System metrics (Monitoring)

## Technology Stack

- **Backend:** Node.js + Express
- **Authentication:** LDAP/Active Directory
- **Template Engine:** EJS
- **Styling:** Custom CSS with modern design
- **Security:** Helmet, rate limiting, secure sessions

## Future Enhancements

- [ ] Real user CRUD operations via LDAP
- [ ] MikroTik API integration for WiFi
- [ ] SMS gateway integration
- [ ] Real-time WebSocket updates
- [ ] Audit logging
- [ ] Multi-language support
- [ ] Dark mode theme

## License

Internal use only - Enterprise Edition

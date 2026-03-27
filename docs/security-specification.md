# EvenTix - Security Specifications & Best Practices

**Security Lead:** Zie  
**Compliance Standards:** OWASP Top 10, GDPR, and regional payment-provider security requirements  
**Last Updated:** March 27, 2026

---

## 1. Authentication & Authorization

### 1.A JWT Token Strategy

**Token Generation:**
```javascript
// backend/src/services/authService.js
const jwt = require('jsonwebtoken');

function generateTokens(user, org) {
  const accessPayload = {
    sub: user.id,
    email: user.email,
    role: org.role || 'Member',  // Owner, Co-Organizer, Staff, Member
    org_id: org.id,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (60 * 60), // 1 hour
    aud: 'eventix'
  };

  const refreshPayload = {
    sub: user.id,
    type: 'refresh',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60), // 7 days
    aud: 'eventix'
  };

  const accessToken = jwt.sign(accessPayload, process.env.JWT_SECRET, {
    algorithm: 'HS256'
  });

  const refreshToken = jwt.sign(refreshPayload, process.env.JWT_REFRESH_SECRET, {
    algorithm: 'HS256'
  });

  return { accessToken, refreshToken };
}
```

**Token Storage:**
- **Access Token:** Stored in memory or secure sessionStorage (JavaScript)
- **Refresh Token:** Stored in HTTP-only, Secure, SameSite cookie (backend handles automatically)

**Token Validation:**
```javascript
// Every protected endpoint validates token
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer token

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
}
```

### 1.B Role-Based Access Control (RBAC)

**Role Hierarchy:**
```
Owner
├─ Can manage all aspects of organization
├─ Can invite/remove Co-Organizers
├─ Access to financial data

Co-Organizer
├─ Can create/edit events
├─ Can manage members and approvals
├─ Cannot access financial data
├─ Cannot delete organization

Staff
├─ Can check in attendees (scanner)
├─ Can view event roster
├─ Read-only access

Member
├─ Can RSVP for events
├─ Can view personal tickets
├─ Can transfer tickets (same org only)
```

**RBAC Middleware:**
```javascript
function requireRole(allowedRoles) {
  return (req, res, next) => {
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        error: 'Insufficient permissions for this action',
        required_role: allowedRoles,
        your_role: req.user.role
      });
    }
    next();
  };
}

// Usage:
app.get(
  '/organizations/:id/financials',
  authenticateToken,
  requireRole(['Owner', 'Co-Organizer']),
  getFinancials
);
```

### 1.C Session Management

**Session Timeout Rules:**
- **Idle Timeout:** 30 minutes (no activity)
- **Absolute Timeout:** 8 hours (regardless of activity)
- **Device Logout:** Log out all sessions when password changed

**Implementation:**
```javascript
// Add to every request
function refreshSessionTimeout(req, res, next) {
  const lastActivity = req.session?.lastActivity;
  const now = Date.now();

  // Check idle timeout (30 minutes)
  if (lastActivity && (now - lastActivity) > 30 * 60 * 1000) {
    req.session = null;
    return res.status(401).json({ error: 'Session expired' });
  }

  // Update last activity
  if (req.session) {
    req.session.lastActivity = now;
  }

  next();
}
```

---

## 2. Password Security

### Password Requirements
- **Minimum Length:** 12 characters
- **Complexity:** At least one uppercase, lowercase, number, and symbol
- **Blacklist:** Common passwords (check against NIST list)
- **History:** Cannot reuse last 5 passwords

### Password Hashing
```javascript
const bcrypt = require('bcrypt');
const SALT_ROUNDS = 12;

async function hashPassword(plainPassword) {
  // bcrypt automatically generates salt and handles timing attacks
  const hash = await bcrypt.hash(plainPassword, SALT_ROUNDS);
  return hash;
}

async function verifyPassword(plainPassword, hash) {
  return bcrypt.compare(plainPassword, hash);
}
```

**Never:**
- Hash passwords with MD5 or SHA1
- Store passwords in plain text
- Use reversible encryption
- Use weak salts

### Password Reset Flow
```javascript
// 1. User requests password reset
app.post('/auth/forgot-password', async (req, res) => {
  const user = await User.findOne({ email: req.body.email });
  if (!user) {
    // Don't reveal if email exists (security)
    return res.json({ message: 'If email exists, reset link sent' });
  }

  // 2. Generate secure reset token (1-hour expiry)
  const resetToken = crypto.randomBytes(32).toString('hex');
  const resetTokenHash = await bcrypt.hash(resetToken, 10);

  user.resetTokenHash = resetTokenHash;
  user.resetTokenExpiry = new Date(Date.now() + 60 * 60 * 1000);
  await user.save();

  // 3. Send reset link via email
  const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
  await emailService.sendPasswordReset(user.email, resetUrl);

  return res.json({ message: 'If email exists, reset link sent' });
});

// 4. User submits new password
app.post('/auth/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;
  const user = await User.findOne({
    resetTokenExpiry: { $gt: Date.now() }
  });

  if (!user || !(await bcrypt.compare(token, user.resetTokenHash))) {
    return res.status(400).json({ error: 'Invalid or expired reset token' });
  }

  // 5. Update password and clear reset token
  user.password_hash = await hashPassword(newPassword);
  user.resetTokenHash = null;
  user.resetTokenExpiry = null;
  await user.save();

  return res.json({ message: 'Password reset successfully' });
});
```

---

## 3. Data Encryption

### Encryption at Rest
**Database:** All sensitive fields encrypted using column-level encryption:
```javascript
// Example: Encrypt user phone numbers
const crypto = require('crypto');

function encryptField(plaintext) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(
    'aes-256-gcm',
    Buffer.from(process.env.ENCRYPTION_KEY, 'hex'),
    iv
  );

  let encrypted = cipher.update(plaintext, 'utf8', 'hex');
  encrypted += cipher.final('hex');

  const tag = cipher.getAuthTag();
  return `${iv.toString('hex')}:${tag.toString('hex')}:${encrypted}`;
}

function decryptField(ciphertext) {
  const [iv, tag, encrypted] = ciphertext.split(':');
  const decipher = crypto.createDecipheriv(
    'aes-256-gcm',
    Buffer.from(process.env.ENCRYPTION_KEY, 'hex'),
    Buffer.from(iv, 'hex')
  );

  decipher.setAuthTag(Buffer.from(tag, 'hex'));
  let plaintext = decipher.update(encrypted, 'hex', 'utf8');
  plaintext += decipher.final('utf8');

  return plaintext;
}
```

### Encryption in Transit
**HTTPS/TLS 1.3:**
- All endpoints require HTTPS
- Force HTTPS redirect (HTTP → HTTPS)
- HSTS header: `Strict-Transport-Security: max-age=31536000; includeSubDomains`

---

## 4. Request Validation & Sanitization

### Input Validation
```javascript
const { body, validationResult } = require('express-validator');

app.post('/organizations/:id/events', [
  // Validate fields
  body('title')
    .trim()
    .isLength({ min: 5, max: 150 })
    .withMessage('Title must be 5-150 characters'),
  
  body('description')
    .trim()
    .isLength({ max: 5000 })
    .withMessage('Description too long'),
  
  body('price')
    .isFloat({ min: 0, max: 999999 })
    .withMessage('Price must be between 0 and 999999'),
  
  body('start_date')
    .isISO8601()
    .toDate()
    .custom(date => date > new Date())
    .withMessage('Start date must be in the future')
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  // Process validated input
  const { title, description, price, start_date } = req.body;
  // ...
});
```

### SQL Injection Prevention
```javascript
// ✅ SAFE: Use parameterized queries
const result = await db.query(
  'SELECT * FROM users WHERE email = $1 AND status = $2',
  [userEmail, 'active']
);

// ❌ UNSAFE: String concatenation (never do this)
const query = `SELECT * FROM users WHERE email = '${userEmail}'`;
```

### XSS Prevention
```javascript
// Sanitize output in templates
<div>{{ user.full_name | sanitize }}</div>

// Use React safely (automatically escapes)
<div>{user.full_name}</div>

// Never use dangerouslySetInnerHTML except for trusted content
// ✅ SAFE
<div dangerouslySetInnerHTML={{ __html: trustedMarkdown }} />

// ❌ UNSAFE
<div dangerouslySetInnerHTML={{ __html: userInput }} />
```

---

## 5. Rate Limiting

### Configuration
```javascript
const rateLimit = require('express-rate-limit');

// General API rate limiter
const apiLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100, // 100 requests per minute
  message: 'Too many requests from this IP, please try again later',
  standardHeaders: true, // Return RateLimit-* headers
  legacyHeaders: false,
  skip: (req) => req.user?.role === 'Owner' // Admins get higher limits
});

// Auth limiter (stricter)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per 15 minutes
  skipSuccessfulRequests: true // Don't count successful attempts
});

// Scanner limiter (high throughput allowed)
const scannerLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 1000 // Allow high throughput for scanner
});

// Apply to routes
app.use('/api/v1/', apiLimiter);
app.post('/auth/login', authLimiter, loginHandler);
app.post('/scan/verify', scannerLimiter, scanHandler);
```

---

## 6. CORS Configuration

### Safe CORS Policy
```javascript
const cors = require('cors');

app.use(cors({
  origin: process.env.NODE_ENV === 'production'
    ? ['https://eventix.app', 'https://www.eventix.app']
    : ['http://localhost:3000'],
  credentials: true, // Allow cookies
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400 // 24 hours
}));

// Never use wildcard origin in production
// ❌ UNSAFE
app.use(cors({ origin: '*' }));
```

---

## 7. CSRF Protection

### Token-Based CSRF Prevention
```javascript
const csrfProtection = require('csurf');
const session = require('express-session');

// Session middleware required
app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: true,
  cookie: {
    secure: true, // HTTPS only
    httpOnly: true, // Prevent JavaScript access
    sameSite: 'Strict' // CSRF protection
  }
}));

// CSRF middleware
app.use(csrfProtection);

// Generate CSRF token for forms
app.get('/login', (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// Validate CSRF token on form submission
app.post('/auth/login', csrfProtection, (req, res) => {
  // CSRF token automatically validated
  // ...
});
```

---

## 8. Security Headers

### Express Configuration
```javascript
const helmet = require('helmet');

app.use(helmet()); // Automatically sets secure headers

// Explicit headers:
app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'", "'unsafe-inline'"],
    styleSrc: ["'self'", "'unsafe-inline'"],
    imgSrc: ["'self'", "https:", "data:"],
    connectSrc: ["'self'", "https://api.eventix.app", "https://api.globelabs.com.ph"],
    frameSrc: ["'self'"]
  }
}));

app.use(helmet.hsts({
  maxAge: 31536000, // 1 year
  includeSubDomains: true,
  preload: true
}));

app.use(helmet.noSniff()); // X-Content-Type-Options: nosniff
app.use(helmet.xssFilter()); // X-XSS-Protection
app.use(helmet.referrerPolicy({ policy: 'no-referrer' }));
```

---

## 9. Logging & Monitoring (Without PII Leaks)

### Secure Logging
```javascript
function sanitizeLog(data) {
  const sensitive = ['password', 'credit_card', 'ssn', 'phone', 'address'];
  const sanitized = { ...data };

  sensitive.forEach(field => {
    if (sanitized[field]) {
      sanitized[field] = '[REDACTED]';
    }
  });

  return sanitized;
}

// Usage
app.post('/auth/login', (req, res) => {
  logger.info('Login attempt', sanitizeLog(req.body));
  // Response: { email: 'user@example.com', password: '[REDACTED]' }
});
```

### Error Logging (No Stack Traces in Client)
```javascript
// Backend: Log full stack trace
logger.error('Database error', {
  error: err.toString(),
  stack: err.stack, // Include stack trace
  userId: req.user?.id,
  endpoint: req.path
});

// Client: Return generic error
res.status(500).json({
  error: 'Internal server error',
  request_id: generateRequestId() // For support tracking
});
```

---

## 10. Third-Party Security

### Dependency Scanning
```bash
# Regular security audits
npm audit

# Fix vulnerabilities automatically (where compatible)
npm audit fix

# Use Dependabot on GitHub for automated PRs
# GitHub → Settings → Code security → Enable Dependabot
```

### API Key Rotation
- **GCash/Payment Provider:** Rotate keys every 90 days
- **JWT Secrets:** Rotate every 6 months
- **Email Service:** Rotate credentials annually
- **Database:** Rotate passwords every 3 months

---

## 11. Compliance & Audit Trail

### GDPR Compliance
- **Right to Access:** Endpoint to export user data
- **Right to Delete:** Anonymize user upon account deletion
- **Consent:** Track user consent for emails/analytics
- **Data Retention:** Delete old records after 2 years

### Audit Logging
```javascript
async function logAuditEvent(action, userId, resourceType, resourceId, changes) {
  await AuditLog.create({
    action, // 'create', 'update', 'delete', 'ban_user'
    userId,
    resourceType, // 'user', 'event', 'organization'
    resourceId,
    changes, // { field: { old: X, new: Y } }
    ip_address: req.ip,
    user_agent: req.get('user-agent'),
    timestamp: new Date()
  });
}

// Examples:
logAuditEvent('ban_user', admin_id, 'user', user_id, { status: 'Active' → 'Banned' });
logAuditEvent('create_event', org_owner_id, 'event', event_id, { ... });
```

---

## 12. Security Checklist

**Before Launch:**
- [ ] All passwords hashed with bcrypt (12 rounds)
- [ ] HTTPS enforced (no HTTP)
- [ ] HSTS header configured
- [ ] CORS properly restricted
- [ ] CSRF tokens implemented
- [ ] Rate limiting enabled
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention verified
- [ ] XSS protection active
- [ ] Session timeout configured
- [ ] Secrets in environment variables (not hardcoded)
- [ ] Sensitive data encrypted at rest
- [ ] Audit logging enabled
- [ ] Security headers configured (Helmet)
- [ ] Dependency vulnerabilities resolved
- [ ] Error handling doesn't leak details
- [ ] Logs sanitized (no PII)
- [ ] Webhook signature verification working
- [ ] Two-Factor Authentication available (future)

**Ongoing:**
- [ ] Weekly security audits (`npm audit`)
- [ ] Monthly key rotation alerts
- [ ] Quarterly penetration testing
- [ ] Quarterly security training for team
- [ ] Annual compliance audit


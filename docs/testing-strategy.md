# EvenTix - Testing Strategy & Quality Assurance

**QA Lead:** Zie  
**Testing Framework:** Jest (Backend), Vitest (Frontend)  
**Last Updated:** March 27, 2026

---

## 1. Testing Philosophy & Coverage Goals

### Testing Pyramid
```
          ╱╲                Manual/E2E Tests (5%)
         ╱  ╲               • Full user journeys
        ╱────╲              • Cross-browser testing
       ╱  __  ╲    Integration Tests (20%)
      ╱  ╱  ╲  ╲           • API endpoints
     ╱__╱    ╲__╲          • Database interactions
    ╱ Unit Tests (75%) ╲   • State management
   ╱___________________╲  • Critical business logic
```

### Coverage Targets

| Area | Target | Rationale |
| :--- | :--- | :--- |
| **Backend - Core Logic** | 85%+ | Authentication, payments, RBAC must be bulletproof |
| **Backend - Utils** | 70%+ | Hashing, encryption, helpers |
| **Frontend - Components** | 60%+ | UI rendering and user interactions |
| **Frontend - Pages** | 50%+ | High-level integration |
| **Database** | 90%+ | Schema validation, migrations |

---

## 2. Unit Testing (Backend)

### Setup
```bash
# Install testing dependencies
cd backend
npm install --save-dev jest @types/jest supertest

# Configure Jest in package.json
"scripts": {
  "test": "jest",
  "test:watch": "jest --watch",
  "test:coverage": "jest --coverage"
},
"jest": {
  "testEnvironment": "node",
  "collectCoverageFrom": ["src/**/*.js"],
  "coveragePathIgnorePatterns": ["/node_modules/", "dist/"],
  "testMatch": ["**/__tests__/**/*.test.js", "**/?(*.)+(spec|test).js"]
}
```

### Example: Unit Test for Password Hashing
```javascript
// backend/src/services/__tests__/authService.test.js
const { hashPassword, verifyPassword } = require('../authService');

describe('authService - Password Hashing', () => {
  it('should hash a password securely', async () => {
    const plainPassword = 'SecurePassword123!';
    const hash = await hashPassword(plainPassword);

    // Check hash is different from plaintext
    expect(hash).not.toBe(plainPassword);
    
    // Check hash is consistently generated (bcrypt should produce different hash each time)
    const hash2 = await hashPassword(plainPassword);
    expect(hash).not.toBe(hash2);
  });

  it('should verify correct password', async () => {
    const plainPassword = 'SecurePassword123!';
    const hash = await hashPassword(plainPassword);

    const isMatch = await verifyPassword(plainPassword, hash);
    expect(isMatch).toBe(true);
  });

  it('should reject incorrect password', async () => {
    const plainPassword = 'SecurePassword123!';
    const wrongPassword = 'WrongPassword456!';
    const hash = await hashPassword(plainPassword);

    const isMatch = await verifyPassword(wrongPassword, hash);
    expect(isMatch).toBe(false);
  });

  it('should reject weak passwords on hashing', async () => {
    const weakPasswords = [
      'short',           // Too short
      'NoSpeed',         // No numbers
      'NouppEr123',      // No uppercase
      'NOUPPER123',      // No lowercase
      'NO_SPECIAL123!',  // Usually rejected by most validators
    ];

    for (const pwd of weakPasswords) {
      // Validation happens before hashing in real code
      const isValid = validatePassword(pwd);
      expect(isValid).toBe(false);
    }
  });
});
```

### Example: Unit Test for RBAC
```javascript
// backend/src/middlewares/__tests__/rbac.test.js
const { requireRole } = require('../rbac');

describe('RBAC Middleware - Role-Based Access Control', () => {
  let req, res, next;

  beforeEach(() => {
    req = { user: {} };
    res = { status: jest.fn().returnThis(), json: jest.fn() };
    next = jest.fn();
  });

  it('should allow Owner access to admin endpoints', () => {
    req.user.role = 'Owner';
    const middleware = requireRole(['Owner', 'Co-Organizer']);

    middleware(req, res, next);
    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  it('should deny Member access to admin endpoints', () => {
    req.user.role = 'Member';
    const middleware = requireRole(['Owner', 'Co-Organizer']);

    middleware(req, res, next);
    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(403);
  });

  it('should allow Staff to access scanner endpoints', () => {
    req.user.role = 'Staff';
    const middleware = requireRole(['Staff', 'Co-Organizer', 'Owner']);

    middleware(req, res, next);
    expect(next).toHaveBeenCalled();
  });
});
```

### Example: Unit Test for Cryptographic Hash
```javascript
// backend/src/utils/__tests__/crypto.test.js
const { generateQRHash, verifyQRHash } = require('../crypto');

describe('Crypto - QR Hash Generation', () => {
  const testData = {
    userId: 'user-123',
    eventId: 'event-456',
    tierId: 'tier-789',
  };

  it('should generate a deterministic hash', () => {
    const hash1 = generateQRHash(testData);
    const hash2 = generateQRHash(testData);

    // Same input should produce same hash (deterministic)
    expect(hash1).toBe(hash2);
  });

  it('should generate different hashes for different data', () => {
    const hash1 = generateQRHash(testData);
    const hash2 = generateQRHash({
      ...testData,
      tierId: 'tier-diff'
    });

    expect(hash1).not.toBe(hash2);
  });

  it('should verify valid hashes', () => {
    const hash = generateQRHash(testData);
    const isValid = verifyQRHash(hash, testData);

    expect(isValid).toBe(true);
  });

  it('should reject tampered hashes', () => {
    const hash = generateQRHash(testData);
    const tamperedHash = hash.slice(0, -1) + 'X'; // Change last char

    const isValid = verifyQRHash(tamperedHash, testData);
    expect(isValid).toBe(false);
  });

  it('should reject hash with wrong data', () => {
    const hash = generateQRHash(testData);
    const wrongData = { ...testData, userId: 'user-different' };

    const isValid = verifyQRHash(hash, wrongData);
    expect(isValid).toBe(false);
  });
});
```

---

## 3. Integration Testing (Backend)

### Database Integration Tests
```javascript
// backend/src/models/__tests__/ticket.integration.test.js
const db = require('../../db');
const Ticket = require('../Ticket');
const Event = require('../Event');
const User = require('../User');

describe('Ticket Model - Integration Tests', () => {
  let testUser, testEvent, testTier;

  beforeAll(async () => {
    // Setup test database
    await db.connection.query('BEGIN');
  });

  beforeEach(async () => {
    // Create test fixtures
    testUser = await User.create({
      email: 'test@example.com',
      full_name: 'Test User',
      password_hash: 'hashed_password'
    });

    testEvent = await Event.create({
      org_id: 'org-123',
      title: 'Test Event',
      start_date: new Date(Date.now() + 86400000),
      end_date: new Date(Date.now() + 86400000)
    });

    testTier = await EventTier.create({
      event_id: testEvent.id,
      name: 'General Admission',
      price: 50.00,
      capacity: 100
    });
  });

  afterEach(async () => {
    // Rollback after each test
    await db.connection.query('ROLLBACK');
    await db.connection.query('BEGIN');
  });

  afterAll(async () => {
    await db.connection.query('ROLLBACK');
    await db.connection.end();
  });

  it('should create a ticket with valid data', async () => {
    const ticket = await Ticket.create({
      event_id: testEvent.id,
      user_id: testUser.id,
      tier_id: testTier.id,
      qr_hash: 'EVT_abc123xyz789',
      status: 'Active'
    });

    expect(ticket.id).toBeDefined();
    expect(ticket.status).toBe('Active');
  });

  it('should enforce capacity limits on tier', async () => {
    // Fill the tier to capacity
    for (let i = 0; i < 100; i++) {
      const user = await User.create({
        email: `user${i}@example.com`,
        full_name: `User ${i}`,
        password_hash: 'hash'
      });

      await Ticket.create({
        event_id: testEvent.id,
        user_id: user.id,
        tier_id: testTier.id,
        qr_hash: `EVT_hash_${i}`,
        status: 'Active'
      });
    }

    // Should fail to create 101st ticket
    const overCapacityUser = await User.create({
      email: 'overcapacity@example.com',
      full_name: 'Over Capacity',
      password_hash: 'hash'
    });

    await expect(Ticket.create({
      event_id: testEvent.id,
      user_id: overCapacityUser.id,
      tier_id: testTier.id,
      qr_hash: 'EVT_over_101',
      status: 'Active'
    })).rejects.toThrow('Capacity exceeded');
  });

  it('should handle ticket transfer correctly', async () => {
    // Create initial ticket
    const originalTicket = await Ticket.create({
      event_id: testEvent.id,
      user_id: testUser.id,
      tier_id: testTier.id,
      qr_hash: 'EVT_original_hash',
      status: 'Active'
    });

    // Create recipient
    const recipient = await User.create({
      email: 'recipient@example.com',
      full_name: 'Recipient User',
      password_hash: 'hash'
    });

    // Transfer ticket
    const newTicket = await Ticket.transfer(originalTicket.id, recipient.id);

    // Verify original is marked transferred
    const transferred = await Ticket.findById(originalTicket.id);
    expect(transferred.status).toBe('Transferred');

    // Verify new ticket exists with new hash
    expect(newTicket.user_id).toBe(recipient.id);
    expect(newTicket.qr_hash).not.toBe('EVT_original_hash');
    expect(newTicket.status).toBe('Active');
  });
});
```

### API Endpoint Integration Tests
```javascript
// backend/src/routes/__tests__/events.integration.test.js
const request = require('supertest');
const app = require('../../app');
const db = require('../../db');

describe('Events API - Integration Tests', () => {
  let authToken, orgId;

  beforeAll(async () => {
    // Login and get auth token
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'organizer@example.com',
        password: 'SecurePassword123!'
      });

    authToken = loginRes.body.access_token;
    orgId = loginRes.body.org_id;
  });

  it('should create an event', async () => {
    const res = await request(app)
      .post(`/api/v1/organizations/${orgId}/events`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        title: 'Tech Conference 2026',
        description: 'Annual tech gathering',
        start_date: new Date(Date.now() + 86400000).toISOString(),
        end_date: new Date(Date.now() + 172800000).toISOString(),
        tiers: [
          { name: 'General', price: 50, capacity: 500 }
        ]
      });

    expect(res.status).toBe(201);
    expect(res.body.title).toBe('Tech Conference 2026');
    expect(res.body.status).toBe('Draft');
  });

  it('should prevent non-owner from creating events', async () => {
    // Login as member
    const memberRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'member@example.com',
        password: 'SecurePassword123!'
      });

    const memberToken = memberRes.body.access_token;

    const res = await request(app)
      .post(`/api/v1/organizations/${orgId}/events`)
      .set('Authorization', `Bearer ${memberToken}`)
      .send({
        title: 'Unauthorized Event',
        start_date: new Date().toISOString(),
        end_date: new Date().toISOString()
      });

    expect(res.status).toBe(403);
    expect(res.body.error).toContain('Insufficient permissions');
  });

  it('should publish an event', async () => {
    // Create event
    const createRes = await request(app)
      .post(`/api/v1/organizations/${orgId}/events`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        title: 'Test Event',
        start_date: new Date(Date.now() + 86400000).toISOString(),
        end_date: new Date(Date.now() + 172800000).toISOString()
      });

    const eventId = createRes.body.id;

    // Publish event
    const publishRes = await request(app)
      .post(`/api/v1/events/${eventId}/publish`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(publishRes.status).toBe(200);
    expect(publishRes.body.status).toBe('Published');
  });
});
```

---

## 4. Frontend Component Testing

### Setup
```bash
# Install dependencies
cd frontend
npm install --save-dev vitest @testing-library/react @testing-library/jest-dom

# Configure in vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './vitest.setup.ts'
  }
})
```

### Example: Component Test
```javascript
// frontend/src/components/__tests__/EventCard.test.tsx
import { render, screen } from '@testing-library/react';
import EventCard from '../EventCard';

describe('EventCard Component', () => {
  const mockEvent = {
    id: 'event-123',
    title: 'Tech Conference',
    date: '2026-06-15',
    organization: 'Tech Community',
    price: 50,
    image: 'https://example.com/image.jpg'
  };

  it('renders event card with correct data', () => {
    render(<EventCard event={mockEvent} />);

    expect(screen.getByText('Tech Conference')).toBeInTheDocument();
    expect(screen.getByText('Tech Community')).toBeInTheDocument();
    expect(screen.getByText('$50')).toBeInTheDocument();
  });

  it('displays image correctly', () => {
    render(<EventCard event={mockEvent} />);

    const image = screen.getByAltText('Tech Conference');
    expect(image).toHaveAttribute('src', mockEvent.image);
  });

  it('handles free events', () => {
    const freeEvent = { ...mockEvent, price: 0 };
    render(<EventCard event={freeEvent} />);

    expect(screen.getByText('FREE')).toBeInTheDocument();
  });

  it('triggers callback on click', () => {
    const handleClick = jest.fn();
    render(<EventCard event={mockEvent} onClick={handleClick} />);

    const card = screen.getByRole('button');
    card.click();

    expect(handleClick).toHaveBeenCalledWith(mockEvent.id);
  });
});
```

---

## 5. End-to-End Testing (E2E)

### Setup with Playwright
```bash
# Install Playwright
npm install --save-dev @playwright/test

# Create playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: { baseURL: 'http://localhost:3000' },
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI
  }
});
```

### Example: E2E Test - Full RSVP Flow
```javascript
// frontend/e2e/rsvp-flow.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Member RSVP Flow', () => {
  test('should complete full RSVP from event discovery to confirmation', async ({ page }) => {
    // 1. Login as member
    await page.goto('/');
    await page.click('text=Login');
    await page.fill('input[type="email"]', 'member@example.com');
    await page.fill('input[type="password"]', 'SecurePassword123!');
    await page.click('button:has-text("Sign In")');

    // Verify logged in
    await expect(page).toHaveURL('/feed');

    // 2. Navigate to event details
    await page.click('text=Tech Conference 2026');
    await expect(page).toHaveURL(/\/events\/\w+/);

    // 3. Click RSVP button
    await page.click('button:has-text("RSVP Now")');

    // 4. Select ticket tier
    await page.click('text=General Admission');

    // 5. Add optional merchandise
    const addMerchBtn = await page.locator('button:has-text("Add T-Shirt")');
    await addMerchBtn.click();

    // 6. Review and confirm
    await expect(page.locator('text=Subtotal:')).toBeVisible();
    await page.click('button:has-text("Proceed to Payment")');

    // 7. Payment flow (GCash QR)
    await expect(page.locator('img[alt="GCash QR Code"]')).toBeVisible();
    await expect(page.locator('text=Scan this QR with GCash')).toBeVisible();

    // Simulate async webhook callback completing payment
    await page.evaluate(() => {
      window.dispatchEvent(new CustomEvent('paymentCompleted', {
        detail: { provider: 'gcash', referenceId: 'EVT_TEST_123' }
      }));
    });

    await page.click('button:has-text("I have completed payment")');

    // 8. Verify ticket created
    await expect(page).toHaveURL('/wallet');
    await expect(page.locator('text=Tech Conference 2026')).toBeVisible();

    // 9. Verify QR code displayed
    const qrCode = page.locator('canvas'); // QR code as canvas
    await expect(qrCode).toBeVisible();
  });

  test('should prevent RSVP when capacity exceeded', async ({ page }) => {
    // ... setup ...

    // Attempt RSVP for sold-out event
    await page.click('button:has-text("RSVP Now")');

    // Should show error
    await expect(page.locator('text=Event is sold out')).toBeVisible();
  });
});
```

### Example: E2E Test - Scanner Flow
```javascript
// e2e/scanner-flow.spec.ts
test('should scan ticket and check in attendee', async ({ page }) => {
  // Login as Staff
  await page.fill('input[type="email"]', 'staff@example.com');
  await page.fill('input[type="password"]', 'SecurePassword123!');
  await page.click('button:has-text("Sign In")');

  // Navigate to scanner
  await page.click('text=Events');
  await page.click('text=Tech Conference');
  await page.click('button:has-text("Live Scanner")');

  // Wait for camera/scanner UI
  await expect(page.locator('[data-testid="scanner-view"]')).toBeVisible();

  // Simulate QR code scan (inject fake QR data)
  await page.evaluate(() => {
    const event = new Event('qrScanned');
    (event as any).qrData = 'EVT_abc123xyz789';
    document.dispatchEvent(event);
  });

  // Verify green flash (valid ticket)
  const scanView = page.locator('[data-testid="scanner-view"]');
  await expect(scanView).toHaveClass(/bg-green/);

  // Verify attendee info displayed
  await expect(page.locator('text=John Doe')).toBeVisible();
  await expect(page.locator('text=VIP')).toBeVisible();

  // Verify add-on checklist
  await expect(page.locator('text=Event T-Shirt (L)')).toBeVisible();
  await page.click('button:has-text("Confirm Received")');

  // Verify fulfilled
  const checkbox = page.locator('[data-testid="addon-checkbox"]');
  await expect(checkbox).toBeChecked();
});
```

---

## 6. Performance Testing

### Load Testing with Artillery
```bash
# Install
npm install --save-dev artillery

# Create load test config (load-test.yml)
config:
  target: "https://api.eventix.app"
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Ramp up"
    - duration: 60
      arrivalRate: 100
      name: "Spike"

scenarios:
  - name: "RSVP Flow"
    flow:
      - post:
          url: "/api/v1/auth/login"
          json:
            email: "{{ $randomString() }}@example.com"
            password: "SecurePassword123!"
          capture:
            json: "$.access_token"
            as: "token"
      - post:
          url: "/api/v1/events/{{ $randomString() }}/rsvp"
          headers:
            Authorization: "Bearer {{ token }}"
          json:
            tier_id: "tier-123"

# Run test
artillery run load-test.yml
```

### Performance Metrics
| Metric | Target | Tool |
| :--- | :--- | :--- |
| **Page Load** | < 2 seconds | Lighthouse, WebPageTest |
| **API Response** | < 200ms (p95) | Artillery, K6 |
| **Scanner Latency** | < 1.5 seconds | Custom E2E |
| **Concurrent Users** | 500+ | Load testing |
| **Database Queries** | < 100ms | Query analyzer |

---

## 7. Testing Schedule

| Phase | Tests | Frequency |
| :--- | :--- | :--- |
| **Development** | Unit + Integration | Every commit (CI/CD) |
| **Staging** | All + E2E + Load | Before release |
| **Production** | Smoke tests + Monitoring | Post-deployment |

---

## 8. Test Case Inventory

### Critical Paths (Must Test Thoroughly)
- ✓ Member registration and login
- ✓ Organization creation and event publishing
- ✓ RSVP and ticket generation
- ✓ Payment processing (success and failure)
- ✓ Ticket transfer
- ✓ QR code scanning and check-in
- ✓ Ticket capacity limits
- ✓ User banning/moderation
- ✓ Authorization checks (RBAC)
- ✓ Session timeout

### Edge Cases to Test
- Simultaneous RSVPs for limited tickets
- Multi-day event attendance tracking
- Timezone handling
- Very long event names/descriptions
- Concurrent ticket transfers
- Refund race conditions
- Database connection failures
- Webhook replay handling

---

## 9. Debugging & Test Failure Analysis

```bash
# Run tests with debug output
DEBUG=eventix:* npm test

# Run single test file
npm test -- authService.test.js

# Run tests in watch mode
npm test -- --watch

# Generate coverage report
npm run test:coverage
# Open coverage/index.html in browser
```


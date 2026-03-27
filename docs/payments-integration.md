# EvenTix - Payment Integration & Processing Guide

## 1. Payment Processor Selection & Architecture

### Why GCash?
- **Local Payment Method:** Dominant mobile wallet in Philippines (95M+ users)
- **Zero Fraud Risk:** Phone number verification and OTP authentication built-in
- **Simplified Integration:** RESTful API, no PCI burden on EvenTix
- **Low Transaction Fees:** 1-2% per transaction vs 3.9% + fixed fees for international processors
- **Instant Settlement:** P2P transfers and merchant payouts processed in real-time
- **No Setup Fees:** Free to integrate, only pay per transaction

### Architecture Overview
```
┌─────────────────┐
│   Member App    │
│   (Next.js)     │
└────────┬────────┘
         │ Generate QR Code
         │ Request Payment
┌────────▼────────┐
│  BFF (Next.js   │
│   API Routes)   │
└────────┬────────┘
         │ Create Payment Link
         │
┌────────▼────────────────────┐
│   Backend REST API          │
│  (Render/Railway)           │
├─────────────────────────────┤
│  - Generate QR Code         │
│  - Poll Payment Status      │
│  - Handle Webhooks          │
└────────┬────────────────────┘
         │
┌────────▼────────────────────┐
│   GCash API                 │
│  (Globe Labs)               │
└─────────────────────────────┘
         │
     [Member scans QR]
     [Enters OTP]
     [Payment Complete]
```

---

## 2. Secret Management & Environment Variables

### Required Environment Variables

**Backend (.env file):**
```bash
# GCash Configuration
GCASH_API_KEY=your_globe_labs_api_key
GCASH_MERCHANT_ID=your_merchant_id
GCASH_WEBHOOK_SECRET=your_webhook_secret_key
GCASH_APP_ID=your_app_id
GCASH_APP_SECRET=your_app_secret

# GCash Endpoints
GCASH_API_BASE_URL=https://devapi.globelabs.com.ph  # Development
# GCASH_API_BASE_URL=https://api.globelabs.com.ph  # Production

# Platform Configuration
PLATFORM_FEE_PERCENTAGE=2.0
PLATFORM_FIXED_FEE_PHP=5
APP_BASE_URL=https://eventix.app
GCASH_API_VERSION=v2
```

**Frontend (.env.local file):**
```bash
NEXT_PUBLIC_API_BASE_URL=https://api.eventix.app
NEXT_PUBLIC_QR_GENERATION_ENDPOINT=/api/payments/generate-qr
```

### Security Best Practices
- **Never** commit API keys or webhook secrets to Git
- Store secrets in environment variable vaults (GitHub Secrets, Render Deploy Config, etc.)
- Rotate webhook secrets every 90 days
- Use Development API key during local testing
- Switch to Production API key after deploy
- Enable IP whitelisting on GCash portal for additional security

---

## 3. Payment Flow: RSVP & Ticket Purchase

### Step 1: Member Initiates RSVP (Frontend)
```javascript
// Member selects event, tiers, and add-ons
const checkoutPayload = {
  event_id: "event-uuid",
  tier_id: "tier-uuid",
  addons: [
    { addon_id: "addon-uuid", quantity: 2 }
  ]
};
```

### Step 2: Frontend Requests QR Payment (BFF)
```javascript
// Call Next.js BFF endpoint
const response = await fetch('/api/payments/generate-qr', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${accessToken}` },
  body: JSON.stringify(checkoutPayload)
});

const { qr_code_image, payment_reference_id, amount_total } = await response.json();
```

### Step 3: Backend Generates GCash QR Code (Render/Railway)
```javascript
const axios = require('axios');
const QRCode = require('qrcode');

// Backend calculates totals
const subtotal = tier.price + addons.reduce((sum, a) => sum + (a.price * a.qty), 0);
const platformFees = (subtotal * PLATFORM_FEE_PERCENTAGE / 100) + PLATFORM_FIXED_FEE_PHP;
const total = subtotal + platformFees;

// Generate unique payment reference
const paymentRefId = `EVT_${Date.now()}_${user.id.substring(0, 8)}`;

// Create GCash payment request
const gcashPayload = {
  merchantId: process.env.GCASH_MERCHANT_ID,
  referenceId: paymentRefId,
  amount: total,
  currency: 'PHP',
  description: `RSVP for ${event.title} by ${user.full_name}`,
  metadata: {
    event_id: event.id,
    user_id: user.id,
    tier_id: tier.id,
    org_id: org.id,
    type: 'event_rsvp'
  },
  returnUrl: `${process.env.APP_BASE_URL}/payment-callback?ref=${paymentRefId}`,
  notifyUrl: `${process.env.APP_BASE_URL}/api/webhooks/gcash`
};

// Generate QR Code (Dynamic QR with payment data)
const qrContent = JSON.stringify(gcashPayload);
const qrCodeImage = await QRCode.toDataURL(qrContent);

// Store payment intent in database for polling
await PaymentIntent.create({
  reference_id: paymentRefId,
  user_id: user.id,
  event_id: event.id,
  amount: total,
  status: 'pending',
  expires_at: new Date(Date.now() + 30 * 60 * 1000), // 30 min expiry
  qr_data: qrContent
});

return {
  qr_code_image: qrCodeImage,
  payment_reference_id: paymentRefId,
  amount_total: total,
  expires_in: 1800 // 30 minutes in seconds
};
```

### Step 4: Member Scans QR and Completes Payment
```javascript
// Member scans the displayed QR code using GCash app
// GCash app handles all authentication (SMS OTP, fingerprint, etc.)
// Frontend polls for payment status

const pollPaymentStatus = async (paymentRefId) => {
  let attempts = 0;
  const maxAttempts = 60; // Poll for 5 minutes (5s × 60)

  while (attempts < maxAttempts) {
    try {
      const response = await fetch(`/api/payments/status/${paymentRefId}`, {
        headers: { 'Authorization': `Bearer ${accessToken}` }
      });

      const { status, error } = await response.json();

      if (status === 'completed') {
        return { success: true, paymentRefId };
      } else if (status === 'failed') {
        return { success: false, error };
      } else if (status === 'expired') {
        return { success: false, error: 'Payment QR expired. Please try again.' };
      }

      // Wait 5 seconds before next poll
      await new Promise(resolve => setTimeout(resolve, 5000));
      attempts++;
    } catch (err) {
      console.error('Poll error:', err);
      attempts++;
    }
  }

  return { success: false, error: 'Payment timeout' };
};

// Start polling
const result = await pollPaymentStatus(paymentRefId);
if (result.success) {
  // Proceed to Step 5
} else {
  showErrorAlert(result.error);
}
```

### Step 5: Backend Confirms Payment & Creates Ticket
```javascript
// Webhook confirms payment is successful (see Section 4)
// Upon success:

// 1. Create ticket with cryptographic hash
const qrHash = generateSecureHash(user.id, event.id, tier.id, CRYPTO_SALT);
const ticket = await Ticket.create({
  event_id: event.id,
  user_id: user.id,
  tier_id: tier.id,
  qr_hash: qrHash,
  status: 'Active',
  purchased_at: new Date()
});

// 2. Link add-ons to ticket
for (const addon of addons) {
  await TicketAddon.create({
    ticket_id: ticket.id,
    addon_id: addon.id,
    quantity: addon.quantity,
    fulfilled: false
  });
}

// 3. Record transaction
await Transaction.create({
  org_id: org.id,
  user_id: user.id,
  ticket_id: ticket.id,
  type: 'ticket_purchase',
  gross_amount: subtotal,
  platform_fee: platformFees,
  net_amount: subtotal,
  status: 'completed',
  gcash_reference_id: paymentRefId,
  payment_method: 'gcash'
});

// 4. Return ticket to frontend
return {
  ticket_id: ticket.id,
  qr_hash: ticket.qr_hash,
  status: 'success'
};
```

---

## 4. Webhook Handling (Critical for Payment Verification)

### Webhook Configuration
**GCash Portal → Developer Settings → Webhooks:**
- **Endpoint URL:** `https://api.eventix.app/webhooks/gcash`
- **Events to Listen For:**
  - `payment.completed` (successful transaction)
  - `payment.failed` (transaction declined)
  - `payment.expired` (QR code timeout)
  - `payment.refunded` (refund processed)

### Webhook Handler Implementation
```javascript
// backend/src/routes/webhooks.js
const express = require('express');
const router = express.Router();
const crypto = require('crypto');

router.post('/gcash', express.json(), async (req, res) => {
  const signature = req.headers['x-gcash-signature'];
  const timestamp = req.headers['x-gcash-timestamp'];
  let event;

  try {
    // Verify webhook signature (prevents spoofing)
    const payload = JSON.stringify(req.body);
    const signatureData = `${payload}${timestamp}${process.env.GCASH_WEBHOOK_SECRET}`;
    const expectedSignature = crypto
      .createHash('sha256')
      .update(signatureData)
      .digest('hex');

    if (signature !== expectedSignature) {
      throw new Error('Invalid webhook signature');
    }

    event = req.body;
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle different event types
  switch (event.eventType) {
    case 'payment.completed':
      await handlePaymentSuccess(event.data);
      break;

    case 'payment.failed':
      await handlePaymentFailure(event.data);
      break;

    case 'payment.expired':
      await handlePaymentExpired(event.data);
      break;

    case 'payment.refunded':
      await handleRefund(event.data);
      break;

    default:
      console.log(`Unhandled event type: ${event.eventType}`);
  }

  // Acknowledge receipt
  res.json({acknowledged: true});
});

// Payment Success Handler
async function handlePaymentSuccess(paymentData) {
  const { referenceId, amount, timestamp } = paymentData;

  // Fetch payment intent to verify amount
  const paymentIntent = await PaymentIntent.findOne({
    reference_id: referenceId
  });

  if (paymentIntent && paymentIntent.amount === amount) {
    paymentIntent.status = 'completed';
    paymentIntent.completed_at = new Date(timestamp);
    await paymentIntent.save();

    // Update related transaction
    await Transaction.updateOne(
      { gcash_reference_id: referenceId },
      { status: 'completed', completed_at: new Date() }
    );

    // Emit success notification
    await notificationService.sendTicketConfirmation(
      paymentIntent.user_id,
      paymentIntent.event_id
    );
  }
}

// Payment Failure Handler
async function handlePaymentFailure(paymentData) {
  const { referenceId, failureReason, timestamp } = paymentData;

  const paymentIntent = await PaymentIntent.findOne({
    reference_id: referenceId
  });

  if (paymentIntent) {
    paymentIntent.status = 'failed';
    paymentIntent.failure_reason = failureReason;
    paymentIntent.failed_at = new Date(timestamp);
    await paymentIntent.save();

    // Update transaction
    await Transaction.updateOne(
      { gcash_reference_id: referenceId },
      { 
        status: 'failed',
        failure_reason: failureReason,
        failed_at: new Date()
      }
    );

    // Notify user to retry
    await notificationService.sendPaymentFailureAlert(
      paymentIntent.user_id,
      `Payment failed: ${failureReason}. Please try again.`
    );
  }
}

// Payment Expired Handler
async function handlePaymentExpired(paymentData) {
  const { referenceId } = paymentData;

  const paymentIntent = await PaymentIntent.findOne({
    reference_id: referenceId
  });

  if (paymentIntent) {
    paymentIntent.status = 'expired';
    paymentIntent.expired_at = new Date();
    await paymentIntent.save();

    // Notify user to retry
    await notificationService.sendPaymentExpiredAlert(
      paymentIntent.user_id,
      'Your payment QR code has expired. Please generate a new one.'
    );
  }
}

// Refund Handler
async function handleRefund(refundData) {
  const { originalReferenceId, refundAmount, timestamp } = refundData;

  const transaction = await Transaction.findOne({
    gcash_reference_id: originalReferenceId
  });

  if (transaction) {
    transaction.status = 'refunded';
    transaction.refunded_amount = refundAmount;
    transaction.refunded_at = new Date(timestamp);
    await transaction.save();

    // Invalidate associated ticket
    const ticket = await Ticket.findById(transaction.ticket_id);
    if (ticket) {
      ticket.status = 'Cancelled';
      ticket.cancelled_reason = 'Refunded';
      await ticket.save();
    }

    // Notify user
    await notificationService.sendRefundConfirmation(
      transaction.user_id,
      refundAmount
    );
  }
}

module.exports = router;
```

---

## 5. Membership Fee Processing

### Membership Fee Collection Flow

**Setup:**
1. Organizer configures membership fee (e.g., $9.99/month) via Settings
2. Fee is stored in `organizations.membership_fee` and `organizations.billing_interval`

**Payment:**
```javascript
// When user requests to join an organization with membership fee
const joinRequest = await OrganizationUser.create({
  org_id: org.id,
  user_id: user.id,
  role: 'Member',
  status: 'Pending'
});

// If org has membership fee, generate QR for payment
if (org.membership_fee > 0) {
  const paymentRefId = `MEM_${Date.now()}_${user.id.substring(0, 8)}`;
  const qrContent = JSON.stringify({
    merchantId: process.env.GCASH_MERCHANT_ID,
    referenceId: paymentRefId,
    amount: org.membership_fee,
    currency: 'PHP',
    description: `Membership fee for ${org.name}`
  });
  const qrCodeImage = await QRCode.toDataURL(qrContent);

  await PaymentIntent.create({
    reference_id: paymentRefId,
    user_id: user.id,
    org_id: org.id,
    amount: org.membership_fee,
    type: 'membership_fee',
    status: 'pending',
    expires_at: new Date(Date.now() + 30 * 60 * 1000)
  });

  return {
    join_request_id: joinRequest.id,
    requires_payment: true,
    qr_code_image: qrCodeImage,
    payment_reference_id: paymentRefId
  };
}
```

**Tracking:**
```javascript
// After successful membership payment
const orgUser = await OrganizationUser.findOne({
  org_id: org.id,
  user_id: user.id
});

// Set dues_paid_until based on billing interval
if (org.billing_interval === 'monthly') {
  orgUser.dues_paid_until = addMonths(new Date(), 1);
} else if (org.billing_interval === 'annually') {
  orgUser.dues_paid_until = addMonths(new Date(), 12);
} else {
  orgUser.dues_paid_until = null; // one_time
}

orgUser.status = 'Active';
await orgUser.save();
```

**Recurring Charges (Future):**
- Create separate QR code for each billing cycle
- Send email reminder 7 days before membership expiration
- Implement auto-retry logic for failed payments
- Consider GCash Subscriptions API integration for automated billing

---

## 6. Refunds & Cancellations

### Refund Policy
- **Full Refund:** Available up to 48 hours before event start
- **Partial Refund (50%):** Available 48-24 hours before event
- **No Refund:** Within 24 hours of event start

### Refund Implementation
```javascript
// backend/src/services/refundService.js
async function processRefund(ticketId, reason) {
  const ticket = await Ticket.findById(ticketId);
  const transaction = await Transaction.findOne({ ticket_id: ticketId });
  const event = await Event.findById(ticket.event_id);

  // Check refund eligibility
  const hoursUntilEvent = (event.start_date - Date.now()) / (1000 * 60 * 60);

  if (hoursUntilEvent < 0) {
    throw new Error('Event already started; no refunds available');
  }

  let refundPercentage = 1.0; // Full refund
  if (hoursUntilEvent < 24) {
    throw new Error('Within 24-hour window; no refunds');
  } else if (hoursUntilEvent < 48) {
    refundPercentage = 0.5; // 50% refund
  }

  const refundAmount = transaction.gross_amount * refundPercentage;

  // Issue refund via GCash API
  const refundResponse = await axios.post(
    `${process.env.GCASH_API_BASE_URL}/v2/refunds`,
    {
      originalTransactionId: transaction.gcash_reference_id,
      amount: refundAmount,
      reason: reason,
      merchantId: process.env.GCASH_MERCHANT_ID
    },
    {
      headers: {
        'Authorization': `Bearer ${process.env.GCASH_API_KEY}`,
        'Content-Type': 'application/json'
      }
    }
  );

  const refund = refundResponse.data;

  // Update ticket status
  ticket.status = 'Refunded';
  ticket.refunded_at = new Date();
  await ticket.save();

  // Record refund transaction
  await RefundLog.create({
    ticket_id: ticketId,
    original_transaction_id: transaction.id,
    refund_amount: refundAmount,
    refund_percentage: refundPercentage,
    reason: reason,
    gcash_refund_id: refund.refundId,
    status: 'completed'
  });

  return { success: true, refundId: refund.id, amount: refundAmount };
}
```

---

## 7. Add-On Purchase & Inventory Management

### Add-On Checkout
```javascript
// When member selects add-ons during RSVP
const addons = [
  { addon_id: 'addon-1', quantity: 2 },
  { addon_id: 'addon-2', quantity: 1 }
];

// Check inventory availability (concurrency-safe)
for (const addon of addons) {
  const eventAddon = await EventAddon.findById(addon.addon_id);
  
  // Lock row to prevent race conditions
  const locked = await db.query(
    'SELECT * FROM event_addons WHERE id = $1 FOR UPDATE',
    [addon.addon_id]
  );

  if (locked[0].stock < addon.quantity) {
    throw new Error(`Insufficient stock for ${eventAddon.name}`);
  }

  // Deduct stock
  eventAddon.stock -= addon.quantity;
  await eventAddon.save();
}
```

---

## 8. Financial Reporting & Analytics

### Revenue Dashboard Data
```javascript
// backend/src/services/financialService.js
async function getOrgRevenueSummary(orgId, startDate, endDate) {
  const transactions = await Transaction.find({
    org_id: orgId,
    created_at: { $gte: startDate, $lte: endDate },
    status: 'completed'
  });

  const summary = {
    ticket_revenue: 0,
    addon_revenue: 0,
    membership_dues: 0,
    total_fees: 0,
    net_revenue: 0
  };

  for (const txn of transactions) {
    if (txn.type === 'ticket_purchase') {
      summary.ticket_revenue += txn.gross_amount;
    } else if (txn.type === 'addon_purchase') {
      summary.addon_revenue += txn.gross_amount;
    } else if (txn.type === 'membership_fee') {
      summary.membership_dues += txn.gross_amount;
    }
    
    summary.total_fees += txn.platform_fee;
  }

  summary.net_revenue = 
    (summary.ticket_revenue + summary.addon_revenue + summary.membership_dues) 
    - summary.total_fees;

  return summary;
}
```

---

## 9. PCI Compliance Checklist

**EvenTix Data Handling:**
- ✅ **No sensitive financial data stored locally** (GCash handles all auth)
- ✅ **HTTPS enforced** for all payment endpoints
- ✅ **JWT authentication** validates all payment requests
- ✅ **Webhook signature verification** prevents spoofing
- ✅ **Environment variables** used for API keys (never hardcoded)
- ✅ **Logs sanitized** (QR data and reference IDs only)
- ✅ **Rate limiting** prevents brute-force attacks

**Annual Activities:**
- Conduct security audit of payment infrastructure
- Update GCash SDK to latest version
- Review and rotate webhook secrets and API keys
- Review transaction logs for anomalies
- Test refund flow quarterly

---

## 10. Error Handling & User Feedback

### Common Payment Errors
```javascript
const paymentErrorMessages = {
  'insufficient_balance': 'Insufficient GCash balance. Please add funds and try again.',
  'transaction_declined': 'Your GCash transaction was declined. Please check and retry.',
  'invalid_otp': 'Incorrect OTP. Please enter the correct code sent to your phone.',
  'otp_expired': 'Your OTP has expired. Please request a new one.',
  'processing_error': 'An error occurred while processing your payment. Please try again.',
  'qr_expired': 'The payment QR code has expired. Please generate a new one.',
  'user_cancelled': 'Payment was cancelled by user.',
  'network_error': 'Network error. Please check your connection and try again.'
};
```

### Frontend Error Handling
```javascript
// Poll for payment status and handle errors
const result = await pollPaymentStatus(paymentRefId);

if (result.success) {
  showSuccessAlert('Payment successful! Your ticket is confirmed.');
  redirectToTicketWallet();
} else {
  const userMessage = paymentErrorMessages[result.error] || result.error;
  showErrorAlert(userMessage);
  logErrorMetrics({ 
    error: result.error, 
    paymentRefId,
    timestamp: new Date() 
  });

  // Show retry button
  if (result.error !== 'Payment timeout') {
    showRetryButton(() => {
      // Redirect back to generate new QR
      window.location.href = '/checkout';
    });
  }
}
```

---

## 11. Testing & Sandbox Environment

### GCash Development Keys
Use these during development:
```bash
GCASH_API_BASE_URL=https://devapi.globelabs.com.ph
GCASH_API_KEY=your_dev_api_key
GCASH_MERCHANT_ID=your_dev_merchant_id
GCASH_APP_ID=your_dev_app_id
GCASH_APP_SECRET=your_dev_app_secret
```

### Test Scenarios
| Scenario | GCash Account |
| :--- | :--- |
| Success | Use any test GCash number provided by Globe Labs |
| Insufficient Balance | Create test account with 0 balance |
| OTP Failed | Cancel OTP dialog in GCash app |
| Timeout | Don't complete payment within 30 minutes |
| Manual Refund | Issue refund from GCash dashboard afterward |

### Manual Webhook Testing
```bash
# Send test webhook directly (development only)
curl -X POST http://localhost:5000/api/webhooks/gcash \
  -H "Content-Type: application/json" \
  -H "x-gcash-signature: $(echo -n 'payload' | openssl dgst -sha256 -hmac 'secret' | cut -d' ' -f2)" \
  -H "x-gcash-timestamp: $(date +%s)" \
  -d '{
    "eventType": "payment.completed",
    "data": {
      "referenceId": "EVT_test_123",
      "amount": 500,
      "timestamp": "2026-03-27T10:00:00Z"
    }
  }'
```

---

## 12. Production Checklist

Before going live:
- [ ] Switch to Production API keys in production environment
- [ ] Change API endpoint to https://api.globelabs.com.ph
- [ ] Configure webhook signature verification with production secret
- [ ] Set up GCash monitoring and alerts via Globe Labs dashboard
- [ ] Test full payment flow end-to-end (QR generation, scanning, webhook)
- [ ] Configure email receipts for payment confirmations
- [ ] Verify currency set to PHP
- [ ] Document refund policy and communicate to organizers
- [ ] Test webhook delivery with production webhook secret
- [ ] Set up monitoring for failed payments and expired QRs
- [ ] Create runbook for payment-related issues
- [ ] Train support team on payment troubleshooting
- [ ] Document incident response procedures


# EvenTix - REST API Contracts & Specifications

**Backend Owner:** Backend Dev  
**Base URL:** `https://api.eventix.app` (Production) | `http://localhost:5000` (Development)  
**API Version:** v1  
**Last Updated:** March 27, 2026

---

## 1. Authentication & Authorization

### A. Token-Based Authentication
All protected endpoints require a valid JWT Bearer token in the `Authorization` header.

```
Authorization: Bearer <jwt_token>
```

**Token Structure:**
```json
{
  "sub": "user_id (UUID)",
  "email": "user@example.com",
  "role": "Member|Staff|Co-Organizer|Owner",
  "org_id": "organization_id (UUID)",
  "iat": 1690000000,
  "exp": 1690086400,
  "aud": "eventix"
}
```

**Token Validity:**
- Access Token TTL: 1 hour
- Refresh Token TTL: 7 days
- Refresh tokens stored securely in HTTP-only cookies (backend) or Secure storage (mobile)

### B. RBAC (Role-Based Access Control)
Enforce these rules at the middleware level:

| Role | Allowed Endpoints |
| :--- | :--- |
| **Owner** | All organization endpoints (events, members, financials) |
| **Co-Organizer** | All organization endpoints except: Settings, Delete Organization, Payout Configuration |
| **Staff** | Scanner (check-in), View Attendees, Limited Member Management |
| **Member** | Personal feed, RSVP, Wallet, Profile, Public Org Search |

---

## 2. Authentication Endpoints

### `POST /auth/register`
**Description:** User registration (Member or Organizer).

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "full_name": "John Doe",
  "account_type": "Member|Organizer"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "expires_in": 3600
}
```

**Error Responses:**
- `400 Bad Request`: Invalid email format or weak password
- `409 Conflict`: Email already registered

---

### `POST /auth/login`
**Description:** User login with email and password.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "expires_in": 3600
}
```

**Error Responses:**
- `401 Unauthorized`: Invalid email or password
- `429 Too Many Requests`: 5 failed attempts in 15 minutes (rate limited)

---

### `POST /auth/refresh`
**Description:** Refresh expired access token using a valid refresh token.

**Request:**
```json
{
  "refresh_token": "eyJhbGc..."
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGc...",
  "expires_in": 3600
}
```

**Error Responses:**
- `401 Unauthorized`: Invalid or expired refresh token

---

### `POST /auth/logout`
**Description:** Invalidate the user's refresh token.

**Request:** (Authenticated)
```
No body required
```

**Response (204 No Content):**
```
(Empty body)
```

---

## 3. Organization Endpoints

### `POST /organizations`
**Description:** Create a new organization (Organizer only).

**Request:** (Authenticated, Role: Member creating first org)
```json
{
  "name": "Tech Community",
  "description": "A vibrant tech community",
  "logo_url": "https://cdn.example.com/logo.png",
  "branding_color": "#3B82F6",
  "is_public": true
}
```

**Response (201 Created):**
```json
{
  "id": "org-uuid",
  "name": "Tech Community",
  "description": "A vibrant tech community",
  "logo_url": "https://cdn.example.com/logo.png",
  "branding_color": "#3B82F6",
  "is_public": true,
  "membership_fee": 0.00,
  "created_at": "2026-03-27T10:00:00Z"
}
```

---

### `GET /organizations`
**Description:** Fetch all public organizations (paginated).

**Query Parameters:**
```
?page=1&limit=20&search=Tech&sort_by=created_at
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "org-uuid",
      "name": "Tech Community",
      "description": "A vibrant tech community",
      "logo_url": "https://cdn.example.com/logo.png",
      "member_count": 250,
      "is_public": true
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 542,
    "pages": 28
  }
}
```

---

### `GET /organizations/:org_id`
**Description:** Fetch a single organization by ID.

**Response (200 OK):**
```json
{
  "id": "org-uuid",
  "name": "Tech Community",
  "description": "A vibrant tech community",
  "logo_url": "https://cdn.example.com/logo.png",
  "branding_color": "#3B82F6",
  "is_public": true,
  "membership_fee": 9.99,
  "member_count": 250,
  "created_at": "2026-03-27T10:00:00Z"
}
```

---

### `PATCH /organizations/:org_id`
**Description:** Update organization details (Owner/Co-Organizer only).

**Request:** (Authenticated)
```json
{
  "name": "Tech Community (Updated)",
  "branding_color": "#EF4444",
  "membership_fee": 19.99,
  "is_public": false
}
```

**Response (200 OK):**
```json
{
  "id": "org-uuid",
  "name": "Tech Community (Updated)",
  "branding_color": "#EF4444",
  "membership_fee": 19.99,
  "is_public": false
}
```

---

### `DELETE /organizations/:org_id`
**Description:** Delete organization and all related data (Owner only).

**Response (204 No Content):**
```
(Empty body - cascading delete triggers)
```

---

## 4. Event Endpoints

### `POST /organizations/:org_id/events`
**Description:** Create a new event (Owner/Co-Organizer only).

**Request:** (Authenticated)
```json
{
  "title": "Tech Conference 2026",
  "description": "Annual tech gathering",
  "start_date": "2026-06-15T09:00:00Z",
  "end_date": "2026-06-17T18:00:00Z",
  "artwork_url": "https://cdn.example.com/ticket.png",
  "location": "Convention Center, NYC",
  "tiers": [
    {
      "name": "General Admission",
      "price": 50.00,
      "capacity": 500
    },
    {
      "name": "VIP",
      "price": 150.00,
      "capacity": 100
    }
  ],
  "addons": [
    {
      "name": "Event T-Shirt (Medium)",
      "price": 25.00,
      "stock": 300
    }
  ]
}
```

**Response (201 Created):**
```json
{
  "id": "event-uuid",
  "org_id": "org-uuid",
  "title": "Tech Conference 2026",
  "description": "Annual tech gathering",
  "start_date": "2026-06-15T09:00:00Z",
  "end_date": "2026-06-17T18:00:00Z",
  "artwork_url": "https://cdn.example.com/ticket.png",
  "status": "Draft",
  "created_at": "2026-03-27T10:00:00Z"
}
```

---

### `GET /organizations/:org_id/events`
**Description:** Fetch all events for an organization (paginated).

**Query Parameters:**
```
?page=1&limit=20&status=Published&sort_by=start_date
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "event-uuid",
      "title": "Tech Conference 2026",
      "start_date": "2026-06-15T09:00:00Z",
      "end_date": "2026-06-17T18:00:00Z",
      "status": "Published",
      "tickets_sold": 450,
      "tickets_available": 150,
      "capacity": 600
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 35, "pages": 2 }
}
```

---

### `GET /events/:event_id`
**Description:** Fetch event details (public or authenticated member of org).

**Response (200 OK):**
```json
{
  "id": "event-uuid",
  "org_id": "org-uuid",
  "title": "Tech Conference 2026",
  "description": "Annual tech gathering",
  "start_date": "2026-06-15T09:00:00Z",
  "end_date": "2026-06-17T18:00:00Z",
  "artwork_url": "https://cdn.example.com/ticket.png",
  "location": "Convention Center, NYC",
  "status": "Published",
  "tiers": [
    {
      "id": "tier-uuid",
      "name": "General Admission",
      "price": 50.00,
      "capacity": 500,
      "available": 450
    }
  ],
  "addons": [
    {
      "id": "addon-uuid",
      "name": "Event T-Shirt (Medium)",
      "price": 25.00,
      "stock": 300
    }
  ]
}
```

---

### `PATCH /events/:event_id`
**Description:** Update event details (Owner/Co-Organizer only).

**Response (200 OK):**
```json
{ "message": "Event updated successfully" }
```

---

### `POST /events/:event_id/publish`
**Description:** Publish event (change status from Draft to Published).

**Response (200 OK):**
```json
{
  "id": "event-uuid",
  "status": "Published",
  "published_at": "2026-03-27T10:15:00Z"
}
```

---

## 5. Ticketing & RSVP Endpoints

### `POST /events/:event_id/rsvp`
**Description:** Create ticket and process payment for RSVP (Authenticated Member).

**Request:**
```json
{
  "tier_id": "tier-uuid",
  "addons": [
    {
      "addon_id": "addon-uuid",
      "quantity": 2
    }
  ],
  "payment_method_id": "pm_1234567890"
}
```

**Response (201 Created):**
```json
{
  "ticket_id": "ticket-uuid",
  "user_id": "user-uuid",
  "event_id": "event-uuid",
  "tier": "General Admission",
  "qr_hash": "EVT_abc123xyz789...",
  "status": "Active",
  "subtotal": 50.00,
  "addons_cost": 50.00,
  "fees": 5.00,
  "total": 105.00,
  "purchased_at": "2026-03-27T10:20:00Z"
}
```

**Error Responses:**
- `400 Bad Request`: Tier/addon not found
- `409 Conflict`: No capacity/stock available
- `402 Payment Required`: Payment failed
- `403 Forbidden`: User banned from organization

---

### `GET /users/tickets`
**Description:** Fetch all tickets for the authenticated user (paginated).

**Query Parameters:**
```
?page=1&limit=20&status=Active&sort_by=purchased_at
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "ticket_id": "ticket-uuid",
      "event_title": "Tech Conference 2026",
      "event_date": "2026-06-15T09:00:00Z",
      "tier": "General Admission",
      "status": "Active",
      "qr_hash": "EVT_abc123xyz789..."
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 12, "pages": 1 }
}
```

---

### `GET /tickets/:ticket_id`
**Description:** Fetch ticket details by ID (Authenticated, Owner or Org Staff).

**Response (200 OK):**
```json
{
  "ticket_id": "ticket-uuid",
  "user_id": "user-uuid",
  "event_id": "event-uuid",
  "tier": "General Admission",
  "qr_hash": "EVT_abc123xyz789...",
  "status": "Active",
  "addons": [
    {
      "name": "Event T-Shirt (Medium)",
      "price": 25.00,
      "quantity": 2,
      "fulfilled": false
    }
  ],
  "purchased_at": "2026-03-27T10:20:00Z",
  "valid_from": "2026-06-15T00:00:00Z",
  "valid_until": "2026-06-18T00:00:00Z"
}
```

---

### `POST /tickets/:ticket_id/transfer`
**Description:** Transfer ticket to another user within the same organization.

**Request:** (Authenticated, Ticket Owner)
```json
{
  "recipient_email": "recipient@example.com"
}
```

**Response (201 Created):**
```json
{
  "original_ticket_id": "ticket-uuid-old",
  "new_ticket_id": "ticket-uuid-new",
  "status": "Transferred",
  "original_qr_hash": "EVT_old_hash_invalidated",
  "new_qr_hash": "EVT_new_hash_generated",
  "transferred_at": "2026-03-27T10:25:00Z"
}
```

**Error Responses:**
- `404 Not Found`: Recipient not found or not in same organization
- `403 Forbidden`: User banned or ticket already transferred

---

## 6. Scanner & Attendance Endpoints

### `POST /scan/verify`
**Description:** Verify and log ticket scan at event entry (Authenticated Staff).

**Request:**
```json
{
  "qr_hash": "EVT_abc123xyz789...",
  "event_id": "event-uuid",
  "day_identifier": "2026-06-15"
}
```

**Response (200 OK):**
```json
{
  "valid": true,
  "member_name": "John Doe",
  "ticket_tier": "VIP",
  "tier_color": "gold",
  "addons": [
    {
      "name": "Event T-Shirt (Medium)",
      "quantity": 2,
      "fulfilled": false
    }
  ],
  "checked_in_at": "2026-06-15T09:15:30Z"
}
```

**Response (Invalid Ticket):**
```json
{
  "valid": false,
  "reason": "Ticket_Already_Scanned|Ticket_Invalid|User_Banned|Day_Mismatch",
  "member_name": "John Doe",
  "tier_color": "red"
}
```

---

### `POST /scan/fulfill-addon`
**Description:** Mark add-on as fulfilled (Authenticated Staff).

**Request:**
```json
{
  "ticket_id": "ticket-uuid",
  "addon_id": "addon-uuid"
}
```

**Response (200 OK):**
```json
{
  "addon_id": "addon-uuid",
  "fulfilled": true,
  "fulfilled_at": "2026-06-15T09:20:00Z"
}
```

---

### `GET /events/:event_id/attendance`
**Description:** Fetch attendance statistics for an event (Authenticated Owner/Co-Organizer).

**Response (200 OK):**
```json
{
  "event_id": "event-uuid",
  "total_rsvps": 450,
  "checked_in": 400,
  "no_show": 50,
  "by_tier": {
    "General Admission": { "rsvps": 350, "checked_in": 310 },
    "VIP": { "rsvps": 100, "checked_in": 90 }
  },
  "by_day": {
    "2026-06-15": 300,
    "2026-06-16": 280,
    "2026-06-17": 250
  }
}
```

---

## 7. Member Management Endpoints

### `GET /organizations/:org_id/members`
**Description:** Fetch all members of an organization (Owner/Co-Organizer only, paginated).

**Query Parameters:**
```
?page=1&limit=20&role=Member&status=Active&search=John
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "user_id": "user-uuid",
      "full_name": "John Doe",
      "email": "john@example.com",
      "role": "Member",
      "status": "Active",
      "joined_at": "2026-03-01T10:00:00Z",
      "dues_paid_until": "2026-06-01"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 250, "pages": 13 }
}
```

---

### `GET /organizations/:org_id/approvals`
**Description:** Fetch pending member join requests (Owner/Co-Organizer only).

**Response (200 OK):**
```json
{
  "data": [
    {
      "user_id": "user-uuid",
      "full_name": "Jane Smith",
      "email": "jane@example.com",
      "status": "Pending",
      "requested_at": "2026-03-26T15:00:00Z"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 5, "pages": 1 }
}
```

---

### `POST /organizations/:org_id/members/:user_id/approve`
**Description:** Approve a pending member join request (Owner/Co-Organizer only).

**Response (200 OK):**
```json
{
  "user_id": "user-uuid",
  "status": "Active",
  "approved_at": "2026-03-27T10:30:00Z"
}
```

---

### `POST /organizations/:org_id/members/:user_id/reject`
**Description:** Reject a pending member join request (Owner/Co-Organizer only).

**Response (200 OK):**
```json
{
  "user_id": "user-uuid",
  "status": "Rejected"
}
```

---

### `POST /organizations/:org_id/members/:user_id/ban`
**Description:** Ban a member from the organization (Owner/Co-Organizer only).

**Request:**
```json
{
  "reason": "Disruptive behavior at events"
}
```

**Response (200 OK):**
```json
{
  "user_id": "user-uuid",
  "status": "Banned",
  "banned_at": "2026-03-27T10:35:00Z",
  "reason": "Disruptive behavior at events"
}
```

---

### `PATCH /organizations/:org_id/members/:user_id/role`
**Description:** Update member role (Owner only).

**Request:**
```json
{
  "role": "Co-Organizer|Staff|Member"
}
```

**Response (200 OK):**
```json
{
  "user_id": "user-uuid",
  "role": "Co-Organizer"
}
```

---

## 8. Evaluation & Certificate Endpoints

### `POST /events/:event_id/evaluation`
**Description:** Create evaluation form (Owner/Co-Organizer only, post-event).

**Request:**
```json
{
  "form_schema": {
    "questions": [
      {
        "id": "q1",
        "type": "rating",
        "label": "How would you rate this event?",
        "scale": 5
      },
      {
        "id": "q2",
        "type": "text",
        "label": "What could we improve?"
      }
    ]
  },
  "cert_template_url": "https://cdn.example.com/cert-template.pdf"
}
```

**Response (201 Created):**
```json
{
  "evaluation_id": "eval-uuid",
  "event_id": "event-uuid",
  "created_at": "2026-03-27T10:40:00Z"
}
```

---

### `POST /events/:event_id/evaluate`
**Description:** Submit evaluation responses (Authenticated Member).

**Request:**
```json
{
  "response_data": {
    "q1": 5,
    "q2": "Great event, would like more networking opportunities"
  }
}
```

**Response (201 Created):**
```json
{
  "response_id": "resp-uuid",
  "evaluation_id": "eval-uuid",
  "user_id": "user-uuid",
  "submitted_at": "2026-03-27T10:45:00Z",
  "certificate_ready": true,
  "certificate_url": "https://cdn.example.com/certificates/cert-abc123.pdf"
}
```

---

### `GET /users/certificates`
**Description:** Fetch all certificates for the authenticated user (paginated).

**Response (200 OK):**
```json
{
  "data": [
    {
      "certificate_id": "cert-uuid",
      "event_title": "Tech Conference 2026",
      "event_date": "2026-06-15",
      "pdf_url": "https://cdn.example.com/certificates/cert-abc123.pdf",
      "issued_at": "2026-03-27T10:45:00Z"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 8, "pages": 1 }
}
```

---

## 9. Financial Endpoints

### `GET /organizations/:org_id/financials`
**Description:** Fetch financial data for an organization (Owner/Co-Organizer only).

**Query Parameters:**
```
?start_date=2026-01-01&end_date=2026-03-31&group_by=month
```

**Response (200 OK):**
```json
{
  "organization_id": "org-uuid",
  "currency": "USD",
  "summary": {
    "ticket_revenue": 22500.00,
    "addon_revenue": 3750.00,
    "membership_dues": 1500.00,
    "total_revenue": 27750.00,
    "total_fees": 1387.50,
    "net_revenue": 26362.50
  },
  "by_period": [
    {
      "period": "2026-01",
      "revenue": 9250.00,
      "fees": 462.50
    }
  ]
}
```

---

### `GET /organizations/:org_id/transactions`
**Description:** Fetch transaction ledger (Owner/Co-Organizer only, paginated).

**Query Parameters:**
```
?page=1&limit=50&type=payment&sort_by=created_at
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "transaction_id": "txn-uuid",
      "user_id": "user-uuid",
      "user_name": "John Doe",
      "type": "ticket_purchase",
      "event_title": "Tech Conference 2026",
      "amount": 50.00,
      "fees": 2.50,
      "net": 47.50,
      "status": "completed",
      "created_at": "2026-03-27T10:20:00Z"
    }
  ],
  "pagination": { "page": 1, "limit": 50, "total": 450, "pages": 9 }
}
```

---

### `PATCH /organizations/:org_id/settings/membership-fees`
**Description:** Update membership fee configuration (Owner only).

**Request:**
```json
{
  "fee_amount": 19.99,
  "billing_interval": "monthly|annually|one_time"
}
```

**Response (200 OK):**
```json
{
  "membership_fee": 19.99,
  "billing_interval": "monthly"
}
```

---

## 10. Public Profile Endpoints

### `GET /u/:username`
**Description:** Fetch public profile data (Trophy Room, no auth required).

**Response (200 OK):**
```json
{
  "user_id": "user-uuid",
  "full_name": "John Doe",
  "bio": "Tech enthusiast and event organizer",
  "id_cards": [
    {
      "org_id": "org-uuid",
      "org_name": "Tech Community",
      "org_logo_url": "https://cdn.example.com/logo.png",
      "member_photo_url": "https://cdn.example.com/john-doe.jpg",
      "role": "Member",
      "joined_at": "2026-01-15"
    }
  ],
  "souvenirs": [
    {
      "event_title": "Tech Conference 2026",
      "event_date": "2026-06-15",
      "artwork_url": "https://cdn.example.com/ticket.png",
      "status": "Evolved_Souvenir",
      "attendance_count": 3
    }
  ],
  "stats": {
    "total_events_attended": 12,
    "total_certificates": 8,
    "member_since": "2026-01-15"
  }
}
```

---

## 11. Error Response Format

All error responses follow this standardized format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "field": "field_name",
      "issue": "Specific validation error"
    },
    "timestamp": "2026-03-27T10:50:00Z",
    "request_id": "req-abc123xyz"
  }
}
```

**Common Error Codes:**
- `AUTHENTICATION_REQUIRED`: Missing or invalid JWT token
- `INSUFFICIENT_PERMISSIONS`: User lacks required role
- `VALIDATION_ERROR`: Invalid request payload
- `RESOURCE_NOT_FOUND`: Entity does not exist
- `CONFLICT`: State conflict (e.g., already scanned)
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `PAYMENT_FAILED`: Payment processor error

---

## 12. Rate Limiting

| Endpoint Group | Limit | Window |
| :--- | :--- | :--- |
| **Auth (login/register)** | 5 requests | 15 minutes |
| **Scanner (verify)** | 100 requests | 1 minute |
| **All other endpoints** | 100 requests | 1 minute (per user) |

---

## 13. API Versioning & Changelog

**Current Version:** v1  
**Endpoint Prefix:** All requests to `/api/v1/...`

To maintain backward compatibility, breaking changes require a major version bump (v2, v3, etc.).


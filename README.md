# EvenTix 🎫
**Transform Event Management. Secure Ticketing. Community First.**

![Status](https://img.shields.io/badge/Status-In%20Development-blue?style=flat-square)
![Phase](https://img.shields.io/badge/Phase-Planning%20%26%20Discovery-yellow?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## Overview

**EvenTix** is a comprehensive, decoupled 3-tier platform designed to empower organizations to manage their members, publish events, handle secure real-time attendance checking, and create digital collectible souvenirs. Built for organizations who need control, security, and community engagement.

### The Problem
Event organizers struggle with:
- ❌ Fragmented ticketing systems (email confirmations, PDFs, manual tracking)
- ❌ No real-time attendance verification
- ❌ Scalping and ticket fraud through physical duplicates
- ❌ Poor post-event engagement and alumni community building
- ❌ Expensive, globally-focused payment solutions unsuitable for emerging markets

### The Solution
EvenTix provides:
- ✅ **Secure QR-Based Ticketing** - Cryptographically unforgeable, single-use-per-day verification
- ✅ **Real-Time Attendance Scanning** - Live dashboard with gamification (raffle triggers)
- ✅ **Digital Souvenir Wallet** - Collectible, "evolving" tickets that members cherish
- ✅ **Community Identity System** - Digital ID cards that members proudly display
- ✅ **Philippines-First Payments** - GCash integration for instant, low-cost settlements
- ✅ **Post-Event Excellence** - Evaluation forms, auto-generated certificates, public profiles

---

## 🎯 Key Features

### For Members
| Feature | Benefit |
| :--- | :--- |
| **Event Discovery** | Browse and discover public organizations and their events |
| **Mobile Wallet** | Active QR tickets at your fingertips, instant access |
| **Digital ID Cards** | Beautiful, shareable identity within each organization |
| **Evolving Souvenirs** | Tickets "transform" based on attendance (gold status for 100% attendance) |
| **Trophy Room** | Public profile showcasing your verified attendance history & collectibles |
| **Ticket Transfers** | Securely pass tickets to friends within the same organization (anti-scalping) |
| **Post-Event Certificates** | Auto-generated, downloadable PDFs upon event evaluation completion |

### For Organizers
| Feature | Benefit |
| :--- | :--- |
| **Event Wizard** | Multi-step creation: timing, ticketing tiers, add-ons, evaluations |
| **Tiered Ticketing** | Multiple ticket types (General, VIP, Early Bird) with capacity limits |
| **Add-Ons & Merchandise** | Sell merchandise, meals, or services during RSVP with inventory tracking |
| **Live Scanner UI** | Check in attendees in real-time with color-coded feedback (Green/Red/Gold) |
| **Command Center** | Live dashboards: attendance charts, revenue breakdown, raffle triggers |
| **Member Management** | Approvals queue, role assignments, banning/moderation tools |
| **Financial Insights** | Revenue dashboard tracking tickets, add-ons, membership dues |
| **Post-Event Workflows** | Custom evaluation forms, certificate design, PDF generation |

---

## 🏗️ Architecture

**Decoupled 3-Tier Client-Server Design**

```
┌──────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER (Vercel)                   │
├──────────────────────────────────────────────────────────────────┤
│  Next.js Frontend Monorepo                                       │
│  ├─ Organization Portal (Web-Optimized)    [Frontend Dev 1]      │
│  ├─ Member Portal (Mobile-First)           [Frontend Dev 2]      │
│  └─ Backend-for-Frontend (BFF) Proxy       [Secure Auth]         │
└──────────────────────────────┬───────────────────────────────────┘
                               │
         ┌─────────────────────┴─────────────────────┐
         │  Next.js API Routes                       │
         │  (HTTP-only cookies, rate limiting)       │
         │
┌────────▼─────────────────────────────────────────┐
│       APPLICATION LAYER (Render/Railway)         │
├──────────────────────────────────────────────────┤
│  RESTful API (Express/NestJS)                    │
│  ├─ Authentication & RBAC (JWT + Middleware)     │
│  ├─ Cryptographic QR Engine (Secure Hashing)     │
│  ├─ Financial Logic (Cart, Refunds, Payouts)     │
│  ├─ Real-Time Attendance Verification            │
│  └─ Evaluation & Certificate Generation          │
└────────┬─────────────────────────────────────────┘
         │
┌────────▼─────────────────────────────────────────┐
│       DATA LAYER (Supabase - PostgreSQL)         │
├──────────────────────────────────────────────────┤
│  Relational Database                             │
│  ├─ Users & Organizations (RBAC)                 │
│  ├─ Events & Tiered Ticketing                    │
│  ├─ Tickets & Attendance Logs                    │
│  ├─ Transactions & Financial Ledger              │
│  └─ Post-Event Evaluations & Certificates        │
└──────────────────────────────────────────────────┘
```

**Why This Architecture?**
- 🔒 **Security:** BFF hides core API and auth tokens from browser
- 📊 **Scalability:** Decoupled tiers scale independently
- 🎯 **Flexibility:** Teams can work without merge conflicts
- 🚀 **Deployment:** Each layer deploying to modern free/affordable PaaS

---

## 💻 Tech Stack

| Layer | Technology | Host |
| :--- | :--- | :--- |
| **Frontend** | Next.js (React) + TypeScript + Tailwind CSS | Vercel (Free Tier) |
| **BFF** | Next.js API Routes + JWT + Rate Limiting | Vercel |
| **Backend API** | Node.js/Express (or NestJS) + RESTful | Render/Railway (Free Tier) |
| **Database** | PostgreSQL + ACID Transactions + Webhooks | Supabase (Free Tier) |
| **Payments** | GCash (Philippine Mobile Wallet) + QR | Globe Labs API |
| **Authentication** | JWT Tokens + OAuth (optional) | Backend-managed |
| **Real-Time** | Polling + Webhooks | Native |

---

## 📦 Repository Structure

```
eventix-monorepo/
├── docs/                          # Project Documentation (Source of Truth)
│   ├── architecture.md            # 3-tier design & deployment strategy
│   ├── modules.md                 # Feature breakdown by team
│   ├── interfaces.md              # UI/UX inventory (30+ screens)
│   ├── schema.md                  # Database design (13 tables)
│   ├── roles_and_designations.md  # Team structure & permissions
│   ├── phases.md                  # 16-week development timeline
│   ├── structure.md               # Git strategy & repo layout
│   ├── api-contracts.md           # REST API endpoint documentation
│   ├── payments-integration.md    # GCash integration guide
│   ├── deployment-guide.md        # Setup for Vercel, Render, Supabase
│   ├── security-specification.md  # JWT, RBAC, encryption, compliance
│   └── testing-strategy.md        # Unit, integration, E2E tests
│
├── frontend/                      # Next.js Monorepo
│   ├── src/app/(auth)/            # Shared Login & Registration
│   ├── src/app/(organization)/    # Organization Portal [FD1]
│   │   ├── dashboard/
│   │   ├── events/
│   │   ├── scanner/
│   │   └── members/
│   ├── src/app/(member)/          # Member Portal [FD2]
│   │   ├── feed/
│   │   ├── explore/
│   │   ├── wallet/
│   │   └── u/[username]/          # Public Trophy Room
│   ├── src/app/api/               # Next.js BFF Routes
│   ├── src/components/            # Shared & Portal-Specific Components
│   └── tailwind.config.ts         # Global Design System
│
├── backend/                       # Express/NestJS REST API
│   ├── src/controllers/           # Business logic (Auth, Events, Tickets)
│   ├── src/middlewares/           # JWT validation, RBAC, rate limiting
│   ├── src/models/                # PostgreSQL ORM models
│   ├── src/routes/                # API endpoint definitions
│   ├── src/services/              # Crypto, payments, notifications
│   ├── src/utils/                 # Helpers (hashing, PDF generation)
│   ├── tests/                     # Unit & integration tests
│   └── package.json               # Dependencies
│
└── .github/
    └── workflows/
        └── deploy.yml             # CI/CD pipeline (GitHub Actions)
```

---

## 👥 Team & Roles

| Role | Assigned To | Primary Responsibility |
| :--- | :--- | :--- |
| **System Architect** | Zie | Documentation, schema design, quality audits, deployment |
| **UI/UX Designer** | Jomari | Figma prototypes, design system, visual assets |
| **Frontend Dev 1** | [Name] | Organization Portal (Web-optimized dashboards, scanner UI) |
| **Frontend Dev 2** | [Name] | Member Portal (Mobile-first, wallet, social features) |
| **Backend Dev** | [Name] | REST API, database, cryptography, payment integration |

---

## 🚀 Quick Start

### Prerequisites
- Node.js v18+, npm v9+
- Git & GitHub account
- PostgreSQL understanding
- GCash merchant account (for production)

### Local Development Setup

```bash
# 1. Clone repository
git clone https://github.com/your-org/eventix-monorepo.git
cd eventix-monorepo

# 2. Setup Backend
cd backend
npm install
cp .env.example .env.local
# Fill in DATABASE_URL, JWT_SECRET, GCASH_API_KEY, etc.
npm run migrate:latest        # Create tables
npm run dev                   # Start API on http://localhost:5000

# 3. Setup Frontend (new terminal)
cd frontend
npm install
cp .env.example .env.local
# Fill in NEXT_PUBLIC_API_BASE_URL=http://localhost:5000
npm run dev                   # Start frontend on http://localhost:3000

# 4. Access the app
# Member Portal: http://localhost:3000/feed
# Org Portal:    http://localhost:3000/dashboard
```

### Running Tests

```bash
# Backend tests (unit + integration)
cd backend
npm test                      # Run all tests
npm test -- --watch          # Watch mode
npm run test:coverage        # Coverage report

# Frontend tests
cd frontend
npm test                      # Component tests
npm run e2e                   # End-to-end tests (Playwright)
```

---

## 📋 Development Phases

**16-week timeline** with staggered design-to-code pipeline:

| Phase | Duration | Focus | Deliverable |
| :--- | :--- | :--- | :--- |
| **Phase 0** | Week 0 | Planning & Setup | Monorepo, DB schema, team kickoff |
| **Phase 1** | Weeks 1-2 | Foundation | Auth, design system, database initialization |
| **Phase 2** | Weeks 3-4 | Core Infrastructure | Auth implementation, org profiles, event discovery UI |
| **Phase 3** | Weeks 5-7 | Event Engine | Event creation wizard, checkout flow, ticket generation |
| **Phase 4** | Weeks 8-10 | Ticketing & RBAC | Cryptographic hashing, transfers, gamification |
| **Phase 5** | Weeks 11-12 | Execution Tools | Live scanner, dashboards, real-time check-ins |
| **Phase 6** | Weeks 13-14 | Collectibles | Evolving souvenirs, certificates, trophy room |
| **Phase 7** | Weeks 15-16 | QA & Launch | Testing, deployment, production launch |

→ See [phases.md](phases.md) for detailed task breakdown and Definition of Done

---

## 🔐 Security & Compliance

✅ **Authentication:** JWT-based with refresh token rotation  
✅ **Authorization:** Role-Based Access Control (Owner, Co-Organizer, Staff, Member)  
✅ **Encryption:** AES-256 for sensitive data at rest, TLS 1.3 in transit  
✅ **Payments:** GCash handles all OTP/auth; EvenTix stores QR references only  
✅ **Webhooks:** HMAC-SHA256 signature verification  
✅ **Rate Limiting:** 100 req/min (general), 5 attempts/15min (auth), 1000/min (scanner)  
✅ **Audit Logging:** All admin actions tracked with timestamps  

→ See [security-specification.md](security-specification.md) for details

---

## 📊 API Documentation

The EvenTix REST API is fully documented with 50+ endpoint examples:

- **Authentication:** Login, registration, refresh tokens
- **Organizations:** Create, list, update, members management
- **Events:** Full CRUD, publish, get attendance stats
- **Ticketing:** RSVP, ticket transfers, capacity enforcement
- **Scanner:** Real-time verification, add-on fulfillment
- **Financials:** Revenue dashboard, transactions, payouts
- **Evaluations:** Forms, submissions, certificate generation

→ See [api-contracts.md](api-contracts.md) for complete OpenAPI-style documentation

---

## 💳 Payment Integration

**GCash is the primary payment method for the Philippine market:**

- 📱 **QR-Based:** Members scan and complete payment in GCash app
- 🔒 **Secure:** OTP authentication, no card data stored locally
- ⚡ **Instant:** Real-time settlement and P2P payouts
- 💰 **Affordable:** 1-2% fees vs international processors (3.9%+)

→ See [payments-integration.md](payments-integration.md) for full spec

---

## 🌐 Deployment

**Multi-platform deployment strategy (zero infrastructure cost initially):**

| Component | Platform | URL |
| :--- | :--- | :--- |
| **Frontend** | Vercel | https://eventix.app |
| **API** | Render | https://api.eventix.app |
| **Database** | Supabase | PostgreSQL managed instance |

→ See [deployment-guide.md](deployment-guide.md) for step-by-step setup

---

## 📚 Documentation Index

| Document | Purpose |
| :--- | :--- |
| [architecture.md](architecture.md) | System design, 3-tier overview, security model |
| [modules.md](modules.md) | Feature breakdown, responsibilities, team assignments |
| [interfaces.md](interfaces.md) | UI/UX screen inventory for both portals (30+ screens) |
| [schema.md](schema.md) | Database design with all tables, relationships, implementation notes |
| [api-contracts.md](api-contracts.md) | REST API endpoints, request/response, error codes |
| [payments-integration.md](payments-integration.md) | GCash integration, payment flows, webhook handling |
| [deployment-guide.md](deployment-guide.md) | Vercel, Render, Supabase setup with CI/CD |
| [security-specification.md](security-specification.md) | JWT, RBAC, encryption, compliance checklist |
| [testing-strategy.md](testing-strategy.md) | Unit, integration, E2E test plans with examples |
| [roles_and_designations.md](roles_and_designations.md) | Team structure (5 roles), responsibilities |
| [phases.md](phases.md) | 16-week development roadmap with DoD for each phase |
| [structure.md](structure.md) | Git workflow, branch strategy, monorepo layout |

---

## 🎬 Getting Started (For Team)

1. **Read the foundations:** Start with [architecture.md](architecture.md) and [modules.md](modules.md)
2. **Understand your role:** See [roles_and_designations.md](roles_and_designations.md)
3. **Check the roadmap:** Review [phases.md](phases.md) for your phase
4. **Set up locally:** Follow [Quick Start](#-quick-start) above
5. **Review specs:** 
   - Designers → [interfaces.md](interfaces.md)
   - Frontend → [api-contracts.md](api-contracts.md) + [interfaces.md](interfaces.md)
   - Backend → [schema.md](schema.md) + [api-contracts.md](api-contracts.md)
6. **Deploy:** Follow [deployment-guide.md](deployment-guide.md)

---

## 🤝 Contributing

We follow a strict **prefix-based git workflow**:

```bash
# Branch naming by role:
git checkout -b feat/member/[feature-name]        # Frontend Dev 2 (Member Portal)
git checkout -b feat/org/[feature-name]           # Frontend Dev 1 (Org Portal)
git checkout -b feat/api/[feature-name]           # Backend Dev
git checkout -b docs/[feature-name]               # System Architect
git checkout -b fix/[bug-name]                    # Bug fixes (any role)

# Example
git checkout -b feat/member/digital-wallet
git add .
git commit -m "feat(member): implement digital wallet with QR display"
git push origin feat/member/digital-wallet
```

**All PRs must:**
- ✅ Target the `dev` branch
- ✅ Pass CI/CD pipeline (linting, tests, builds)
- ✅ Be approved by the System Architect
- ✅ Include updated tests

---

## 📞 Support & Questions

| Topic | Resource |
| :--- | :--- |
| **Architecture Questions** | See [architecture.md](architecture.md) or contact Zie |
| **Design Questions** | See [interfaces.md](interfaces.md) or Figma prototype (link to be added) |
| **API Issues** | See [api-contracts.md](api-contracts.md) + [security-specification.md](security-specification.md) |
| **Deployment Issues** | See [deployment-guide.md](deployment-guide.md) |
| **Payment Issues** | See [payments-integration.md](payments-integration.md) |

---

## 📅 Project Status

**Current Phase:** Phase 0 (Discovery, Planning & Repo Initialization)

- [x] Architecture documented
- [x] Database schema designed
- [x] UI/UX inventory created
- [x] Team roles assigned
- [x] API contracts specified
- [x] Payment integration designed
- [x] Deployment strategy defined
- [x] Security specifications finalized
- [x] Testing strategy outlined
- [ ] Repository initialized
- [ ] Team kickoff complete
- [ ] Phase 1 (Foundation) begins

---

## 📈 Roadmap

**What's Coming:**

- **Q2 2026:** Phases 0-3 (Foundation, Core Infrastructure, Event Engine)
- **Q3 2026:** Phases 4-5 (Ticketing, Execution Tools)
- **Q3-Q4 2026:** Phases 6-7 (Collectibles, QA, Launch)

**Future Enhancements (Post-Launch):**
- Two-factor authentication for organizers
- Advanced analytics & cohort analysis
- API for third-party integrations
- Mobile app (iOS/Android) for scanner
- Additional regional payment gateway integrations for international expansion
- Blockchain-based certificate verification

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🙏 Acknowledgments

Built by the **Sinkronizze Team** and designed for the Philippine event community.

---

**Ready to revolutionize event management? Let's build EvenTix! 🚀**

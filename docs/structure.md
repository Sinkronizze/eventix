# EvenTix - Repository Structure & Git Strategy

## 1. Git Branching Strategy
To maintain a clean codebase and prevent merge conflicts between the two frontends and the backend API, the Sinkronizze team will use a strict prefix-based branching model. 

### Core Branches (Protected)
*   `main`: The production-ready code. Only the Architect (Zie) merges into this.
*   `staging`: The testing environment. Used for Phase 7 end-to-end testing.
*   `dev`: The active development branch where all features are integrated.

### Role-Based Feature Branches
Developers must branch off `dev` and use the following prefixes based on their role:

*   **System Architect (Zie):** 
    *   `docs/[feature-name]` (e.g., `docs/system-design`, `docs/api-contracts`)
*   **Frontend Dev 1 (Org Portal):** 
    *   `feat/org/[feature-name]` (e.g., `feat/org/event-builder`, `feat/org/scanner-ui`)
*   **Frontend Dev 2 (Member Portal):** 
    *   `feat/member/[feature-name]` (e.g., `feat/member/digital-wallet`, `feat/member/checkout-flow`)
*   **Backend Dev:** 
    *   `feat/api/[feature-name]` (e.g., `feat/api/auth-middleware`, `feat/api/crypto-hash`)
    *   `db/[migration-name]` (e.g., `db/init-schema`)
*   **Universal (Bug Fixes):**
    *   `fix/[bug-name]` (e.g., `fix/org/scanner-latency`)

**Pull Request (PR) Policy:** All PRs targeting the `dev` branch must be reviewed and approved by the System Architect to ensure they align with the API contracts and `schema.md`.

---

## 2. Global Monorepo Directory Structure
EvenTix operates as a decoupled 3-tier platform. The repository is divided into high-level directories to strictly separate the Next.js frontend, the REST API backend, and the project documentation.

```text
eventix-monorepo/
│
├── docs/                        # Owned by: Zie (System Architect)
│   ├── architecture.md
│   ├── modules.md
│   ├── schema.md
│   ├── interfaces.md
│   ├── roles_and_designations.md
│   ├── phases.md
│   └── structure.md
│
├── backend/                     # Owned by: Backend Dev
│   ├── src/
│   │   ├── config/              # DB connection, environment variables
│   │   ├── controllers/         # Business logic (e.g., EventController, TicketController)
│   │   ├── middlewares/         # JWT Auth, RBAC validation
│   │   ├── models/              # DB schema mappings/ORM models
│   │   ├── routes/              # Express/NestJS route definitions
│   │   └── utils/               # Cryptography hashers, PDF generators
│   ├── tests/
│   ├── package.json
│   └── .env.example
│
└── frontend/                    # Owned by: Frontend 1 & Frontend 2
    ├── public/                  # Static assets (fonts, default logos)
    ├── src/
    │   ├── app/
    │   │   ├── (auth)/          # Shared Login/Register routes
    │   │   │
    │   │   ├── (organization)/  # Owned by: Frontend Dev 1
    │   │   │   ├── dashboard/
    │   │   │   ├── events/
    │   │   │   ├── scanner/
    │   │   │   └── members/
    │   │   │
    │   │   ├── (member)/        # Owned by: Frontend Dev 2
    │   │   │   ├── feed/
    │   │   │   ├── explore/
    │   │   │   ├── wallet/
    │   │   │   └── u/[username]/ # The public Trophy Room
    │   │   │
    │   │   └── api/             # Next.js BFF (Backend-for-Frontend) Proxy
    │   │
    │   ├── components/
    │   │   ├── shared/          # UI/UX Base (Buttons, Inputs) - Built from Figma
    │   │   ├── organization/    # Complex tables, Event Builder forms
    │   │   └── member/          # Digital Ticket cards, Swipeable carousels
    │   │
    │   ├── lib/                 # Utility functions, API fetchers
    │   ├── styles/              # Global Tailwind CSS variables
    │   └── types/               # TypeScript interfaces (mapping to schema.md)
    │
    ├── tailwind.config.ts
    └── package.json
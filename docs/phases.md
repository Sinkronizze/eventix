# EvenTix - Project Development Phases & Timeline

## Overview
This document outlines the sequential development phases for the EvenTix platform. We utilize a staggered design approach: the UI/UX Designer operates one phase ahead of the Frontend Developers. 

As the System Architect, Zie will conduct a formal audit at the conclusion of every phase. No phase is complete until the **Definition of Done (DoD)** for all tasks is met and signed off by the Lead.

---

### Phase 0: Discovery, Planning & Repo Initialization (Current Phase)
**Goal:** Establish the technical "Source of Truth" and project infrastructure to prevent architectural drift.

| Task ID | Task Description | Assigned To | Definition of Done (DoD) |
| :--- | :--- | :--- | :--- |
| **0.1** | **System Design Documentation** | Zie (Architect) | `architecture.md`, `modules.md`, `schema.md`, and `interfaces.md` finalized and approved. |
| **0.2** | **Project & Team Governance** | Zie (Architect) | `roles_and_designations.md` and `phases.md` shared with Sinkronizze team. |
| **0.3** | **Monorepo & Git Strategy** | Zie (Architect) | Central GitHub repository created. `structure.md` implemented. Protected branches (`main`, `dev`) established. |
| **0.4** | **Initial Team Kickoff** | Entire Team | All 5 members briefed on their specific folders, branching prefixes, and the staggered design-to-code pipeline. |
| **0.5** | **Documentation Sign-Off** | Zie (Architect) | All planning docs merged into `docs/system-design`. Team has "Read Access" to the master blueprint. |

---

### Phase 1: Foundation & Base Design System (Weeks 1-2)
**Goal:** Establish the database, code repositories, and the global design language without overwhelming the design team.

| Task ID | Task Description | Assigned To | Definition of Done (DoD) |
| :--- | :--- | :--- | :--- |
| **1.1** | **Database Initialization** | Backend Dev | PostgreSQL deployed on Supabase. `schema.md` tables fully migrated. |
| **1.2** | **Global Design System & Auth UI**| UI/UX Designer | Typography, color palettes, core components, and Auth screens completed in Figma. |
| **1.3** | **Frontend Repo Scaffolding** | FD1 & FD2 | Next.js monorepo initialized. Global CSS/Tailwind configured to match the designer's variables. |
| **1.4** | **Architecture & Schema Sign-Off** | Zie (Architect) | Repositories are clean, DB schema strictly matches `schema.md`, and Figma links are centralized. |

---

### Phase 2: Core Infrastructure & Discovery Design (Weeks 3-4)
**Goal:** Secure the login flows in code, while the designer maps out the event discovery and creation screens.

| Task ID | Task Description | Assigned To | Definition of Done (DoD) |
| :--- | :--- | :--- | :--- |
| **2.1** | **Backend API & Auth Logic** | Backend Dev | Express/NestJS server running. JWT auth endpoints working. RBAC middleware scaffolded. |
| **2.2** | **Auth & Routing Implementation**| FD1 & FD2 | Login/Registration functional on both portals. Secure routing established preventing unauthorized access. |
| **2.3** | **Member Feed & Event Builder UI**| UI/UX Designer | High-fidelity screens for the Member Event Feed, Explore Tab, and the Org Event Creation Wizard completed. |
| **2.4** | **Org Profile Creation** | FD1 | Admins can successfully create an Org profile, upload logos, and save to the database. |
| **2.5** | **API Contract & Security Audit** | Zie (Architect) | Postman/Insomnia testing confirms backend rejects invalid JWTs. Frontend state management for Auth is verified secure. |

---

### Phase 3: The Event Engine & Transactional Design (Weeks 5-7)
**Goal:** Code the event creation and discovery features, while the designer tackles the complex checkout and digital wallet screens.

| Task ID | Task Description | Assigned To | Definition of Done (DoD) |
| :--- | :--- | :--- | :--- |
| **3.1** | **Event Builder (CRUD) Code** | FD1 | Multi-step wizard complete. Admins can fully create and publish events to the database. |
| **3.2** | **Org & Event Endpoints** | Backend Dev | REST APIs for querying events, organizations, and handling the creation payload are live. |
| **3.3** | **Explore Tab & Feed Code** | FD2 | Members can browse public orgs, request to join, and see a dynamic feed of events. |
| **3.4** | **Checkout, Wallet & Scanner UI**| UI/UX Designer | High-fidelity screens for the RSVP flow, Digital Wallet (Hero Ticket), and web-based Scanner UI completed. |
| **3.5** | **BFF (Backend-for-Frontend) Audit**| Zie (Architect) | Verify that Next.js API routes (BFF) are correctly hiding backend REST API keys and cleanly formatting JSON payloads. |

---

### Phase 4: Ticketing, RSVP & Gamification Design (Weeks 8-10)
**Goal:** Implement the transactional core and cryptography, while the designer finalizes the post-event and dashboard layouts.

| Task ID | Task Description | Assigned To | Definition of Done (DoD) |
| :--- | :--- | :--- | :--- |
| **4.1** | **Checkout & Crypto API** | Backend Dev | Payment logic and secure hashing algorithm generates unforgeable QR strings upon RSVP. |
| **4.2** | **RSVP & Digital Wallet Code** | FD2 | Mobile UI for selecting tiers, confirming payment, and rendering the active QR ticket is functional. |
| **4.3** | **Dashboards & Souvenir UI** | UI/UX Designer | High-fidelity screens for Org Financial Dashboards, Evolving Souvenir Grids, and PDF Certificates completed. |
| **4.4** | **Ticket Transfers** | Backend Dev & FD2 | Users can transfer tickets. Backend successfully voids old hash and mints new one. |
| **4.5** | **Cryptography & Logic Review** | Zie (Architect) | Code review of the QR hashing algorithm. Verify `capacity` and `stock` variables cannot be bypassed during checkout. |

---

### Phase 5: Event Execution & Dashboards (Weeks 11-12)
**Goal:** Code the day-of-event tools and data visualization. The designer shifts to QA and polishing.

| Task ID | Task Description | Assigned To | Definition of Done (DoD) |
| :--- | :--- | :--- | :--- |
| **5.1** | **QR Scanner API** | Backend Dev | Verification endpoint decrypts hash, checks multi-day validity, and logs attendance. |
| **5.2** | **Live Scanner UI Code** | FD1 | Camera interface works natively (flashing Green/Red/Gold) and displays the Add-on fulfillment checklist. |
| **5.3** | **Command Center & Dashboards** | FD1 | Live check-in charts, raffle trigger, and financial data populated via backend JSON. |
| **5.4** | **UI/UX Polish & Component Audit**| UI/UX Designer | Correct any padding, color, or responsive layout drift with FD1 & FD2. |
| **5.5** | **Hardware & Latency Testing** | Zie (Architect) | Test the Scanner UI on actual mobile/tablet cameras. Ensure scan-to-database validation occurs in under 1.5 seconds. |

---

### Phase 6: Post-Event & Collectibles (Weeks 13-14)
**Goal:** Implement the EvenTix digital collectibles and post-event workflows.

| Task ID | Task Description | Assigned To | Definition of Done (DoD) |
| :--- | :--- | :--- | :--- |
| **6.1** | **Evolving Souvenirs Code** | Backend Dev & FD2 | Backend updates ticket status. Frontend Vault renders aesthetic grid without functional QR codes. |
| **6.2** | **Evaluation & Cert Workflow** | Backend Dev & FD2 | Endpoints process feedback forms and dynamically generate PDF certificates for the user to download. |
| **6.3** | **The Trophy Room** | FD2 | Public URL route displays read-only ID cards, verified souvenirs, and stats safely. |
| **6.4** | **Moderation Controls** | FD1 | Org Admins can successfully Ban/Block a user, instantly revoking access. |
| **6.5** | **Asset Generation Audit** | Zie (Architect) | Verify PDF generation does not block the main thread. Ensure Trophy Room endpoints do not leak PII (Personally Identifiable Information). |

---

### Phase 7: QA, Testing & Launch (Weeks 15-16)
**Goal:** Break the system, fix the bugs, and deploy to production.

| Task ID | Task Description | Assigned To | Definition of Done (DoD) |
| :--- | :--- | :--- | :--- |
| **7.1** | **Concurrency Testing** | Backend Dev | Stress test the RSVP endpoint to ensure no overbooking occurs during simultaneous purchases. |
| **7.2** | **End-to-End (E2E) Test** | Entire Team | Run a mock event from Creation -> RSVP -> Scanning -> Certificate generation without crashes. |
| **7.3** | **Production Deployment** | Zie (Architect) | Frontend domains linked (Vercel), API scaled (Render/Railway), DB backups configured (Supabase). |
| **7.4** | **Final Project Sign-Off** | Zie (Architect) | System meets all core requirements, performance metrics, and security standards. Platform is launched. |
# EvenTix - Team Roles & Designations

**Team:** Sinkronizze
**Project:** EvenTix (Decoupled 3-Tier Platform)

## 1. System Architect & Project Tracker
**Assigned To:** Zie
**Core Focus:** System blueprints, database schema, workflow tracking, and documentation alignment.

*   **Responsibilities:**
    *   **Architecture Ownership:** Author and maintain all core documentation (`architecture.md`, `modules.md`, `schema.md`, `interfaces.md`).
    *   **Development Tracking:** Act as the central node bridging design, frontend, and backend. Ensure that no developer deviates from the established database schema or API contracts.
    *   **Quality & Alignment:** Verify that the UI designs fulfill the exact requirements listed in the interface inventory, and that the final code matches the system design.
    *   **Deployment Strategy:** Oversee the integration of the Next.js frontend, the Render/Railway backend, and the Supabase PostgreSQL database.

## 2. UI/UX Designer
**Assigned To:** Jomari
**Core Focus:** Prototyping, visual hierarchy, user flows, and design system creation.

*   **Responsibilities:**
    *   **High-Fidelity Prototyping:** Translate the `interfaces.md` inventory into clickable prototypes (e.g., in Figma) before any frontend code is written.
    *   **Dual-Platform Design:** Design a strict mobile-first experience for the Member Portal and a data-dense, web-optimized dashboard for the Organization Portal.
    *   **Visual Assets:** Design the collectible "Digital Souvenir" ticket templates, the ID Card components, and the system's global UI components (buttons, typography, color palettes).
    *   **Handoff:** Provide exact CSS values, hex codes, and asset exports to the Frontend Developers.

## 3. Frontend Developer 1 (Organization Portal)
**Assigned To:** Charles
**Core Focus:** Web-optimized dashboards, data tables, and complex form interactions.
**Environment:** Next.js `app/(organization)`

*   **Responsibilities:**
    *   **Dashboard Execution:** Build the desktop-first interface for Organization Admins, strictly following the UI/UX designs.
    *   **Complex Forms:** Implement the multi-step Event Builder wizard and the dynamic Evaluation Form builder.
    *   **Scanner UI:** Develop the webcam-based QR scanner interface, ensuring it clearly displays add-on checklists and visual validation cues (Green/Red/Gold).
    *   **API Integration:** Connect the frontend to the secure Next.js BFF routes to fetch analytics, manage members, and process CRUD operations.

## 4. Frontend Developer 2 (Member Portal)
**Assigned To:** Paul
**Core Focus:** Mobile-first interactions, digital wallets, and frictionless checkout flows.
**Environment:** Next.js `app/(member)`

*   **Responsibilities:**
    *   **Mobile Execution:** Build the responsive, touch-optimized Member Portal, focusing heavily on the bottom navigation stack.
    *   **The Digital Wallet:** Render the active QR tickets and the aesthetic grid view for the "Evolved" souvenir history.
    *   **RSVP & Checkout:** Build a seamless, multi-step flow for selecting ticket tiers, adding merchandise, and processing payments.
    *   **Public Profile:** Construct the read-only "Trophy Room" view for members to share their verifiable attendance records.

## 5. Backend Developer
**Assigned To:** Jericho
**Core Focus:** Core REST API, PostgreSQL database, security logic, and cryptography.
**Environment:** Render/Railway (API Engine) + Supabase (Database)

*   **Responsibilities:**
    *   **Database Engineering:** Implement the strict relational PostgreSQL schema (`schema.md`), ensuring proper foreign keys and ACID compliance.
    *   **Security & RBAC:** Build the middleware to handle JWT authentication and enforce Role-Based Access Control (e.g., verifying if a user is Banned before allowing an RSVP).
    *   **Cryptographic Ticketing:** Program the hashing engine that generates secure QR strings and the verification endpoint used by the Organization Scanner.
    *   **Complex Logic:** Write the endpoints to calculate dashboard analytics, process membership fee gates, handle ticket transfers (re-hashing), and dynamically generate post-event PDF certificates.

---

## Sinkronizze Pipeline Summary

| Role | Name | Primary Output | System Interaction |
| :--- | :--- | :--- | :--- |
| **System Architect** | Zie | Documentation, Schemas, Timelines | Guides the entire team; validates all outputs against the plan. |
| **UI/UX Designer** | Jomari | Figma Prototypes, Design System | Feeds visual blueprints directly to both Frontend Developers. |
| **Frontend Dev 1** | Charles | Org Portal (Desktop/Web) | Consumes Backend APIs; reports to Architect on feature completion. |
| **Frontend Dev 2** | Paul | Member Portal (Mobile) | Consumes Backend APIs; reports to Architect on feature completion. |
| **Backend Dev** | Jericho | REST API, Database, Auth Logic | Provides the data foundation for both Frontends; follows Architect's schema. |
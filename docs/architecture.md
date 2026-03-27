# EvenTix - System Architecture Document

## 1. System Overview
EvenTix is a centralized platform designed for organizations to manage their members, publish events, and handle secure, real-time event attendance. 

## 2. High-Level Architecture
EvenTix utilizes a **Decoupled 3-Tier Client-Server Architecture** featuring a Backend-For-Frontend (BFF) pattern for enhanced security.

### A. Presentation Layer (Frontend - Next.js & React)
The user-facing interface. Next.js provides the structural framework, while the actual UI components are built using React. Its sole responsibility is displaying data and capturing inputs securely.
*   **Client (Browser):** The React UI running on the user's device (a mobile-first view for Members, and a rich, data-heavy dashboard for Organizers).
*   **Backend-For-Frontend (Next.js Server):** A secure proxy using Next.js API Routes. It safely attaches HTTP-only authentication tokens and forwards requests to the core backend, ensuring the main API and cryptographic logic remain hidden from the public internet.

### B. Application Layer (Backend Core API)
The brain of the platform. A standalone RESTful API decoupled from the UI that handles all business logic, security rules, and data processing.
*   **Responsibilities:** Enforces strict role-based authorization (e.g., denying Member access to Organization endpoints), aggregates complex analytics for the dashboards, and runs the cryptographic engine that generates and verifies unforgeable QR ticket hashes.

### C. Data Layer (Relational Database)
The memory of the platform. A strict, relational database using **PostgreSQL** to ensure structural integrity and persistent storage.
*   **Responsibilities:** Maintains rigid data relationships (e.g., a ticket cannot exist without a valid event and user) and utilizes ACID compliance to handle real-time concurrency—ensuring that if two members RSVP at the exact same millisecond for the last ticket, only one succeeds.

## 3. Deployment Strategy (Modern Free Tier)
To ensure the project is publicly accessible for portfolio showcases without incurring infrastructure costs, EvenTix utilizes a modern, zero-cost cloud deployment stack.

*   **Frontend Hosting (Vercel):** The Next.js monorepo is linked directly to Vercel. This provides automatic deployments on every `git push`, global edge caching, and native support for Next.js API Routes (BFF) on their Hobby tier.
*   **Backend Hosting (Render):** The RESTful API is deployed on a modern PaaS (Platform as a Service) Render. This abstracts server management while providing a free environment for the application layer to process business logic.
*   **Database Hosting (Supabase):** The PostgreSQL database is hosted on Supabase. This provides a generous free tier with a powerful, managed relational database that easily connects to the backend API.

## Architecture & Deployment Summary

| Layer | Technology | Primary Function | Security, Integrity & Hosting |
| :--- | :--- | :--- | :--- |
| **Presentation** | Next.js & React | Displays UI and captures user input (Mobile & Web). | **BFF Proxy (Vercel):** Hides the core API from the browser; securely handles HTTP-only auth tokens. |
| **Application** | RESTful API | Processes business logic, auth, and data aggregation. | **Auth & Crypto (Render/Railway):** Enforces strict role access; generates unforgeable QR hashes. |
| **Data** | PostgreSQL | Provides persistent storage and manages data relationships. | **ACID Compliance (Supabase):** Ensures referential integrity and safe concurrent transactions. |
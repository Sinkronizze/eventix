# EvenTix - Core Modules & Feature Breakdown

**Project Lead / Systems Architect:** Zie
**Team:** Anti-Tisis

## 1. Organization Portal (Assigned to: Frontend Dev 1)
**Environment:** Next.js `app/(organization)` route group. Web-optimized (Desktop/Tablet).
**Primary Focus:** Data visualization, member lifecycle management, event execution, and post-event feedback.

*   **Authentication & Onboarding:**
    *   Secure login/registration for Organization Admins.
    *   Organization profile setup (Logo, description, branding colors, and public discoverability toggle).
*   **Monetization & Financial Dashboard:**
    *   **Membership Fees:** Set required membership dues (monthly/annually/one-time) and track payment statuses.
    *   **Revenue Tracking:** Real-time metrics on revenue generated from paid event ticket sales and add-ons.
*   **Analytics Dashboard:**
    *   Real-time overview of active events and live attendance counts.
    *   Historical data: Member retention rates, most popular events, and overall attendance trends.
*   **Event Engine & Post-Event Workflows (CRUD):**
    *   **Event Scheduling (Single/Multi-Day):** Define event duration, whether it is a single evening or a multi-day conference/series.
    *   **Tiered Ticketing & Event Add-Ons:** Create multiple ticket tiers (e.g., General Admission, VIP) and optional add-ons (e.g., Event T-Shirt, Meals) that members can purchase during RSVP.
    *   **Souvenir Ticket Design:** Upload a custom, visually appealing "Ticket Artwork" or banner.
    *   **Evaluation Builder:** Create custom post-event feedback forms (e.g., star ratings, text responses).
    *   **Certificate Template:** Upload a base certificate design where the system will dynamically overlay the member's name upon evaluation completion.
*   **Deep Member Management & Moderation:**
    *   **Collaborative Roles (Multi-Admin):** Assign granular permissions to a team of organizers (e.g., Owner, Co-Organizer, Event Staff) to allow multiple people to safely manage the same organization.
    *   **Approvals:** Accept or reject user requests to join the organization.
    *   **Moderation (Block/Ban):** Ability to permanently ban problematic members, immediately revoking their access to the organization's feed, tickets, and future events.
    *   **Lifecycle Tracking:** View individual member profiles to see their entire attendance history and standing.
*   **Event Execution & Scanner:**
    *   **Multi-Day QR Scanner UI:** Web-based interface utilizing the device's camera. The scanner verifies the ticket against the *current day's* attendance roster.
    *   **Tier & Add-On Display:** The scanner UI distinctly flashes to indicate a member's ticket tier (e.g., Gold for VIP) and clearly lists any purchased add-ons so staff can distribute merchandise at the door.
    *   **Raffle/Gamification Trigger:** A specific control panel to randomly select a winner *only* from checked-in members.

---

## 2. Member Portal (Assigned to: Frontend Dev 2)
**Environment:** Next.js `app/(member)` route group. Strictly Mobile-First.
**Primary Focus:** Organization discovery, digital identity, collectible ticketing, and post-event actions.

*   **Organization Discovery & Onboarding:**
    *   **Explore Tab:** Browse and search for public organizations to join.
    *   **Join & Pay Flow:** Submit membership requests and handle membership fee payments.
*   **Digital Organization Identity (ID Card):**
    *   A visually distinct, digital "ID Card" component for each organization the user belongs to (displays name, tier/role, join date, branding).
    *   *Note: Banned members will have their ID card visually revoked or removed.*
*   **Dynamic Event Feed & RSVP:**
    *   List of upcoming events exclusively from the user's approved organizations.
    *   **Event Cards:** Clearly display date ranges (for multi-day events) and pricing (Free vs. Cost).
    *   **Checkout/RSVP Flow:** Seamless selection of Ticket Tiers and optional Add-Ons, processing payment before generating the secure QR ticket.
*   **The "EvenTix" Digital Souvenir Wallet & Vault:**
    *   **Active Tickets:** Quick access to the QR codes needed for upcoming events (clearly indicating ticket tier, add-ons, and valid days).
    *   **Secure Ticket Transfers (Anti-Scalping):** Ability to digitally transfer a ticket to another verified member within the same organization, instantly voiding the sender's QR code and generating a new one for the recipient.
    *   **Dynamic Souvenir History (The Collection):** A highly visual "scrapbook" of past events. Tickets "evolve" based on attendance (e.g., a ticket for a 3-day event turns gold if the member attends all 3 days).
    *   **The "Trophy Room" (Public Profile):** An opt-in, read-only public web page (`eventix.com/u/username`) where members can showcase their ID Cards, verified digital souvenirs, and certificates as a verifiable resume of community involvement.
    *   **Post-Event Evaluation & Certificates:** A notification prompts the user to fill out the event's evaluation form to unlock and download their personalized PDF Certificate.

---

## 3. Backend API & BFF Integration (Assigned to: Backend Dev & Architect)
**Environment:** Next.js API Routes (BFF) forwarding to Render/Railway REST API.
**Primary Focus:** Security, complex financial logic, dynamic states, dynamic file generation, and RBAC.

*   **Security, Middleware & RBAC (Role-Based Access Control):**
    *   JWT token validation to ensure standard Members cannot access Organization endpoints.
    *   Intra-organization hierarchy checks (e.g., verifying a user isn't banned before allowing an RSVP or ticket transfer).
    *   Concurrency locking to prevent overbooking if multiple members RSVP simultaneously or purchase limited add-ons.
*   **Advanced Financial Processing Logic:**
    *   Endpoints to handle membership statuses, fee gates, and secure payment processing for tiered tickets and add-on cart totals.
*   **Cryptographic Ticketing & Transfer Engine:**
    *   Logic to generate unforgeable hashes for QR codes based on `user_id` + `event_id` + `tier_data` + `server_secret_salt`.
    *   **Transfer Logic:** Validates internal ticket transfers, invalidating the original hash and minting a new cryptographically secure hash for the recipient.
    *   **Multi-Day & Dynamic State Verification:** Tracks daily attendance to determine if a multi-day ticket should "evolve" into a higher-tier visual state in the user's souvenir wallet.
*   **Evaluation & Certificate Gatekeeper:**
    *   Logic to securely process form submissions, tie the feedback to the specific event/organization, and dynamically generate a PDF certificate *only* after verifying attendance and form completion.
*   **Public Profile Aggregation:**
    *   Read-only endpoints to safely fetch and display a user's "Trophy Room" data without exposing PII (Personally Identifiable Information).

---

## Module Summary

| Module | Assigned To | Environment | Key Features |
| :--- | :--- | :--- | :--- |
| **Organization Portal** | Frontend Dev 1 | Web (Desktop/Tablet) | Tiered Tickets & Add-Ons, Multi-Admin Roles, Moderation, Scanner (Add-on UI) |
| **Member Portal** | Frontend Dev 2 | Mobile-First | Public "Trophy Room", Ticket Transfers, Evolving Souvenirs, Tiered Checkout |
| **Backend API & BFF** | Backend Dev & Architect | Next.js API & REST API | Strict RBAC Validation, Cart/Financial Logic, Ticket Re-hashing (Transfers) |
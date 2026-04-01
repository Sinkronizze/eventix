# EvenTix - UI/UX Screen Inventory (Interfaces)

**Project Lead / Systems Architect:** Zie
**Team:** Anti-Tisis

## Overview for Design Team
This document outlines every distinct interface required for the EvenTix platform. 
*   **Frontend Dev 1** will build the **Organization Portal**, which must be designed "Web-First" (optimized for desktop, data tables, sidebars, and dense dashboards).
*   **Frontend Dev 2** will build the **Member Portal**, which must be designed strictly "Mobile-First" (optimized for touch targets, bottom navigation, and quick mobile interactions).

---

## 1. Global & Authentication (Shared UI Components)
These screens serve as the entry point for all users and establish the global design system (typography, buttons, form inputs).

*   **Public Landing Page:** The marketing face of EvenTix. Highlights the Unique Value Proposition (Secure Ticketing, Collectible Souvenirs, Community Management).
*   **Authentication Flow:**
    *   **Login Screen:** Email/Password input with OAuth options.
    *   **Registration Screen:** Account creation.
    *   **Password Reset:** Standard recovery flow.

---

## 2. Member Portal (Mobile-First UI)
*Assigned to: Frontend Dev 2*
*Design Constraints: Prioritize mobile viewports, utilize a persistent bottom navigation bar, and focus on fast, frictionless interactions using Navigation Stacks.*

### Tab 1: Feed (The Home Screen Stack)
*   **The Event Feed (Root Screen)**
    *   **Header:** A personalized greeting and a notification bell icon.
    *   **Filter/Pill Bar:** A horizontally scrolling list of chips to filter events by joined organizations.
    *   **Event Cards:** 16:9 thumbnail image, floating badges ("Free", "Paid", "Multi-Day"), Event Title, Organization Name, Date/Time, and a capacity status indicator.
*   **Event Detail Page (Child Screen)**
    *   **Hero Image:** A large, immersive cover photo.
    *   **Body Content:** Title, Date/Time, Location (with mini-map), "Hosted By" section, and rich text description.
    *   **Sticky Bottom Bar:** Remains at the bottom while scrolling. Contains the ticket price and a massive "RSVP" button.
*   **Checkout/RSVP Modal (Child Screen - Slides up)**
    *   **Step 1:** Selectable cards for Ticket Tiers (General, VIP) and prices.
    *   **Step 2:** List of available Add-Ons (Merch, Meals) with +/- quantity selectors.
    *   **Step 3:** Summary showing subtotal, fees, and Total Price.
    *   **Step 4:** Payment input fields and a final "Confirm RSVP" button.

### Tab 2: Explore (The Discovery Stack)
*   **Organization Search (Root Screen)**
    *   **Header:** Persistent search bar with a category filter icon.
    *   **Organization List/Grid:** Cards showing the Org Logo, full name, member count, and visual cue.
*   **Organization Public Profile (Child Screen)**
    *   **Visuals:** Background cover photo with the Org Logo overlapping.
    *   **Details:** Name, member count, bio/description, and membership fee details.
    *   **Action:** A massive "Request to Join" button.
    *   **Preview:** A horizontally scrolling section of "Past Public Events".
*   **Join/Pay Modal (Child Screen)**
    *   Triggered by the Join button. Handles membership fee checkout and sends the request to the organizer.

### Tab 3: Wallet (The Active Ticket Stack)
*   **Wallet List (Root Screen)**
    *   **Header:** "My Tickets" title.
    *   **List Items:** Designed like perforated stubs with a color band for the tier, Event Title, Date, and a mini QR icon.
*   **Active Ticket View / Hero Screen (Child Screen)**
    *   **The Ticket Frame:** Designed as a premium digital asset.
    *   **The Code:** A massive, crisp QR code in the center.
    *   **The Details:** Member Name, Event Title, Valid Dates, and Ticket Tier.
    *   **Add-On Checklist:** A distinct box listing purchased add-ons for door staff to read.
    *   **Action:** A secondary ghost button for "Transfer Ticket".
*   **Transfer Modal (Child Screen)**
    *   **Input:** Search bar to find a recipient within the same organization.
    *   **Warning:** Red text ("This action is irreversible...").
    *   **Action:** "Confirm Transfer" button.

### Tab 4: Profile (The Identity & History Stack)
*   **My Profile & ID Cards (Root Screen)**
    *   **Top Bar:** User's avatar, Full Name, and Settings gear icon.
    *   **The Carousel:** A horizontally swipeable area for digital ID Cards.
    *   **ID Card Design:** Looks like a physical badge. Uses the org's brand color, logo, member photo, Full Name, Role, and Join Date.
*   **The Vault / Scrapbook (Child Screen)**
    *   **Grid Layout:** A masonry grid of high-fidelity images representing past "Evolved" souvenir tickets.
*   **Evaluation & Certificate Modals (Child Screens)**
    *   **Evaluation Modal:** 5-star rating, text area for feedback, and "Submit" button.
    *   **Certificate Viewer:** PDF viewer component with "Download PDF" and "Share to LinkedIn" buttons.
*   **The "Trophy Room" (Public Profile Link)**
    *   A stylized, shareable read-only page displaying the member's ID cards, verified attendance stats, and souvenir grid.

---

## 3. Organization Portal (Web-Optimized Dashboard)
*Assigned to: Frontend Dev 1*
*Design Constraints: Prioritize desktop/tablet layouts, data tables, persistent left-side navigation, and complex form interactions.*

### Sidebar Route 1: Dashboard (The Overview)
*   **Global Dashboard (Root Screen)**
    *   **Header:** Organization Name, current date, and user profile dropdown.
    *   **Key Metrics Cards:** Four large widgets at the top showing: Total Members, Active Events, 30-Day Revenue, and Pending Join Requests.
    *   **Charts:** A wide line chart displaying attendance trends over the last 6 months.
    *   **Quick Actions:** A sticky panel or prominent buttons for "Create New Event" and "Review Pending Members".

### Sidebar Route 2: Events (The Event Engine)
*   **Events List (Root Screen)**
    *   **Data Table:** Columns for Status (Draft/Published/Completed), Event Title, Date, and Tickets Sold vs. Capacity.
    *   **Filters:** Tabs above the table to quickly filter by status.
    *   **Action:** Prominent "Create Event" button.
*   **Event Creation Builder (Child Screen / Multi-Step Wizard)**
    *   **Step 1 - Basic Info:** Text inputs for Title, Dates, Location map picker, Rich Text Editor for description, and an image dropzone for Souvenir Ticket Artwork.
    *   **Step 2 - Ticketing Engine:** A dynamic form where organizers can click "Add Tier" to define General/VIP tiers, set prices, and set capacity limits.
    *   **Step 3 - Add-Ons:** A dynamic form to add merchandise/meals, set prices, and define stock inventory.
    *   **Step 4 - Post-Event:** A simple drag-and-drop or checklist builder for the Evaluation Form, and a PDF file uploader for the base Certificate Template.
*   **Event Command Center (Child Screen / Live View)**
    *   *Reached by clicking a specific event from the Events List.*
    *   **Tabs:** Overview | Attendees | Scanner | Gamification
    *   **Overview Tab:** Live pie charts of "Checked-In vs. Absent", and a revenue breakdown block.
    *   **Attendees Tab:** A searchable list of everyone who RSVP'd, with a "Manual Check-In" button next to their name.
    *   **Gamification Tab:** The "Start Raffle" trigger, displaying an animated randomizer that selects a winner from the checked-in list.
*   **Live Scanner UI (Child Screen - Launched from Command Center)**
    *   **Layout:** A distraction-free, full-screen mode optimized for a tablet or laptop webcam.
    *   **Viewfinder:** The live camera feed centered on the screen.
    *   **Scan Feedback (Crucial UX):** The entire screen background flashes dynamically based on the scan: **Green** (Valid/Go), **Red** (Invalid/Banned/Stop), **Gold** (VIP).
    *   **Fulfillment Box:** Pops up upon a successful scan showing member name, tier, and a checklist of add-ons (e.g., "Hand them 1x Medium Shirt") with checkboxes to mark them fulfilled.

### Sidebar Route 3: Members (The Community CRM)
*   **Member Directory (Root Screen)**
    *   **Data Table:** Columns for Member Name, Role, Join Date, and Status (Active/Banned).
    *   **Filters:** Search bar for names, and a dropdown to filter by Role.
*   **Approvals Queue (Child Screen / Tab)**
    *   **List View:** Displays users requesting to join, with bulk "Approve Selected" and "Reject Selected" buttons.
*   **Member Detail Profile (Child Screen / Slide-out Panel)**
    *   **Header:** Member's photo, Full Name, and current Role badge.
    *   **History:** A scrolling timeline or mini-table of every event they have attended.
    *   **Admin Controls:** A dropdown to modify their role (Promote to Co-Organizer/Staff).
    *   **Danger Zone:** A heavily styled red section containing the "Ban/Block User" button.

### Sidebar Route 4: Financials (The Ledger)
*   **Revenue Dashboard (Root Screen)**
    *   **Charts:** Bar charts splitting revenue between "Ticket Sales", "Add-Ons", and "Membership Dues".
    *   **Transactions Table:** A chronological ledger of every payment made by members to the organization.
*   **Payouts & Gateway (Child Screen)**
    *   **Gateway Status:** UI showing if their GCash/payment processor is connected and active.
    *   **Membership Fee Configurator:** Input fields to set the cost of joining the organization and the billing interval (monthly, annually, one-time).

### Sidebar Route 5: Settings (Org Configuration)
*   **Organization Profile (Root Screen)**
    *   **Branding Form:** Image uploaders for the Org Logo and Banner. A Hex-code color picker for the org's branding color (which reflects on the ID cards).
    *   **Details Form:** Text inputs for Organization Name, Contact Email, and Description.
    *   **Visibility Toggle:** A switch to "List Organization on Public Explore Tab" (making it discoverable to new members).

---

## Interface Summary

| Module / Category | Primary Interfaces | Target Viewport | Assigned To |
| :--- | :--- | :--- | :--- |
| **Global** | Landing Page, Login, Registration, Password Reset | Responsive (All) | Shared / Designer |
| **Member: Feed** | Event Feed, Event Detail, RSVP/Checkout Modal | Mobile-First | Frontend Dev 2 |
| **Member: Explore** | Org Search, Org Public Profile, Join/Pay Modal | Mobile-First | Frontend Dev 2 |
| **Member: Wallet** | Wallet List, Active Hero Ticket, Transfer Modal | Mobile-First | Frontend Dev 2 |
| **Member: Profile** | ID Cards Carousel, Vault/Scrapbook, Evaluations, Trophy Room | Mobile-First | Frontend Dev 2 |
| **Org: Dashboard** | Global Metrics, Trend Charts, Quick Action Panel | Web (Desktop/Tablet) | Frontend Dev 1 |
| **Org: Events** | Events List, Multi-Step Wizard, Command Center, Live Scanner UI | Web (Desktop/Tablet) | Frontend Dev 1 |
| **Org: Members** | Member Directory, Approvals Queue, Member Detail (Banning/Roles) | Web (Desktop/Tablet) | Frontend Dev 1 |
| **Org: Financials** | Revenue Dashboard, Transactions Ledger, Fee Configurator | Web (Desktop/Tablet) | Frontend Dev 1 |
| **Org: Settings** | Branding Uploaders, Description form, Visibility Toggles | Web (Desktop/Tablet) | Frontend Dev 1 |
# EvenTix - Database Schema Document

**Database Engine:** PostgreSQL

## 1. Core Architecture Overview
This schema is highly relational, utilizing Foreign Keys (`FK`) with cascading deletes where appropriate to maintain strict ACID compliance. It supports advanced features including Role-Based Access Control (RBAC), multi-day event tracking, tiered ticketing, and dynamic post-event evaluations using `JSONB` for flexibility.

---

## 2. Table Definitions

### A. Core Identity & Organizations

#### `users`
Stores all registered accounts on the platform (both Organizers and Members).
| Column Name | Data Type | Constraints & Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key (PK) |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL |
| `password_hash` | VARCHAR(255) | NOT NULL |
| `full_name` | VARCHAR(100) | NOT NULL |
| `public_profile_enabled` | BOOLEAN | DEFAULT FALSE (Toggles "Trophy Room" visibility) |
| `created_at` | TIMESTAMP | |

#### `organizations`
Stores the parent entities that host events and manage members.
| Column Name | Data Type | Constraints & Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key (PK) |
| `name` | VARCHAR(150) | NOT NULL |
| `description` | TEXT | |
| `logo_url` | VARCHAR(255) | |
| `branding_color` | VARCHAR(7) | Hex code (e.g., #FF5733) |
| `is_public` | BOOLEAN | DEFAULT TRUE (Show on Explore tab) |
| `membership_fee` | NUMERIC(10,2)| DEFAULT 0.00 |
| `created_at` | TIMESTAMP | |

#### `organization_user` (Pivot Table)
Manages the relationship, RBAC, and moderation between Users and Organizations.
| Column Name | Data Type | Constraints & Description |
| :--- | :--- | :--- |
| `org_id` | UUID | PK, FK references `organizations.id` |
| `user_id` | UUID | PK, FK references `users.id` |
| `role` | VARCHAR(50) | `Owner`, `Co-Organizer`, `Staff`, `Member` |
| `status` | VARCHAR(50) | `Pending`, `Active`, `Banned` |
| `dues_paid_until` | DATE | NULL if free. Determines active financial standing. |
| `joined_at` | TIMESTAMP | |

---

### B. Events & Monetization

#### `events`
Stores the core event details, supporting single and multi-day schedules.
| Column Name | Data Type | Constraints & Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key (PK) |
| `org_id` | UUID | FK references `organizations.id` |
| `title` | VARCHAR(150) | NOT NULL |
| `description` | TEXT | |
| `start_date` | TIMESTAMP | NOT NULL |
| `end_date` | TIMESTAMP | NOT NULL (Same as start_date for 1-day events) |
| `artwork_url` | VARCHAR(255) | The base image for the Souvenir Ticket |
| `status` | VARCHAR(50) | `Draft`, `Published`, `Completed` |
| `created_at` | TIMESTAMP | |

#### `event_tiers`
Defines the different ticket types (Free or Paid) available for an event.
| Column Name | Data Type | Constraints & Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key (PK) |
| `event_id` | UUID | FK references `events.id` |
| `name` | VARCHAR(100) | e.g., "General Admission", "VIP", "Early Bird" |
| `price` | NUMERIC(10,2)| DEFAULT 0.00 (For Free events) |
| `capacity` | INTEGER | Maximum tickets available for this specific tier |

#### `event_addons`
Optional merchandise or meals members can buy during RSVP.
| Column Name | Data Type | Constraints & Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key (PK) |
| `event_id` | UUID | FK references `events.id` |
| `name` | VARCHAR(100) | e.g., "Event T-Shirt (Large)" |
| `price` | NUMERIC(10,2)| NOT NULL |
| `stock` | INTEGER | Available inventory |

---

### C. Ticketing & Attendance (The Cryptographic Core)

#### `tickets`
The central asset. Serves as the active QR ticket, and later, the digital souvenir.
| Column Name | Data Type | Constraints & Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key (PK) |
| `event_id` | UUID | FK references `events.id` |
| `user_id` | UUID | FK references `users.id` (Current Owner) |
| `tier_id` | UUID | FK references `event_tiers.id` |
| `qr_hash` | VARCHAR(255) | UNIQUE, NOT NULL (The cryptographically secure string) |
| `status` | VARCHAR(50) | `Active`, `Transferred`, `Evolved_Souvenir` |
| `purchased_at`| TIMESTAMP | |

#### `ticket_addons` (Pivot Table)
Maps the add-ons a user purchased to their specific ticket.
| Column Name | Data Type | Constraints & Description |
| :--- | :--- | :--- |
| `ticket_id` | UUID | PK, FK references `tickets.id` |
| `addon_id` | UUID | PK, FK references `event_addons.id` |
| `quantity` | INTEGER | DEFAULT 1 |
| `fulfilled` | BOOLEAN | DEFAULT FALSE (Toggled by scanner staff at door) |

#### `attendance_logs`
Crucial for multi-day events. Logs exactly when and who scanned the ticket.
| Column Name | Data Type | Constraints & Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key (PK) |
| `ticket_id` | UUID | FK references `tickets.id` |
| `scanned_by` | UUID | FK references `users.id` (The Staff member who scanned it) |
| `scanned_at` | TIMESTAMP | NOT NULL |
| `day_identifier`| DATE | Ensures a ticket is only scanned once per day of the event |

---

### D. Post-Event Workflows

#### `evaluations`
The dynamic form created by the organizer.
| Column Name | Data Type | Constraints & Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key (PK) |
| `event_id` | UUID | UNIQUE, FK references `events.id` |
| `form_schema` | JSONB | Stores dynamic questions (e.g., ratings, text fields) |
| `cert_template_url`| VARCHAR(255) | Base PDF/Image for the certificate overlay |

#### `evaluation_responses`
The member's answers to the evaluation.
| Column Name | Data Type | Constraints & Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key (PK) |
| `evaluation_id`| UUID | FK references `evaluations.id` |
| `user_id` | UUID | FK references `users.id` |
| `response_data`| JSONB | The submitted answers matching the `form_schema` |
| `submitted_at` | TIMESTAMP | Automatically unlocks the certificate generation |

#### `certificates`
The final generated PDF locked in the user's vault.
| Column Name | Data Type | Constraints & Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key (PK) |
| `event_id` | UUID | FK references `events.id` |
| `user_id` | UUID | FK references `users.id` |
| `pdf_url` | VARCHAR(255) | Link to the generated, personalized PDF file |
| `issued_at` | TIMESTAMP | |

---

## 3. Key Backend Implementation Notes
1.  **Ticket Transfers:** When a user transfers a ticket, do NOT update the `user_id` on the existing ticket. Update the old ticket's status to `Transferred`, generate a *new* row in `tickets` for the recipient with a freshly generated `qr_hash`, and carry over any `ticket_addons`. This preserves the forensic audit trail.
2.  **Concurrency:** The backend must use database-level locking (`SELECT ... FOR UPDATE` in PostgreSQL) when inserting rows into `tickets` to ensure `event_tiers.capacity` and `event_addons.stock` are never exceeded during simultaneous RSVPs.
3.  **Evolving Souvenirs:** A cron job or an end-of-event hook should count a user's `attendance_logs` against the total days of the `events.start_date` and `events.end_date`. If they match, the `tickets.status` updates to `Evolved_Souvenir`, changing how the Next.js frontend renders it in the Trophy Room.
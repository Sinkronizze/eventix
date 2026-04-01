BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  public_profile_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(150) NOT NULL,
  description TEXT,
  logo_url VARCHAR(255),
  branding_color VARCHAR(7),
  is_public BOOLEAN NOT NULL DEFAULT TRUE,
  membership_fee NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT organizations_branding_color_hex_chk CHECK (
    branding_color IS NULL OR branding_color ~ '^#[A-Fa-f0-9]{6}$'
  ),
  CONSTRAINT organizations_membership_fee_nonnegative_chk CHECK (membership_fee >= 0)
);

CREATE TABLE IF NOT EXISTS organization_user (
  org_id UUID NOT NULL,
  user_id UUID NOT NULL,
  role VARCHAR(50) NOT NULL,
  status VARCHAR(50) NOT NULL,
  dues_paid_until DATE,
  joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (org_id, user_id),
  CONSTRAINT organization_user_org_fk FOREIGN KEY (org_id)
    REFERENCES organizations(id)
    ON DELETE CASCADE,
  CONSTRAINT organization_user_user_fk FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE,
  CONSTRAINT organization_user_role_chk CHECK (role IN ('Owner', 'Co-Organizer', 'Staff', 'Member')),
  CONSTRAINT organization_user_status_chk CHECK (status IN ('Pending', 'Active', 'Banned'))
);

CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL,
  title VARCHAR(150) NOT NULL,
  description TEXT,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  artwork_url VARCHAR(255),
  status VARCHAR(50) NOT NULL DEFAULT 'Draft',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT events_org_fk FOREIGN KEY (org_id)
    REFERENCES organizations(id)
    ON DELETE CASCADE,
  CONSTRAINT events_status_chk CHECK (status IN ('Draft', 'Published', 'Completed')),
  CONSTRAINT events_date_range_chk CHECK (end_date >= start_date)
);

CREATE TABLE IF NOT EXISTS event_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL,
  name VARCHAR(100) NOT NULL,
  price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  capacity INTEGER NOT NULL,
  CONSTRAINT event_tiers_event_fk FOREIGN KEY (event_id)
    REFERENCES events(id)
    ON DELETE CASCADE,
  CONSTRAINT event_tiers_price_nonnegative_chk CHECK (price >= 0),
  CONSTRAINT event_tiers_capacity_positive_chk CHECK (capacity > 0)
);

CREATE TABLE IF NOT EXISTS event_addons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL,
  name VARCHAR(100) NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  stock INTEGER NOT NULL,
  CONSTRAINT event_addons_event_fk FOREIGN KEY (event_id)
    REFERENCES events(id)
    ON DELETE CASCADE,
  CONSTRAINT event_addons_price_nonnegative_chk CHECK (price >= 0),
  CONSTRAINT event_addons_stock_nonnegative_chk CHECK (stock >= 0)
);

CREATE TABLE IF NOT EXISTS tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL,
  user_id UUID NOT NULL,
  tier_id UUID NOT NULL,
  qr_hash VARCHAR(255) UNIQUE NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'Active',
  purchased_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT tickets_event_fk FOREIGN KEY (event_id)
    REFERENCES events(id)
    ON DELETE CASCADE,
  CONSTRAINT tickets_user_fk FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE,
  CONSTRAINT tickets_tier_fk FOREIGN KEY (tier_id)
    REFERENCES event_tiers(id)
    ON DELETE RESTRICT,
  CONSTRAINT tickets_status_chk CHECK (status IN ('Active', 'Transferred', 'Evolved_Souvenir'))
);

CREATE TABLE IF NOT EXISTS ticket_addons (
  ticket_id UUID NOT NULL,
  addon_id UUID NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  fulfilled BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (ticket_id, addon_id),
  CONSTRAINT ticket_addons_ticket_fk FOREIGN KEY (ticket_id)
    REFERENCES tickets(id)
    ON DELETE CASCADE,
  CONSTRAINT ticket_addons_addon_fk FOREIGN KEY (addon_id)
    REFERENCES event_addons(id)
    ON DELETE CASCADE,
  CONSTRAINT ticket_addons_quantity_positive_chk CHECK (quantity > 0)
);

CREATE TABLE IF NOT EXISTS attendance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL,
  scanned_by UUID,
  scanned_at TIMESTAMP NOT NULL,
  day_identifier DATE NOT NULL,
  CONSTRAINT attendance_logs_ticket_fk FOREIGN KEY (ticket_id)
    REFERENCES tickets(id)
    ON DELETE CASCADE,
  CONSTRAINT attendance_logs_scanned_by_fk FOREIGN KEY (scanned_by)
    REFERENCES users(id)
    ON DELETE SET NULL,
  CONSTRAINT attendance_logs_ticket_day_unique UNIQUE (ticket_id, day_identifier)
);

CREATE TABLE IF NOT EXISTS evaluations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID UNIQUE NOT NULL,
  form_schema JSONB NOT NULL,
  cert_template_url VARCHAR(255),
  CONSTRAINT evaluations_event_fk FOREIGN KEY (event_id)
    REFERENCES events(id)
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS evaluation_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  evaluation_id UUID NOT NULL,
  user_id UUID NOT NULL,
  response_data JSONB NOT NULL,
  submitted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT evaluation_responses_evaluation_fk FOREIGN KEY (evaluation_id)
    REFERENCES evaluations(id)
    ON DELETE CASCADE,
  CONSTRAINT evaluation_responses_user_fk FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE,
  CONSTRAINT evaluation_responses_unique_submission UNIQUE (evaluation_id, user_id)
);

CREATE TABLE IF NOT EXISTS certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL,
  user_id UUID NOT NULL,
  pdf_url VARCHAR(255) NOT NULL,
  issued_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT certificates_event_fk FOREIGN KEY (event_id)
    REFERENCES events(id)
    ON DELETE CASCADE,
  CONSTRAINT certificates_user_fk FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE,
  CONSTRAINT certificates_user_event_unique UNIQUE (event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_organization_user_user_id ON organization_user(user_id);
CREATE INDEX IF NOT EXISTS idx_events_org_id ON events(org_id);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_event_tiers_event_id ON event_tiers(event_id);
CREATE INDEX IF NOT EXISTS idx_event_addons_event_id ON event_addons(event_id);
CREATE INDEX IF NOT EXISTS idx_tickets_event_id ON tickets(event_id);
CREATE INDEX IF NOT EXISTS idx_tickets_user_id ON tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_tier_id ON tickets(tier_id);
CREATE INDEX IF NOT EXISTS idx_attendance_logs_ticket_id ON attendance_logs(ticket_id);
CREATE INDEX IF NOT EXISTS idx_attendance_logs_scanned_by ON attendance_logs(scanned_by);
CREATE INDEX IF NOT EXISTS idx_attendance_logs_day_identifier ON attendance_logs(day_identifier);
CREATE INDEX IF NOT EXISTS idx_evaluation_responses_evaluation_id ON evaluation_responses(evaluation_id);
CREATE INDEX IF NOT EXISTS idx_evaluation_responses_user_id ON evaluation_responses(user_id);
CREATE INDEX IF NOT EXISTS idx_certificates_user_id ON certificates(user_id);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_addons ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_addons ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE evaluation_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM authenticated;

GRANT USAGE ON SCHEMA public TO service_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;

COMMIT;

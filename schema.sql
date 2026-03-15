-- ============================================================
-- EventAxom - Complete Database Schema
-- PostgreSQL / Supabase
-- ============================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- for full text search

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE user_role AS ENUM ('user', 'organiser', 'admin');
CREATE TYPE event_status AS ENUM ('draft', 'pending', 'approved', 'rejected', 'cancelled', 'completed');
CREATE TYPE ticket_status AS ENUM ('active', 'used', 'cancelled', 'refunded');
CREATE TYPE payment_status AS ENUM ('pending', 'success', 'failed', 'refunded');
CREATE TYPE event_category AS ENUM (
  'concert', 'cultural', 'college_festival', 'workshop',
  'sports', 'night_show', 'comedy', 'tech', 'food', 'art', 'other'
);
CREATE TYPE assam_city AS ENUM (
  'guwahati', 'dibrugarh', 'jorhat', 'tezpur', 'silchar',
  'nagaon', 'lakhimpur', 'dhubri', 'karimganj', 'bongaigaon',
  'goalpara', 'sivasagar', 'other'
);

-- ============================================================
-- USERS
-- ============================================================

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  role user_role DEFAULT 'user',
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  google_id TEXT UNIQUE,
  referral_code TEXT UNIQUE DEFAULT UPPER(SUBSTRING(MD5(RANDOM()::TEXT), 1, 8)),
  referred_by UUID REFERENCES users(id),
  wallet_balance DECIMAL(10,2) DEFAULT 0,
  notification_preferences JSONB DEFAULT '{"email": true, "sms": true, "push": true}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_referral_code ON users(referral_code);

-- ============================================================
-- ORGANISER PROFILES
-- ============================================================

CREATE TABLE organiser_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  org_name TEXT NOT NULL,
  org_description TEXT,
  org_logo_url TEXT,
  org_website TEXT,
  bank_account_number TEXT,
  bank_ifsc TEXT,
  upi_id TEXT,
  razorpay_account_id TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  total_events INTEGER DEFAULT 0,
  total_revenue DECIMAL(10,2) DEFAULT 0,
  commission_rate DECIMAL(5,2) DEFAULT 5.0, -- platform commission %
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- ============================================================
-- EVENTS
-- ============================================================

CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organiser_id UUID NOT NULL REFERENCES organiser_profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  ai_description TEXT, -- AI generated description
  banner_url TEXT,
  poster_url TEXT,
  category event_category NOT NULL DEFAULT 'other',
  city assam_city NOT NULL DEFAULT 'guwahati',
  venue_name TEXT NOT NULL,
  venue_address TEXT,
  venue_lat DECIMAL(10, 8),
  venue_lng DECIMAL(11, 8),
  start_datetime TIMESTAMPTZ NOT NULL,
  end_datetime TIMESTAMPTZ NOT NULL,
  status event_status DEFAULT 'pending',
  is_featured BOOLEAN DEFAULT FALSE,
  is_trending BOOLEAN DEFAULT FALSE,
  total_capacity INTEGER NOT NULL DEFAULT 100,
  tickets_sold INTEGER DEFAULT 0,
  min_price DECIMAL(10,2) DEFAULT 0,
  max_price DECIMAL(10,2) DEFAULT 0,
  is_free BOOLEAN DEFAULT FALSE,
  tags TEXT[],
  seo_title TEXT,
  seo_description TEXT,
  view_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,
  refund_policy TEXT DEFAULT 'No refunds after booking.',
  age_restriction INTEGER,
  dress_code TEXT,
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_events_organiser ON events(organiser_id);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_city ON events(city);
CREATE INDEX idx_events_category ON events(category);
CREATE INDEX idx_events_start_datetime ON events(start_datetime);
CREATE INDEX idx_events_slug ON events(slug);
CREATE INDEX idx_events_trending ON events(is_trending, is_featured);
CREATE INDEX idx_events_search ON events USING GIN(to_tsvector('english', title || ' ' || COALESCE(description, '')));

-- ============================================================
-- TICKET TIERS
-- ============================================================

CREATE TABLE ticket_tiers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  name TEXT NOT NULL, -- e.g. "General", "VIP", "VVIP", "Early Bird"
  description TEXT,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  original_price DECIMAL(10,2), -- for showing discounts
  capacity INTEGER NOT NULL,
  sold_count INTEGER DEFAULT 0,
  is_early_bird BOOLEAN DEFAULT FALSE,
  early_bird_ends_at TIMESTAMPTZ,
  sale_starts_at TIMESTAMPTZ,
  sale_ends_at TIMESTAMPTZ,
  benefits TEXT[], -- list of tier benefits
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ticket_tiers_event ON ticket_tiers(event_id);

-- ============================================================
-- BOOKINGS
-- ============================================================

CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_ref TEXT UNIQUE NOT NULL DEFAULT 'AXM-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT), 1, 8)),
  user_id UUID NOT NULL REFERENCES users(id),
  event_id UUID NOT NULL REFERENCES events(id),
  tier_id UUID NOT NULL REFERENCES ticket_tiers(id),
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  platform_fee DECIMAL(10,2) DEFAULT 0,
  gst_amount DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL,
  coupon_id UUID,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  payment_status payment_status DEFAULT 'pending',
  razorpay_order_id TEXT,
  razorpay_payment_id TEXT,
  razorpay_signature TEXT,
  special_requirements TEXT,
  booker_name TEXT NOT NULL,
  booker_email TEXT NOT NULL,
  booker_phone TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bookings_event ON bookings(event_id);
CREATE INDEX idx_bookings_status ON bookings(payment_status);
CREATE INDEX idx_bookings_ref ON bookings(booking_ref);

-- ============================================================
-- TICKETS (individual tickets per booking)
-- ============================================================

CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(id),
  user_id UUID NOT NULL REFERENCES users(id),
  ticket_number TEXT UNIQUE NOT NULL DEFAULT 'TKT-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT), 1, 10)),
  qr_code_data TEXT NOT NULL, -- encrypted QR data
  qr_code_url TEXT, -- generated QR image URL
  status ticket_status DEFAULT 'active',
  seat_number TEXT, -- optional seat assignment
  checked_in_at TIMESTAMPTZ,
  checked_in_by UUID REFERENCES users(id), -- organiser who scanned
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tickets_booking ON tickets(booking_id);
CREATE INDEX idx_tickets_user ON tickets(user_id);
CREATE INDEX idx_tickets_event ON tickets(event_id);
CREATE INDEX idx_tickets_number ON tickets(ticket_number);
CREATE INDEX idx_tickets_status ON tickets(status);

-- ============================================================
-- COUPONS
-- ============================================================

CREATE TABLE coupons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID REFERENCES events(id), -- NULL = platform-wide
  organiser_id UUID REFERENCES organiser_profiles(id),
  code TEXT UNIQUE NOT NULL,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'flat')),
  discount_value DECIMAL(10,2) NOT NULL,
  min_order_amount DECIMAL(10,2) DEFAULT 0,
  max_discount DECIMAL(10,2),
  usage_limit INTEGER,
  used_count INTEGER DEFAULT 0,
  valid_from TIMESTAMPTZ DEFAULT NOW(),
  valid_until TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- REFERRALS
-- ============================================================

CREATE TABLE referrals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  referrer_id UUID NOT NULL REFERENCES users(id),
  referred_id UUID NOT NULL REFERENCES users(id),
  referral_type TEXT NOT NULL CHECK (referral_type IN ('user', 'organiser')),
  reward_amount DECIMAL(10,2) DEFAULT 0,
  reward_paid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(referrer_id, referred_id)
);

-- ============================================================
-- REVIEWS & RATINGS
-- ============================================================

CREATE TABLE event_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id),
  user_id UUID NOT NULL REFERENCES users(id),
  booking_id UUID REFERENCES bookings(id),
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  is_verified BOOLEAN DEFAULT FALSE, -- only allowed if booking confirmed
  is_approved BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);

-- ============================================================
-- WAITLIST
-- ============================================================

CREATE TABLE event_waitlist (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id),
  tier_id UUID REFERENCES ticket_tiers(id),
  user_id UUID NOT NULL REFERENCES users(id),
  email TEXT NOT NULL,
  phone TEXT,
  notified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL, -- 'booking_confirmed', 'event_reminder', 'ticket_ready', etc.
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);

-- ============================================================
-- EVENT ANALYTICS (aggregated)
-- ============================================================

CREATE TABLE event_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id),
  date DATE NOT NULL,
  page_views INTEGER DEFAULT 0,
  unique_visitors INTEGER DEFAULT 0,
  tickets_sold INTEGER DEFAULT 0,
  revenue DECIMAL(10,2) DEFAULT 0,
  shares INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, date)
);

-- ============================================================
-- PLATFORM SETTINGS
-- ============================================================

CREATE TABLE platform_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO platform_settings VALUES
  ('platform_fee_percentage', '5', NOW()),
  ('gst_percentage', '18', NOW()),
  ('free_tier_limit', '500', NOW()),
  ('referral_reward_user', '50', NOW()),
  ('referral_reward_organiser', '200', NOW());

-- ============================================================
-- ADMIN AUDIT LOG
-- ============================================================

CREATE TABLE admin_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID NOT NULL REFERENCES users(id),
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  details JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY (Supabase RLS)
-- ============================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can read their own data
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Events are publicly readable if approved
CREATE POLICY "Anyone can view approved events" ON events FOR SELECT USING (status = 'approved');
CREATE POLICY "Organisers can manage own events" ON events FOR ALL USING (
  organiser_id IN (SELECT id FROM organiser_profiles WHERE user_id = auth.uid())
);

-- Bookings are private to user
CREATE POLICY "Users view own bookings" ON bookings FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Tickets private to user" ON tickets FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Notifications private" ON notifications FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER events_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER bookings_updated_at BEFORE UPDATE ON bookings FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-generate event slug
CREATE OR REPLACE FUNCTION generate_event_slug()
RETURNS TRIGGER AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  base_slug := LOWER(REGEXP_REPLACE(NEW.title, '[^a-zA-Z0-9]+', '-', 'g'));
  base_slug := TRIM(BOTH '-' FROM base_slug);
  final_slug := base_slug || '-' || SUBSTRING(NEW.id::TEXT, 1, 8);
  NEW.slug := final_slug;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER events_gen_slug BEFORE INSERT ON events FOR EACH ROW EXECUTE FUNCTION generate_event_slug();

-- Update tickets_sold count
CREATE OR REPLACE FUNCTION update_ticket_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.payment_status = 'success' AND OLD.payment_status != 'success' THEN
    UPDATE events SET tickets_sold = tickets_sold + NEW.quantity WHERE id = NEW.event_id;
    UPDATE ticket_tiers SET sold_count = sold_count + NEW.quantity WHERE id = NEW.tier_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER bookings_update_counts AFTER UPDATE ON bookings FOR EACH ROW EXECUTE FUNCTION update_ticket_counts();

# EventAxom — Complete Deployment & Setup Guide
## Assam's #1 Event Ticketing Platform

---

## 📁 Project Structure

```
eventaxom/
├── frontend/                    # Next.js 14 frontend
│   ├── src/
│   │   ├── app/                 # Next.js App Router pages
│   │   │   ├── page.tsx         # Homepage (Hero, Trending, Categories)
│   │   │   ├── layout.tsx       # Root layout (Navbar, Footer, Toast)
│   │   │   ├── events/
│   │   │   │   ├── page.tsx     # Explore events (filterable listing)
│   │   │   │   ├── [slug]/page.tsx  # Event detail + booking widget
│   │   │   │   └── city/[city]/page.tsx  # City-specific events
│   │   │   ├── auth/
│   │   │   │   ├── login/page.tsx    # Email + Phone OTP login
│   │   │   │   └── register/page.tsx # Registration
│   │   │   ├── dashboard/
│   │   │   │   ├── page.tsx          # User profile dashboard
│   │   │   │   ├── tickets/page.tsx  # Ticket wallet + QR viewer
│   │   │   │   └── notifications/page.tsx
│   │   │   ├── organiser/
│   │   │   │   ├── register/page.tsx
│   │   │   │   ├── dashboard/page.tsx  # Organiser dashboard + analytics
│   │   │   │   ├── events/create/page.tsx  # 5-step event creation + AI
│   │   │   │   ├── ai-tools/page.tsx       # AI marketing tools
│   │   │   │   └── scan/page.tsx           # QR scanner for entry
│   │   │   └── admin/page.tsx      # Admin panel
│   │   ├── components/
│   │   │   ├── layout/
│   │   │   │   ├── Navbar.tsx    # Responsive navbar + search modal
│   │   │   │   └── Footer.tsx    # Footer with SEO city links
│   │   │   └── events/
│   │   │       └── EventCard.tsx # Reusable card (default/compact/featured)
│   │   ├── lib/
│   │   │   └── api.ts           # All API calls + constants
│   │   ├── store/
│   │   │   └── authStore.ts     # Zustand auth state
│   │   └── styles/
│   │       └── globals.css      # TailwindCSS + custom styles
│   ├── tailwind.config.js
│   ├── next.config.js
│   └── vercel.json
│
├── backend/                     # Node.js + Express API
│   ├── src/
│   │   ├── index.js             # Server entry point
│   │   ├── config/
│   │   │   └── supabase.js      # Supabase admin + anon clients
│   │   ├── middleware/
│   │   │   └── auth.js          # JWT auth + role guards
│   │   ├── routes/
│   │   │   ├── auth.js          # Email, Google, Phone OTP auth
│   │   │   ├── users.js         # Profile, notifications, referrals
│   │   │   ├── events.js        # Full event CRUD + city/category filters
│   │   │   ├── bookings.js      # Razorpay payment flow
│   │   │   ├── tickets.js       # Ticket wallet + QR scanner
│   │   │   ├── organisers.js    # Organiser dashboard + CSV download
│   │   │   ├── admin.js         # Admin panel routes
│   │   │   ├── ai.js            # AI description/captions/poster
│   │   │   ├── payments.js      # Payment config + history
│   │   │   ├── search.js        # Full-text event search
│   │   │   ├── analytics.js     # Event analytics tracking
│   │   │   └── webhooks.js      # Razorpay webhook handler
│   │   └── services/
│   │       ├── qr.js            # AES-256-GCM QR encryption
│   │       ├── email.js         # Nodemailer ticket delivery
│   │       ├── otp.js           # Twilio Verify OTP
│   │       └── upload.js        # Cloudinary image upload
│   ├── schema.sql               # Complete PostgreSQL schema
│   ├── railway.toml             # Railway deployment config
│   └── .env.example
│
└── docs/
    └── DEPLOYMENT.md            # This file
```

---

## 🚀 Quick Start (Local Development)

### Prerequisites
- Node.js 18+
- npm or yarn
- A Supabase project
- Razorpay account (test mode)
- Twilio account (for OTP)
- Cloudinary account (for images)
- OpenAI API key (for AI features)

---

## Step 1: Database Setup (Supabase)

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run the entire `backend/schema.sql`
3. Enable **Row Level Security** (already in schema)
4. In **Authentication > Providers**, enable:
   - Email
   - Google OAuth (add your client ID/secret)
5. Copy your project URL, anon key, and service role key

---

## Step 2: Backend Setup

```bash
cd eventaxom/backend
cp .env.example .env
# Fill in all values in .env
npm install
npm run dev
# → API running at http://localhost:5000
```

**Required .env values:**
| Variable | Where to get |
|---|---|
| `SUPABASE_URL` | Supabase Project Settings > API |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Project Settings > API |
| `JWT_SECRET` | Generate: `openssl rand -hex 32` |
| `RAZORPAY_KEY_ID` | Razorpay Dashboard > API Keys |
| `RAZORPAY_KEY_SECRET` | Razorpay Dashboard > API Keys |
| `OPENAI_API_KEY` | [platform.openai.com](https://platform.openai.com) |
| `SMTP_USER/PASS` | Gmail App Password |
| `TWILIO_*` | [console.twilio.com](https://console.twilio.com) |
| `CLOUDINARY_*` | [cloudinary.com](https://cloudinary.com) |

---

## Step 3: Frontend Setup

```bash
cd eventaxom/frontend
cp .env.example .env.local
# Fill in values
npm install
npm run dev
# → Frontend at http://localhost:3000
```

---

## Step 4: Create First Admin User

```sql
-- Run in Supabase SQL Editor after registering
UPDATE users SET role = 'admin' WHERE email = 'your@email.com';
```

---

## ☁️ Production Deployment

### Backend → Railway

1. Push code to GitHub
2. Go to [railway.app](https://railway.app) → New Project → Deploy from GitHub
3. Select the `backend` folder
4. Add all environment variables from `.env.example`
5. Deploy → Copy the generated URL (e.g. `https://eventaxom-api.up.railway.app`)

**Alternative: Render**
1. New Web Service → Connect GitHub repo
2. Root directory: `backend`
3. Build command: `npm install`
4. Start command: `npm start`
5. Add environment variables

---

### Frontend → Vercel

1. Push code to GitHub
2. Go to [vercel.com](https://vercel.com) → New Project → Import GitHub
3. Select the `frontend` folder
4. Add environment variables:
   - `NEXT_PUBLIC_API_URL` = your Railway backend URL
   - `NEXT_PUBLIC_SUPABASE_URL` = your Supabase URL
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = your Supabase anon key
   - `NEXT_PUBLIC_RAZORPAY_KEY_ID` = your Razorpay key
5. Deploy → your site is live!

---

## 🌐 Custom Domain Setup

1. Buy domain: `eventaxom.in` (Namecheap / GoDaddy / Google Domains)
2. In Vercel: Settings > Domains → add `eventaxom.in`
3. Update DNS records as instructed by Vercel
4. Add subdomain `api.eventaxom.in` → point to Railway backend
5. Update `NEXT_PUBLIC_API_URL` to `https://api.eventaxom.in/api`

---

## 💳 Razorpay Setup

1. Create account at [razorpay.com](https://razorpay.com)
2. Complete KYC (for live payments)
3. Generate API keys (test mode first)
4. Configure webhook:
   - URL: `https://api.eventaxom.in/webhook/razorpay`
   - Events: `payment.captured`, `payment.failed`, `refund.processed`
5. Copy webhook secret to `RAZORPAY_WEBHOOK_SECRET`

**UPI/QR support is automatic** — Razorpay's checkout handles UPI, QR, cards, net banking, wallets automatically.

---

## 📱 SEO-Optimized City URLs

The following URLs are pre-configured via Vercel rewrites:

| URL | Maps to |
|---|---|
| `/events-guwahati` | `/events/city/guwahati` |
| `/events-dibrugarh` | `/events/city/dibrugarh` |
| `/events-jorhat` | `/events/city/jorhat` |
| `/events-tezpur` | `/events/city/tezpur` |
| `/events-silchar` | `/events/city/silchar` |
| `/events-assam` | `/events` |

Add these to Google Search Console to rank for local event searches.

---

## 🤖 AI Features Setup

1. Get OpenAI API key from [platform.openai.com](https://platform.openai.com)
2. Add to backend `.env`: `OPENAI_API_KEY=sk-...`
3. AI features available:
   - **AI Description Generator** — gpt-4o-mini, ~500 tokens per call
   - **Marketing Captions** — Instagram, WhatsApp, Facebook, Twitter, SMS
   - **AI Poster Generator** — DALL-E 3 (costs ~$0.04 per image)
   - **Event Recommendations** — based on booking history

**Cost estimate:** ~₹2 per AI description, ~₹3 per poster

---

## 📧 Email Setup (Gmail)

1. Enable 2FA on your Gmail
2. Go to Google Account → Security → App Passwords
3. Generate password for "Mail"
4. Use in `SMTP_PASS`

For production, use [Resend](https://resend.com) or [SendGrid](https://sendgrid.com) for better deliverability.

---

## 📲 SMS/OTP Setup (Twilio)

1. Create account at [twilio.com](https://twilio.com)
2. Create a Verify Service in the Console
3. Copy:
   - Account SID → `TWILIO_ACCOUNT_SID`
   - Auth Token → `TWILIO_AUTH_TOKEN`
   - Verify Service SID → `TWILIO_VERIFY_SERVICE_SID`

---

## 📊 Platform Economics

| Revenue Stream | Rate |
|---|---|
| Platform fee | 5% of ticket price |
| GST (collected & remitted) | 18% |
| Free events | ₹0 platform fee |
| AI poster generation | Optional upsell |

**Example:** Event with 500 × ₹500 tickets
- Gross: ₹2,50,000
- EventAxom fee (5%): ₹12,500
- Organiser receives: ₹2,37,500 (minus payment gateway ~2%)

---

## 🔒 Security Checklist

- [x] JWT tokens with 7-day expiry
- [x] Razorpay payment signature verification
- [x] QR codes encrypted with AES-256-GCM
- [x] Row Level Security on Supabase tables
- [x] Rate limiting on all API endpoints
- [x] Helmet.js security headers
- [x] CORS restricted to frontend domain
- [x] Input validation with express-validator
- [x] Admin audit log for all admin actions

---

## 🚦 Launch Checklist

### Pre-Launch
- [ ] Complete Razorpay KYC and go live
- [ ] Set up custom domain `eventaxom.in`
- [ ] Configure email with custom domain
- [ ] Set up Google Analytics
- [ ] Submit sitemap to Google Search Console
- [ ] Create social media accounts (@eventaxom)
- [ ] Create 5–10 seed events in Guwahati

### Go-Live
- [ ] Switch Razorpay from test to live mode
- [ ] Set `NODE_ENV=production` everywhere
- [ ] Enable Supabase database backups
- [ ] Set up Sentry for error tracking
- [ ] Set up uptime monitoring (Better Uptime / UptimeRobot)

---

## 📱 Mobile App (Future)
The backend API is mobile-ready. You can build:
- **React Native** app using the same API
- **PWA** — already works well as installable PWA from the Next.js app
- **Flutter** app for Android (key market in Assam)

---

## 🆘 Support

- Tech support: dev@eventaxom.in
- Business: business@eventaxom.in
- WhatsApp: +91-XXXXXXXXXX

---

*EventAxom — Built for Assam, Ready for Northeast India 🌿*

// ============================================================
// EventAxom - Main Server Entry
// ============================================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const app = express();

// ─── Middleware ───────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: [process.env.FRONTEND_URL, 'http://localhost:3000'],
  credentials: true,
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 100,
  message: { error: 'Too many requests. Please try again later.' },
});
app.use('/api/', limiter);

// Stricter rate for auth
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { error: 'Too many auth attempts.' },
});

// ─── Routes ──────────────────────────────────────────────
app.use('/api/auth',       authLimiter, require('./routes/auth'));
app.use('/api/users',      require('./routes/users'));
app.use('/api/events',     require('./routes/events'));
app.use('/api/bookings',   require('./routes/bookings'));
app.use('/api/tickets',    require('./routes/tickets'));
app.use('/api/organisers', require('./routes/organisers'));
app.use('/api/admin',      require('./routes/admin'));
app.use('/api/payments',   require('./routes/payments'));
app.use('/api/ai',         require('./routes/ai'));
app.use('/api/search',     require('./routes/search'));
app.use('/api/analytics',  require('./routes/analytics'));

// Razorpay Webhook (raw body needed for signature verification)
app.use('/webhook/razorpay',
  express.raw({ type: 'application/json' }),
  require('./routes/webhooks')
);

// ─── Health Check ─────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    platform: 'EventAxom',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// ─── Error Handler ────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// ─── 404 ─────────────────────────────────────────────────
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════════╗
  ║        EventAxom API Server           ║
  ║  Port: ${PORT}                           ║
  ║  Env:  ${process.env.NODE_ENV}              ║
  ╚═══════════════════════════════════════╝
  `);
});

module.exports = app;

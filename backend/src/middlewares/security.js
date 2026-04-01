const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const session = require("express-session");
const csrf = require("csurf");
const { env } = require("../config/env");

const isProduction = env.NODE_ENV === "production";
const parsedOrigins = env.CORS_ORIGINS.split(",").map((origin) => origin.trim());

const corsMiddleware = cors({
  origin(origin, callback) {
    if (!origin) {
      return callback(null, true);
    }

    if (parsedOrigins.includes(origin)) {
      return callback(null, true);
    }

    return callback(new Error("CORS blocked for this origin"));
  },
  credentials: true,
  methods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-CSRF-Token"],
  maxAge: 86400
});

const helmetMiddleware = helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "https:", "data:"],
      connectSrc: ["'self'", ...parsedOrigins],
      frameSrc: ["'none'"],
      objectSrc: ["'none'"]
    }
  },
  hsts: isProduction
    ? {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
      }
    : false,
  referrerPolicy: { policy: "no-referrer" }
});

const apiRateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests from this IP. Try again in a minute." }
});

const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true,
  message: { error: "Too many authentication attempts. Try again later." }
});

const sessionMiddleware = session({
  secret: env.SESSION_SECRET,
  name: "eventix.sid",
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: isProduction,
    httpOnly: true,
    sameSite: "strict",
    maxAge: 8 * 60 * 60 * 1000
  }
});

const csrfMiddleware = csrf();

module.exports = {
  corsMiddleware,
  helmetMiddleware,
  apiRateLimiter,
  authRateLimiter,
  sessionMiddleware,
  csrfMiddleware
};

const dotenv = require("dotenv");

dotenv.config();

const requiredEnvVars = [
  "PORT",
  "NODE_ENV",
  "DB_URL",
  "JWT_SECRET",
  "JWT_REFRESH_SECRET",
  "SESSION_SECRET",
  "CORS_ORIGINS"
];

const missing = requiredEnvVars.filter((name) => !process.env[name]);

if (missing.length > 0) {
  throw new Error(`Missing required environment variables: ${missing.join(", ")}`);
}

module.exports = {
  env: {
    PORT: Number(process.env.PORT),
    NODE_ENV: process.env.NODE_ENV,
    DB_URL: process.env.DB_URL,
    DB_SSL: process.env.DB_SSL || "true",
    DB_SSL_REJECT_UNAUTHORIZED: process.env.DB_SSL_REJECT_UNAUTHORIZED || "false",
    JWT_SECRET: process.env.JWT_SECRET,
    JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET,
    SESSION_SECRET: process.env.SESSION_SECRET,
    CORS_ORIGINS: process.env.CORS_ORIGINS,
    TRUST_PROXY: process.env.TRUST_PROXY || "true"
  }
};

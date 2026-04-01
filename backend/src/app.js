const express = require("express");
const healthRoutes = require("./routes/health.route");
const {
  corsMiddleware,
  helmetMiddleware,
  apiRateLimiter,
  sessionMiddleware,
  csrfMiddleware
} = require("./middlewares/security");

const app = express();

app.disable("x-powered-by");
app.set("trust proxy", 1);
app.use(helmetMiddleware);
app.use(corsMiddleware);
app.use(express.json({ limit: "100kb" }));
app.use(express.urlencoded({ extended: false, limit: "100kb" }));
app.use(apiRateLimiter);
app.use(sessionMiddleware);

// CSRF token endpoint for browser clients using cookie auth/session.
app.get("/api/v1/csrf-token", csrfMiddleware, (req, res) => {
  res.status(200).json({ csrfToken: req.csrfToken() });
});

app.use("/api/v1", healthRoutes);

app.use((error, _req, res, _next) => {
  const status = error.status || 500;
  const message = status === 500 ? "Internal server error" : error.message;

  res.status(status).json({ error: message });
});

module.exports = app;

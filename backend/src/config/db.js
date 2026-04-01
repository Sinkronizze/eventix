const { Pool } = require("pg");
const { env } = require("./env");

const useSsl = env.DB_SSL === "true";

const pool = new Pool({
  connectionString: env.DB_URL,
  ssl: useSsl
    ? { rejectUnauthorized: env.DB_SSL_REJECT_UNAUTHORIZED === "true" }
    : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
  statement_timeout: 10000,
  query_timeout: 10000,
  application_name: "eventix-backend"
});

pool.on("error", (error) => {
  // Fail loudly so stale clients never continue in an unsafe state.
  console.error("Unexpected idle PG client error", error);
  process.exit(1);
});

async function query(text, params) {
  return pool.query(text, params);
}

async function assertDatabaseConnection() {
  await pool.query("SELECT 1");
}

module.exports = {
  pool,
  query,
  assertDatabaseConnection
};

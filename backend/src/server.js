const app = require("./app");
const { env } = require("./config/env");
const { assertDatabaseConnection } = require("./config/db");

async function startServer() {
  try {
    await assertDatabaseConnection();

    app.listen(env.PORT, () => {
      console.log(`Eventix backend listening on port ${env.PORT}`);
    });
  } catch (error) {
    console.error("Failed to boot backend", error);
    process.exit(1);
  }
}

startServer();

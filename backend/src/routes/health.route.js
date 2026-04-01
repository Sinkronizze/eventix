const express = require("express");
const { assertDatabaseConnection } = require("../config/db");

const router = express.Router();

router.get("/health", async (_req, res, next) => {
  try {
    await assertDatabaseConnection();
    res.status(200).json({ status: "ok" });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

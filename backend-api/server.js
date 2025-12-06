const express = require("express");
const app = express();
const PORT = 3001;

// Simple status endpoint
app.get("/api/status", (req, res) => {
  res.json({
    timestamp: new Date().toISOString(),
    instanceId: process.env.INSTANCE_ID || "unknown",
    message: "Hello from EC2 on LocalStack!",
  });
});

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`API server running on port ${PORT}`);
  console.log(`Instance ID: ${process.env.INSTANCE_ID || "unknown"}`);
});

const express = require("express");
const cors = require("cors");
const app = express();
const PORT = process.env.PORT || 3001;

// Enable CORS for all routes
app.use(
  cors({
    origin: true, // Allow all origins for development
    credentials: true,
  })
);

// Simple status endpoint
app.get("/api/status", (req, res) => {
  res.json({
    timestamp: new Date().toISOString(),
    instanceId:
      process.env.EC2_INSTANCE_ID ||
      process.env.INSTANCE_ID ||
      "docker-container",
    environment: process.env.NODE_ENV || "development",
    branch: process.env.BRANCH_NAME || "unknown",
    message: "Hello from EC2 Docker container on LocalStack!",
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

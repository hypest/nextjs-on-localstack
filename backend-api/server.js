const express = require("express");
const cors = require("cors");
const app = express();

// Enable CORS for all routes
app.use(
  cors({
    origin: true, // Allow all origins for development
    credentials: true,
  })
);

app.use(express.json());

// Simple status endpoint
app.get("/api/status", (req, res) => {
  res.json({
    timestamp: new Date().toISOString(),
    instanceId:
      process.env.EC2_INSTANCE_ID ||
      process.env.INSTANCE_ID ||
      process.env.AWS_LAMBDA_FUNCTION_NAME ||
      "docker-container",
    environment: process.env.NODE_ENV || "development",
    executionContext: process.env.AWS_LAMBDA_FUNCTION_NAME ? "lambda" : "container",
    message: "Hello from LocalStack backend!",
  });
});

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

// Export app for Lambda handler
module.exports = app;

// Only start server if running directly (not in Lambda)
if (require.main === module) {
  const PORT = process.env.PORT || 3001;
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`API server running on port ${PORT}`);
    console.log(`Instance ID: ${process.env.INSTANCE_ID || "unknown"}`);
  });
}

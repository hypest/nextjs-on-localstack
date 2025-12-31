import { useState, useEffect } from "react";

export default function StatusDisplay() {
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    // Get API endpoint from environment variable (set at build time)
    const apiEndpoint =
      process.env.NEXT_PUBLIC_API_ENDPOINT ||
      "http://localhost:3001/api/status";

    fetch(apiEndpoint)
      .then((response) => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
      })
      .then((data) => {
        setStatus(data);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message);
        setLoading(false);
      });
  }, []);

  if (loading) {
    return (
      <div style={styles.container}>
        <h2>Backend Status</h2>
        <p>Loading...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div style={styles.container}>
        <h2>Backend Status</h2>
        <p style={styles.error}>Error: {error}</p>
        <p style={styles.hint}>
          Make sure the EC2 instance is running and accessible.
        </p>
      </div>
    );
  }

  return (
    <div style={styles.container}>
      <h2>Backend Status</h2>
      <div style={styles.statusCard}>
        <p>
          <strong>Instance ID:</strong> {status.instanceId}
        </p>
        <p>
          <strong>Timestamp:</strong>{" "}
          {new Date(status.timestamp).toLocaleString()}
        </p>
        <p>
          <strong>Message:</strong> {status.message}
        </p>
      </div>
    </div>
  );
}

const styles = {
  container: {
    marginTop: "2rem",
    padding: "1.5rem",
    border: "1px solid #ddd",
    borderRadius: "8px",
    backgroundColor: "#f9f9f9",
  },
  statusCard: {
    marginTop: "1rem",
    padding: "1rem",
    backgroundColor: "#fff",
    borderRadius: "4px",
    border: "1px solid #e0e0e0",
  },
  error: {
    color: "#d32f2f",
    fontWeight: "bold",
  },
  hint: {
    fontSize: "0.9rem",
    color: "#666",
    fontStyle: "italic",
  },
};

FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy server code
COPY . .

# Expose ports
# 9050: ENet (placeholder — actual ENet needs native lib)
# 9051: WebSocket
# 9052: HTTP REST API
EXPOSE 9051 9052

# Create database directory
RUN mkdir -p database

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:9052/api/hello')"

# Run server
CMD ["python", "server.py"]

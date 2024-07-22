# Build stage
FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y curl

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Runtime stage
FROM ubuntu:22.04

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    fonts-roboto \
    && rm -rf /var/lib/apt/lists/*

# Copy Ollama from the builder stage
COPY --from=builder /usr/local/bin/ollama /usr/local/bin/ollama

# Set up a directory for our web application
WORKDIR /app

# Copy the web application files
COPY index.html script.js styles.css ./

# Install a simple HTTP server
RUN npm install -g http-server

# Expose ports for Ollama API and web server
EXPOSE 11434 8080

# Start Ollama and the web server
CMD ollama serve & http-server -p 8080
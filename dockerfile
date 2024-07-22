# Use Ubuntu as the base image
FROM ubuntu:22.04

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    nodejs \
    npm \
    fonts-roboto

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Set up a directory for our web application
WORKDIR /app

# Copy the HTML and JavaScript files
COPY index.html .
COPY script.js .
COPY styles.css .

# Install a simple HTTP server
RUN npm install -g http-server

# Expose ports for Ollama API and web server
EXPOSE 11434 8080

# Start Ollama and the web server
CMD ollama serve & http-server -p 8080
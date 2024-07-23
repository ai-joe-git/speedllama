#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to print messages
print_message() {
    echo ">>> $1"
}

# Create project directory
print_message "Creating SpeedLLama project directory..."
mkdir SpeedLLama
cd SpeedLLama

# Initialize npm project and install dependencies
print_message "Initializing npm project and installing dependencies..."
npm init -y > /dev/null
npm install express > /dev/null

# Create public directory
print_message "Creating public directory..."
mkdir -p public

# Download index.html
print_message "Downloading index.html..."
curl -s -o public/index.html https://raw.githubusercontent.com/ai-joe-git/speedllama/main/public/index.html

# Create server.js
print_message "Creating server.js..."
cat << EOF > server.js
const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  const indexPath = path.join(__dirname, 'public', 'index.html');
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(500).send('Error: index.html not found');
  }
});

app.listen(port, () => {
  console.log(\`SpeedLLama server running at http://localhost:\${port}\`);
});
EOF

# Start the server
print_message "Starting the SpeedLLama server..."
node server.js

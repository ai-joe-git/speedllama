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

# Create public directory if it doesn't exist
print_message "Creating public directory if it doesn't exist..."
mkdir -p public

# Check if index.html exists
if [ ! -f public/index.html ]; then
    print_message "Warning: index.html not found in public folder. Please ensure it exists before running the server."
fi

# Create server.js
print_message "Creating server.js..."
cat << EOF > server.js
const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(port, () => {
  console.log(\`SpeedLLama server running at http://localhost:\${port}\`);
});
EOF

# Start the server
print_message "Starting the SpeedLLama server..."
node server.js

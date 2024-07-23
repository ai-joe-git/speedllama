#!/bin/bash

# Function to print messages
print_message() {
    echo ">>> $1"
}

# Create a temporary directory
temp_dir=$(mktemp -d)
cd "$temp_dir"

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    print_message "Ollama is not installed. Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh 
else
    print_message "Ollama is installed. Starting Ollama server..."
    ollama serve
fi

# Download the installation script
print_message "Downloading SpeedLLama installation script..."
curl -s -O https://raw.githubusercontent.com/ai-joe-git/speedllama/main/public/install_speedllama.sh

# Make the script executable
print_message "Making the installation script executable..."
chmod +x install_speedllama.sh

# Run the installation script
print_message "Running the SpeedLLama installation script..."
./install_speedllama.sh

# Clean up
cd ..
rm -rf "$temp_dir"

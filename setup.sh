#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update package list and install necessary dependencies
echo "Updating package list and installing dependencies..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Install Docker if not already installed
if ! command_exists docker; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install Docker Compose if not already installed
if ! command_exists docker-compose; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Install Python3 and pip if not already installed
if ! command_exists python3; then
    echo "Installing Python3 and pip..."
    sudo apt-get install -y python3 python3-pip
fi

# Create project structure
mkdir -p backend frontend models

# Create a Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required Python packages
pip install fastapi uvicorn pydantic llama-cpp-python

# Create backend.py
cat > backend/backend.py << EOL
import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from llama_cpp import Llama
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

models_dir = os.getenv('MODELS_DIR', 'models')
initialized_models = {}

class ChatRequest(BaseModel):
    message: str
    model: str

class ChatResponse(BaseModel):
    response: str

@app.get("/models")
async def get_models():
    try:
        models = [f for f in os.listdir(models_dir) if f.endswith('.gguf')]
        return models
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        model_path = os.path.join(models_dir, request.model)
        
        if not os.path.exists(model_path):
            raise HTTPException(status_code=400, detail="Selected model not found")
        
        if request.model not in initialized_models:
            initialized_models[request.model] = Llama(model_path=model_path, n_ctx=2048, n_threads=4)
        
        llm = initialized_models[request.model]
        
        output = llm(
            request.message,
            max_tokens=100,
            stop=["Human:", "\n"],
            echo=False
        )
        
        response_text = output['choices'][0]['text'].strip()
        
        return ChatResponse(response=response_text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOL

# Create Dockerfile
cat > backend/Dockerfile << EOL
FROM python:3.9-slim

WORKDIR /app

COPY . /app

# Create and activate virtual environment in the container
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir fastapi uvicorn pydantic llama-cpp-python

EXPOSE 8000

CMD ["uvicorn", "backend:app", "--host", "0.0.0.0", "--port", "8000"]
EOL

# Create frontend/index.html
cat > frontend/index.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SpeedLLama</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f0f0f0; }
        .chat-container { width: 80%; max-width: 800px; background-color: white; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); overflow: hidden; }
        .chat-messages { height: 400px; overflow-y: auto; padding: 20px; }
        .message { margin-bottom: 10px; padding: 10px; border-radius: 5px; }
        .user-message { background-color: #e6f2ff; text-align: right; }
        .ai-message { background-color: #f0f0f0; }
        .input-area { display: flex; padding: 20px; }
        #user-input { flex-grow: 1; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
        #send-button { padding: 10px 20px; background-color: #4CAF50; color: white; border: none; border-radius: 5px; margin-left: 10px; cursor: pointer; }
        #model-selector { margin-bottom: 10px; padding: 5px; }
    </style>
</head>
<body>
    <div class="chat-container">
        <select id="model-selector"></select>
        <div class="chat-messages" id="chat-messages"></div>
        <div class="input-area">
            <input type="text" id="user-input" placeholder="Type your message...">
            <button id="send-button">Send</button>
        </div>
    </div>

    <script>
        const chatMessages = document.getElementById('chat-messages');
        const userInput = document.getElementById('user-input');
        const sendButton = document.getElementById('send-button');
        const modelSelector = document.getElementById('model-selector');

        // Fetch available models
        fetch('http://localhost:8000/models')
            .then(response => response.json())
            .then(models => {
                models.forEach(model => {
                    const option = document.createElement('option');
                    option.value = model;
                    option.textContent = model;
                    modelSelector.appendChild(option);
                });
            });

        function addMessage(message, isUser = false) {
            const messageElement = document.createElement('div');
            messageElement.classList.add('message');
            messageElement.classList.add(isUser ? 'user-message' : 'ai-message');
            messageElement.textContent = message;
            chatMessages.appendChild(messageElement);
            chatMessages.scrollTop = chatMessages.scrollHeight;
        }

        function sendMessage() {
            const message = userInput.value.trim();
            if (message) {
                addMessage(message, true);
                userInput.value = '';

                fetch('http://localhost:8000/chat', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        message: message,
                        model: modelSelector.value
                    }),
                })
                .then(response => response.json())
                .then(data => {
                    addMessage(data.response);
                })
                .catch((error) => {
                    console.error('Error:', error);
                    addMessage('Error: Unable to get response from the server.');
                });
            }
        }

        sendButton.addEventListener('click', sendMessage);
        userInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                sendMessage();
            }
        });
    </script>
</body>
</html>
EOL

# Create docker-compose.yml
cat > docker-compose.yml << EOL
version: '3'
services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    volumes:
      - ./models:/app/models
    environment:
      - MODELS_DIR=/app/models

  frontend:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./frontend:/usr/share/nginx/html
EOL

# Download the dolphin-2.9.3-qwen2-0.5b GGUF model
echo "Downloading dolphin-2.9.3-qwen2-0.5b GGUF model..."
curl -L "https://huggingface.co/mradermacher/dolphin-2.9.3-qwen2-0.5b-GGUF/resolve/main/dolphin-2.9.3-qwen2-0.5b.Q5_K_M.gguf?download=true" -o models/dolphin-2.9.3-qwen2-0.5b.Q5_K_M.gguf

# Build and start the Docker containers
echo "Building and starting Docker containers..."
docker-compose up --build -d

echo "Setup complete! Your local ChatGPT clone is now running."
echo "Frontend: http://localhost:8080"
echo "Backend: http://localhost:8000"

# Deactivate the virtual environment
deactivate

echo "Note: You may need to log out and log back in for Docker to work without sudo."

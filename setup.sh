#!/bin/bash

# Make this script executable
chmod +x "$0"

# Exit immediately if a command exits with a non-zero status
set -e

# Update and install system dependencies
echo "Updating system and installing dependencies..."
sudo apt update
sudo apt install -y build-essential cmake gcc g++ python3-dev python3-pip git curl

# Upgrade pip and install Python dependencies
echo "Upgrading pip and installing Python dependencies..."
pip install --upgrade pip setuptools wheel
pip install fastapi uvicorn pydantic

# Install llama-cpp-python with specific flags
echo "Installing llama-cpp-python..."
CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" pip install llama-cpp-python --no-cache-dir

# Create project structure
mkdir -p backend frontend models

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

# Create an updated Dockerfile
cat > backend/Dockerfile << EOL
FROM python:3.9-slim

WORKDIR /app

COPY . /app

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    gcc \
    g++ \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir fastapi uvicorn pydantic
RUN CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" pip install --no-cache-dir llama-cpp-python

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
        .chat-container { width: 80%; max-width: 600px; background-color: white; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.1); overflow: hidden; }
        .chat-header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
        .chat-messages { height: 300px; overflow-y: auto; padding: 20px; }
        .message { margin-bottom: 10px; }
        .user-message { text-align: right; }
        .bot-message { text-align: left; }
        .message-content { display: inline-block; padding: 8px 12px; border-radius: 20px; max-width: 70%; }
        .user-message .message-content { background-color: #4CAF50; color: white; }
        .bot-message .message-content { background-color: #f1f0f0; }
        .chat-input { display: flex; padding: 20px; }
        #user-input { flex-grow: 1; padding: 10px; border: 1px solid #ddd; border-radius: 4px; margin-right: 10px; }
        #send-button { padding: 10px 20px; background-color: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer; }
        #model-selector { margin-bottom: 10px; padding: 10px; width: 100%; }
    </style>
</head>
<body>
    <div class="chat-container">
        <div class="chat-header">
            <h2>SpeedLLama Chat</h2>
        </div>
        <select id="model-selector"></select>
        <div class="chat-messages" id="chat-messages"></div>
        <div class="chat-input">
            <input type="text" id="user-input" placeholder="Type your message...">
            <button id="send-button">Send</button>
        </div>
    </div>
    <script>
        const chatMessages = document.getElementById('chat-messages');
        const userInput = document.getElementById('user-input');
        const sendButton = document.getElementById('send-button');
        const modelSelector = document.getElementById('model-selector');

        function addMessage(content, isUser = false) {
            const messageDiv = document.createElement('div');
            messageDiv.className = isUser ? 'message user-message' : 'message bot-message';
            messageDiv.innerHTML = \`<span class="message-content">\${content}</span>\`;
            chatMessages.appendChild(messageDiv);
            chatMessages.scrollTop = chatMessages.scrollHeight;
        }

        async function sendMessage() {
            const message = userInput.value.trim();
            if (message) {
                addMessage(message, true);
                userInput.value = '';

                try {
                    const response = await fetch('http://localhost:8000/chat', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({
                            message: message,
                            model: modelSelector.value
                        }),
                    });

                    if (!response.ok) {
                        throw new Error('Network response was not ok');
                    }

                    const data = await response.json();
                    addMessage(data.response);
                } catch (error) {
                    console.error('Error:', error);
                    addMessage('Sorry, there was an error processing your request.');
                }
            }
        }

        sendButton.addEventListener('click', sendMessage);
        userInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                sendMessage();
            }
        });

        async function loadModels() {
            try {
                const response = await fetch('http://localhost:8000/models');
                const models = await response.json();
                modelSelector.innerHTML = models.map(model => \`<option value="\${model}">\${model}</option>\`).join('');
            } catch (error) {
                console.error('Error loading models:', error);
            }
        }

        loadModels();
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
  frontend:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./frontend:/usr/share/nginx/html
EOL

# Download the dolphin-2.9.3-qwen2-0.5b GGUF model
echo "Downloading dolphin-2.9.3-qwen2-0.5b GGUF model..."
curl -L "https://huggingface.co/mradermacher/dolphin-2.9.3-qwen2-0.5b-GGUF/resolve/main/dolphin-2.9.3-qwen2-0.5b.Q4_K_M.gguf" -o models/dolphin-2.9.3-qwen2-0.5b.Q4_K_M.gguf

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "Please log out and log back in to use Docker without sudo."
fi

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

echo "Building and starting Docker containers..."
docker-compose up --build -d

echo "Setup complete! You can access the application at http://localhost:8080"

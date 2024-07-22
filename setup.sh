#!/bin/bash

# Make this script executable
chmod +x "$0"

# Exit immediately if a command exits with a non-zero status
set -e

# Create project structure
mkdir -p backend frontend models

# Create backend.py
cat > backend/backend.py << EOL
import os
import logging
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from llama_cpp import Llama
from fastapi.middleware.cors import CORSMiddleware

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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
        logger.error(f"Error getting models: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        model_path = os.path.join(models_dir, request.model)
        
        if not os.path.exists(model_path):
            logger.error(f"Selected model not found: {request.model}")
            raise HTTPException(status_code=400, detail="Selected model not found")
        
        if request.model not in initialized_models:
            logger.info(f"Initializing model: {request.model}")
            initialized_models[request.model] = Llama(model_path=model_path, n_ctx=2048, n_threads=4)
        
        llm = initialized_models[request.model]
        
        logger.info(f"Generating response for message: {request.message}")
        output = llm(
            request.message,
            max_tokens=500,
            stop=["Human:", "\n"],
            echo=False
        )
        
        response_text = output['choices'][0]['text'].strip()
        logger.info(f"Generated response: {response_text}")
        
        return ChatResponse(response=response_text)
    except Exception as e:
        logger.error(f"Error in chat: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOL

# Create Dockerfile
cat > backend/Dockerfile << EOL
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    && rm -rf /var/lib/apt/lists/*

COPY . /app

RUN python -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir fastapi uvicorn pydantic llama-cpp-python

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
    <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'unsafe-inline'; connect-src http://localhost:8001;">
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
        .model-select { padding: 10px; margin-bottom: 10px; }
        #loading { text-align: center; padding: 10px; display: none; }
    </style>
</head>
<body>
    <div class="chat-container">
        <select id="model-select" class="model-select">
            <option value="">Select a model</option>
        </select>
        <div class="chat-messages" id="chat-messages">
        </div>
        <div id="loading">Loading...</div>
        <div class="input-area">
            <input type="text" id="user-input" placeholder="Type your message...">
            <button id="send-button">Send</button>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const chatMessages = document.getElementById('chat-messages');
            const userInput = document.getElementById('user-input');
            const sendButton = document.getElementById('send-button');
            const modelSelect = document.getElementById('model-select');
            const loadingIndicator = document.getElementById('loading');

            async function fetchModels() {
                try {
                    const response = await fetch('http://localhost:8001/models');
                    if (!response.ok) {
                        throw new Error('Failed to fetch models');
                    }
                    const models = await response.json();
                    models.forEach(model => {
                        const option = document.createElement('option');
                        option.value = model;
                        option.textContent = model;
                        modelSelect.appendChild(option);
                    });
                } catch (error) {
                    console.error('Error fetching models:', error);
                    addMessage('Failed to load models. Please try again later.', false);
                }
            }

            fetchModels();

            function addMessage(content, isUser) {
                const messageDiv = document.createElement('div');
                messageDiv.classList.add('message');
                messageDiv.classList.add(isUser ? 'user-message' : 'ai-message');
                
                const paragraphs = content.split('\n');
                paragraphs.forEach(paragraph => {
                    const p = document.createElement('p');
                    p.textContent = paragraph;
                    messageDiv.appendChild(p);
                });
                
                chatMessages.appendChild(messageDiv);
                chatMessages.scrollTop = chatMessages.scrollHeight;
            }

            async function sendMessage() {
                const message = userInput.value.trim();
                const selectedModel = modelSelect.value;

                if (!selectedModel) {
                    addMessage('Please select a model first.', false);
                    return;
                }

                if (message) {
                    addMessage(message, true);
                    userInput.value = '';
                    loadingIndicator.style.display = 'block';
                    
                    try {
                        const response = await fetch('http://localhost:8001/chat', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                            },
                            body: JSON.stringify({ 
                                message: message,
                                model: selectedModel
                            }),
                        });
                        
                        if (!response.ok) {
                            throw new Error('Network response was not ok');
                        }
                        
                        const data = await response.json();
                        addMessage(data.response, false);
                    } catch (error) {
                        console.error('Error:', error);
                        addMessage('Sorry, there was an error processing your request.', false);
                    } finally {
                        loadingIndicator.style.display = 'none';
                    }
                }
            }

            sendButton.addEventListener('click', sendMessage);
            userInput.addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    sendMessage();
                }
            });
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
      - "8001:8000"
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

# Create a virtual environment
python3 -m venv speedllama_env

# Activate the virtual environment
source speedllama_env/bin/activate

# Upgrade pip and install dependencies in the virtual environment
pip install --upgrade pip
pip install fastapi uvicorn pydantic llama-cpp-python

# Check if the GGUF model file already exists
MODEL_FILE="models/dolphin-2.9.3-qwen2-0.5b.Q5_K_M.gguf"
if [ -f "$MODEL_FILE" ]; then
    echo "GGUF model file already exists. Skipping download."
else
    # Download the dolphin-2.9.3-qwen2-0.5b GGUF model
    echo "Downloading dolphin-2.9.3-qwen2-0.5b GGUF model..."
    if ! curl -L "https://huggingface.co/mradermacher/dolphin-2.9.3-qwen2-0.5b-GGUF/resolve/main/dolphin-2.9.3-qwen2-0.5b.Q5_K_M.gguf?download=true" -o "$MODEL_FILE"; then
        echo "Failed to download the model. Please check your internet connection and try again."
        exit 1
    fi
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null
then
    echo "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Build and start the Docker containers
echo "Building and starting Docker containers..."
docker-compose up --build -d

# Function to wait for the backend to be ready
wait_for_backend() {
    echo "Waiting for the backend to be ready..."
    while ! curl -s http://localhost:8001/models > /dev/null; do
        sleep 1
    done
    echo "Backend is ready!"
}

# Wait for the backend to be ready
wait_for_backend

echo "Setup complete! Your local ChatGPT clone is now running."
echo "Frontend: http://localhost:8080"
echo "Backend: http://localhost:8001"

# Deactivate the virtual environment
deactivate

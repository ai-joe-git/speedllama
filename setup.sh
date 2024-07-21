#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

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

# Create Dockerfile
cat > backend/Dockerfile << EOL
FROM python:3.9-slim

WORKDIR /app

COPY . /app

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
        .model-select { padding: 10px; margin-bottom: 10px; }
    </style>
</head>
<body>
    <div class="chat-container">
        <select id="model-select" class="model-select">
            <option value="">Select a model</option>
        </select>
        <div class="chat-messages" id="chat-messages">
        </div>
        <div class="input-area">
            <input type="text" id="user-input" placeholder="Type your message...">
            <button id="send-button">Send</button>
        </div>
    </div>

    <script>
        const chatMessages = document.getElementById('chat-messages');
        const userInput = document.getElementById('user-input');
        const sendButton = document.getElementById('send-button');
        const modelSelect = document.getElementById('model-select');

        async function fetchModels() {
            try {
                const response = await fetch('http://localhost:8000/models');
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
            messageDiv.textContent = content;
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
                
                try {
                    const response = await fetch('http://localhost:8000/chat', {
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
                }
            }
        }

        sendButton.addEventListener('click', sendMessage);
        userInput.addEventListener('keypress', (e) => {
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

# Check and download the dolphin-2.9.3-qwen2-0.5b GGUF model if not present
MODEL_FILE="models/dolphin-2.9.3-qwen2-0.5b.Q5_K_M.gguf"
if [ ! -f "$MODEL_FILE" ]; then
    echo "Downloading dolphin-2.9.3-qwen2-0.5b GGUF model..."
    curl -L "https://huggingface.co/mradermacher/dolphin-2.9.3-qwen2-0.5b-GGUF/resolve/main/dolphin-2.9.3-qwen2-0.5b.Q5_K_M.gguf?download=true" -o "$MODEL_FILE"
    echo "Download complete."
else
    echo "GGUF model file already exists. Skipping download."
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

echo "Setup complete! Your local ChatGPT clone is now running."
echo "Frontend: http://localhost:8080"
echo "Backend: http://localhost:8000"

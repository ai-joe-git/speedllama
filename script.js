const chatContainer = document.getElementById('chat-container');
const userInput = document.getElementById('user-input');
const sendButton = document.getElementById('send-button');
const modelSelect = document.getElementById('model-select');
const modelInput = document.getElementById('model-input');
const pullModelButton = document.getElementById('pull-model');

let currentModel = '';

sendButton.addEventListener('click', sendMessage);
userInput.addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
        sendMessage();
    }
});
pullModelButton.addEventListener('click', pullModel);

// Fetch available models on page load
fetchAvailableModels();

function sendMessage() {
    const message = userInput.value.trim();
    if (message && currentModel) {
        appendMessage('User', message);
        userInput.value = '';
        fetchOllamaResponse(message);
    } else if (!currentModel) {
        appendMessage('System', 'Please select a model first.');
    }
}

function appendMessage(sender, message) {
    const messageElement = document.createElement('div');
    messageElement.classList.add('message', sender.toLowerCase() + '-message');
    messageElement.textContent = `${sender}: ${message}`;
    chatContainer.appendChild(messageElement);
    chatContainer.scrollTop = chatContainer.scrollHeight;
}

async function fetchOllamaResponse(message) {
    try {
        const response = await fetch('http://localhost:11434/api/generate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: currentModel,
                prompt: message,
            }),
        });

        if (!response.ok) {
            throw new Error('Network response was not ok');
        }

        const data = await response.json();
        appendMessage('Ollama', data.response);
    } catch (error) {
        console.error('Error:', error);
        appendMessage('System', 'Error: Unable to fetch response from Ollama.');
    }
}

async function fetchAvailableModels() {
    try {
        const response = await fetch('http://localhost:11434/api/tags');
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        const data = await response.json();
        updateModelSelect(data.models);
    } catch (error) {
        console.error('Error fetching models:', error);
        appendMessage('System', 'Error: Unable to fetch available models.');
    }
}

function updateModelSelect(models) {
    modelSelect.innerHTML = '<option value="">Select a model</option>';
    models.forEach(model => {
        const option = document.createElement('option');
        option.value = model.name;
        option.textContent = model.name;
        modelSelect.appendChild(option);
    });

    modelSelect.addEventListener('change', function() {
        currentModel = this.value;
        if (currentModel) {
            appendMessage('System', `Model changed to ${currentModel}`);
        }
    });
}

async function pullModel() {
    const modelName = modelInput.value.trim();
    if (modelName) {
        try {
            appendMessage('System', `Pulling model: ${modelName}`);
            const response = await fetch('http://localhost:11434/api/pull', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ name: modelName }),
            });

            if (!response.ok) {
                throw new Error('Network response was not ok');
            }

            appendMessage('System', `Model ${modelName} pulled successfully`);
            fetchAvailableModels();
        } catch (error) {
            console.error('Error pulling model:', error);
            appendMessage('System', `Error: Unable to pull model ${modelName}`);
        }
    }
}
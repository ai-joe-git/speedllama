let OLLAMA_API_URL = '/api';

document.addEventListener('DOMContentLoaded', () => {
    const apiUrlInput = document.getElementById('api-url');
    const updateApiButton = document.getElementById('update-api');
    const modelSelect = document.getElementById('model-select');
    const customModelInput = document.getElementById('custom-model');
    const pullModelButton = document.getElementById('pull-model');
    const chatInput = document.getElementById('chat-input');
    const sendMessageButton = document.getElementById('send-message');
    const chatOutput = document.getElementById('chat-output');

    updateApiButton.addEventListener('click', updateApiUrl);
    pullModelButton.addEventListener('click', pullModel);
    sendMessageButton.addEventListener('click', sendMessage);

    refreshModelList();

    function updateApiUrl() {
        OLLAMA_API_URL = apiUrlInput.value;
        refreshModelList();
    }

    async function refreshModelList() {
        try {
            const response = await fetch(`${OLLAMA_API_URL}/tags`);
            if (!response.ok) throw new Error('Failed to fetch models');
            const data = await response.json();
            modelSelect.innerHTML = '<option value="">Select a model</option>';
            data.models.forEach(model => {
                const option = document.createElement('option');
                option.value = model.name;
                option.textContent = model.name;
                modelSelect.appendChild(option);
            });
        } catch (error) {
            console.error('Error fetching models:', error);
            chatOutput.innerHTML += `<p>System: Error fetching available models. ${error.message}</p>`;
        }
    }

    async function pullModel() {
        const modelName = modelSelect.value || customModelInput.value;
        if (!modelName) {
            chatOutput.innerHTML += '<p>System: Please select or enter a model name.</p>';
            return;
        }
        try {
            const response = await fetch(`${OLLAMA_API_URL}/pull`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name: modelName }),
            });
            if (!response.ok) throw new Error('Failed to pull model');
            chatOutput.innerHTML += `<p>System: Model ${modelName} pulled successfully.</p>`;
            refreshModelList();
        } catch (error) {
            console.error('Error pulling model:', error);
            chatOutput.innerHTML += `<p>System: Error pulling model. ${error.message}</p>`;
        }
    }

    async function sendMessage() {
        const modelName = modelSelect.value || customModelInput.value;
        const message = chatInput.value;
        if (!modelName || !message) {
            chatOutput.innerHTML += '<p>System: Please select a model and enter a message.</p>';
            return;
        }
        try {
            chatOutput.innerHTML += `<p><strong>You:</strong> ${message}</p>`;
            chatInput.value = '';
            const response = await fetch(`${OLLAMA_API_URL}/generate`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ model: modelName, prompt: message }),
            });
            if (!response.ok) throw new Error('Failed to generate response');
            const data = await response.json();
            chatOutput.innerHTML += `<p><strong>AI:</strong> ${data.response}</p>`;
        } catch (error) {
            console.error('Error sending message:', error);
            chatOutput.innerHTML += `<p>System: Error generating response. ${error.message}</p>`;
        }
    }
});
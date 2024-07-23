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
mkdir public

# Create index.html
print_message "Creating index.html..."
cat << EOF > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SpeedLLama</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #8e44ad, #3498db);
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            overflow: hidden;
        }

        .chat-container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 30px;
            width: 90%;
            max-width: 800px;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
            transition: all 0.3s ease;
        }

        .chat-title {
            text-align: center;
            color: #fff;
            font-size: 28px;
            margin-bottom: 20px;
        }

        .input-group {
            margin-bottom: 15px;
        }

        input, select, button {
            width: 100%;
            padding: 12px;
            border-radius: 10px;
            border: none;
            background: rgba(255, 255, 255, 0.2);
            color: #ffffff;
            transition: all 0.3s ease;
        }

        input::placeholder, select {
            color: rgba(255, 255, 255, 0.7);
        }

        button {
            background: rgba(52, 152, 219, 0.7);
            cursor: pointer;
            font-weight: bold;
        }

        button:hover {
            background: rgba(52, 152, 219, 0.9);
        }

        .chat-area {
            height: 300px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 15px;
            overflow-y: auto;
            color: #fff;
        }

        .send-button {
            background: rgba(46, 204, 113, 0.7);
        }

        .send-button:hover {
            background: rgba(46, 204, 113, 0.9);
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .chat-container, .input-group, .chat-area {
            animation: fadeIn 0.5s ease-out;
        }

        .message {
            margin-bottom: 10px;
            padding: 5px;
            border-radius: 5px;
            background: rgba(255, 255, 255, 0.1);
        }

        .user-message {
            text-align: right;
            background: rgba(52, 152, 219, 0.3);
        }

        .assistant-message {
            text-align: left;
            background: rgba(46, 204, 113, 0.3);
        }

        .code-block {
            position: relative;
            background-color: #282c34;
            border-radius: 5px;
            padding: 10px;
            margin: 10px 0;
            font-family: 'Courier New', monospace;
            white-space: pre-wrap;
            word-wrap: break-word;
        }

        .code-block code {
            color: #abb2bf;
        }

        .copy-button {
            position: absolute;
            top: 5px;
            right: 5px;
            background-color: #4CAF50;
            border: none;
            color: white;
            padding: 5px 10px;
            text-align: center;
            text-decoration: none;
            display: inline-block;
            font-size: 12px;
            margin: 4px 2px;
            cursor: pointer;
            border-radius: 3px;
            width: 150px;
            height: 45px;
        }

        .copy-button:hover {
            background-color: #45a049;
        }

        .copy-button:active {
            background-color: #3e8e41;
        }

        .html-preview {
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 10px;
            margin: 10px 0;
            background-color: white;
            overflow: auto;
            max-height: 300px;
        }

        .html-preview-toggle {
            background-color: #4CAF50;
            border: none;
            color: white;
            padding: 5px 10px;
            text-align: center;
            text-decoration: none;
            display: inline-block;
            font-size: 12px;
            margin: 4px 2px;
            cursor: pointer;
            border-radius: 3px;
        }
    </style>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/highlight.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/styles/atom-one-dark.min.css">
</head>
<body>
    <div class="chat-container">
        <h1 class="chat-title">SpeedLLama</h1>
        <div class="input-group">
            <input type="text" id="api-url" placeholder="API URL" value="http://localhost:11434">
            <button onclick="updateAPI()">Update API URL</button>
        </div>
        <div class="input-group">
            <select id="model-select" onchange="selectModel(this.value)"></select>
            <input type="text" id="model-name" placeholder="Enter model name to pull">
            <button onclick="pullModel()">Pull Model</button>
        </div>
        <div class="chat-area" id="chat-messages"></div>
        <div class="input-group">
            <input type="text" id="user-input" placeholder="Type your message...">
            <button class="send-button" onclick="sendMessage()">Send</button>
        </div>
    </div>
    <script>
        let apiUrl = 'http://localhost:11434';
        let currentModel = '';
        let currentResponse = '';

        async function fetchModels() {
            try {
                const response = await fetch(`${apiUrl}/api/tags`);
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                const data = await response.json();
                const selectElement = document.getElementById('model-select');
                selectElement.innerHTML = '<option value="">Select a model</option>';
                data.models.forEach(model => {
                    const option = document.createElement('option');
                    option.value = model.name;
                    option.textContent = model.name;
                    selectElement.appendChild(option);
                });
            } catch (error) {
                console.error('Error fetching models:', error);
                addMessage('System', 'Error fetching available models. Failed to fetch models');
            }
        }

        function updateAPI() {
            const newUrl = document.getElementById('api-url').value;
            if (newUrl) {
                apiUrl = newUrl;
                addMessage('System', `API URL updated to: ${apiUrl}`);
                fetchModels();
            }
        }

        async function pullModel() {
            const modelName = document.getElementById('model-name').value;
            if (modelName) {
                try {
                    const response = await fetch(`${apiUrl}/api/pull`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ name: modelName })
                    });
                    if (!response.ok) {
                        throw new Error('Network response was not ok');
                    }
                    const data = await response.json();
                    addMessage('System', `Model ${modelName} pulled successfully`);
                    fetchModels();
                } catch (error) {
                    console.error('Error pulling model:', error);
                    addMessage('System', `Error pulling model ${modelName}`);
                }
            }
        }

        function selectModel(model) {
            currentModel = model;
            addMessage('System', `Selected model: ${currentModel}`);
        }

        async function sendMessage() {
            const userInput = document.getElementById('user-input');
            const message = userInput.value.trim();
            if (message && currentModel) {
                addMessage('User', message);
                userInput.value = '';
                currentResponse = '';

                try {
                    const response = await fetch(`${apiUrl}/api/generate`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            model: currentModel,
                            prompt: message
                        })
                    });
                    
                    const reader = response.body.getReader();
                    const decoder = new TextDecoder();

                    while (true) {
                        const { done, value } = await reader.read();
                        if (done) break;
                        
                        const chunk = decoder.decode(value, { stream: true });
                        const lines = chunk.split('\n');
                        
                        for (const line of lines) {
                            if (line.trim() !== '') {
                                try {
                                    const data = JSON.parse(line);
                                    currentResponse += data.response;
                                    updateAssistantMessage(currentResponse);
                                } catch (error) {
                                    console.error('Error parsing JSON:', error);
                                }
                            }
                        }
                    }
                } catch (error) {
                    console.error('Error sending message:', error);
                    addMessage('System', 'Error: Unable to get response from the model');
                }
            } else if (!currentModel) {
                addMessage('System', 'Please select a model first');
            }
        }

        function addMessage(sender, content) {
            const chatArea = document.getElementById('chat-messages');
            const messageElement = document.createElement('div');
            messageElement.classList.add('message');
            messageElement.classList.add(sender.toLowerCase() + '-message');
            messageElement.textContent = `${sender}: ${content}`;
            chatArea.appendChild(messageElement);
            chatArea.scrollTop = chatArea.scrollHeight;
        }

        function updateAssistantMessage(content) {
            const chatArea = document.getElementById('chat-messages');
            let assistantMessage = chatArea.querySelector('.assistant-message:last-child');
            
            if (!assistantMessage) {
                assistantMessage = document.createElement('div');
                assistantMessage.classList.add('message', 'assistant-message');
                chatArea.appendChild(assistantMessage);
            }
            
            const formattedContent = formatMessageContent(content);
            assistantMessage.innerHTML = `Assistant: ${formattedContent}`;
            chatArea.scrollTop = chatArea.scrollHeight;

            // Apply syntax highlighting to code blocks
            document.querySelectorAll('pre code').forEach((block) => {
                hljs.highlightElement(block);
            });
        }

        function formatMessageContent(content) {
            // Replace code blocks
            content = content.replace(/```(\w+)?\n([\s\S]*?)```/g, (match, language, code) => {
                const uniqueId = 'code-' + Math.random().toString(36).substr(2, 9);
                return `
                    <div class="code-block" id="${uniqueId}">
                        <button class="copy-button" onclick="copyCode('${uniqueId}')">Copy</button>
                        <pre><code class="${language || ''}">${escapeHtml(code.trim())}</code></pre>
                    </div>
                `;
            });

            // Replace inline code
            content = content.replace(/`([^`]+)`/g, '<code>$1</code>');

            // Handle HTML content
            content = content.replace(/(<\w+>[\s\S]*?<\/\w+>)/g, (match) => {
                const escapedHtml = escapeHtml(match);
                const uniqueId = 'html-' + Math.random().toString(36).substr(2, 9);
                return `
                    <div class="html-block" id="${uniqueId}">
                        <button class="html-preview-toggle" onclick="toggleHtmlPreview(this)">Toggle HTML Preview</button>
                        <button class="copy-button" onclick="copyCode('${uniqueId}')">Copy</button>
                        <div class="code-block"><pre><code class="html">${escapedHtml}</code></pre></div>
                        <div class="html-preview" style="display:none;">${match}</div>
                    </div>
                `;
            });

            return content;
        }

        function escapeHtml(unsafe) {
            return unsafe
                 .replace(/&/g, "&amp;")
                 .replace(/</g, "&lt;")
                 .replace(/>/g, "&gt;")
                 .replace(/"/g, "&quot;")
                 .replace(/'/g, "&#039;");
        }

        function toggleHtmlPreview(button) {
    const htmlBlock = button.parentElement;
    const codeBlock = htmlBlock.querySelector('.code-block');
    const htmlPreview = htmlBlock.querySelector('.html-preview');
    
    if (htmlPreview.style.display === 'none') {
        codeBlock.style.display = 'none';
        htmlPreview.style.display = 'block';
        button.textContent = 'Show HTML Code';
        
        // Create an iframe to render the HTML content
        const iframe = document.createElement('iframe');
        iframe.srcdoc = htmlPreview.innerHTML;
        iframe.style.width = '100%';
        iframe.style.height = '300px';
        iframe.style.border = 'none';
        
        // Clear the preview div and append the iframe
        htmlPreview.innerHTML = '';
        htmlPreview.appendChild(iframe);
    } else {
        codeBlock.style.display = 'block';
        htmlPreview.style.display = 'none';
        button.textContent = 'Toggle HTML Preview';
    }
}

        function copyCode(elementId) {
            const element = document.getElementById(elementId);
            let textToCopy;

            if (element.classList.contains('html-block')) {
                textToCopy = element.querySelector('.code-block code').textContent;
            } else {
                textToCopy = element.querySelector('code').textContent;
            }

            navigator.clipboard.writeText(textToCopy).then(() => {
                const copyButton = element.querySelector('.copy-button');
                const originalText = copyButton.textContent;
                copyButton.textContent = 'Copied!';
                setTimeout(() => {
                    copyButton.textContent = originalText;
                }, 2000);
            }).catch(err => {
                console.error('Failed to copy text: ', err);
            });
        }

        // Initialize
        fetchModels();

        // Allow sending message with Enter key
        document.getElementById('user-input').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                sendMessage();
            }
        });
    </script>
</body>
</html>
EOF

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
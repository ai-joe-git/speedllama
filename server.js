const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const path = require('path');

const app = express();
const port = 5500;

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Proxy API requests
app.use('/api', createProxyMiddleware({ 
    target: process.env.OLLAMA_API_URL || 'http://localhost:11434',
    changeOrigin: true,
    pathRewrite: {
        '^/api': '/'
    }
}));

app.listen(port, '0.0.0.0', () => {
    console.log(`Server running at http://localhost:${port}`);
});
<img src="tenor.gif" alt="SpeedLLama Logo" width="400" align="center">

# SpeedLLama

SpeedLLama is a fast, lightweight web interface for interacting with Ollama-based language models. It provides a user-friendly chat interface that allows users to easily communicate with various AI models through the Ollama API.

## Features

- Simple and intuitive chat interface
- Support for multiple Ollama models
- Real-time model selection and pulling
- Customizable API endpoint
- Responsive design for various screen sizes

## Installation

### Prerequisites

- Node.js (v14 or later)
- npm (usually comes with Node.js)
- Ollama installed and running on your machine or a remote server

### Steps

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/SpeedLLama.git
   cd SpeedLLama
   ```

2. Install dependencies:
   ```
   npm init -y
   npm install express
   ```

3. Create a file named `server.js` in the project root and add the following code:
   ```javascript
   const express = require('express');
   const path = require('path');
   const app = express();
   const port = process.env.PORT || 3000;

   app.use(express.static(path.join(__dirname, 'public')));

   app.get('/', (req, res) => {
     res.sendFile(path.join(__dirname, 'public', 'index.html'));
   });

   app.listen(port, () => {
     console.log(`SpeedLLama server running at http://localhost:${port}`);
   });
   ```

4. Create a `public` directory in the project root and move your `index.html` file into it.

5. Start the server:
   ```
   node server.js
   ```

6. Open your web browser and navigate to `http://localhost:3000` to use SpeedLLama.

## Usage

1. Ensure that Ollama is running on your machine or the specified remote server.
2. If Ollama is running on a different machine or port, update the API URL in the SpeedLLama interface.
3. Select a model from the dropdown or pull a new model using the provided input field.
4. Start chatting with the selected model using the message input at the bottom of the interface.

## Configuration

You can customize the default API URL by modifying the `apiUrl` variable in the `<script>` section of the `index.html` file.

## Contributing

Contributions to SpeedLLama are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgements

- This project uses the [Ollama](https://github.com/jmorganca/ollama) API for model interaction.
- Interface design inspired by modern chat applications.

```

To set up this project structure and deploy the HTML page:

1. Create a new directory for your project and navigate into it:
   ```
   mkdir SpeedLLama
   cd SpeedLLama
   ```

2. Create a `public` directory:
   ```
   mkdir public
   ```

3. Save the HTML code (the full code I provided earlier) as `index.html` in the `public` directory.

4. Create a `server.js` file in the root directory with the content provided in the README.

5. Initialize the project and install Express:
   ```
   npm init -y
   npm install express
   ```

6. Start the server:
   ```
   node server.js
   ```

Now you have a basic server setup that serves your SpeedLLama HTML page. You can access it by opening a web browser and navigating to `http://localhost:3000`.

This setup provides a simple way to deploy your SpeedLLama interface. For production environments, you might want to consider using process managers like PM2 and setting up HTTPS for secure connections.

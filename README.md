# SpeedLLama
<img src="tenor.gif" alt="SpeedLLama Logo" width="400" align="center">

SpeedLLama is a fast, lightweight web interface for interacting with Ollama-based language models. It provides a user-friendly chat interface that allows users to easily communicate with various AI models through the Ollama API.

## Features

- Simple and intuitive chat interface
- Support for multiple Ollama models
- Real-time model selection and pulling
- Customizable API endpoint
- Responsive design for various screen sizes

## Quick Installation

You can install SpeedLLama with a single command:

```bash
curl -s https://raw.githubusercontent.com/yourusername/SpeedLLama/main/speedllama_installer.sh | bash
```

This command will download and run the installation script, which will set up SpeedLLama on your system.

## Manual Installation

If you prefer to install manually or review the installation process, follow these steps:

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/SpeedLLama.git
   cd SpeedLLama
   ```

2. Run the installation script:
   ```
   chmod +x install_speedllama.sh
   ./install_speedllama.sh
   ```

## Prerequisites

- Node.js (v14 or later)
- npm (usually comes with Node.js)
- Ollama installed and running on your machine or a remote server

## Usage

1. Ensure that Ollama is running on your machine or the specified remote server.
2. Open your web browser and navigate to `http://localhost:3000` to use SpeedLLama.
3. If Ollama is running on a different machine or port, update the API URL in the SpeedLLama interface.
4. Select a model from the dropdown or pull a new model using the provided input field.
5. Start chatting with the selected model using the message input at the bottom of the interface.

## Configuration

You can customize the default API URL by modifying the `apiUrl` variable in the `<script>` section of the `index.html` file.

## Contributing

Contributions to SpeedLLama are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgements

- This project uses the [Ollama](https://github.com/jmorganca/ollama) API for model interaction.
- Interface design inspired by modern chat applications.

## Troubleshooting

If you encounter any issues during installation or usage:

1. Ensure you have the latest version of Node.js and npm installed.
2. Check that Ollama is properly installed and running.
3. Verify your firewall settings if you're using a remote Ollama server.

For more help, please open an issue on the GitHub repository.
```

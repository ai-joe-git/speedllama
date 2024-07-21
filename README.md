![Image Description](speedllama.webp)

# SpeedLLama

This project sets up a local ChatGPT-like environment using the dolphin-2.9.3-qwen2-0.5b model. It includes a FastAPI backend and a simple HTML/JavaScript frontend, all containerized with Docker for easy deployment.

## One-Line Installation

To install and run this project, use the following command:

```bash
curl -fsSL https://raw.githubusercontent.com/ai-joe-git/speedllama/main/setup.sh | bash
```

## Prerequisites

- Docker
- Docker Compose
- Curl (for the one-line installation)

## What the Script Does

The setup script (`setup.sh`) automatically:

1. Creates the necessary project structure
2. Generates backend Python code
3. Creates a Dockerfile for the backend
4. Generates the frontend HTML/JavaScript
5. Creates a docker-compose.yml file
6. Downloads the dolphin-2.9.3-qwen2-0.5b GGUF model
7. Builds and starts the Docker containers

## Usage

After installation:

1. Open a web browser and go to `http://localhost:8080`
2. Select the model from the dropdown menu
3. Start chatting!

## Customization

To add more GGUF models, place them in the `models/` directory created by the script. They will automatically appear in the model selection dropdown on the frontend.

## Troubleshooting

If you encounter any issues, please check:

1. Docker and Docker Compose are installed and running
2. The required ports (8000 and 8080) are not in use by other applications
3. Your system meets the resource requirements for running the AI model

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)

## Disclaimer

This project is for educational purposes only. Ensure you comply with the licensing terms of the AI model and all dependencies used in this project.

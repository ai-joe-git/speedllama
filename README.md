# SpeedLLama
<img src="tenor.gif" alt="SpeedLLama Logo" width="400" align="center">

SpeedLLama is a lightweight web server application.

## Installation and Usage

### Option 1: Direct Installation

To install and run SpeedLLama directly on your system:

1. Run the following command in your terminal:

```bash
curl -s https://raw.githubusercontent.com/ai-joe-git/speedllama/main/public/speedllama_installer.sh | bash
```

2. This will download and run the SpeedLLama installer, which will set up the necessary files and start the server.

3. Once the installation is complete, you should see a message indicating that the SpeedLLama server is running at `http://localhost:3000`.

### Option 2: Using Docker

To run SpeedLLama in a Docker container:

1. Make sure you have Docker installed on your system.

2. Clone this repository:

```bash
git clone https://github.com/ai-joe-git/speedllama.git
cd speedllama
```

3. Build the Docker image:

```bash
docker build -t speedllama .
```

4. Run the container:

```bash
docker run -p 3000:3000 speedllama
```

5. The SpeedLLama server will now be accessible at `http://localhost:3000`.

## Features

- Simple Express.js server
- Serves static files from the `public` directory
- Easy to install and run

## Requirements

- Node.js (for direct installation)
- Docker (for containerized deployment)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)
```


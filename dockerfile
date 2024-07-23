# Use an official Node.js runtime as the base image
FROM node:14

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install project dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Create the public directory
RUN mkdir -p public

# Download the index.html file
RUN curl -s -o public/index.html https://raw.githubusercontent.com/ai-joe-git/speedllama/main/public/index.html

# Create the server.js file
RUN echo "const express = require('express');" > server.js && \
    echo "const path = require('path');" >> server.js && \
    echo "const fs = require('fs');" >> server.js && \
    echo "const app = express();" >> server.js && \
    echo "const port = process.env.PORT || 3000;" >> server.js && \
    echo "app.use(express.static('public'));" >> server.js && \
    echo "app.get('/', (req, res) => {" >> server.js && \
    echo "  const indexPath = path.join(__dirname, 'public', 'index.html');" >> server.js && \
    echo "  if (fs.existsSync(indexPath)) {" >> server.js && \
    echo "    res.sendFile(indexPath);" >> server.js && \
    echo "  } else {" >> server.js && \
    echo "    res.status(500).send('Error: index.html not found');" >> server.js && \
    echo "  }" >> server.js && \
    echo "});" >> server.js && \
    echo "app.listen(port, () => {" >> server.js && \
    echo "  console.log(\`SpeedLLama server running at http://localhost:\${port}\`);" >> server.js && \
    echo "});" >> server.js

# Expose the port the app runs on
EXPOSE 3000

# Define the command to run the app
CMD [ "node", "server.js" ]

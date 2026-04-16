FROM node:20-alpine

WORKDIR /app

# Copy package files first to leverage Docker cache
COPY package*.json ./

# Use npm ci for faster, more reliable builds in CI/Docker environments
RUN npm ci

# Copy the rest of the application code
COPY . .

EXPOSE 5173

# Run in development mode with host binding
CMD ["npm", "run", "dev", "--", "--host"]

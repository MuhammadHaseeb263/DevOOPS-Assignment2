# ---------- Stage 1: build the static site ----------
# Pinned Node image (no :latest). "AS builder" names this stage so
# the next stage can copy files out of it.
FROM node:22-alpine AS builder

# All following instructions run inside /app in the image
WORKDIR /app

# Copy only the package files first. Docker caches the npm ci layer
# below and reuses it until the dependencies change.
COPY package*.json ./

# Clean, reproducible install of exact versions from package-lock.json
RUN npm ci

# Copy the page sources and the shared stylesheet.
# These change often, so they come after npm ci to keep the cache useful.
COPY src/ ./src/
COPY styles/ ./styles/

# Run Parcel to generate the static site in /app/dist
RUN npm run build

# ---------- Stage 2: runtime image ----------
# Small pinned Nginx image. Node.js and node_modules are NOT included here.
FROM nginx:1.27-alpine

# Copy only the built static files from the builder stage into Nginx's web root
COPY --from=builder /app/dist /usr/share/nginx/html

# Document that Nginx listens on port 80 inside the container
EXPOSE 80

# Run Nginx in the foreground so the container keeps running
CMD ["nginx", "-g", "daemon off;"]

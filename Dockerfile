# Stage 1: The Build Stage (Flutter SDK for compilation)
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Copy the pubspec files first to leverage Docker cache
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the source code
COPY . .

# Build the Flutter web application
RUN flutter build web --release

# Stage 2: The Runtime Stage (Nginx for serving static files)
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Remove default nginx static assets
RUN rm -rf ./*

# Copy the built web assets from the build stage
COPY --from=build /app/build/web .

# Copy custom Nginx configuration to support SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose the application port
EXPOSE 80

# Command to run Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]

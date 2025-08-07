To use NGINX as a caching server for files, you can configure it as a reverse proxy with caching enabled. Below is a step-by-step guide to set up NGINX to cache files from a backend server or static files.

### Prerequisites
- NGINX installed on your server (e.g., via `apt install nginx` on Ubuntu or equivalent for your OS).
- Basic understanding of NGINX configuration files (typically located in `/etc/nginx/`).
- A backend server or static files to cache.

### Steps to Configure NGINX for Caching

1. **Set Up the Cache Directory**
   Create a directory where NGINX will store cached files. Ensure NGINX has the appropriate permissions to write to it.

   ```bash
   sudo mkdir -p /var/cache/nginx
   sudo chown www-data:www-data /var/cache/nginx
   sudo chmod 700 /var/cache/nginx
   ```

   The `www-data` user is the default NGINX user on Debian/Ubuntu. Adjust if your system uses a different user (e.g., `nginx` on CentOS).

2. **Configure NGINX for Caching**
   Edit the NGINX configuration file, typically located at `/etc/nginx/nginx.conf` or in a specific server block under `/etc/nginx/sites-available/`.

   Add the following configuration to enable caching:

   ```nginx
   # Define the cache path and settings
   proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=10g inactive=60m use_temp_path=off;

   server {
       listen 80;
       server_name your_domain.com; # Replace with your domain or IP

       # Cache settings
       proxy_cache my_cache;
       proxy_cache_valid 200 301 302 24h; # Cache successful responses for 24 hours
       proxy_cache_key "$scheme$request_uri"; # Cache key based on scheme and URI
       proxy_cache_use_stale error timeout updating; # Serve stale cache during backend issues
       proxy_cache_background_update on; # Update cache in the background
       proxy_cache_lock on; # Prevent multiple requests from hitting the backend

       # Proxy to backend or serve static files
       location / {
           proxy_pass http://backend_server; # Replace with your backend server (e.g., http://127.0.0.1:8080)
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

           # Optional: Add cache status header for debugging
           add_header X-Cache-Status $upstream_cache_status;
       }

       # Optional: Bypass cache for specific requests (e.g., dynamic content)
       location ~* \.(php|css|js)$ {
           proxy_pass http://backend_server;
           proxy_cache_bypass $http_cookie; # Bypass cache if cookies are present
       }
   }
   ```

   **Explanation of Key Directives:**
   - `proxy_cache_path`: Defines the cache storage location (`/var/cache/nginx`), cache zone name (`my_cache`), memory for cache keys (`10m`), maximum cache size (`10g`), and how long inactive items stay in the cache (`60m`).
   - `proxy_cache`: Specifies the cache zone to use (`my_cache`).
   - `proxy_cache_valid`: Sets the cache duration for specific HTTP status codes (e.g., 24 hours for 200, 301, 302 responses).
   - `proxy_cache_key`: Defines the key for caching (based on the scheme and request URI).
   - `proxy_cache_use_stale`: Allows serving stale content in case of backend errors or timeouts.
   - `proxy_cache_background_update`: Updates cache in the background to avoid delays for users.
   - `proxy_cache_lock`: Prevents multiple simultaneous requests from hitting the backend when cache is being populated.
   - `add_header X-Cache-Status`: Adds a response header to indicate cache status (`HIT`, `MISS`, `BYPASS`, etc.).
   - `proxy_cache_bypass`: Skips caching for specific conditions, like requests with cookies.

3. **Test the Configuration**
   Verify the NGINX configuration for syntax errors:

   ```bash
   sudo nginx -t
   ```

   If the test is successful, reload NGINX to apply the changes:

   ```bash
   sudo systemctl reload nginx
   ```

4. **Serving Static Files (Optional)**
   If you want NGINX to cache and serve static files directly (e.g., images, CSS, JS), you can configure a `location` block for static content:

   ```nginx
   location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf)$ {
       root /path/to/static/files; # Replace with the path to your static files
       expires 30d; # Cache files in the browser for 30 days
       add_header Cache-Control "public";
       access_log off; # Optional: Disable logging for static files
   }
   ```

   This configuration serves static files from the specified directory and sets browser caching headers.

5. **Monitor and Test Caching**
   - Check the `X-Cache-Status` header in responses using browser developer tools or a tool like `curl`:
     ```bash
     curl -I http://your_domain.com/some/file
     ```
     Look for `X-Cache-Status: HIT` (cached) or `MISS` (not cached yet).
   - Verify that files are being stored in `/var/cache/nginx`:
     ```bash
     ls -l /var/cache/nginx
     ```

6. **Optional: Fine-Tune Cache Settings**
   - **Cache Invalidation**: To manually clear the cache, delete the contents of `/var/cache/nginx`:
     ```bash
     sudo rm -rf /var/cache/nginx/*
     sudo systemctl reload nginx
     ```
   - **Cache Bypass for Specific Cases**: Use `proxy_cache_bypass` or `proxy_no_cache` to skip caching for dynamic content or specific users:
     ```nginx
     proxy_cache_bypass $arg_nocache; # Bypass cache if ?nocache=true is in the URL
     ```
   - **Cache by Content Type**: Cache only specific content types (e.g., images):
     ```nginx
     location ~* \.(jpg|jpeg|png|gif)$ {
         proxy_cache my_cache;
         proxy_cache_valid 200 7d; # Cache images for 7 days
         proxy_pass http://backend_server;
     }
     ```

7. **Logging and Debugging**
   Enable access and error logs to troubleshoot caching issues:

   ```nginx
   access_log /var/log/nginx/cache_access.log;
   error_log /var/log/nginx/cache_error.log;
   ```

   Check these logs for issues with cache hits/misses or backend connectivity.

### Notes
- Replace `your_domain.com` with your actual domain or server IP.
- Replace `http://backend_server` with the address of your upstream server (e.g., `http://127.0.0.1:8080`).
- Adjust cache size (`max_size`), duration (`proxy_cache_valid`), and other parameters based on your needs.
- If you don’t have a backend server and want to cache local files, use the `root` directive instead of `proxy_pass`.
- For high-traffic sites, consider using `levels=1:2` in `proxy_cache_path` to improve performance by organizing cache files in a directory hierarchy.

### Example: Caching Static Files Locally
If you’re caching files from a local directory (e.g., `/var/www/html`), use this simplified configuration:

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=10g inactive=60m use_temp_path=off;

server {
    listen 80;
    server_name your_domain.com;

    location / {
        root /var/www/html;
        proxy_cache my_cache;
        proxy_cache_valid 200 30d;
        proxy_cache_key "$scheme$request_uri";
        add_header X-Cache-Status $upstream_cache_status;
    }
}
```

### Testing the Setup
- Access your site (`http://your_domain.com`) and check the `X-Cache-Status` header.
- Monitor the cache directory (`/var/cache/nginx`) to ensure files are being cached.
- Simulate backend downtime to verify that NGINX serves cached content (`proxy_cache_use_stale`).

If you need more specific configurations (e.g., caching for a particular file type or integrating with a specific backend like S3), let me know, and I can tailor the setup further!

------------------------------------------------------------------------------------

To deploy an NGINX server with caching capabilities in a Docker container, you can create a custom Docker image with a tailored NGINX configuration. Below is a complete setup, including a Dockerfile, NGINX configuration, and instructions for running the container.

### Steps to Deploy NGINX with Caching in Docker

1. **Create the NGINX Configuration File**
   This configuration sets up NGINX as a reverse proxy with caching, similar to the previous example, but tailored for a Docker environment.

2. **Create a Dockerfile**
   The Dockerfile will install NGINX, set up the cache directory, and copy the configuration file.

3. **Build and Run the Docker Container**
   Instructions for building the image and running the container with appropriate volume mounts for the cache.

### Artifacts and Instructions

```nginx
# Define the cache path and settings
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=10g inactive=60m use_temp_path=off;

server {
    listen 80;
    server_name localhost;

    # Cache settings
    proxy_cache my_cache;
    proxy_cache_valid 200 301 302 24h; # Cache successful responses for 24 hours
    proxy_cache_key "$scheme$request_uri"; # Cache key based on scheme and URI
    proxy_cache_use_stale error timeout updating; # Serve stale cache during backend issues
    proxy_cache_background_update on; # Update cache in the background
    proxy_cache_lock on; # Prevent multiple requests from hitting the backend

    # Proxy to backend
    location / {
        proxy_pass http://backend:8080; # Assumes backend container is named 'backend' and runs on port 8080
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # Add cache status header for debugging
        add_header X-Cache-Status $upstream_cache_status;
    }

    # Bypass cache for specific file types (e.g., dynamic content)
    location ~* \.(php|css|js)$ {
        proxy_pass http://backend:8080;
        proxy_cache_bypass $http_cookie; # Bypass cache if cookies are present
    }

    # Serve static files directly with caching
    location ~* \.(jpg|jpeg|png|gif|ico|woff|woff2|ttf)$ {
        root /usr/share/nginx/html;
        expires 30d; # Cache in browser for 30 days
        add_header Cache-Control "public";
        access_log off; # Disable logging for static files
    }

    # Logging
    access_log /var/log/nginx/cache_access.log;
    error_log /var/log/nginx/cache_error.log;
}
```

```dockerfile
# Use official NGINX image as the base
FROM nginx:alpine

# Create cache directory
RUN mkdir -p /var/cache/nginx && \
    chown -R nginx:nginx /var/cache/nginx && \
    chmod -R 700 /var/cache/nginx

# Copy custom NGINX configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]
```

### Steps to Deploy

1. **Prepare the Directory Structure**
   Create a directory for your Docker project and save the above artifacts:

   ```bash
   mkdir nginx-cache
   cd nginx-cache
   ```

   Save the NGINX configuration as `nginx.conf` and the Dockerfile as `Dockerfile` in this directory.

2. **Build the Docker Image**
   Build the custom NGINX image using the Dockerfile:

   ```bash
   docker build -t nginx-cache:latest .
   ```

3. **Run the Docker Container**
   Run the NGINX container, linking it to a backend server (if applicable) and mounting the cache directory for persistence:

   ```bash
   docker run -d \
     --name nginx-cache \
     -p 80:80 \
     -v nginx-cache:/var/cache/nginx \
     --link backend:backend \
     nginx-cache:latest
   ```

   **Notes:**
   - Replace `--link backend:backend` with the appropriate backend container name and alias if you’re using a backend server. Alternatively, use Docker networking (e.g., a `docker-compose.yml` setup) for better container communication.
   - The `-v nginx-cache:/var/cache/nginx` creates a Docker volume to persist cached files across container restarts. You can replace it with a host path (e.g., `-v /path/to/cache:/var/cache/nginx`) if preferred.

4. **Example: Docker Compose for NGINX and Backend**
   If you have a backend server (e.g., a simple Node.js or Python app), you can use Docker Compose to manage both the NGINX and backend containers. Here’s an example `docker-compose.yml`:

   ```yaml
version: '3.8'

services:
  nginx:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "80:80"
    volumes:
      - nginx-cache:/var/cache/nginx
    depends_on:
      - backend
    networks:
      - app-network

  backend:
    image: nginx:alpine # Replace with your backend image (e.g., node, python)
    expose:
      - "8080"
    networks:
      - app-network

volumes:
  nginx-cache:

networks:
  app-network:
    driver: bridge
   ```

   Save this as `docker-compose.yml` in the same directory, then run:

   ```bash
   docker-compose up -d
   ```

   This sets up NGINX as a caching proxy in front of a backend container, with a persistent cache volume.

5. **Test the Setup**
   - Access the NGINX server at `http://localhost` (or your server’s IP/domain).
   - Check the `X-Cache-Status` header using:
     ```bash
     curl -I http://localhost
     ```
     Look for `X-Cache-Status: HIT` (cached) or `MISS` (not cached yet).
   - Verify cache files in the Docker volume:
     ```bash
     docker volume inspect nginx-cache
     ```
     If using a host path, check the mounted directory (e.g., `/path/to/cache`).

6. **Optional: Serving Static Files**
   If you want NGINX to serve and cache static files directly, place them in a directory (e.g., `./static`) and mount it into the container:

   ```bash
   docker run -d \
     --name nginx-cache \
     -p 80:80 \
     -v nginx-cache:/var/cache/nginx \
     -v $(pwd)/static:/usr/share/nginx/html:ro \
     nginx-cache:latest
   ```

   Update the `nginx.conf` to point to the mounted directory for static files:

   ```nginx
   location /static {
       root /usr/share/nginx/html;
       expires 30d;
       add_header Cache-Control "public";
   }
   ```

7. **Cache Management**
   - To clear the cache, remove the cache volume or directory:
     ```bash
     docker volume rm nginx-cache
     ```
     Or, if using a host path:
     ```bash
     rm -rf /path/to/cache/*
     ```
   - Restart the container to apply changes:
     ```bash
     docker restart nginx-cache
     ```

### Notes
- **Backend Configuration**: The `proxy_pass http://backend:8080` assumes a backend container named `backend` listening on port 8080. Adjust the address based on your setup (e.g., `http://your-backend-ip:port`).
- **Cache Persistence**: The Docker volume (`nginx-cache`) ensures cache persistence across container restarts. Use a host-mounted directory for easier access if needed.
- **Security**: Ensure the cache directory (`/var/cache/nginx`) has proper permissions (`chown nginx:nginx` and `chmod 700`) to prevent unauthorized access.
- **Scaling**: For production, consider using Docker Compose or Kubernetes for better networking and scaling, and adjust `max_size` and `inactive` in `proxy_cache_path` based on your traffic and storage needs.
- **Logging**: Logs are written to `/var/log/nginx/cache_access.log` and `/var/log/nginx/cache_error.log` inside the container. Mount these paths as volumes to persist logs:
  ```bash
  -v $(pwd)/logs:/var/log/nginx
  ```

If you need a specific backend setup (e.g., Node.js, Python) or additional NGINX features (e.g., cache purging, SSL), let me know, and I can provide further customization!

----------------------------------------------------------------------------

To use NGINX in a Docker container as a caching proxy gateway for multiple backend servers, you can configure it to route requests to different backends based on criteria like URL paths, domains, or other headers, while caching responses from each backend. This setup allows NGINX to act as a reverse proxy with caching, distributing requests to multiple upstream servers and storing their responses in a shared cache. Below, I’ll provide a complete solution tailored to your Docker-based NGINX setup, building on the previous configurations for caching and cache invalidation.

### Overview
- **Goal**: Configure NGINX in a Docker container to act as a caching gateway for multiple backend servers, with cache invalidation using `ETag`/`Last-Modified` headers or a purge endpoint.
- **Key Features**:
  - Route requests to different backend servers based on URL paths or domains.
  - Cache responses from all backends in a shared cache.
  - Support cache invalidation when files change (using `ETag`/`Last-Modified` or a purge endpoint).
  - Deploy using Docker Compose for easy management of NGINX and backend containers.

### Steps to Implement NGINX as a Caching Gateway

1. **Define Backend Servers**
   Assume you have multiple backend servers (e.g., `backend1`, `backend2`, `backend3`) running on different hosts/ports or containers. For example:
   - `backend1:8081` (serves images)
   - `backend2:8082` (serves videos)
   - `backend3:8083` (serves APIs or dynamic content)

2. **Configure NGINX as a Caching Gateway**
   Update the NGINX configuration to define upstream blocks for each backend and route requests accordingly, with caching enabled. Include cache invalidation mechanisms (e.g., `ETag`/`Last-Modified` or a purge endpoint).

3. **Set Up Docker Compose**
   Use Docker Compose to manage the NGINX container and simulate multiple backend servers for testing.

4. **Handle Cache Invalidation**
   Extend the previous cache invalidation strategies (`ETag`/`Last-Modified` or purge endpoint) to work with multiple backends.

### Artifacts and Configuration

Below are the updated configuration files, incorporating multiple backends and caching.

```nginx
# Define the cache path
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=10g inactive=60m use_temp_path=off;

# Define upstream servers
upstream backend1 {
    server backend1:8081;
}
upstream backend2 {
    server backend2:8082;
}
upstream backend3 {
    server backend3:8083;
}

server {
    listen 80;
    server_name localhost;

    # Cache settings
    proxy_cache my_cache;
    proxy_cache_valid 200 301 302 24h; # Cache successful responses for 24 hours
    proxy_cache_key "$scheme$host$request_uri"; # Include host in cache key to avoid collisions
    proxy_cache_use_stale error timeout updating;
    proxy_cache_background_update on;
    proxy_cache_lock on;
    proxy_cache_revalidate on; # Revalidate with ETag/Last-Modified
    add_header X-Cache-Status $upstream_cache_status;

    # Route to backend1 (e.g., for images)
    location /images/ {
        proxy_pass http://backend1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Route to backend2 (e.g., for videos)
    location /videos/ {
        proxy_pass http://backend2;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Route to backend3 (e.g., for APIs)
    location /api/ {
        proxy_pass http://backend3;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_cookie; # Skip caching for dynamic API requests
    }

    # Cache purge endpoint
    location ~ /purge/(.*) {
        allow 127.0.0.1;
        allow 172.0.0.0/8; # Allow Docker network IPs
        deny all;
        proxy_cache_purge my_cache "$scheme$host$1";
    }

    # Static files (optional, served directly by NGINX)
    location ~* \.(jpg|jpeg|png|gif|ico|woff|woff2|ttf)$ {
        root /usr/share/nginx/html;
        expires 30d;
        add_header Cache-Control "public";
        etag on;
    }

    # Logging
    access_log /var/log/nginx/cache_access.log;
    error_log /var/log/nginx/cache_error.log;
}
```

```dockerfile
# Use official NGINX image with cache purge module
FROM nginx:alpine

# Create cache directory
RUN mkdir -p /var/cache/nginx && \
    chown -R nginx:nginx /var/cache/nginx && \
    chmod -R 700 /var/cache/nginx

# Copy NGINX configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]
```

```yaml
version: '3.8'

services:
  nginx:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "80:80"
    volumes:
      - nginx-cache:/var/cache/nginx
      - ./static:/usr/share/nginx/html:ro # Optional: static files
    depends_on:
      - backend1
      - backend2
      - backend3
    networks:
      - app-network

  backend1:
    image: nginx:alpine # Simulate backend1 (e.g., image server)
    expose:
      - "8081"
    volumes:
      - ./backend1:/usr/share/nginx/html:ro # Mount sample files
    command: ["nginx", "-g", "daemon off;"]
    networks:
      - app-network

  backend2:
    image: nginx:alpine # Simulate backend2 (e.g., video server)
    expose:
      - "8082"
    volumes:
      - ./backend2:/usr/share/nginx/html:ro # Mount sample files
    command: ["nginx", "-g", "daemon off;"]
    networks:
      - app-network

  backend3:
    image: nginx:alpine # Simulate backend3 (e.g., API server)
    expose:
      - "8083"
    volumes:
      - ./backend3:/usr/share/nginx/html:ro # Mount sample files
    command: ["nginx", "-g", "daemon off;"]
    networks:
      - app-network

  monitor:
    build:
      context: .
      dockerfile: Dockerfile-monitor
    volumes:
      - ./backend1:/path/to/backend1:ro
      - ./backend2:/path/to/backend2:ro
      - ./backend3:/path/to/backend3:ro
    depends_on:
      - nginx
    networks:
      - app-network

volumes:
  nginx-cache:

networks:
  app-network:
    driver: bridge
```

```x-shellscript
#!/bin/sh

# Directories to monitor
WATCH_DIRS="/path/to/backend1 /path/to/backend2 /path/to/backend3"

# NGINX purge endpoint
PURGE_URL="http://nginx/purge"

# Monitor directories for changes
for dir in $WATCH_DIRS; do
    inotifywait -m "$dir" -e create -e modify |
        while read -r directory events filename; do
            echo "File changed in $dir: $filename"
            # Construct the URL path based on backend
            case "$dir" in
                "/path/to/backend1") PREFIX="images" ;;
                "/path/to/backend2") PREFIX="videos" ;;
                "/path/to/backend3") PREFIX="api" ;;
                *) PREFIX="" ;;
            esac
            RELATIVE_PATH="${directory#${dir}}/$filename"
            PURGE_PATH="${PREFIX}${RELATIVE_PATH#/}"
            curl -X GET "${PURGE_URL}/${PURGE_PATH}"
            echo "Cache purged for: $PURGE_PATH"
        done &
done

# Keep script running
wait
```

```dockerfile
FROM alpine:3.18

RUN apk add --no-cache inotify-tools curl

COPY monitor-and-purge.sh /monitor-and-purge.sh

RUN chmod +x /monitor-and-purge.sh

CMD ["/monitor-and-purge.sh"]
```

### Steps to Deploy

1. **Prepare the Directory Structure**
   Create a project directory and save the artifacts:

   ```bash
   mkdir nginx-gateway
   cd nginx-gateway
   mkdir static backend1 backend2 backend3
   ```

   - Place the above files (`nginx.conf`, `Dockerfile`, `docker-compose.yml`, `monitor-and-purge.sh`, `Dockerfile-monitor`) in `nginx-gateway`.
   - For testing, add sample files to `backend1`, `backend2`, and `backend3` directories (e.g., `backend1/image.jpg`, `backend2/video.mp4`, `backend3/data.json`).

2. **Build and Run**
   Build and start the containers using Docker Compose:

   ```bash
   docker-compose up -d --build
   ```

   This starts:
   - NGINX as the caching gateway on port 80.
   - Three backend servers (`backend1`, `backend2`, `backend3`) on ports 8081, 8082, and 8083, respectively.
   - A monitoring container to watch for file changes and purge the cache.

3. **Cache Invalidation**
   - **ETag/Last-Modified**: Enabled via `proxy_cache_revalidate on`. Each backend (simulated as NGINX containers in this example) generates `ETag` and `Last-Modified` headers by default, allowing NGINX to revalidate cached files automatically.
   - **Purge Endpoint**: The `/purge` endpoint allows manual cache invalidation. The `monitor-and-purge.sh` script watches the `backend1`, `backend2`, and `backend3` directories and triggers purges when files change. For example:
     - A change to `backend1/image.jpg` triggers a purge request to `http://nginx/purge/images/image.jpg`.
     - The script maps directories to URL prefixes (`/images`, `/videos`, `/api`).

4. **Testing**
   - Access files via NGINX:
     ```bash
     curl -I http://localhost/images/image.jpg
     curl -I http://localhost/videos/video.mp4
     curl -I http://localhost/api/data.json
     ```
     Check `X-Cache-Status` for `HIT` (cached) or `MISS` (not cached).
   - Modify a file (e.g., `touch backend1/image.jpg`) and verify the cache is invalidated:
     - For `ETag`/`Last-Modified`, the next request should show `MISS` or `EXPIRED`.
     - For the purge endpoint, the monitoring script should log the purge request, and the next request should show `MISS`.
   - Manually purge a file:
     ```bash
     curl -X GET http://localhost/purge/images/image.jpg
     ```

5. **Customizing for Your Backends**
   - **Replace Backend Images**: In `docker-compose.yml`, replace `image: nginx:alpine` with your actual backend images (e.g., Node.js, Python, or S3-compatible servers).
   - **Adjust Ports**: Update the `expose` ports in `docker-compose.yml` and `upstream` definitions in `nginx.conf` to match your backends’ ports.
   - **Routing Rules**: Modify the `location` blocks in `nginx.conf` to route based on your needs (e.g., by domain, subdomain, or query parameters):
     ```nginx
     # Example: Route by domain
     server {
         listen 80;
         server_name backend1.example.com;
         proxy_pass http://backend1;
         proxy_cache my_cache;
         ...
     }
     ```
   - **Cache Key**: The `proxy_cache_key "$scheme$host$request_uri"` includes `$host` to prevent cache collisions across backends with different domains or paths.

6. **Cache Invalidation for Multiple Backends**
   - **ETagწ: Ensure each backend provides `ETag` or `Last-Modified` headers. If not, you’ll rely on the purge endpoint.
   - **Purge Endpoint**: The monitoring script handles all backends by mapping directories to URL prefixes. Adjust the `case` statement in `monitor-and-purge.sh` to match your backend paths.
   - **File Monitoring**: The script monitors multiple directories. Add more directories to `WATCH_DIRS` if you have additional backends.

7. **Security**
   - Restrict the purge endpoint to trusted IPs (e.g., Docker network `172.0.0.0/8`).
   - Consider adding HTTP basic authentication to the purge endpoint:
     ```nginx
     location ~ /purge/(.*) {
         auth_basic "Restricted";
         auth_basic_user_file /etc/nginx/.htpasswd;
         proxy_cache_purge my_cache "$scheme$host$1";
     }
     ```
     Create an `.htpasswd` file and mount it into the NGINX container.

### Notes
- **Cache Purge Module**: The provided `Dockerfile` uses the standard NGINX image for simplicity. If you need the `ngx_cache_purge` module, use the custom Dockerfile from the previous response to compile NGINX with the module.
- **Performance**: Adjust `max_size` and `inactive` in `proxy_cache_path` based on your storage and traffic needs.
- **Backend Heterogeneity**: If backends use different protocols or response formats, ensure they provide consistent `ETag`/`Last-Modified` headers for Option 1, or rely on the purge endpoint.
- **Monitoring Script**: The `monitor-and-purge.sh` script assumes local file monitoring. For remote backends, integrate with their change notification APIs (e.g., S3 event notifications) or webhooks.

### Testing
- Verify routing:
  ```bash
  curl -I http://localhost/images/image.jpg # Should hit backend1
  curl -I http://localhost/videos/video.mp4 # Should hit backend2
  ```
- Test cache invalidation:
  - Modify a file in `backend1`, `backend2`, or `backend3`.
  - Check `X-Cache-Status` for `MISS` after the purge or revalidation.
- Check the cache directory:
  ```bash
  docker exec nginx-cache ls -l /var/cache/nginx
  ```

If you need specific configurations for your backend servers (e.g., S3, custom APIs) or additional features (e.g., load balancing across multiple instances of a backend), let me know, and I can refine the setup!

---------------------------------------------------------------------------------------

To adapt your NGINX caching proxy gateway for multiple environments (dev, staging, and production) within a Docker-based setup, you need to ensure the configuration is flexible, maintainable, and secure across environments while accommodating differences in backend servers, caching behavior, and operational requirements. Below, I’ll provide a solution that extends the previous setup to handle dev, staging, and production environments, focusing on environment-specific configurations, cache management, and deployment strategies.

### Key Considerations for Multi-Environment Setup
- **Environment-Specific Backends**: Each environment (dev, staging, production) has its own set of backend servers (e.g., different IPs/ports or container names).
- **Caching Behavior**:
  - **Dev**: Minimal or no caching to facilitate rapid development and debugging.
  - **Staging**: Moderate caching to simulate production but allow testing of cache invalidation.
  - **Production**: Aggressive caching with strict invalidation controls for performance.
- **Cache Invalidation**: Use `ETag`/`Last-Modified` headers for automatic invalidation and a purge endpoint for manual control, with environment-specific access controls.
- **Configuration Management**: Use environment variables or separate configuration files to avoid duplicating NGINX configs.
- **Docker Deployment**: Use Docker Compose with environment-specific overrides for easy deployment.

### Solution Overview
1. **Modular NGINX Configuration**: Use a single `nginx.conf` with included environment-specific configurations to handle different backends and caching rules.
2. **Docker Compose with Overrides**: Define a base `docker-compose.yml` and environment-specific override files (`docker-compose.dev.yml`, `docker-compose.staging.yml`, `docker-compose.prod.yml`).
3. **Cache Invalidation**: Extend the previous `ETag`/`Last-Modified` and purge endpoint mechanisms to work across environments.
4. **Environment Variables**: Use environment variables to set backend addresses and cache settings dynamically.
5. **Monitoring Script**: Adapt the file monitoring script to handle environment-specific directories and purge endpoints.

### Artifacts

Below are the updated and new configuration files to support dev, staging, and production environments.

```nginx
# Define the cache path
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=${CACHE_MAX_SIZE:-10g} inactive=${CACHE_INACTIVE:-60m} use_temp_path=off;

# Define upstream servers (populated by environment-specific configs)
upstream backend1 {
    server ${BACKEND1_HOST:-backend1}:${BACKEND1_PORT:-8081};
}
upstream backend2 {
    server ${BACKEND2_HOST:-backend2}:${BACKEND2_PORT:-8082};
}
upstream backend3 {
    server ${BACKEND3_HOST:-backend3}:${BACKEND3_PORT:-8083};
}

server {
    listen 80;
    server_name ${SERVER_NAME:-localhost};

    # Cache settings
    proxy_cache my_cache;
    proxy_cache_valid 200 301 302 ${CACHE_VALID_TIME:-24h};
    proxy_cache_key "$scheme$host$request_uri";
    proxy_cache_use_stale error timeout updating;
    proxy_cache_background_update on;
    proxy_cache_lock on;
    proxy_cache_revalidate ${CACHE_REVALIDATE:-on};
    add_header X-Cache-Status $upstream_cache_status;

    # Include environment-specific configurations
    include /etc/nginx/conf.d/*.conf;

    # Default routes (can be overridden by environment-specific configs)
    location /images/ {
        proxy_pass http://backend1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /videos/ {
        proxy_pass http://backend2;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /api/ {
        proxy_pass http://backend3;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_cookie;
    }

    # Cache purge endpoint
    location ~ /purge/(.*) {
        allow 127.0.0.1;
        allow 172.0.0.0/8; # Docker network IPs
        deny all;
        proxy_cache_purge my_cache "$scheme$host$1";
    }

    # Static files
    location ~* \.(jpg|jpeg|png|gif|ico|woff|woff2|ttf)$ {
        root /usr/share/nginx/html;
        expires ${STATIC_EXPIRES:-30d};
        add_header Cache-Control "public";
        etag on;
    }

    # Logging
    access_log /var/log/nginx/cache_access.log;
    error_log /var/log/nginx/cache_error.log;
}
```

```dockerfile
# Use official NGINX image
FROM nginx:alpine

# Create cache directory
RUN mkdir -p /var/cache/nginx && \
    chown -R nginx:nginx /var/cache/nginx && \
    chmod -R 700 /var/cache/nginx

# Create directory for environment-specific configs
RUN mkdir -p /etc/nginx/conf.d

# Copy NGINX configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d /etc/nginx/conf.d

# Expose port 80
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]
```

```yaml
version: '3.8'

services:
  nginx:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "80:80"
    volumes:
      - nginx-cache:/var/cache/nginx
      - ./static:/usr/share/nginx/html:ro
    depends_on:
      - backend1
      - backend2
      - backend3
    networks:
      - app-network
    environment:
      - CACHE_MAX_SIZE=${CACHE_MAX_SIZE}
      - CACHE_INACTIVE=${CACHE_INACTIVE}
      - CACHE_VALID_TIME=${CACHE_VALID_TIME}
      - CACHE_REVALIDATE=${CACHE_REVALIDATE}
      - SERVER_NAME=${SERVER_NAME}
      - BACKEND1_HOST=${BACKEND1_HOST}
      - BACKEND1_PORT=${BACKEND1_PORT}
      - BACKEND2_HOST=${BACKEND2_HOST}
      - BACKEND2_PORT=${BACKEND2_PORT}
      - BACKEND3_HOST=${BACKEND3_HOST}
      - BACKEND3_PORT=${BACKEND3_PORT}
      - STATIC_EXPIRES=${STATIC_EXPIRES}

  backend1:
    image: nginx:alpine
    expose:
      - "8081"
    volumes:
      - ./backend1:/usr/share/nginx/html:ro
    command: ["nginx", "-g", "daemon off;"]
    networks:
      - app-network

  backend2:
    image: nginx:alpine
    expose:
      - "8082"
    volumes:
      - ./backend2:/usr/share/nginx/html:ro
    command: ["nginx", "-g", "daemon off;"]
    networks:
      - app-network

  backend3:
    image: nginx:alpine
    expose:
      - "8083"
    volumes:
      - ./backend3:/usr/share/nginx/html:ro
    command: ["nginx", "-g", "daemon off;"]
    networks:
      - app-network

  monitor:
    build:
      context: .
      dockerfile: Dockerfile-monitor
    volumes:
      - ./backend1:/path/to/backend1:ro
      - ./backend2:/path/to/backend2:ro
      - ./backend3:/path/to/backend3:ro
    depends_on:
      - nginx
    networks:
      - app-network

volumes:
  nginx-cache:

networks:
  app-network:
    driver: bridge
```

```x-shellscript
#!/bin/sh

# Directories to monitor
WATCH_DIRS="/path/to/backend1 /path/to/backend2 /path/to/backend3"

# NGINX purge endpoint
PURGE_URL="http://nginx/purge"

# Monitor directories for changes
for dir in $WATCH_DIRS; do
    inotifywait -m "$dir" -e create -e modify |
        while read -r directory events filename; do
            echo "File changed in $dir: $filename"
            case "$dir" in
                "/path/to/backend1") PREFIX="images" ;;
                "/path/to/backend2") PREFIX="videos" ;;
                "/path/to/backend3") PREFIX="api" ;;
                *) PREFIX="" ;;
            esac
            RELATIVE_PATH="${directory#${dir}}/$filename"
            PURGE_PATH="${PREFIX}${RELATIVE_PATH#/}"
            curl -X GET "${PURGE_URL}/${PURGE_PATH}"
            echo "Cache purged for: $PURGE_PATH"
        done &
done

wait
```

```dockerfile
FROM alpine:3.18

RUN apk add --no-cache inotify-tools curl

COPY monitor-and-purge.sh /monitor-and-purge.sh

RUN chmod +x /monitor-and-purge.sh

CMD ["/monitor-and-purge.sh"]
```

```nginx
# Dev environment: Minimal caching
proxy_cache_valid 200 301 302 10s; # Short cache duration
proxy_cache_revalidate off; # Disable revalidation for faster debugging
```

```nginx
# Staging environment: Moderate caching
proxy_cache_valid 200 301 302 1h; # Cache for 1 hour
proxy_cache_revalidate on; # Enable revalidation
```

```nginx
# Production environment: Aggressive caching
proxy_cache_valid 200 301 302 24h; # Cache for 24 hours
proxy_cache_revalidate on; # Enable revalidation

# Optional: Stricter purge access
location ~ /purge/(.*) {
    allow 127.0.0.1;
    allow 172.0.0.0/8;
    deny all;
    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_cache_purge my_cache "$scheme$host$1";
}
```

```yaml
version: '3.8'

services:
  nginx:
    environment:
      - CACHE_MAX_SIZE=1g
      - CACHE_INACTIVE=10m
      - CACHE_VALID_TIME=10s
      - CACHE_REVALIDATE=off
      - SERVER_NAME=dev.example.com
      - BACKEND1_HOST=backend1
      - BACKEND1_PORT=8081
      - BACKEND2_HOST=backend2
      - BACKEND2_PORT=8082
      - BACKEND3_HOST=backend3
      - BACKEND3_PORT=8083
      - STATIC_EXPIRES=1d
    volumes:
      - ./dev.conf:/etc/nginx/conf.d/env.conf:ro
```

```yaml
version: '3.8'

services:
  nginx:
    environment:
      - CACHE_MAX_SIZE=5g
      - CACHE_INACTIVE=30m
      - CACHE_VALID_TIME=1h
      - CACHE_REVALIDATE=on
      - SERVER_NAME=staging.example.com
      - BACKEND1_HOST=backend1
      - BACKEND1_PORT=8081
      - BACKEND2_HOST=backend2
      - BACKEND2_PORT=8082
      - BACKEND3_HOST=backend3
      - BACKEND3_PORT=8083
      - STATIC_EXPIRES=7d
    volumes:
      - ./staging.conf:/etc/nginx/conf.d/env.conf:ro
```

```yaml
version: '3.8'

services:
  nginx:
    environment:
      - CACHE_MAX_SIZE=10g
      - CACHE_INACTIVE=60m
      - CACHE_VALID_TIME=24h
      - CACHE_REVALIDATE=on
      - SERVER_NAME=prod.example.com
      - BACKEND1_HOST=backend1
      - BACKEND1_PORT=8081
      - BACKEND2_HOST=backend2
      - BACKEND2_PORT=8082
      - BACKEND3_HOST=backend3
      - BACKEND3_PORT=8083
      - STATIC_EXPIRES=30d
    volumes:
      - ./prod.conf:/etc/nginx/conf.d/env.conf:ro
      - ./.htpasswd:/etc/nginx/.htpasswd:ro
```

### Steps to Deploy

1. **Prepare the Directory Structure**
   Create a project directory and save all artifacts:

   ```bash
   mkdir nginx-gateway
   cd nginx-gateway
   mkdir static backend1 backend2 backend3 conf.d
   ```

   - Save `nginx.conf`, `Dockerfile`, `docker-compose.yml`, `monitor-and-purge.sh`, and `Dockerfile-monitor` in `nginx-gateway`.
   - Save `dev.conf`, `staging.conf`, and `prod.conf` in `nginx-gateway/conf.d`.
   - Save `docker-compose.dev.yml`, `docker-compose.staging.yml`, and `docker-compose.prod.yml` in `nginx-gateway`.
   - Add sample files to `backend1`, `backend2`, and `backend3` for testing (e.g., `backend1/image.jpg`).
   - For production, create an `.htpasswd` file for purge endpoint authentication:
     ```bash
     printf "admin:$(openssl passwd -apr1 yourpassword)\n" > .htpasswd
     ```

2. **Deploy for Each Environment**
   Use Docker Compose with the appropriate override file:

   - **Dev**:
     ```bash
     docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
     ```

   - **Staging**:
     ```bash
     docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d --build
     ```

   - **Production**:
     ```bash
     docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
     ```

3. **Environment-Specific Configurations**
   - **Dev**:
     - Cache duration: 10 seconds (`CACHE_VALID_TIME=10s`).
     - Revalidation disabled (`CACHE_REVALIDATE=off`) for faster debugging.
     - Smaller cache size (`CACHE_MAX_SIZE=1g`).
     - Static file expiry: 1 day (`STATIC_EXPIRES=1d`).
   - **Staging**:
     - Cache duration: 1 hour (`CACHE_VALID_TIME=1h`).
     - Revalidation enabled (`CACHE_REVALIDATE=on`).
     - Moderate cache size (`CACHE_MAX_SIZE=5g`).
     - Static file expiry: 7 days (`STATIC_EXPIRES=7d`).
   - **Production**:
     - Cache duration: 24 hours (`CACHE_VALID_TIME=24h`).
     - Revalidation enabled (`CACHE_REVALIDATE=on`).
     - Larger cache size (`CACHE_MAX_SIZE=10g`).
     - Static file expiry: 30 days (`STATIC_EXPIRES=30d`).
     - Purge endpoint secured with HTTP basic auth.

4. **Cache Invalidation**
   - **ETag/Last-Modified**: Enabled via `proxy_cache_revalidate` (except in dev). Backends must provide these headers for automatic invalidation.
   - **Purge Endpoint**: The `/purge` endpoint is available in all environments. In production, it requires authentication. Trigger a purge:
     ```bash
     curl -X GET -u admin:yourpassword http://localhost/purge/images/image.jpg
     ```
   - **Monitoring Script**: The `monitor-and-purge.sh` script watches all backend directories and purges the cache when files change. For production, update the script to include authentication:
     ```bash
     curl -X GET -u admin:yourpassword "${PURGE_URL}/${PURGE_PATH}"
     ```

5. **Testing**
   - Verify routing and caching:
     ```bash
     curl -I http://localhost/images/image.jpg
     curl -I http://localhost/videos/video.mp4
     curl -I http://localhost/api/data.json
     ```
     Check `X-Cache-Status` for `HIT` or `MISS`.
   - Test cache invalidation:
     - Modify a file (e.g., `touch backend1/image.jpg`).
     - In dev, cache expires quickly (10s). In staging/production, verify `MISS` after purge or revalidation.
   - Test purge endpoint:
     ```bash
     curl -X GET http://localhost/purge/images/image.jpg # Dev/Staging
     curl -X GET -u admin:yourpassword http://localhost/purge/images/image.jpg # Prod
     ```

6. **Customizing for Your Backends**
   - **Backend Images**: Replace `image: nginx:alpine` in `docker-compose.yml` with your actual backend images (e.g., Node.js, Python).
   - **Backend Addresses**: Update `BACKEND1_HOST`, `BACKEND1_PORT`, etc., in the environment-specific `docker-compose.*.yml` files to match your backend servers’ IPs/ports.
   - **Routing Rules**: Adjust `location` blocks in `dev.conf`, `staging.conf`, or `prod.conf` if your routing differs (e.g., by subdomain or query parameters).
   - **Cache Settings**: Modify `CACHE_MAX_SIZE`, `CACHE_INACTIVE`, `CACHE_VALID_TIME`, and `STATIC_EXPIRES` in the `docker-compose.*.yml` files to suit each environment’s needs.

### Notes
- **Cache Purge Module**: The provided `Dockerfile` uses the standard NGINX image. If you need the `ngx_cache_purge` module, replace it with the custom Dockerfile from the previous response.
- **Environment Isolation**: Ensure each environment runs on separate hosts or networks to avoid conflicts. Use different `SERVER_NAME` values (e.g., `dev.example.com`, `staging.example.com`, `prod.example.com`).
- **Security**: In production, the `.htpasswd` file adds an extra layer of security for the purge endpoint. Consider additional measures like IP whitelisting or a VPN for sensitive environments.
- **Monitoring**: The `monitor-and-purge.sh` script assumes local file monitoring. For remote backends (e.g., S3), integrate with their APIs or webhooks for change notifications.
- **Scaling**: For production, consider adding load balancers or multiple backend instances in the `upstream` blocks:
  ```nginx
  upstream backend1 {
      server backend1-a:8081;
      server backend1-b:8081;
  }
  ```

If you need help with specific backend integrations (e.g., S3, Kubernetes) or advanced features (e.g., custom logging, rate limiting), let me know!
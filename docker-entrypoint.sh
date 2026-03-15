#!/bin/sh

# Overwrite the compiled config.json using runtime environment variables
cat <<EOF > /usr/share/nginx/html/assets/assets/config.json
{
  "coreBaseUrl": "${CORE_API_URL:-http://localhost:8080}",
  "userBaseUrl": "${USER_API_URL:-http://localhost:8073}"
}
EOF

# Start nginx
exec nginx -g 'daemon off;'

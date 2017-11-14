#!/bin/sh

set -euo pipefail

# Validate environment variables
: "${UPSTREAM_HOST:?Set UPSTREAM_HOST using --env}"
: "${UPSTREAM_PORT:?Set UPSTREAM_PORT using --env}"
PROTOCOL=${PROTOCOL:=HTTP}
USER=${USER:=''}
PASSWORD=${PASSWORD:=''}

if [ "$PROTOCOL" = "HTTP" ]; then
  PROTO=http
fi

if [ "$PROTOCOL" = "HTTPS" ]; then
  PROTO=https
fi


# Template an nginx.conf
cat <<EOF >/etc/nginx/nginx.conf
user nginx;
worker_processes 2;
events {
  worker_connections 1024;
}
EOF

if [ "$PROTOCOL" = "HTTP" ] || [ "$PROTOCOL" = "HTTPS" ]; then
cat <<EOF >>/etc/nginx/nginx.conf
http {
  real_ip_header X-Forwarded-For;
  set_real_ip_from 10.0.0.0/8;
  server {
    location / {
      # Reject requests with unsupported HTTP method
      if (\$request_method !~ ^(GET|POST|HEAD|OPTIONS|PUT|DELETE)$) {
        return 405;
      }
      proxy_redirect          off;
      proxy_set_header        Host            \$host;
      proxy_set_header        X-Real-IP       \$remote_addr;
      proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
      client_max_body_size    10m;
      client_body_buffer_size 128k;
      proxy_connect_timeout   90;
      proxy_send_timeout      90;
      proxy_read_timeout      90;
      proxy_buffering off;
      proxy_ignore_client_abort on;
            
      #Auth turned off by default      
      ##auth_basic "Login required";
      ##auth_basic_user_file /etc/nginx/.htpasswd;
      ##proxy_set_header       Authorization "";

      proxy_pass ${PROTO}://${UPSTREAM_HOST}:${UPSTREAM_PORT};
    }
  }
}
EOF
  if [ -n "${USER}" ]; then
    echo -n ${USER}':' >> /etc/nginx/.htpasswd
    echo $(openssl passwd -apr1 ${PASSWORD}) >> /etc/nginx/.htpasswd
    # Activate auth
    sed -e 's/\##//g' /etc/nginx/nginx.conf > /etc/nginx/nginx.conf.auth
    mv /etc/nginx/nginx.conf.auth /etc/nginx/nginx.conf
  fi
elif [ "$PROTOCOL" == "TCP" ]; then
cat <<EOF >>/etc/nginx/nginx.conf
stream {
  server {
    listen ${UPSTREAM_PORT};
    proxy_pass ${UPSTREAM_HOST}:${UPSTREAM_PORT};
  }
}
EOF
else
echo "Unknown PROTOCOL. Valid values are HTTP, HTTPS or TCP."
fi

echo "Proxy ${PROTOCOL} for ${UPSTREAM_HOST}:${UPSTREAM_PORT}"

# Launch nginx in the foreground
/usr/sbin/nginx -g "daemon off;"

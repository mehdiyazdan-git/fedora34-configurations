#!/bin/bash

set -euo pipefail  # Enable strict error handling

# --- Constants ---
REACTJS_DIR="/home/vagrant/reactjs"
REPO_URL="https://github.com/mehdiyazdan-git/parsparand-reporter-application-web.git"
PROJECT_NAME="parsparand-reporter-application-web"
SPRING_BOOT_APP_DIR="/home/vagrant/parsparand-reporter-application"
SPRING_BOOT_APP_PROPERTIES="$SPRING_BOOT_APP_DIR/src/main/resources/application.properties"

# --- Functions ---

function clone_react_app() {
    if [ -d "$REACTJS_DIR/$PROJECT_NAME" ]; then
        echo "Project directory already exists. Skipping clone..."
    else
        mkdir -p "$REACTJS_DIR"
        git clone "$REPO_URL" "$REACTJS_DIR/$PROJECT_NAME"
    fi
}

function configure_permissions() {
    sudo chown -R vagrant:vagrant "$REACTJS_DIR/$PROJECT_NAME"
    sudo chmod -R 755 "$REACTJS_DIR/$PROJECT_NAME"
}

function build_and_install_dependencies() {
    pushd "$REACTJS_DIR/$PROJECT_NAME"
    if ! command -v npm >/dev/null; then
        echo "Node.js and npm are not installed. Please install them first."
        exit 1
    fi
    npm install
    npm run build
    popd
}

function create_systemd_service() {
    local service_file="$REACTJS_DIR/$PROJECT_NAME/$PROJECT_NAME.service"

    if [ ! -f "$service_file" ]; then
        echo "Service file not found: $service_file"
        exit 1
    fi

    sudo cp "$service_file" /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable "$PROJECT_NAME"
    sudo systemctl start "$PROJECT_NAME"
}


function set_environment_variables() {
    local env_file="$REACTJS_DIR/$PROJECT_NAME/.env"
    # shellcheck disable=SC2155
    local ip_address=$(hostname -I | awk '{print $1}')
    local default_server_port=9090  # New: Default server port

    read -rp "Enter the port your Spring Boot backend is listening on (default: $default_server_port): " SERVER_PORT
    SERVER_PORT=${SERVER_PORT:-$default_server_port}  # Use default if not provided

    # Create or update the .env file
    cat <<EOF > "$env_file"
PORT=3000
REACT_APP_IPADDRESS=$ip_address
REACT_APP_PORT=$SERVER_PORT  # Use the same port for both React and Spring Boot
EOF

    echo "Environment variables set in $env_file"

    # Update application.properties for Spring Boot
    if [ -f "$SPRING_BOOT_APP_PROPERTIES" ]; then
        sed -i "s/^server.port=.*/server.port=$SERVER_PORT/" "$SPRING_BOOT_APP_PROPERTIES"
        echo "Updated server.port in $SPRING_BOOT_APP_PROPERTIES"
    else
        echo "Warning: application.properties not found at $SPRING_BOOT_APP_PROPERTIES"
    fi
}

# --- Main Script ---

clone_react_app
configure_permissions
build_and_install_dependencies
set_environment_variables
create_systemd_service

echo "ReactJS application setup complete!"

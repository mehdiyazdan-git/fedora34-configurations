#!/bin/bash

set -euo pipefail  # Enable strict error handling

# --- Functions ---

function get_postgresql_credentials() {
    if [ $# -ge 3 ]; then
        pgsql_username="$1"
        pgsql_password="$2"
        pgsql_database="$3"
    else
        read -rp "Enter PostgreSQL Username: " pgsql_username
        read -rsp "Enter PostgreSQL Password: " pgsql_password
        echo "" # Newline for clarity
        read -rp "Enter PostgreSQL Database Name: " pgsql_database
    fi
}

function configure_java_alternatives() {
    local java_path="/usr/lib/jvm/java-17-openjdk/bin/java"
    local javac_path="/usr/lib/jvm/java-17-openjdk/bin/javac"

    if ! command -v java >/dev/null; then
        echo "Java is not installed. Please install OpenJDK 17 first."
        exit 1
    fi

    sudo update-alternatives --install /usr/bin/java java "$java_path" 100
    sudo update-alternatives --install /usr/bin/javac javac "$javac_path" 100
    sudo update-alternatives --config java
    sudo update-alternatives --config javac
}

function create_application_properties() {
    cat <<EOF > application.properties
DB_USERNAME=${pgsql_username}
DB_PASSWORD=${pgsql_password}
DB_HOST=localhost
DB_PORT=5432
DB_NAME=${pgsql_database}
DB_URL=jdbc:postgresql://\$DB_HOST:\$DB_PORT/\$DB_NAME
EOF
}

# --- Main Script ---

get_postgresql_credentials "$@"  # Get credentials (args or input)

configure_java_alternatives      # Set up Java alternatives

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin

create_application_properties   # Create the properties file

echo "Java and PostgreSQL configuration complete."
echo "You can now run your Java application with the generated application.properties file."
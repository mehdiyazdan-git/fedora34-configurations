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

function configure_git() {
    git config --global user.name "mehdiyazdan"
    git config --global user.email "yazdanparast.ubuntu@gmail.com"
    git config --global credential.helper store
}

function clone_and_build_project() {
    local repo_url="https://github.com/mehdiyazdan-git/parsparand-reporter-application.git"
    local project_dir="parsparand-reporter-application"

    if [ -d "$project_dir" ]; then
        echo "Project directory already exists. Skipping clone..."
    else
        git clone "$repo_url"
    fi
    pushd "$project_dir"
    mvn clean install
    popd
}

function create_systemd_service() {
    local jar_file="/home/vagrant/parsparand-reporter-application/target/parsparand-reporter-application-0.0.1-SNAPSHOT.jar"
    local service_file="/home/vagrant/parsparand-reporter-application/parsparand-reporter-application.service"

    sudo cp "$jar_file" /usr/local/bin/parsparand-reporter-application.jar
    sudo cp "$service_file" /etc/systemd/system/parsparand-reporter-application.service
    sudo systemctl daemon-reload
    sudo systemctl enable parsparand-reporter-application
    sudo systemctl start parsparand-reporter-application
}

# --- Main Script ---

get_postgresql_credentials "$@"

configure_java_alternatives

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin

configure_git

clone_and_build_project

create_systemd_service

create_application_properties

echo "Java, PostgreSQL, Git, and project configuration complete."

#!/bin/bash

# Check for parameters and set them as environment variables
if [ $# -lt 3 ]; then
    echo "Usage: $0 <username> <password> <database_name>"
    exit 1
fi

export PGUSER="$1"
export PGPASSWORD="$2"
export PGDATABASE="$3"

# Initialize the PostgreSQL data directory
echo "Initializing PostgreSQL database..."
sudo postgresql-setup initdb

# Enable and start PostgreSQL service
echo "Starting PostgreSQL service..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Create a new user with the provided password
echo "Creating user '$PGUSER'..."
sudo -u postgres psql -c "CREATE USER $PGUSER WITH PASSWORD '$PGPASSWORD';"

# Create a new database with the provided name
echo "Creating database '$PGDATABASE'..."
sudo -u postgres psql -c "CREATE DATABASE $PGDATABASE;"

# Grant all privileges on the database to the user
echo "Granting privileges to user '$PGUSER' on database '$PGDATABASE'..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $PGDATABASE TO $PGUSER;"

# Make the user a superuser
echo "Promoting user '$PGUSER' to superuser..."
sudo -u postgres psql -c "ALTER USER $PGUSER WITH SUPERUSER;"

echo "PostgreSQL setup complete!"

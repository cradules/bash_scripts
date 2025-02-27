#!/bin/bash

set -e

echo "Updating package list..."
sudo apt update -y

echo "Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

echo "Starting and enabling PostgreSQL service..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Detect the installed PostgreSQL version
POSTGRES_VERSION=$(psql --version | awk '{print $3}' | cut -d'.' -f1)

# Confirm installation directory
PG_HBA_CONF="/etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf"

if [[ ! -f "$PG_HBA_CONF" ]]; then
    echo "Error: PostgreSQL configuration file not found at $PG_HBA_CONF"
    exit 1
fi

# Prompt for postgres user password
while true; do
    read -sp "Enter a password for the 'postgres' user: " POSTGRES_PASSWORD
    echo ""
    read -sp "Confirm password: " POSTGRES_PASSWORD_CONFIRM
    echo ""

    if [[ "$POSTGRES_PASSWORD" == "$POSTGRES_PASSWORD_CONFIRM" ]]; then
        break
    else
        echo "Passwords do not match. Please try again."
    fi
done

# Set the password for the postgres user
echo "Setting password for PostgreSQL user 'postgres'..."
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';"

# Configure PostgreSQL for password authentication
echo "Updating authentication method in pg_hba.conf..."
sudo sed -i "s/^local\s*all\s*postgres\s*peer/local all postgres md5/" "$PG_HBA_CONF"

# Restart PostgreSQL to apply changes
echo "Restarting PostgreSQL..."
sudo systemctl restart postgresql

echo "PostgreSQL installation and setup complete!"
echo "You can now connect using: psql -U postgres -W"

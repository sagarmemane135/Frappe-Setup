#!/bin/bash

# 1. Start Services
echo "Starting MariaDB and Redis..."
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi
mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld /var/lib/mysql
sudo -u mysql mariadbd &

# Start Redis servers
redis-server --daemonize yes

sleep 5

# 2. Set Database Root Password
if [ ! -f "/var/lib/mysql/.password_set" ]; then
    if [ ! -z "$DB_ROOT_PASSWORD" ]; then
        echo "Setting database root password..."
        mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD'; FLUSH PRIVILEGES;" 2>/dev/null || {
            echo "Password may already be set, continuing..."
        }
        echo "Password set" > /var/lib/mysql/.password_set
    fi
else
    echo "Database password already configured."
fi

# Set charset configuration
if [ ! -z "$DB_ROOT_PASSWORD" ]; then
    mariadb -u root -p"$DB_ROOT_PASSWORD" -e "SET GLOBAL character_set_server = 'utf8mb4'; SET GLOBAL collation_server = 'utf8mb4_unicode_ci';" 2>/dev/null || \
    mariadb -u root -e "SET GLOBAL character_set_server = 'utf8mb4'; SET GLOBAL collation_server = 'utf8mb4_unicode_ci';" 2>/dev/null || true
else
    mariadb -u root -e "SET GLOBAL character_set_server = 'utf8mb4'; SET GLOBAL collation_server = 'utf8mb4_unicode_ci';" 2>/dev/null || true
fi

# 3. Initialize Bench in the mounted volume (much faster!)
SNAME=${SITE_NAME:-development.localhost}
APASS=${ADMIN_PASSWORD:-admin}

# Ensure proper ownership first
chown -R frappe:frappe /home/frappe/frappe-bench

if [ ! -f "/home/frappe/frappe-bench/Procfile" ]; then
    echo "Initializing bench directly in mounted volume..."
    
    # Ensure proper ownership first
    chown -R frappe:frappe /home/frappe/frappe-bench
    
    # Initialize bench with force flag to overwrite existing structure
    sudo -u frappe bash -c "
        cd /home/frappe/frappe-bench
        
        # Initialize bench directly in the current directory with --ignore-exist flag
        export PATH=/home/frappe/.local/bin:\$PATH
        bench init --frappe-branch version-15 --skip-redis-config-generation --ignore-exist .
        
        echo 'Bench initialized successfully in mounted volume!'
    "

    # Create site
    echo "Creating site: $SNAME with Admin Password: $APASS"
    sudo -u frappe -i bash -c "cd /home/frappe/frappe-bench && \
        export PATH=/home/frappe/.local/bin:\$PATH && \
        bench new-site $SNAME --admin-password $APASS --db-root-password '$DB_ROOT_PASSWORD' --install-app frappe --force && \
        bench use $SNAME"
fi

# 4. Start Redis Queue Server
if [ -f "/home/frappe/frappe-bench/config/redis_queue.conf" ]; then
    echo "Starting Redis queue server..."
    redis-server /home/frappe/frappe-bench/config/redis_queue.conf --daemonize yes
    sleep 2
fi

# 5. Start Bench
echo "------------------------------------------------"
echo "Site $SNAME is ready. Starting bench..."
echo "------------------------------------------------"

# Ensure proper permissions and start bench
chown -R frappe:frappe /home/frappe/frappe-bench 2>/dev/null || true

sudo -u frappe -i bash -c "cd /home/frappe/frappe-bench && \
    export PATH=/home/frappe/.local/bin:\$PATH && \
    bench start"
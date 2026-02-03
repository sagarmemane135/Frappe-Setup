#!/bin/bash

# 1. Start Services
echo "Starting MariaDB and Redis..."
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi
mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld /var/lib/mysql
sudo -u mysql mariadbd &
redis-server --daemonize yes
sleep 5

# 2. Set Database Root Password from Args
# If DB_ROOT_PASSWORD is provided, we set it; otherwise, we use empty for local dev
if [ ! -z "$DB_ROOT_PASSWORD" ]; then
    mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD'; FLUSH PRIVILEGES;"
fi
mariadb -u root -p"$DB_ROOT_PASSWORD" -e "SET GLOBAL character_set_server = 'utf8mb4'; SET GLOBAL collation_server = 'utf8mb4_unicode_ci';"

# 3. SYNC & AUTO-CREATE SITE
# We use defaults if variables aren't passed
SNAME=${SITE_NAME:-development.localhost}
APASS=${ADMIN_PASSWORD:-admin}

if [ ! -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "First run detected. Syncing framework..."
    cp -rp /home/frappe/frappe-template/. /home/frappe/frappe-bench/
    chown -R frappe:frappe /home/frappe/frappe-bench

    echo "Creating site: $SNAME with Admin Password: $APASS"
    sudo -u frappe -i bash -c "cd /home/frappe/frappe-bench && \
        bench new-site $SNAME --admin-password $APASS --db-root-password '$DB_ROOT_PASSWORD' --install-app frappe --force" \
        bench use $SNAME"
fi

# 4. AUTO-START BENCH
echo "------------------------------------------------"
echo "Site $SNAME is ready. Starting bench..."
echo "------------------------------------------------"
chown -R frappe:frappe /home/frappe/frappe-bench
sudo -u frappe -i bash -c "cd /home/frappe/frappe-bench && bench start"
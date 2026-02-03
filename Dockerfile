# 1. Use Ubuntu 24.04 for Python 3.12 support
FROM ubuntu:24.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# 2. Update dependencies
RUN apt-get update && apt-get install -y \
    python3-dev python3-pip python3-venv \
    software-properties-common git build-essential \
    libmariadb-dev mariadb-server mariadb-client libssl-dev \
    pkg-config ca-certificates curl gnupg \
    wkhtmltopdf redis-server sudo \
    cron lsb-release locales \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn

# 3. Create User and setup PATH
RUN useradd -ms /bin/bash frappe \
    && echo "frappe ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER frappe
WORKDIR /home/frappe

# Ensure Python binaries are in PATH
ENV PATH="/home/frappe/.local/bin:${PATH}"

# 4. Install Bench
RUN pip3 install --user frappe-bench --break-system-packages

# 5. Initialize Bench with the stable version-15
# Initialize into a template folder so we can copy it to the mount at runtime
RUN bench init --frappe-branch version-15 --skip-redis-config-generation --skip-assets --python python3 /home/frappe/frappe-template
WORKDIR /home/frappe/frappe-bench

EXPOSE 8000 3306 9000
USER root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
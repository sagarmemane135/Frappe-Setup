# 🚀 Frappe All-in-One Dev Container

This project provides a **Zero-Configuration** Frappe environment. It bakes all system dependencies (Python 3.12, Node 20, MariaDB, Redis) into a single Docker image, allowing any developer to start a Frappe site in seconds without manual installation.

## ✨ Features

* **Ubuntu 24.04 & Python 3.12**: Modern stack ready for Frappe v15/v16.
* **Auto-Initialization**: Automatically syncs the framework and creates a new site on the first run.
* **Persistent Development**: All code (`apps`), sites, and database data are stored on your local machine.
* **Dynamic Config**: Set your site name and passwords via container arguments (ENV variables).

---

## 🛠️ Getting Started

### 1. Prerequisites

* [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed.
* PowerShell (Windows) or Terminal (Linux/Mac).

### 2. Clone & Build

Clone this repository and build the Docker image:

```powershell
git clone https://github.com/sagarmemane135/Frappe-Setup.git
cd Frappe-Setup
docker build -t frappe-dev .
```

### 3. Run the Container

Run the following command. The container will detect it's a first-time setup and automatically initialize everything.

```powershell
docker run -d --name frappe-dev-container `
  -p 8000:8000 -p 3306:3306 `
  -e SITE_NAME="menumate.localhost" `
  -e ADMIN_PASSWORD="admin" `
  -e DB_ROOT_PASSWORD="root" `
  -v "${PWD}/mariadb-data:/var/lib/mysql" `
  -v "${PWD}/apps:/home/frappe/frappe-bench/apps" `
  -v "${PWD}/sites:/home/frappe/frappe-bench/sites" `
  -v "${PWD}/logs:/home/frappe/frappe-bench/logs" `
  frappe-dev
```

**Note:** For Linux/Mac, replace `${PWD}` with `$(pwd)` and remove the backticks (`` ` ``).

---

## ⚙️ Arguments (Environment Variables)

| Variable | Description | Default |
| --- | --- | --- |
| `SITE_NAME` | The name of the Frappe site to create. | `development.localhost` |
| `ADMIN_PASSWORD` | The login password for the 'Administrator' user. | `admin` |
| `DB_ROOT_PASSWORD` | The root password for the MariaDB database. | (empty) |

---

## 📁 Folder Structure

Once the container starts, it will populate your local directory with:

* **`/apps`**: Contains the Frappe framework source code. Drop your custom apps (like *MenuMate*) here.
* **`/sites`**: Contains your site configurations and uploaded files.
* **`/mariadb-data`**: Persistent database files. Your data survives container deletion.

---

## 🛠️ Common Commands

### Accessing the Site

Once the container is running, access your Frappe site at:
- **URL:** `http://localhost:8000`
- **Username:** `Administrator`
- **Password:** Value you set for `ADMIN_PASSWORD` (default: `admin`)

### Accessing the Terminal

To run bench commands manually (e.g., `bench get-app` or `bench console`):

```powershell
docker exec -it frappe-dev-container bash
cd /home/frappe/frappe-bench
```

### Installing Custom Apps

To install a custom Frappe app (e.g., from GitHub):

```powershell
docker exec -it -u frappe frappe-dev-container bash
cd /home/frappe/frappe-bench
bench get-app <app-name> <git-repo-url>
bench --site <your-site-name> install-app <app-name>
bench restart
```

Example:
```bash
bench get-app erpnext https://github.com/frappe/erpnext.git
bench --site menumate.localhost install-app erpnext
```

### Checking Logs

If the container is taking a while to start, monitor the progress:

```powershell
docker logs -f frappe-dev-container
```

### Stopping & Restarting

* **To Stop:** `docker stop frappe-dev-container`
* **To Start:** `docker start frappe-dev-container` (The site will be ready in seconds as it skips initialization)
* **To Remove:** `docker rm frappe-dev-container` (Your data in mounted volumes will persist)

---

## 🗂️ Data Persistence & Git Strategy

The `.gitignore` file excludes:
- `/apps` - Frappe framework and custom app code
- `/sites` - Site configurations and user data
- `/mariadb-data` - Database files
- `/logs` - Application logs

**Why?** These directories contain generated data, dependencies, and large files that shouldn't be version controlled. Only the Docker configuration (Dockerfile, entrypoint.sh) and documentation are tracked in git.

**Your development workflow:**
1. Clone this repo and build the image
2. Run the container to generate local data directories
3. Develop your custom apps in the `/apps` directory
4. Version control your custom apps separately in their own git repositories

---

## 🐛 Troubleshooting

### Container Fails to Start

Check logs for errors:
```powershell
docker logs frappe-dev-container
```

### Port Already in Use

If you see "port is already allocated" error:
- **Port 8000:** Stop any local web servers or change the mapping: `-p 8001:8000`
- **Port 3306:** Stop local MySQL/MariaDB or change the mapping: `-p 3307:3306`

### Slow First Run on Windows

The initial sync of ~30,000 files to Windows volumes can take 5-10 minutes. Subsequent starts are instant. Check progress with `docker logs -f frappe-dev-container`.

### Can't Access Site After Installation

1. Ensure the container is running: `docker ps`
2. Wait for initialization to complete (check logs)
3. Try accessing `http://localhost:8000` or `http://127.0.0.1:8000`
4. Check that your `SITE_NAME` matches the URL you're accessing

### Database Connection Issues

Ensure the `DB_ROOT_PASSWORD` you set during container creation is used consistently. If you need to reset:
```powershell
docker stop frappe-dev-container
docker rm frappe-dev-container
# Remove the mariadb-data directory if you want a fresh database
docker run -d ...  # Run the container again
```

---

## 📝 Notes for DevOps Engineers

* **Syncing Bottleneck:** The first run involves moving ~30,000 files from the image to the host. On Windows, this can take 5-8 minutes. Subsequent starts are near-instant.
* **Port Conflicts:** Ensure ports `8000` and `3306` are not being used by a local installation of MariaDB or Frappe.
* **Production Use:** This setup is optimized for development. For production, use separate containers for services (MariaDB, Redis), implement proper secrets management, and use production-grade configurations.
* **Frappe Version:** Currently set to version-15 branch. Modify the Dockerfile to change versions.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

This project is provided as-is for development purposes. Frappe Framework is licensed under the MIT License.

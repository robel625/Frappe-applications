# ERPNext Healthcare v15 — Docker Installation Guide

A complete, step-by-step guide to install **ERPNext + Healthcare Module (v15)** using Docker on Windows, macOS, or Linux.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Clone the Repository](#2-clone-the-repository)
3. [Build the Docker Image](#3-build-the-docker-image)
4. [Start the Stack](#4-start-the-stack)
5. [Access ERPNext Healthcare](#5-access-erpnext-healthcare)
6. [Reset / Reinstall](#6-reset--reinstall)
7. [Useful Commands](#7-useful-commands)
8. [Troubleshooting](#8-troubleshooting)
9. [Architecture Overview](#9-architecture-overview)
10. [Default Credentials](#10-default-credentials)

---

## 1. Prerequisites

Before you begin, make sure you have:

### Docker Desktop
- **Windows:** [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) (requires WSL 2 enabled)
- **macOS:** [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
- **Linux:** Docker Engine v23.0+ with Docker Compose v2

### System Requirements
| Resource | Minimum |
|----------|---------|
| RAM | 4 GB (6 GB recommended) |
| Disk | 20 GB free space |
| CPU | 2 cores (4 recommended) |

### Verify Docker is Running
Open a terminal (PowerShell on Windows, Terminal on macOS/Linux) and run:

```bash
docker --version
docker compose version
```

Both commands should output version numbers. If they don't, start Docker Desktop and try again.

---

## 2. Clone the Repository

```bash
git clone https://github.com/frappe/frappe_docker.git
cd frappe_docker
```

> **Note:** If you already have the repository cloned, just `cd` into it.

---

## 3. Build the Docker Image

This project uses a custom Dockerfile (`Dockerfile.healthcare`) that builds ERPNext v15 with the Healthcare module from scratch.

### What Gets Built
- **Frappe Framework** v15 (the base web framework)
- **ERPNext** v15 (the ERP system)
- **Healthcare** v15 (patient management, clinical procedures, lab management, etc.)

### Build Command

**Windows (PowerShell):**
```powershell
docker build --no-cache --tag erpnext-healthcare:v15 --file Dockerfile.healthcare .
```

**macOS / Linux:**
```bash
docker build --no-cache --tag erpnext-healthcare:v15 --file Dockerfile.healthcare .
```

**Or on Windows, double-click:**
```
build-healthcare.bat
```

### Build Time
| First Build | Subsequent Builds (cached) |
|-------------|---------------------------|
| 20–40 minutes | 1–3 minutes |

The first build downloads all dependencies, clones source code, compiles assets, and installs apps. Subsequent builds reuse Docker cache layers.

### What Happens During the Build
1. Downloads Python 3.11 base image (Debian Bookworm)
2. Installs system dependencies (Node.js 18, Nginx, wkhtmltopdf, MariaDB client, etc.)
3. Runs `bench init` to set up Frappe Framework v15
4. Runs `bench get-app erpnext` to install ERPNext v15
5. Runs `bench get-app healthcare` to install the Healthcare module v15
6. Copies entrypoint and startup scripts
7. Fixes Windows line endings (CRLF → LF) in shell scripts

### Build Success
You should see:
```
=> naming to docker.io/library/erpnext-healthcare:v15 done
```

---

## 4. Start the Stack

### First Time Setup

```bash
docker compose -f pwd.yml down -v
docker compose -f pwd.yml up -d
```

The `-v` flag removes any old data volumes to ensure a clean start.

### Wait for Site Creation

The `create-site` service automatically:
1. Waits for MariaDB and Redis to be ready
2. Creates the "frontend" site
3. Installs Frappe, ERPNext, and Healthcare on the site

Check progress:
```bash
docker compose -f pwd.yml logs -f create-site
```

You'll see progress bars for:
- Installing frappe...
- Installing erpnext...
- Installing healthcare...

**This takes 5–10 minutes.** Wait until you see:
```
Current Site set to frontend
```

Then press `Ctrl+C` to stop following logs.

### Verify All Services Are Running

```bash
docker compose -f pwd.yml ps -a
```

All services should show `Up` (not `Restarting`):

```
NAME                    STATUS                     PORTS
backend                 Up                         ...
configurator            Exited (0)                 ...
create-site             Exited (0)                 ...
db                      Up (healthy)               3306/tcp
frontend                Up                         0.0.0.0:8080->8080/tcp
queue-long              Up                         ...
queue-short             Up                         ...
redis-cache             Up                         6379/tcp
redis-queue             Up                         6379/tcp
scheduler               Up                         ...
websocket               Up                         ...
```

### Verify Apps Are Installed

```bash
docker compose -f pwd.yml exec backend bench --site frontend list-apps
```

Expected output:
```
frappe     15.x.x UNVERSIONED
erpnext    15.x.x UNVERSIONED
healthcare 15.x.x UNVERSIONED
```

---

## 5. Access ERPNext Healthcare

### Open in Browser

Go to: **http://localhost:8080**

### Login Credentials

| Field | Value |
|-------|-------|
| Email | `Administrator` |
| Password | `admin` |

> **Important:** Type `Administrator` with a capital "A" in the email field.

### First-Time Setup Wizard

After logging in, ERPNext will guide you through:

1. **Select Domain:** Choose "Healthcare" or "Distribution"
2. **Country:** Select your country
3. **Currency:** Set your default currency
4. **Company Name:** Enter your organization name
5. **Bank Account:** (Optional) Add bank details
6. **Fiscal Year:** Set your fiscal year start/end

Follow the wizard to complete the setup.

---

## 6. Reset / Reinstall

If something goes wrong or you want a fresh start:

### Full Reset (Destroys All Data)
```bash
docker compose -f pwd.yml down -v
docker compose -f pwd.yml up -d
```

The `-v` flag removes all data volumes (database, site files, logs).

### Restart Without Losing Data
```bash
docker compose -f pwd.yml restart
```

### Stop Without Removing
```bash
docker compose -f pwd.yml down
```

### Reset Admin Password
```bash
docker compose -f pwd.yml exec backend bench --site frontend set-admin-password admin
```

---

## 7. Useful Commands

### View Logs
```bash
# All services
docker compose -f pwd.yml logs

# Specific service
docker compose -f pwd.yml logs backend
docker compose -f pwd.yml logs create-site
docker compose -f pwd.yml logs frontend

# Follow logs in real-time
docker compose -f pwd.yml logs -f backend
```

### Enter Container Shell
```bash
docker compose -f pwd.yml exec backend bash
```

### Run Bench Commands
```bash
# List installed apps
docker compose -f pwd.yml exec backend bench --site frontend list-apps

# Clear cache
docker compose -f pwd.yml exec backend bench --site frontend clear-cache

# Backup site
docker compose -f pwd.yml exec backend bench --site frontend backup

# Migrate database (after app updates)
docker compose -f pwd.yml exec backend bench --site frontend migrate

# Set admin password
docker compose -f pwd.yml exec backend bench --site frontend set-admin-password NEW_PASSWORD
```

### Check Site Status
```bash
docker compose -f pwd.yml exec backend bench --site frontend doctor
```

### Rebuild Image After Changes
```bash
docker build --tag erpnext-healthcare:v15 --file Dockerfile.healthcare .
docker compose -f pwd.yml down
docker compose -f pwd.yml up -d
```

---

## 8. Troubleshooting

### Problem: `exec /usr/local/bin/entrypoint.sh: no such file or directory`

**Cause:** The Docker image was not built correctly, or you're using a pre-built image that doesn't include the entrypoint script.

**Fix:**
```bash
docker compose -f pwd.yml down
docker build --no-cache --tag erpnext-healthcare:v15 --file Dockerfile.healthcare .
docker compose -f pwd.yml up -d
```

### Problem: `No module named 'erpnext'` or `Could not find app "erpnext"`

**Cause:** The image doesn't have ERPNext installed. This happens when using a wrong base image.

**Fix:** Rebuild with the correct Dockerfile:
```bash
docker compose -f pwd.yml down -v
docker build --no-cache --tag erpnext-healthcare:v15 --file Dockerfile.healthcare .
docker compose -f pwd.yml up -d
```

### Problem: Services Keep Restarting (Status: `Restarting (255)`)

**Check the logs:**
```bash
docker compose -f pwd.yml logs backend
docker compose -f pwd.yml logs frontend
```

**Common causes:**
- Image not built (using wrong image tag)
- CRLF line endings in shell scripts (handled by the Dockerfile)
- MariaDB not ready yet (services depend on configurator)

### Problem: Site Says "Site frontend already exists, skipping creation"

**Cause:** A previous site data volume still exists.

**Fix:** Full reset:
```bash
docker compose -f pwd.yml down -v
docker compose -f pwd.yml up -d
```

### Problem: Cannot Access http://localhost:8080

**Check if frontend is running:**
```bash
docker compose -f pwd.yml ps frontend
```

**Check port conflicts:**
```bash
# Windows
netstat -ano | findstr :8080

# macOS / Linux
lsof -i :8080
```

If another process uses port 8080, either stop it or change the port in `pwd.yml`:
```yaml
ports:
  - "9090:8080"  # Change left side to your preferred port
```

### Problem: `Warning: MariaDB version ['11.8', '8'] is more than 10.8`

This is just a warning, not an error. The system works fine with MariaDB 11.8.

### Problem: Build Fails During `bench init`

**Check Docker resources:**
- Docker Desktop → Settings → Resources → Increase RAM to at least 4 GB
- Ensure at least 10 GB free disk space

**Check network:**
- Ensure you have internet access (build clones GitHub repos)
- If behind a proxy, configure Docker proxy settings

### Problem: Windows Line Endings (CRLF)

The `Dockerfile.healthcare` automatically strips `\r` from shell scripts during build. If you still see issues:
```bash
# Check if a script has CRLF
docker compose -f pwd.yml exec backend cat /usr/local/bin/entrypoint.sh | head -1
# Should show: #!/bin/bash (no ^M)
```

---

## 9. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Network                           │
│                  frappe_network                             │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐     │
│  │ MariaDB  │  │  Redis   │  │  Redis               │     │
│  │   :3306  │  │  Queue   │  │  Cache               │     │
│  │          │  │  :6379   │  │  :6379               │     │
│  └──────────┘  └──────────┘  └──────────────────────┘     │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │               Frappe/ERPNext Stack                    │  │
│  │                                                      │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐            │  │
│  │  │ Backend  │ │Frontend  │ │WebSocket │            │  │
│  │  │(Gunicorn)│ │ (Nginx)  │ │(SocketIO)│            │  │
│  │  │  :8000   │ │  :8080   │ │  :9000   │            │  │
│  │  └──────────┘ └────┬─────┘ └──────────┘            │  │
│  │                    │                                │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐           │  │
│  │  │Scheduler │ │Queue Long│ │Queue Short│           │  │
│  │  └──────────┘ └──────────┘ └──────────┘           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ Configurator │  │ Create-Site  │                        │
│  │  (one-shot)  │  │  (one-shot)  │                        │
│  └──────────────┘  └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘
                          │
                    ┌─────┴─────┐
                    │  :8080    │
                    └───────────┘
                          │
                    ┌─────┴─────┐
                    │  Browser  │
                    │ localhost │
                    └───────────┘
```

### Services Explained

| Service | Purpose | Runs Once? |
|---------|---------|-----------|
| **db** | MariaDB database server | Persistent |
| **redis-cache** | Caching layer | Persistent |
| **redis-queue** | Job queue broker | Persistent |
| **configurator** | Sets up site config (DB, Redis, etc.) | Yes (exits) |
| **create-site** | Creates the site and installs apps | Yes (exits) |
| **backend** | Gunicorn app server (API) | Persistent |
| **frontend** | Nginx reverse proxy (serves the UI) | Persistent |
| **websocket** | Socket.IO for real-time updates | Persistent |
| **queue-long** | Processes long-running background jobs | Persistent |
| **queue-short** | Processes short background jobs | Persistent |
| **scheduler** | Triggers scheduled tasks | Persistent |

---

## 10. Default Credentials

| Item | Value |
|------|-------|
| **URL** | http://localhost:8080 |
| **Admin Email** | `Administrator` |
| **Admin Password** | `admin` |
| **Database Root User** | `root` |
| **Database Root Password** | `admin` |
| **Site Name** | `frontend` |

> **Security:** Change the admin password immediately in production. Never use these defaults in a public-facing deployment.

---

## File Reference

| File | Purpose |
|------|---------|
| `Dockerfile.healthcare` | Builds the ERPNext + Healthcare Docker image |
| `pwd.yml` | Docker Compose file that defines all services |
| `apps.json` | Lists apps to install (ERPNext + Healthcare) |
| `build-healthcare.bat` | Windows batch script to build the image |
| `resources/core/main-entrypoint.sh` | Container entrypoint script |
| `resources/core/start.sh` | Gunicorn startup script |

---

## Quick Start (Copy & Paste)

```bash
# 1. Clone
git clone https://github.com/frappe/frappe_docker.git
cd frappe_docker

# 2. Build (20-40 min first time)
docker build --no-cache --tag erpnext-healthcare:v15 --file Dockerfile.healthcare .

# 3. Start
docker compose -f pwd.yml down -v
docker compose -f pwd.yml up -d

# 4. Wait for site creation (5-10 min)
docker compose -f pwd.yml logs -f create-site

# 5. Open http://localhost:8080
#    Email: Administrator
#    Password: admin
```

---

## License

This installation guide is provided as-is. ERPNext and Frappe are licensed under the [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.html). The Healthcare module (Marley Health by Earthians) is also licensed under GNU GPL v3.

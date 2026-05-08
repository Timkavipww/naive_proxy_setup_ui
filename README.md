# 📘 NaiveProxy Full Stack Server

Production-ready installer for a **NaiveProxy + Caddy + Web UI + Backend API** stack.

This project automates full deployment of a secure proxy system with:

* NaiveProxy (via Caddy forwardproxy module)
* Automatic TLS (Let’s Encrypt)
* Web Admin Panel (React frontend)
* Backend API (FastAPI + Uvicorn)
* User management system
* Firewall + TCP optimization
* One-command install / uninstall

---

# 🧱 Architecture Overview

```bash
                    ┌──────────────┐
                    │  Browser UI  │
                    │ React Panel  │
                    └──────┬───────┘
                           │ HTTPS
                           ▼
                 ┌───────────────────┐
                 │   Caddy Server    │
                 │ TLS termination   │
                 │ Reverse proxy     │
                 └──────┬────┬───────┘
                        │    │
        ┌───────────────┘    └────────────────┐
        ▼                                    ▼
NaiveProxy endpoint                 Backend API (FastAPI)
forwardproxy module                /api/users, /create-user
```

---

# 🚀 Features

## 🔐 Proxy Core (NaiveProxy)

* Caddy-based forward proxy
* TLS via Let’s Encrypt
* Basic Auth per user
* Domain-based access control
* Probe resistance enabled

---

## 🌐 Web UI (React)

* Admin dashboard
* User management (create / delete)
* Copy NaiveProxy & Desktop links
* Show / hide credentials
* Auth via admin password

---

## ⚙️ Backend API (FastAPI)

* `/api/users` — list users
* `/api/create-user` — create proxy user
* `/api/users/{id}` — delete user
* Admin authentication via header
* Generates:

  * NaiveProxy link
  * Desktop proxy link

---

## 🛠 System automation

* Automatic Go installation
* xcaddy build system
* systemd service for Caddy
* optional backend background process (uvicorn)
* frontend build automation
* UFW firewall configuration
* BBR TCP optimization

---

# 📦 Installation

## 1. Clone project

```bash
git clone <repo>
cd naiveproxy
```

---

## 2. Run installer

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

---

## 3. Setup process includes:

* Proxy domain
* TLS email (shared for all certificates)
* Optional UI domain
* Admin password (if UI enabled)

---

# 🌍 Access after install

## Proxy link

```bash
naive+https://USER:PASSWORD@your-domain:443
```

---

## Web UI

```bash
https://ui.your-domain
```

---

## API

```bash
https://ui.your-domain/api/users
```

---

# 👤 User Management

Users are generated automatically and stored in:

```bash
/etc/caddy/users/
```

Each user contains:

* login
* password
* NaiveProxy link
* Desktop proxy link

---

# 🧪 Backend

Runs via:

```bash
uvicorn app:app --host 0.0.0.0 --port 8000
```

Logs:

```bash
api.log
```

---

# 🌐 Frontend build

If UI enabled:

```bash
cd frontend
npm install
npm run build
```

Output:

```bash
/var/www/react
```

---

# 🔐 Security

* Admin auth via header:

  ```bash
  x-admin-password
  ```bash

* Password stored locally in:

  ```bash
  /root/naiveproxy.env
  ```

* TLS automatically issued via Caddy

---

# ⚡ System requirements

* Ubuntu / Debian
* Root access
* Ports:

  * 80 (HTTP / ACME challenge)
  * 443 (TLS / proxy)

---

# 🧹 Uninstall

Full cleanup script:

```bash
chmod +x scripts/uninstall.sh
./scripts/uninstall.sh
```

Supports:

* Stop Caddy service
* Remove Go / xcaddy
* Remove backend (optional)
* Remove frontend (optional)
* Remove `/var/www/react`
* Remove configs `/etc/caddy`
* Clean firewall rules

---

# 📁 Project structure

```bash
.
├── scripts/
│   ├── install.sh
│   └── uninstall.sh
│
├── backend/
│   ├── app.py
│   ├── requirements.txt
│   └── .env.example
│
├── frontend/
│   ├── src/
│   ├── package.json
│   └── dist/
│
├── index.html
└── README.md
```

---

# 🔁 State persistence

Installation state stored in:

```bash
/root/naiveproxy.env
```

Contains:

* DOMAIN
* EMAIL
* LOGIN
* PASSWORD

---

# 🧠 Notes

* Caddy is compiled via `xcaddy` with forwardproxy module
* Backend is intentionally lightweight (no systemd by default)
* Frontend is static build served via Caddy
* UI and proxy domains can be separated
* TLS email is shared across all certificates (recommended)

---

# ⚠️ Known limitations

* Backend runs via `nohup` (not systemd yet)
* No multi-node support
* No database layer (users stored in files)
* No rate limiting by default

---

# 🚀 Future improvements

Planned upgrades:

* systemd backend service
* Redis / DB user storage
* rate limiting per user
* dashboard analytics
* auto-reload frontend/backend
* multi-domain support
* docker version

---

# 👤 Author

Based on:

[https://github.com/RedDevBook/naiveproxy-server-setup](https://github.com/RedDevBook/naiveproxy-server-setup)

Extended into full-stack proxy control system with UI + backend automation.

---

# 💡 Summary

This is no longer just an installer.

It is a **full proxy management system** with:

* Proxy server
* Admin panel
* API backend
* Automated deployment

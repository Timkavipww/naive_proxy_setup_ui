# NaiveProxy Server Installer (Caddy + ForwardProxy)

Автоматический установщик и удаляющий скрипт для развертывания:

- Caddy (с модулем forwardproxy / NaiveProxy)
- Go (автоматическая установка или проверка версии)
- xcaddy (для сборки кастомного Caddy)
- TLS (Let’s Encrypt через Caddy)
- Basic Auth пользователи
- UFW firewall
- BBR TCP optimization

---

# 📦 Возможности

## Install script:

- Проверка ОС (Debian/Ubuntu)
- Проверка архитектуры (amd64 / arm64)
- Проверка занятых портов (80/443)
- Автоустановка Go (если нет или версия < 1.26)
- Сборка Caddy через xcaddy
- Генерация пользователей NaiveProxy
- TLS автоматом (Let's Encrypt)
- Настройка systemd сервиса
- Настройка firewall (UFW)
- Включение BBR

---

## Uninstall script:
- Выборочное удаление компонентов:
  - Caddy
  - Go
  - xcaddy
  - systemd service
  - конфиги (/etc/caddy)
  - users.conf + state file
  - web root (/var/www/html)
  - firewall rules (80/443/22)
- Полный uninstall режим

---

# 🚀 Установка

```bash
chmod +x install.sh
./install.sh

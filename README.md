# NaiveProxy Server Installer (Caddy + ForwardProxy)

Автоматический установщик и деинсталлятор для развертывания NaiveProxy сервера на базе Caddy.

Проект автоматизирует установку всего стека:

- Caddy (с модулем forwardproxy / NaiveProxy)
- Go (автоматическая установка или проверка версии)
- xcaddy (сборка кастомного Caddy)
- TLS (Let’s Encrypt через Caddy)
- Basic Auth пользователи
- UFW firewall
- BBR TCP optimization

---

# 📦 Возможности

## 🚀 Install script

- Проверка ОС (Debian / Ubuntu)
- Проверка архитектуры (amd64 / arm64)
- Проверка занятых портов (80 / 443)
- Автоматическая установка Go (если нет или версия < 1.26)
- Сборка Caddy через xcaddy
- Генерация пользователей NaiveProxy
- Автоматический TLS (Let’s Encrypt)
- Настройка systemd сервиса
- Настройка firewall (UFW)
- Включение BBR (ускорение TCP)

---

## 🧹 Uninstall script

Позволяет выборочно удалить компоненты:

- Caddy
- Go
- xcaddy
- systemd service (caddy)
- конфиги `/etc/caddy`
- `users.conf` + state файл
- web root `/var/www/html`
- правила firewall (80 / 443 / 22)
- полный режим очистки системы

---

# ⚡ Быстрый старт

## Установка

```bash
chmod +x install.sh
./install.sh
````

После установки вы получите:

* домен с TLS (https)
* NaiveProxy link вида:

```
naive+https://USER:PASSWORD@your-domain.com:443
```

* конфиг пользователей:

```
/etc/caddy/users.conf
```

* статус сервиса:

```bash
systemctl status caddy
```

---

## 🔍 Логи

```bash
journalctl -u caddy -f
```

---

## 🧹 Удаление

```bash
chmod +x uninstall.sh
./uninstall.sh
```

---

# ⚙️ Требования

* Debian / Ubuntu
* root доступ
* открытые порты:

  * 80
  * 443

---

# 📁 Структура проекта

```
.
├── install.sh
├── uninstall.sh
├── index.html (опционально)
└── README.md
```

---

# 👤 Автор идеи

Основано на проекте:

[https://github.com/RedDevBook/naiveproxy-server-setup](https://github.com/RedDevBook/naiveproxy-server-setup)

---

# 🧠 Примечания

* Секреты (логин/пароль) сохраняются в `/root/naiveproxy.env`
* Caddy собирается через `xcaddy`
* Конфиги автоматически бэкапятся перед изменениями

```

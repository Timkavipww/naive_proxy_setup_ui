#!/usr/bin/env bash
set -Eeuo pipefail

STATE_FILE="/root/naiveproxy.env"

log()  { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
die()  { printf '[x] %s\n' "$*" >&2; exit 1; }

require_root() {
  [[ "${EUID}" -eq 0 ]] || die "Запусти от root"
}

confirm() {
  read -r -p "$1 [y/N]: " ans
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

remove_service() {
  log "Остановка Caddy..."
  systemctl stop caddy 2>/dev/null || true
  systemctl disable caddy 2>/dev/null || true

  rm -f /etc/systemd/system/caddy.service
  systemctl daemon-reload

  log "Caddy service удалён"
}

remove_caddy_binary() {
  if [[ -f /usr/bin/caddy ]]; then
    rm -f /usr/bin/caddy
    log "Caddy удалён"
  fi
}

remove_xcaddy() {
  if [[ -f /usr/local/bin/xcaddy ]]; then
    rm -f /usr/local/bin/xcaddy
    log "xcaddy удалён"
  fi

  if [[ -d /root/go ]]; then
    confirm "Удалить Go workspace (/root/go)?" && rm -rf /root/go
  fi
}

remove_go() {
  if [[ -d /usr/local/go ]]; then
    rm -rf /usr/local/go
    log "Go удалён (/usr/local/go)"
  fi
}

remove_caddy_config() {
  rm -rf /etc/caddy
  log "/etc/caddy удалён"
}

remove_users_and_state() {
  rm -f /etc/caddy/users.conf 2>/dev/null || true
  rm -f "$STATE_FILE" 2>/dev/null || true
  log "users.conf и state удалены"
}

remove_web_root() {
  rm -rf /var/www/html
  log "web root удалён"
}

remove_firewall() {
  log "Удаляем UFW правила 80/443..."

  ufw delete allow 80/tcp 2>/dev/null || true
  ufw delete allow 443/tcp 2>/dev/null || true

  confirm "Отключить UFW полностью?" && ufw disable || true

  log "Firewall очищен"
}

stop_backend() {
  log "Остановка backend (uvicorn)..."

  pkill -f "uvicorn app:app" 2>/dev/null || true

  # если вдруг был systemd/pm2 в будущем
  pkill -f "python3 -m uvicorn" 2>/dev/null || true

  log "Backend остановлен"
}

remove_backend() {
  if [[ -d "$PROJECT_ROOT/backend" ]]; then
    confirm "Удалить backend папку?" && rm -rf "$PROJECT_ROOT/backend"
    log "Backend удалён"
  fi
}

remove_frontend() {
  if [[ -d "$PROJECT_ROOT/frontend" ]]; then
    confirm "Удалить frontend папку?" && rm -rf "$PROJECT_ROOT/frontend"
    log "Frontend исходники удалены"
  fi
}

remove_react_build() {
  if [[ -d /var/www/react ]]; then
    if confirm "Удалить собранный frontend (/var/www/react) ?"; then
      rm -rf /var/www/react
      log "/var/www/react удалён"
    fi
  fi
}
clean_node_modules() {
  if [[ -d "$PROJECT_ROOT/frontend/node_modules" ]]; then
    confirm "Удалить node_modules?" && rm -rf "$PROJECT_ROOT/frontend/node_modules"
    log "node_modules удалены"
  fi
}

full_cleanup() {
  stop_backend

  remove_service
  remove_caddy_binary
  remove_xcaddy
  remove_go
  remove_caddy_config

  remove_backend
  remove_frontend
  remove_react_build

  remove_users_and_state
  remove_web_root
  remove_firewall
}

menu() {
  echo
  echo "=== NAIVEPROXY UNINSTALL ==="
  echo "1) Удалить Caddy + service"
  echo "2) Удалить Go"
  echo "3) Удалить xcaddy"
  echo "4) Удалить конфиги (/etc/caddy)"
  echo "5) Удалить пользователей + state"
  echo "6) Удалить web root"
  echo "7) Удалить firewall rules"
  echo "8) ПОЛНЫЙ ДЕИНСТАЛЛ"
  echo "9) Остановить backend"
  echo "10) Удалить backend"
  echo "11) Удалить frontend"
  echo "12) Удалить /var/www/react"
  echo "0) Выход"
  echo
}

main() {
  require_root

  while true; do
    menu
    read -r -p "Выбор: " choice

    case "$choice" in
      1) remove_service ;;
      2) remove_go ;;
      3) remove_xcaddy ;;
      4) remove_caddy_config ;;
      5) remove_users_and_state ;;
      6) remove_web_root ;;
      7) remove_firewall ;;
      8) confirm "Точно удалить ВСЁ?" && full_cleanup ;;
      9) stop_backend ;;
      10) remove_backend ;;
      11) remove_frontend ;;
      12) remove_react_build ;;
      0) exit 0 ;;
      *) warn "Неверный выбор" ;;
    esac
  done
}

main "$@"

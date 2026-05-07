#!/usr/bin/env bash
set -Eeuo pipefail

STATE_FILE="/root/naiveproxy.env"

log()  { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
die()  { printf '[x] %s\n' "$*" >&2; exit 1; }

trap 'die "Ошибка на строке $LINENO. Смотри вывод выше."' ERR

require_root() {
  [[ "${EUID}" -eq 0 ]] || die "Запусти скрипт от root."
}

check_system() {
  [[ -r /etc/os-release ]] || die "Не удалось определить ОС."

  # shellcheck disable=SC1091
  . /etc/os-release

  case "${ID:-}" in
    debian|ubuntu) ;;
    *)
      warn "Скрипт рассчитан на Debian/Ubuntu. Сейчас: ${ID:-unknown} ${VERSION_ID:-unknown}"
      ;;
  esac

  case "$(uname -m)" in
    x86_64)
      GO_ARCH="amd64"
      ;;
    aarch64|arm64)
      GO_ARCH="arm64"
      ;;
    *)
      die "Неподдерживаемая архитектура: $(uname -m)"
      ;;
  esac
}

check_ports_free() {
  for port in 80 443; do
    if ss -tln "( sport = :$port )" 2>/dev/null | tail -n +2 | grep -q .; then
      die "Порт $port занят. Освободи его и запусти скрипт снова."
    fi
  done
}

handle_inputs() {
  if [[ -z "${DOMAIN:-}" ]]; then
    while true; do
      read -r -p "Домен: " DOMAIN
      [[ "$DOMAIN" =~ ^([A-Za-z0-9-]+\.)+[A-Za-z]{2,}$ ]] && break
      warn "Неверный домен"
    done
  fi

  if [[ -z "${EMAIL:-}" ]]; then
    while true; do
      read -r -p "Email: " EMAIL
      [[ "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] && break
      warn "Неверный email"
    done
  fi

  export DOMAIN EMAIL
}

save_state() {
  cat > "$STATE_FILE" <<EOF
DOMAIN=$DOMAIN
EMAIL=$EMAIL
LOGIN=$LOGIN
PASSWORD=$PASSWORD
EOF
  chmod 600 "$STATE_FILE"
}

load_state() {
  [[ -f "$STATE_FILE" ]] || return 0
  # shellcheck disable=SC1090
  source "$STATE_FILE"
}

backup_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    local backup="${path}.bak.$(date +%Y%m%d-%H%M%S)"
    cp -a "$path" "$backup"
    log "Сделана резервная копия: $backup"
  fi
}

install_packages() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y curl wget openssl ca-certificates ufw iproute2 tar
}

enable_bbr() {
  local sysctl_file="/etc/sysctl.d/99-naiveproxy-bbr.conf"
  cat > "$sysctl_file" <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
  sysctl --system >/dev/null || true
  if sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr; then
    log "BBR включён."
  else
    warn "BBR не подтвердился. На некоторых ядрах он может быть недоступен."
  fi
}

configure_firewall() {
  ufw allow 22/tcp >/dev/null || true
  ufw allow 80/tcp >/dev/null || true
  ufw allow 443/tcp >/dev/null || true
  ufw --force enable >/dev/null || true
  log "UFW настроен."
}


install_go() {

  export GOPATH=/opt/go
  export GOBIN=/usr/local/bin
  mkdir -p "$GOPATH"
  log "Проверка Go..."

  local required_version="1.26"

  if command -v go >/dev/null 2>&1; then
    local current_version
    current_version="$(go version | awk '{print $3}' | sed 's/go//')"

    log "Обнаружен Go: $current_version"

    if [[ "$(printf '%s\n' "$required_version" "$current_version" | sort -V | head -n1)" == "$required_version" ]] \
       && [[ "$current_version" != "$required_version" ]]; then
      log "Go уже установлен и >= $required_version. Пропускаем установку."
      export PATH="$PATH:/usr/local/go/bin"
      return 0
    fi
  fi

  log "Установка Go..."

  local go_version
  go_version="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n1)"

  [[ "$go_version" =~ ^go[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || die "Не удалось получить версию Go."

  rm -rf /usr/local/go
  rm -rf /root/go

  curl -fsSL "https://go.dev/dl/${go_version}.linux-${GO_ARCH}.tar.gz" \
    | tar -C /usr/local -xzf -

  export PATH="$PATH:/usr/local/go/bin"
  export GOPATH=/opt/go
  export GOBIN=/usr/local/bin

  mkdir -p "$GOPATH"

  go version
}

build_caddy() {
  set -e

  export PATH="$PATH:/usr/local/go/bin"

  export GOCACHE=/root/.cache/go-build
  export GOMODCACHE=/root/go/pkg/mod
  export GOMAXPROCS=$(nproc)

  mkdir -p "$GOCACHE" "$GOMODCACHE"

  log "Проверка xcaddy..."

  if ! command -v xcaddy >/dev/null 2>&1; then
    GOBIN=/usr/local/bin \
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
  fi

  if [[ -x /usr/bin/caddy ]]; then
    log "Caddy уже существует — пропуск сборки"
    return 0
  fi

  log "Сборка Caddy..."

  xcaddy build \
    --output /usr/bin/caddy \
    --with github.com/caddyserver/forwardproxy=github.com/klzgrad/forwardproxy@naive

  chmod +x /usr/bin/caddy

  /usr/bin/caddy version
}

create_web_root() {
  mkdir -p /var/www/html /etc/caddy

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  if [[ -f "$SCRIPT_DIR/index.html" ]]; then
    cp "$SCRIPT_DIR/index.html" /var/www/html/index.html
  else
    echo "Loading..." > /var/www/html/index.html
  fi

  chmod 644 /var/www/html/index.html
}

create_caddyfile() {
  backup_if_exists /etc/caddy/Caddyfile

  cat > /etc/caddy/Caddyfile <<EOF
{
  order forward_proxy before file_server
}

:443, ${DOMAIN} {
  tls ${EMAIL}

  forward_proxy {
    import /etc/caddy/users.conf
    hide_ip
    hide_via
    probe_resistance
  }

  file_server {
    root /var/www/html
  }
}
EOF
  chmod 644 /etc/caddy/Caddyfile
  caddy fmt --overwrite /etc/caddy/Caddyfile
}

create_systemd_unit() {
  backup_if_exists /etc/systemd/system/caddy.service

  cat > /etc/systemd/system/caddy.service <<'EOF'
[Unit]
Description=Caddy with NaiveProxy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=root
Group=root
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
}

gen_token() {
  openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c "$1"
}

create_users_file() {
  USERS_FILE="/etc/caddy/users.conf"
  : > "$USERS_FILE"
  chmod 600 "$USERS_FILE"

  LOGIN="u1_$(gen_token 6)"
  PASSWORD="$(gen_token 24)"

  echo "basic_auth $LOGIN $PASSWORD" >> "$USERS_FILE"

  export LOGIN PASSWORD

  save_state
}

start_service() {
  /usr/bin/caddy validate --config /etc/caddy/Caddyfile || die "Caddy config invalid"

  systemctl daemon-reload
  systemctl enable caddy
  systemctl restart caddy

  systemctl --no-pager --full status caddy || true
}


main() {
  require_root
  check_system
  check_ports_free

  load_state          # ← ВАЖНО
  handle_inputs

  install_packages
  enable_bbr
  configure_firewall

  install_go
  build_caddy

  create_web_root
  create_users_file
  create_caddyfile
  create_systemd_unit

  start_service

  echo
  log "Готово"
  echo "Link:"
  echo "naive+https://${LOGIN:-${LOGIN_STATE}}:${PASSWORD:-${PASSWORD_STATE}}@${DOMAIN}:443"
  echo
  echo "For Desktop"
  echo "https://${LOGIN:-${LOGIN_STATE}}:${PASSWORD:-${PASSWORD_STATE}}@${DOMAIN}"
}

main "$@"

#!/usr/bin/env bash
set -Eeuo pipefail

USERS_DIR="/etc/caddy/users"
CADDY_CONFIG="/etc/caddy/Caddyfile"
STATE_FILE="/root/naiveproxy.env"

log()  { printf '\n[+] %s\n' "$*"; }
warn() { printf '\n[!] %s\n' "$*" >&2; }
die()  { printf '\n[x] %s\n' "$*" >&2; exit 1; }

require_root() {
  [[ "$EUID" -eq 0 ]] || die "Run as root"
}

gen_hex() {
  openssl rand -hex "$1"
}

load_state() {
  if [[ -f "$STATE_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
  fi
}

reload_caddy() {
  if command -v caddy >/dev/null 2>&1; then
    caddy reload --config "$CADDY_CONFIG" >/dev/null 2>&1 \
      && log "Caddy reloaded"
  else
    warn "Caddy not found"
  fi
}

print_result() {
  local domain="${DOMAIN}"

  echo
  log "Готово"
  echo

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔐 NaiveProxy Access"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo
  echo "👤 Login:    $LOGIN"
  echo "🔑 Password: $PASSWORD"
  echo "🌐 Domain:   $domain"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📱 Link"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo
  echo "naive+https://${LOGIN}:${PASSWORD}@${domain}:443"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "💻 Desktop"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo
  echo "https://${LOGIN}:${PASSWORD}@${domain}"
  echo
}

add_user() {
  local prefix="${1:-user}"

  load_state

  [[ -n "${DOMAIN:-}" ]] || die "DOMAIN not found in $STATE_FILE"

  mkdir -p "$USERS_DIR"
  chmod 755 "$USERS_DIR"

  local suffix login password file

  suffix="$(gen_hex 3)"
  login="${prefix}_${suffix}"
  password="$(gen_hex 8)"

  file="${USERS_DIR}/${login}.conf"

  cat > "$file" <<EOF
# user: $login
basic_auth $login $password
EOF

  chmod 600 "$file"

  export LOGIN="$login"
  export PASSWORD="$password"

  reload_caddy
  print_result
}

require_root
add_user "${1:-}"

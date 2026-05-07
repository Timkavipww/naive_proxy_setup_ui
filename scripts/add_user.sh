#!/usr/bin/env bash
set -Eeuo pipefail

USERS_FILE="/etc/caddy/users.conf"
CADDY_CONFIG="/etc/caddy/Caddyfile"
STATE_FILE="/root/naiveproxy.env"

log()  { printf '\n\e[32m[+]\e[0m %s\n' "$*"; }
warn() { printf '\n\e[33m[!]\e[0m %s\n' "$*" >&2; }
die()  { printf '\n\e[31m[x]\e[0m %s\n' "$*" >&2; exit 1; }

require_root() {
  [[ "$EUID" -eq 0 ]] || die "Run as root"
}

gen_hex() {
  openssl rand -hex "$1"
}

load_state() {
  [[ -f "$STATE_FILE" ]] || return 0
  # shellcheck disable=SC1090
  source "$STATE_FILE"
}

reload_caddy() {
  if command -v caddy >/dev/null 2>&1; then
    caddy reload --config "$CADDY_CONFIG" >/dev/null 2>&1 || warn "Caddy reload failed"
  else
    warn "Caddy not found"
  fi
}

add_user() {
  local prefix="${1:-}"
  [[ -z "$prefix" ]] && die "Usage: $0 <prefix>"

  mkdir -p "$(dirname "$USERS_FILE")"
  touch "$USERS_FILE"
  chmod 600 "$USERS_FILE"

  local suffix login password

  suffix="$(gen_hex 3)"
  login="${prefix}_${suffix}"
  password="$(gen_hex 8)"

  {
    echo ""
    echo "# user: $login"
    echo "basic_auth $login $password"
  } >> "$USERS_FILE"

  export LOGIN="$login"
  export PASSWORD="$password"

  reload_caddy

  print_result
}

print_result() {
  load_state

  local domain="${DOMAIN:-your-domain.com}"

  echo
  log "Готово"
  echo

  echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
  echo -e "🔐  NaiveProxy Access"
  echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

  echo
  echo -e "👤 Login:    \e[33m${LOGIN}\e[0m"
  echo -e "🔑 Password: \e[33m${PASSWORD}\e[0m"
  echo -e "🌐 Domain:   \e[33m${domain}\e[0m"

  echo
  echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
  echo -e "📱 Link (NaiveProxy)"
  echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

  echo
  echo -e "\e[32mnaive+https://${LOGIN}:${PASSWORD}@${domain}:443\e[0m"

  echo
  echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
  echo -e "💻 Desktop / Browser"
  echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"

  echo
  echo -e "\e[32mhttps://${LOGIN}:${PASSWORD}@${domain}\e[0m"

  echo
}

main() {
  require_root
  add_user "${1:-}"
}

main "$@"

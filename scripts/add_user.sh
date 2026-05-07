#!/usr/bin/env bash
set -Eeuo pipefail

USERS_DIR="/etc/caddy/users"
CADDY_CONFIG="/etc/caddy/Caddyfile"

log()  { printf '\n\e[32m[+]\e[0m %s\n' "$*"; }
warn() { printf '\n\e[33m[!]\e[0m %s\n' "$*" >&2; }
die()  { printf '\n\e[31m[x]\e[0m %s\n' "$*" >&2; exit 1; }

require_root() {
  [[ "$EUID" -eq 0 ]] || die "Run as root"
}

gen_hex() {
  openssl rand -hex "$1"
}

reload_caddy() {
  command -v caddy >/dev/null 2>&1 || { warn "Caddy not found"; return 0; }
  caddy reload --config "$CADDY_CONFIG" >/dev/null 2>&1 || warn "Caddy reload failed"
}

add_user() {
  local prefix="${1:-}"
  [[ -z "$prefix" ]] && die "Usage: $0 <prefix>"

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

print_result() {
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

require_root
add_user "${1:-}"

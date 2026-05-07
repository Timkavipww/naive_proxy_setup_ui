#!/usr/bin/env bash
set -Eeuo pipefail

USERS_FILE="/etc/caddy/users.conf"
CADDY_CONFIG="/etc/caddy/Caddyfile"

log() { echo "[+] $*"; }
die() { echo "[x] $*" >&2; exit 1; }

require_root() {
  [[ "$EUID" -eq 0 ]] || die "Run as root"
}

gen_hex() {
  local len="$1"
  openssl rand -hex "$((len/2))"
}

gen_token() {
  openssl rand -hex 3   # 6 hex chars
}

add_user() {
  local prefix="${1:-}"

  [[ -z "$prefix" ]] && die "Usage: $0 <prefix>"

  mkdir -p "$(dirname "$USERS_FILE")"
  touch "$USERS_FILE"
  chmod 600 "$USERS_FILE"

  local suffix
  suffix="$(gen_token)"

  local login="${prefix}_${suffix}"
  local password
  password="$(gen_hex 16)"

  {
    echo ""
    echo "# user: $login"
    echo "basic_auth $login $password"
  } >> "$USERS_FILE"

  log "User created:"
  echo "login:    $login"
  echo "password: $password"

  if command -v caddy >/dev/null 2>&1; then
    log "Reloading Caddy..."
    caddy reload --config "$CADDY_CONFIG" || die "Caddy reload failed"
  else
    die "Caddy not found"
  fi
}

main() {
  require_root
  add_user "${1:-}"
}

main "$@"

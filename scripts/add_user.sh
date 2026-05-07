add_user() {
  local prefix="${1:-user}"

  mkdir -p "$USERS_DIR"
  chmod 755 "$USERS_DIR"

  local counter_file="${USERS_DIR}/.counter"
  local index

  # если нет счётчика — начинаем с 1
  if [[ -f "$counter_file" ]]; then
    index=$(cat "$counter_file")
  else
    index=0
  fi

  # увеличиваем
  index=$((index + 1))
  echo "$index" > "$counter_file"

  local suffix login password file

  suffix="$(gen_hex 3)"
  login="${index}_${prefix}_${suffix}"
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

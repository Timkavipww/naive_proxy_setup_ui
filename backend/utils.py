import re
import secrets
import string
import subprocess
from pathlib import Path

from config import config

USERS_DIR = Path("/etc/caddy/users")
CADDY_CONFIG = "/etc/caddy/Caddyfile"


def enrich_user(user: dict) -> dict:
    login = user["login"]
    password = user["password"]

    return {
        **user,
        "file": f"{login}.conf",
        "link": (f"naive+https://{login}:{password}@{config.DOMAIN}:443"),
        "desktop": (f"https://{login}:{password}@{config.DOMAIN}"),
    }


def gen_token(length: int) -> str:
    alphabet = string.ascii_letters + string.digits

    return "".join(secrets.choice(alphabet) for _ in range(length))


def user_file(login: str) -> Path:
    return USERS_DIR / f"{login}.conf"


def add_user_to_file(login: str, password: str):
    USERS_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    file = user_file(login)

    content = f"# user: {login}\nbasic_auth {login} {password}\n"

    file.write_text(content)

    file.chmod(0o600)


def remove_user_from_file(login: str):
    file = user_file(login)

    if file.exists():
        file.unlink()


def parse_users():
    USERS_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    users = []

    for file in USERS_DIR.glob("*.conf"):
        try:
            text = file.read_text()

            match = re.search(
                r"basic_auth\s+(\S+)\s+(\S+)",
                text,
            )

            if not match:
                continue

            login = match.group(1)
            password = match.group(2)

            users.append(
                {
                    "id": login,
                    "login": login,
                    "password": password,
                    "file": file.name,
                }
            )

        except Exception:
            continue

    users.sort(key=lambda x: x["login"])

    return users


def validate_caddy() -> bool:
    result = subprocess.run(
        [
            "caddy",
            "validate",
            "--config",
            CADDY_CONFIG,
        ],
        capture_output=True,
        text=True,
    )

    return result.returncode == 0


def reload_caddy() -> bool:
    result = subprocess.run(
        [
            "caddy",
            "reload",
            "--config",
            CADDY_CONFIG,
        ],
        capture_output=True,
        text=True,
    )

    return result.returncode == 0

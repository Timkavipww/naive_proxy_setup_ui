from os import getenv
from pathlib import Path

from dotenv import load_dotenv
from pydantic_settings import BaseSettings

load_dotenv()


class Config(BaseSettings):
    CADDYFILE: str = getenv("CADDYFILE", "")
    USERS_CONF: str = getenv("USERS_CONF", "")
    DOMAIN: str = getenv("DOMAIN", "")
    ADMIN_PASSWORD: str = getenv("ADMIN_PASSWORD", "")
    USERS_DIR = Path("/etc/caddy/users")
    CADDY_CONFIG = "/etc/caddy/Caddyfile"


config = Config()

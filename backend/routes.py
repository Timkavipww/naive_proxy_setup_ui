from config import config
from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
)
from security import check_auth
from utils import (
    add_user_to_file,
    enrich_user,
    gen_token,
    parse_users,
    reload_caddy,
    remove_user_from_file,
    validate_caddy,
)

router = APIRouter()


@router.post("/create-user")
def create_user(
    prefix: str = "user",
    _: str = Depends(check_auth),
):
    suffix = gen_token(6)

    login = f"{prefix}_{suffix}"
    password = gen_token(24)

    add_user_to_file(
        login,
        password,
    )

    if not validate_caddy():
        remove_user_from_file(login)

        raise HTTPException(
            status_code=500,
            detail="Caddy config invalid",
        )

    if not reload_caddy():
        remove_user_from_file(login)

        raise HTTPException(
            status_code=500,
            detail="Caddy reload failed",
        )

    return {
        "status": "ok",
        "data": {
            "id": login,
            "login": login,
            "password": password,
            "file": f"{login}.conf",
            "link": (f"naive+https://{login}:{password}@{config.DOMAIN}:443"),
            "desktop": (f"https://{login}:{password}@{config.DOMAIN}"),
        },
    }


@router.get("/users")
def get_users(_: str = Depends(check_auth)):
    users = parse_users()

    enriched = [enrich_user(u) for u in users]

    return {
        "count": len(enriched),
        "users": enriched,
    }


@router.get("/users/{user_id}")
def get_user(user_id: str, _: str = Depends(check_auth)):
    users = parse_users()

    for user in users:
        if user["id"] == user_id:
            return {
                "status": "ok",
                "data": enrich_user(user),
            }

    raise HTTPException(status_code=404, detail="User not found")


@router.delete("/users/{user_id}")
def delete_user(
    user_id: str,
    _: str = Depends(check_auth),
):
    users = parse_users()

    if not users:
        raise HTTPException(
            status_code=400,
            detail="No users exist",
        )

    exists = any(user["id"] == user_id for user in users)

    if not exists:
        raise HTTPException(
            status_code=404,
            detail="User not found",
        )

    if len(users) == 1:
        raise HTTPException(
            status_code=400,
            detail="Cannot delete last remaining user",
        )

    remove_user_from_file(user_id)

    updated_users = parse_users()

    if len(updated_users) == 0:
        raise HTTPException(
            status_code=500,
            detail="Refusing state: no users left after deletion",
        )

    if not validate_caddy():
        raise HTTPException(
            status_code=500,
            detail="Caddy config invalid",
        )

    if not reload_caddy():
        raise HTTPException(
            status_code=500,
            detail="Caddy reload failed",
        )

    return {
        "status": "ok",
        "message": f"{user_id} deleted",
        "remaining_users": len(updated_users),
    }

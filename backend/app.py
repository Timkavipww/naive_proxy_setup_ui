from config import config
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import router

app = FastAPI(root_path="/api")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[f"https://ui.{config.DOMAIN}"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(router)

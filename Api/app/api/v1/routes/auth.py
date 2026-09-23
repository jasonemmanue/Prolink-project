from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr

from app.core.security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])

_users: dict[str, dict] = {}  # placeholder MVP; swap with DB


class RegisterIn(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str = "client"  # client | pro


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class TokenOut(BaseModel):
    access_token: str
    role: str


@router.post("/register", response_model=TokenOut)
def register(payload: RegisterIn):
    if payload.email in _users:
        raise HTTPException(400, "Email already used")
    _users[payload.email] = {
        "name": payload.name,
        "password": hash_password(payload.password),
        "role": payload.role,
    }
    return TokenOut(
        access_token=create_access_token(payload.email, payload.role),
        role=payload.role,
    )


@router.post("/login", response_model=TokenOut)
def login(payload: LoginIn):
    u = _users.get(payload.email)
    if not u or not verify_password(payload.password, u["password"]):
        raise HTTPException(401, "Invalid credentials")
    return TokenOut(
        access_token=create_access_token(payload.email, u["role"]),
        role=u["role"],
    )


@router.post("/otp/send")
def otp_send(phone: str):
    # Twilio / local operator wired here.
    return {"sent": True, "channel": "sms"}


@router.post("/otp/verify")
def otp_verify(phone: str, code: str):
    return {"verified": code == "0000"}

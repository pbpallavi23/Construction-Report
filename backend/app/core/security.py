from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import time
from typing import Any

from app.core.config import settings
from app.core.exceptions import UnauthorizedError

_PBKDF2_ROUNDS = 120_000
_PBKDF2_ALGO = "sha256"


def hash_password(plain: str) -> str:
    salt = os.urandom(16)
    digest = hashlib.pbkdf2_hmac(
        _PBKDF2_ALGO, plain.encode("utf-8"), salt, _PBKDF2_ROUNDS
    )
    return "$".join(
        [
            "pbkdf2_sha256",
            str(_PBKDF2_ROUNDS),
            base64.b64encode(salt).decode("ascii"),
            base64.b64encode(digest).decode("ascii"),
        ]
    )


def verify_password(plain: str, stored: str) -> bool:
    try:
        algo, rounds_s, salt_b64, hash_b64 = stored.split("$")
        if algo != "pbkdf2_sha256":
            return False
        salt = base64.b64decode(salt_b64)
        expected = base64.b64decode(hash_b64)
        actual = hashlib.pbkdf2_hmac(
            _PBKDF2_ALGO, plain.encode("utf-8"), salt, int(rounds_s)
        )
        return hmac.compare_digest(actual, expected)
    except (ValueError, TypeError):
        return False


def _b64url_encode(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


def _b64url_decode(segment: str) -> bytes:
    padding = "=" * (-len(segment) % 4)
    return base64.urlsafe_b64decode(segment + padding)


def _sign(signing_input: bytes) -> str:
    signature = hmac.new(
        settings.JWT_SECRET_KEY.encode("utf-8"), signing_input, hashlib.sha256
    ).digest()
    return _b64url_encode(signature)


def create_access_token(subject: str, claims: dict[str, Any] | None = None) -> str:
    now = int(time.time())
    header = {"alg": "HS256", "typ": "JWT"}
    payload: dict[str, Any] = {
        "sub": subject,
        "iat": now,
        "exp": now + settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "type": "access",
    }
    if claims:
        payload.update(claims)

    header_seg = _b64url_encode(json.dumps(header, separators=(",", ":")).encode())
    payload_seg = _b64url_encode(json.dumps(payload, separators=(",", ":")).encode())
    signing_input = f"{header_seg}.{payload_seg}".encode("ascii")
    return f"{header_seg}.{payload_seg}.{_sign(signing_input)}"


def decode_access_token(token: str) -> dict[str, Any]:
    try:
        header_seg, payload_seg, signature_seg = token.split(".")
    except ValueError as exc:
        raise UnauthorizedError("Malformed session token.") from exc

    signing_input = f"{header_seg}.{payload_seg}".encode("ascii")
    expected_sig = _sign(signing_input)
    if not hmac.compare_digest(expected_sig, signature_seg):
        raise UnauthorizedError("Invalid session token signature.")

    try:
        payload = json.loads(_b64url_decode(payload_seg))
    except (ValueError, json.JSONDecodeError) as exc:
        raise UnauthorizedError("Unreadable session token.") from exc

    if int(payload.get("exp", 0)) < int(time.time()):
        raise UnauthorizedError("Session token has expired.")

    return payload

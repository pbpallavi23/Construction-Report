import time
import unittest

from tests import support

from app.core.exceptions import UnauthorizedError
from app.core.security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)


class HashPasswordTests(unittest.TestCase):
    def test_verify_correct_password(self):
        stored = hash_password("correct-horse-battery-staple")
        self.assertTrue(verify_password("correct-horse-battery-staple", stored))

    def test_verify_wrong_password(self):
        stored = hash_password("correct-horse-battery-staple")
        self.assertFalse(verify_password("wrong-password", stored))

    def test_hash_is_salted_and_nondeterministic(self):
        a = hash_password("same-password")
        b = hash_password("same-password")
        self.assertNotEqual(a, b, "two hashes of the same password must differ (salt)")
        self.assertTrue(verify_password("same-password", a))
        self.assertTrue(verify_password("same-password", b))

    def test_verify_password_rejects_garbage_stored_value(self):
        self.assertFalse(verify_password("anything", "not-a-valid-hash"))
        self.assertFalse(verify_password("anything", ""))

    def test_verify_password_rejects_unknown_algorithm(self):
        stored = hash_password("secret").replace("pbkdf2_sha256", "md5", 1)
        self.assertFalse(verify_password("secret", stored))


class AccessTokenTests(unittest.TestCase):
    def test_round_trip(self):
        token = create_access_token("user-123", claims={"email": "a@b.com"})
        payload = decode_access_token(token)
        self.assertEqual(payload["sub"], "user-123")
        self.assertEqual(payload["email"], "a@b.com")
        self.assertEqual(payload["type"], "access")

    def test_tampered_payload_rejected(self):
        token = create_access_token("user-123")
        header, payload, signature = token.split(".")

        tampered_payload = ("A" if payload[0] != "A" else "B") + payload[1:]
        tampered = f"{header}.{tampered_payload}.{signature}"
        with self.assertRaises(UnauthorizedError):
            decode_access_token(tampered)

    def test_tampered_signature_rejected(self):
        token = create_access_token("user-123")
        header, payload, signature = token.split(".")
        bad_sig = ("A" if signature[0] != "A" else "B") + signature[1:]
        with self.assertRaises(UnauthorizedError):
            decode_access_token(f"{header}.{payload}.{bad_sig}")

    def test_malformed_token_rejected(self):
        with self.assertRaises(UnauthorizedError):
            decode_access_token("not-a-jwt-at-all")

    def test_expired_token_rejected(self):


        import base64
        import hashlib
        import hmac
        import json

        from app.core.config import settings

        def b64url(raw: bytes) -> str:
            return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")

        header = {"alg": "HS256", "typ": "JWT"}
        payload = {
            "sub": "user-123",
            "iat": int(time.time()) - 10,
            "exp": int(time.time()) - 1,
            "type": "access",
        }
        header_seg = b64url(json.dumps(header, separators=(",", ":")).encode())
        payload_seg = b64url(json.dumps(payload, separators=(",", ":")).encode())
        signing_input = f"{header_seg}.{payload_seg}".encode("ascii")
        sig = hmac.new(
            settings.JWT_SECRET_KEY.encode("utf-8"), signing_input, hashlib.sha256
        ).digest()
        token = f"{header_seg}.{payload_seg}.{b64url(sig)}"

        with self.assertRaises(UnauthorizedError):
            decode_access_token(token)


if __name__ == "__main__":
    unittest.main()

---
name: auth-patterns
description: "Authentication implementation patterns — session, JWT, OAuth flows. Use when implementing auth from scratch. Triggers on \'auth pattern\', \'jwt\', \'session auth\', \'oauth flow\', \'authentication\'."
triggers: ["authentication", "jwt", "oauth", "api key", "permissions", "login", "session", "rbac", "authorization"]
tags: [engineering, security, authentication, authorization]
department: security
---

# Auth Patterns

Production authentication and authorization patterns. Framework-agnostic patterns for JWT, OAuth2, API keys, sessions, and role-based access control.

## JWT Authentication

### Token Lifecycle

```
Login → Access Token (15min) + Refresh Token (7d)
         │                        │
         ├─ API requests          ├─ Stored httpOnly cookie
         ├─ Short-lived           ├─ Long-lived
         └─ Stateless             └─ Rotated on use
```

### Implementation (Python)

```python
from datetime import datetime, timedelta
from jose import JWTError, jwt

SECRET_KEY = os.environ["JWT_SECRET"]
ALGORITHM = "HS256"

def create_access_token(user_id: int, roles: list[str]) -> str:
    payload = {
        "sub": str(user_id),
        "roles": roles,
        "exp": datetime.utcnow() + timedelta(minutes=15),
        "iat": datetime.utcnow(),
        "type": "access",
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def create_refresh_token(user_id: int) -> str:
    payload = {
        "sub": str(user_id),
        "exp": datetime.utcnow() + timedelta(days=7),
        "type": "refresh",
        "jti": str(uuid4()),  # Unique ID for revocation
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str, expected_type: str = "access") -> dict:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != expected_type:
            raise ValueError("Invalid token type")
        return payload
    except JWTError:
        raise UnauthorizedError("Invalid or expired token")
```

### Token Refresh Flow

```python
@router.post("/auth/refresh")
async def refresh_tokens(refresh_token: str = Cookie(None)):
    payload = verify_token(refresh_token, expected_type="refresh")
    # Check if refresh token is revoked
    if await is_token_revoked(payload["jti"]):
        raise UnauthorizedError("Token revoked")
    # Rotate: issue new pair, revoke old refresh
    user_id = int(payload["sub"])
    await revoke_token(payload["jti"])
    return {
        "access_token": create_access_token(user_id, roles),
        "refresh_token": create_refresh_token(user_id),
    }
```

## OAuth2 Flow (Authorization Code)

```
1. Client → Auth Server: GET /authorize?client_id=X&redirect_uri=Y&scope=Z
2. User authenticates and consents
3. Auth Server → Client: redirect to Y?code=AUTH_CODE
4. Client → Auth Server: POST /token {code, client_secret}
5. Auth Server → Client: {access_token, refresh_token}
```

## API Key Authentication

```python
from fastapi import Security
from fastapi.security import APIKeyHeader

api_key_header = APIKeyHeader(name="X-API-Key")

async def verify_api_key(key: str = Security(api_key_header)):
    # Hash the key for storage comparison (never store plaintext)
    hashed = hashlib.sha256(key.encode()).hexdigest()
    api_key = await db.query(APIKey).filter_by(key_hash=hashed, active=True).first()
    if not api_key:
        raise HTTPException(status_code=403, detail="Invalid API key")
    # Rate limit per key
    if await is_rate_limited(api_key.id):
        raise HTTPException(status_code=429, detail="Rate limited")
    return api_key
```

## Role-Based Access Control (RBAC)

```python
from enum import Enum
from functools import wraps

class Role(str, Enum):
    ADMIN = "admin"
    EDITOR = "editor"
    VIEWER = "viewer"

def require_role(*roles: Role):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, current_user=Depends(get_current_user), **kwargs):
            if current_user.role not in roles:
                raise HTTPException(403, "Insufficient permissions")
            return await func(*args, current_user=current_user, **kwargs)
        return wrapper
    return decorator

@router.delete("/users/{id}")
@require_role(Role.ADMIN)
async def delete_user(id: int, current_user=Depends(get_current_user)):
    ...
```

## Security Checklist

- [ ] Access tokens short-lived (15 min max)
- [ ] Refresh tokens in httpOnly cookies (not localStorage)
- [ ] Refresh token rotation on every use
- [ ] Password hashing with bcrypt/argon2 (never SHA/MD5)
- [ ] API keys hashed in database (never stored plaintext)
- [ ] Rate limiting on auth endpoints (5 req/min)
- [ ] Account lockout after N failed attempts
- [ ] RBAC with least-privilege defaults
- [ ] CORS configured to specific origins (not wildcard)

## When NOT to Use

- Not for authorization (RBAC, permissions) — authentication patterns only
- Not for OAuth provider setup (Auth0, Clerk) — use better-auth-best-practices
- Not for API key management — user authentication flows
- Not for session management in mobile apps — web authentication patterns

## Related Skills

- `bdd-scenarios` — qa
- `code-maturity-assessor` — qa
- `knowledge-synthesis` — qa
- `ci-cd-patterns` — engineering/backend

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

Read, Grep, Glob

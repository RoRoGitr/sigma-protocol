---
name: performance-patterns
description: "Backend application performance optimization patterns. Use when optimizing server-side performance. Triggers on \'backend performance\', \'server optimization\', \'latency reduction\', \'throughput\', \'caching strategy\'."
triggers: ["performance", "cache", "redis", "slow", "optimize", "query", "N+1", "profiling", "latency", "memory"]
tags: [engineering, performance, caching, optimization, backend]
department: engineering
---

# Performance Patterns

Battle-tested optimization patterns from production systems. Covers caching, query optimization, connection management, and profiling.

## Caching Architecture

```
┌──────────────────────────────────────────────────┐
│                 CACHING LAYERS                    │
├──────────────────────────────────────────────────┤
│  L1: In-Process Cache  │ lru_cache, dict         │
│  L2: Redis Cache       │ hot data, sessions       │
│  L3: ORM Cache         │ query result sets         │
│  L4: Database          │ PostgreSQL with indexes   │
└──────────────────────────────────────────────────┘
```

### L1: In-Process Cache

```python
from functools import lru_cache
from cachetools import TTLCache

# Static data that changes rarely
@lru_cache(maxsize=128)
def get_config(key: str) -> str:
    return db.query(Config).filter_by(key=key).scalar()

# Time-bounded hot data
_price_cache = TTLCache(maxsize=1000, ttl=5)  # 5-second TTL

def get_latest_price(symbol: str) -> float:
    if symbol in _price_cache:
        return _price_cache[symbol]
    price = fetch_price(symbol)
    _price_cache[symbol] = price
    return price
```

### L2: Redis Cache

```python
import redis.asyncio as aioredis
import json

class RedisCache:
    def __init__(self, url: str = "redis://localhost:6379"):
        self.redis = aioredis.from_url(url)

    async def get_or_set(self, key: str, factory, ttl: int = 300):
        """Cache-aside pattern with TTL."""
        cached = await self.redis.get(key)
        if cached:
            return json.loads(cached)
        value = await factory()
        await self.redis.set(key, json.dumps(value), ex=ttl)
        return value

    async def invalidate(self, pattern: str):
        """Invalidate by pattern (e.g., 'user:123:*')."""
        keys = []
        async for key in self.redis.scan_iter(match=pattern):
            keys.append(key)
        if keys:
            await self.redis.delete(*keys)

# Usage
cache = RedisCache()
user = await cache.get_or_set(
    f"user:{user_id}",
    lambda: db.get_user(user_id),
    ttl=600
)
```

## N+1 Query Elimination

### The Problem
```python
# BAD: N+1 queries (1 for orders + N for users)
orders = db.query(Order).all()
for order in orders:
    print(order.user.name)  # Each access triggers a query
```

### The Fix: Eager Loading

```python
# SQLAlchemy: joinedload for to-one, selectinload for to-many
from sqlalchemy.orm import joinedload, selectinload

# GOOD: 2 queries total
orders = db.query(Order).options(
    joinedload(Order.user),           # JOIN for to-one
    selectinload(Order.items),        # SELECT IN for to-many
).all()

# Django equivalent
orders = Order.objects.select_related("user").prefetch_related("items").all()

# Prisma equivalent
const orders = await prisma.order.findMany({
  include: { user: true, items: true }
});
```

## Connection Pooling

```python
# SQLAlchemy async pool
from sqlalchemy.ext.asyncio import create_async_engine

engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,          # Base connections
    max_overflow=10,       # Extra under load (total max: 30)
    pool_timeout=30,       # Wait max 30s for connection
    pool_recycle=1800,     # Recycle connections every 30min
    pool_pre_ping=True,    # Test connection before use
)
```

## Database Indexing

```sql
-- Index for frequent WHERE clauses
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status) WHERE status != 'completed';  -- Partial index

-- Composite index for multi-column queries
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- Covering index (avoids table lookup)
CREATE INDEX idx_orders_covering ON orders(user_id, status) INCLUDE (total, created_at);
```

## Profiling Patterns

```python
# Middleware to log slow requests
import time

@app.middleware("http")
async def profile_requests(request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    duration = (time.perf_counter() - start) * 1000
    if duration > 200:  # Log requests > 200ms
        logger.warning("slow_request",
            path=request.url.path,
            method=request.method,
            duration_ms=round(duration, 2),
        )
    return response
```

## Production Checklist

- [ ] Redis for hot data caching (L2)
- [ ] Eager loading to eliminate N+1 queries
- [ ] Connection pooling with pre-ping
- [ ] Database indexes for frequent queries
- [ ] Slow request logging (>200ms threshold)
- [ ] Cache invalidation strategy (TTL + event-based)
- [ ] Pagination for list endpoints (never unbounded)
- [ ] Compression for large API responses (gzip)

## When NOT to Use

- Not for frontend performance (Core Web Vitals, bundle size) — use react-performance
- Not for database query optimization — use database-specific skills
- Not for initial feature development — optimize after functionality is correct
- Not for network/infrastructure performance — focuses on application-level patterns

## Related Skills

- `crewai-patterns` — architecture
- `langgraph-patterns` — architecture
- `address-sanitizer` — security
- `audit-context-building` — security

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

Read, Grep, Glob

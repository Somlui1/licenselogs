import asyncio
import asyncpg

DATABASE_CONFIG = {
    "user": "admin",
    "password": "it@apico4U",
    "database": "license_logs",
    "host": "10.10.10.181",
    "port": 5432,
}

async def test_connect():
    try:
        conn = await asyncpg.connect(**DATABASE_CONFIG)
        print("Connection successful")
        await conn.close()
    except Exception as e:
        print("Connection failed:", e)

asyncio.run(test_connect())

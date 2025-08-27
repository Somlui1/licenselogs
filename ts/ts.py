from sqlalchemy import Column, Integer, String, Date, Time, Numeric, DateTime, create_engine, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
from sqlalchemy.orm import sessionmaker
from faker import Faker

Base = declarative_base()
engine = create_engine("postgresql://admin:it%40apico4U@10.10.10.181:5432/license_logsdb")
schemas = ["autoform", "nx", "catia", "solidworks", "autodesk","testing"]
# สร้าง schema ถ้ายังไม่มี
with engine.connect() as conn:
    for schema_name in schemas:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema_name}"))
    conn.commit()
# สร้าง table ทั้งหมด
class TestingUsers(Base):
    __tablename__ = "users"
    __table_args__ = {"schema": "testing"}  # ใส่ schema
    id = Column(Integer, primary_key=True)
    email = Column(String)
    username = Column(String)
# สร้าง table
Base.metadata.create_all(bind=engine)
print("All schemas and users table created successfully!")
# สร้าง session
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
with SessionLocal() as db:
    users = []
    for _ in range(100):
        user = TestingUsers(
            username=Faker().user_name(),
            email=Faker().email()
        )
        users.append(user)
    
    # เพิ่มทั้งหมดในครั้งเดียว
    db.add_all(users)
    db.commit()

    print("✅ 100 fake users inserted successfully!")

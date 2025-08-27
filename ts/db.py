from sqlalchemy import Column, Integer, String, Date, Time, Numeric, DateTime, create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()
class NX(Base):
    __tablename__ = "main"
    __table_args__ = {"schema": "nx"}
    id = Column(Integer, primary_key=True)
    start_date = Column(Date)
    start_time = Column(Time)
    end_date = Column(Date)
    end_time = Column(Time)
    duration_minutes = Column(Numeric(10,2))
    hostname = Column(String)
    module = Column(String)
    username = Column(String)
    
class Autoform(Base):
    __tablename__ = "main"
    __table_args__ = {"schema": "autoform"}
    id = Column(Integer, primary_key=True)
    start_date = Column(Date)
    start_time = Column(Time)
    start_hours = Column(Integer)
    start_action = Column(String)
    end_date = Column(Date)
    end_time = Column(Time)
    end_hours = Column(Integer)
    end_action = Column(String)
    duration_minutes = Column(Numeric(10,2))
    host = Column(String)
    module = Column(String)
    username = Column(String)
    version = Column(String)

class Solidwork(Base):
    __tablename__ = "main"
    __table_args__ = {"schema": "solidworks"}
    id = Column(Integer, primary_key=True)
    start_date = Column(Date)
    start_time = Column(Time)
    end_date = Column(Date)
    end_time = Column(Time)
    duration_minutes = Column(Numeric(10,2))
    feature = Column(String)
    username = Column(String)
    computer = Column(String)
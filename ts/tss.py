
import db
import inspect
classes = inspect.getmembers(db, inspect.isclass)
# แสดงเฉพาะชื่อ class ที่อยู่ใน module db
class_names = [name for name, cls in classes if cls.__module__ == "db"]
print(class_names)
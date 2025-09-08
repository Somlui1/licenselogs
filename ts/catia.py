import pandas as pd
import re
from datetime import datetime

log_file = "LicenseServer20250818082806.log"  # เปลี่ยนชื่อไฟล์ตามจริง
data = []

# รูปแบบ regex สำหรับบรรทัด License Denied
pattern = re.compile(
    r'(?P<datetime>\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}:\d{3}) W LICENSESERV (?P<feature>\S+) not granted, (?P<reason>.*) \( from client (?P<client>.*?) \((.*?)\)/.*?\|(?P<user>[^|]+)\|(?P<user_full>[^|]+)\|(?P<license>[^|]+)\|(?P<path>.*?) \)'
)

# อ่านไฟล์
with open(log_file, "r", encoding="utf-8") as f:
    for line in f:
        match = pattern.search(line)
        if match:
            entry = match.groupdict()
            dt = datetime.strptime(entry["datetime"], "%Y/%m/%d %H:%M:%S:%f")
            data.append({
                "Date": dt.date(),
                "Time": dt.time(),
                "Feature": entry["feature"],
                "Reason": entry["reason"],
                "User": entry["user"],
                "Client": entry["client"],
                "Path": entry["path"]
            })

# แปลงเป็น DataFrame และบันทึก
df = pd.DataFrame(data)
df.to_excel("license_denied_report.xlsx", index=False)

print("บันทึกข้อมูลเรียบร้อยใน license_denied_report.xlsx")

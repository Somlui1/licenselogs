import re
import pandas as pd
from datetime import datetime, timedelta

log_file = "license_log.txt"

sessions = []
out_entries = {}
current_date = None
last_datetime = None

def parse_date_from_start_date(line):
    match = re.match(r'\d{2}:\d{2}:\d{2} \(lmgrd\) \(@lmgrd-SLOG@\) Start-Date: (.+)', line)
    if match:
        raw_date = match.group(1).strip().split(" SE Asia")[0]
        dt = datetime.strptime(raw_date, "%a %b %d %Y %H:%M:%S")
        return dt.date()
    return None

with open(log_file, "r", encoding="utf-8") as file:
    lines = file.readlines()

    for line in lines:
        # อัปเดตวันที่เมื่อเจอ Start-Date ใหม่
        new_date = parse_date_from_start_date(line)
        if new_date:
            current_date = new_date
            continue

        # จับ log OUT / IN
        match = re.match(r'(\d{2}:\d{2}:\d{2}) \(saltd\) (OUT|IN): "([^"]+)" ([^@]+)@(.+)', line.strip())
        if match and current_date:
            time_str, action, module, user, host = match.groups()
            time_obj = datetime.strptime(time_str, "%H:%M:%S").time()

            # ตรวจสอบว่าข้ามวันหรือไม่ (เวลาลดลงจากบรรทัดก่อน)
            if last_datetime and time_obj < last_datetime.time():
                current_date += timedelta(days=1)

            dt = datetime.combine(current_date, time_obj)
            last_datetime = dt

            key = (user, host, module)

            if action == "OUT":
                out_entries[key] = {
                    "start_datetime": dt,
                    "start_date": dt.strftime("%Y-%m-%d"),
                    "start_time": dt.strftime("%H:%M:%S"),
                    "user": user,
                    "host": host,
                    "module": module
                }
            elif action == "IN":
                if key in out_entries:
                    start = out_entries.pop(key)
                    duration_minutes = (dt - start["start_datetime"]).total_seconds() / 60
                    sessions.append({
                        "start_date": start["start_date"],
                        "start_time": start["start_time"],
                        "end_date": dt.strftime("%Y-%m-%d"),
                        "end_time": dt.strftime("%H:%M:%S"),
                        "duration_minutes": round(duration_minutes, 2),
                        "host": host,
                        "module": module,
                        "user": user
                    })

# สร้าง DataFrame
df = pd.DataFrame(sessions)

# ส่งออก Excel
df.to_excel("license_sessions_multiday.xlsx", index=False)

# แสดงผล
print(df)

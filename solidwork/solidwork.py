import re
import pandas as pd
from datetime import datetime

log_file = "sw_log.txt"  # ชื่อไฟล์ log
data = []

# Regex patterns
timestamp_pattern = re.compile(r'TIMESTAMP (\d{1,2}/\d{1,2}/\d{4})')
entry_pattern = re.compile(
    r'(?P<time>\d{1,2}:\d{2}:\d{2}) '
    r'\(SW_D\) (?P<status>OUT|IN|DENIED|UNSUPPORTED): '
    r'"(?P<feature>[^"]+)" '
    r'(?P<user>[\w.]+)@(?P<computer>[\w\d]+)'
)

current_date = None

with open(log_file, "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        ts_match = timestamp_pattern.search(line)
        if ts_match:
            current_date = ts_match.group(1)
            continue

        entry_match = entry_pattern.search(line)
        if entry_match and current_date:
            time_str = entry_match.group("time")
            full_datetime = f"{current_date} {time_str}"
            dt = datetime.strptime(full_datetime, "%m/%d/%Y %H:%M:%S")

            data.append({
                "datetime": dt,
                "status": entry_match.group("status"),
                "feature": entry_match.group("feature"),
                "user": entry_match.group("user"),
                "computer": entry_match.group("computer"),
            })

df = pd.DataFrame(data)

# ------------------------------
# จับคู่ OUT - IN เพื่อคำนวณ duration
# ------------------------------

sessions = []
out_sessions = {}

for _, row in df.iterrows():
    key = (row['feature'], row['user'], row['computer'])
    if row['status'] == 'OUT':
        # เก็บข้อมูลเริ่มต้น session
        out_sessions[key] = row
    elif row['status'] == 'IN':
        # หา session ที่จับคู่กับ OUT
        if key in out_sessions:
            start = out_sessions.pop(key)
            end = row

            duration_sec = (end['datetime'] - start['datetime']).total_seconds()
            if duration_sec < 0:
                # กรณีเวลาผิดพลาด (เช่น IN ก่อน OUT) ข้าม record นี้
                continue

            sessions.append({
                "start_date": start['datetime'].strftime("%Y-%m-%d"),
                "start_time": start['datetime'].strftime("%H:%M:%S"),
                "end_date": end['datetime'].strftime("%Y-%m-%d"),
                "end_time": end['datetime'].strftime("%H:%M:%S"),
                "duration_minutes": duration_sec / 60,  # นาที
                "feature": start['feature'],
                "user": start['user'],
                "computer": start['computer'],
            })

df_sessions = pd.DataFrame(sessions)

# บันทึกไฟล์ Excel
df_sessions.to_excel("sw_log_sessions.xlsx", index=False)

print("Session summary exported to sw_log_sessions.xlsx")
print(df_sessions.head())

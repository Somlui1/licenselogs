import pandas as pd
import re

file_path = "license_log.txt"
out_entries = {}
sessions = []

with open(file_path, "r", encoding="utf-8", errors="ignore") as file:
    for line in file:
        parts = re.split(r'\s+', line.strip())
        if not parts or len(parts) < 10:
            continue

        action = parts[0].upper()

        if action == 'OUT':
            module = parts[1]
            version = parts[2]
            host = parts[4]
            user = parts[5]
            license_id = parts[10]
            date = parts[-2]       # รูปแบบ MM/DD
            time = parts[-1]       # รูปแบบ HH:MM:SS
            datetime_str = f"2025-{date} {time}"  # เติมปี 2025

            start_dt = pd.to_datetime(datetime_str, format='%Y-%m/%d %H:%M:%S')

            out_entries[license_id] = {
                'module': module,
                'version': version,
                'host': host,
                'user': user,
                'start_datetime': start_dt,
                'start_date': start_dt.strftime('%Y-%m-%d'),
                'start_time': time,
                'start_hours': time[:2],
                'start_action': action
            }

        elif action == 'IN':
            license_id = parts[-3]
            date = parts[-2]
            time = parts[-1]
            datetime_str = f"2025-{date} {time}"

            end_dt = pd.to_datetime(datetime_str, format='%Y-%m/%d %H:%M:%S')

            if license_id in out_entries:
                session = out_entries.pop(license_id)
                session['end_datetime'] = end_dt
                session['end_date'] = end_dt.strftime('%Y-%m-%d')
                session['end_time'] = time
                session['end_hours'] = time[:2]
                session['end_action'] = action
                sessions.append(session)

df_sessions = pd.DataFrame(sessions)
# คำนวณ duration เป็นนาที
df_sessions['duration_seconds'] = (df_sessions['end_datetime'] - df_sessions['start_datetime']).dt.total_seconds() / 60
# จัดเรียงคอลัมน์
columns = [
    'start_date', 'start_time', 'start_hours', 'start_action',
    'end_date', 'end_time', 'end_hours', 'end_action',
    'duration_minutes', 'host', 'module', 'user', 'version'
]
df_sessions = df_sessions[columns]
# ส่งออก Excel
df_sessions.to_excel("license_sessions_with_details.xlsx", index=False)
print("Exported to license_sessions_with_details.xlsx")




import requests
import base64
def get_access_token(client_id, client_secret):
    url = "https://developer.api.autodesk.com/authentication/v2/token"
    # เข้ารหัส base64 จาก client_id:client_secret
    credentials = f"{client_id}:{client_secret}"
    encoded_credentials = base64.b64encode(credentials.encode()).decode()
    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
        "Authorization": f"Basic {encoded_credentials}"
    }
    data = {
        "grant_type": "client_credentials",
        "scope": "data:write"
    }
    response = requests.post(url, headers=headers, data=data)

    if response.status_code == 200:
        return response.json()["access_token"]
    else:
        print(f"Error {response.status_code}: {response.text}")
        return None
def call_insights_api_with_pat(access_token, pat_token):
    url = "https://developer.api.autodesk.com/insights/v1/exports"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}",
        "ADSK-PAT": pat_token
    }
    payload = {
        "outputFormat": "JSON",
        "reports": ["USAGE_REPORT"],
        "startDate": "2025-05-01T00:00:00.000Z",
        "endDate": "2025-05-31T23:59:59.999Z",

        "usageReports": ["USAGE_REPORT_BY_PRODUCT"],
        "filters": {
            "assigned": True,
            "userStatus": ["active", "inactive"]
        }
    }
    response = requests.post(url, headers=headers, json=payload)
    print(f"Status: {response.status_code}")
    print(response.text)
# ใส่ค่า client_id, client_secret, pat_token ของคุณ
client_id = "uGRAGEwGkQtWi64bp2nZSOEyVhZeITwsmxcSpaAXWOhmQRHb"
client_secret = "ZlrzovQIMeU5STe9qdaHcJf0J5y6FEEeDz6CdkRyLEXbR0FGjlnC7j21AASGOX8p"
pat_token = "a37ab074846fbc005165a0812420b399492e334b"
access_token = get_access_token(client_id, client_secret)
print(f"Access Token: {access_token}")
call_insights_api_with_pat(access_token, pat_token)
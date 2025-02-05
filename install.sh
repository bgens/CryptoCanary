#!/bin/bash

echo "[+] Updating System..."
sudo apt update && sudo apt upgrade -y

echo "[+] Installing Dependencies..."
sudo apt install python3 python3-pip nginx jq -y

echo "[+] Installing Python Libraries..."
pip3 install flask requests

echo "[+] Creating Honeypot Directory..."
mkdir -p /opt/honeypot/static /opt/honeypot/templates
cd /opt/honeypot

echo "[+] Creating Configuration File..."
cat <<EOF > config.py
# Webhook for Discord alerts
DISCORD_WEBHOOK = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE"

# Honeypot Credentials (only these will be logged)
HONEYPOT_USERNAME = "admin"
HONEYPOT_PASSWORD = "CHANGE_ME_TO_CANARY_PASSWORD"
EOF

echo "[+] Creating Flask Application..."
cat <<EOF > app.py
from flask import Flask, render_template, request, redirect
import requests
import json
import logging
from datetime import datetime
from config import DISCORD_WEBHOOK, HONEYPOT_USERNAME, HONEYPOT_PASSWORD

app = Flask(__name__)  # No SECRET_KEY needed

logging.basicConfig(filename='/opt/honeypot/honeypot.log', level=logging.INFO, format='%(asctime)s - %(message)s')

def log_attempt(username, password, ip, user_agent):
    if username == HONEYPOT_USERNAME and password == HONEYPOT_PASSWORD:
        log_entry = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "username": username,
            "password": password,
            "ip": ip,
            "user_agent": user_agent
        }

        with open("/opt/honeypot/honeypot.log", "a") as log_file:
            log_file.write(json.dumps(log_entry) + "\n")

        with open("/opt/honeypot/honeypot_data.json", "a") as json_file:
            json.dump(log_entry, json_file)
            json_file.write("\n")

        send_discord_alert(username, password, ip, user_agent)

def send_discord_alert(username, password, ip, user_agent):
    data = {
        "content": f"🚨 **Honeypot Login Detected!**\\n\\n**Username:** `{username}`\\n**Password:** `{password}`\\n**IP Address:** `{ip}`\\n**User-Agent:** `{user_agent}`"
    }

    try:
        response = requests.post(DISCORD_WEBHOOK, json=data)
        if response.status_code != 204:
            logging.error(f"Discord Webhook Error: {response.status_code} - {response.text}")
        else:
            logging.info("Discord Webhook sent successfully.")
    except requests.exceptions.RequestException as e:
        logging.error(f"Discord Webhook Request Failed: {str(e)}")

@app.route("/", methods=["GET", "POST"])
def login():
    error = None
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]
        ip = request.remote_addr
        user_agent = request.headers.get("User-Agent")

        if username == HONEYPOT_USERNAME and password == HONEYPOT_PASSWORD:
            log_attempt(username, password, ip, user_agent)
            return redirect("/dashboard")
        else:
            error = "Login failed. Invalid credentials."

    return render_template("login.html", error=error)

@app.route("/dashboard")
def dashboard():
    return render_template("dashboard.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
EOF

echo "[+] Creating Login Page..."
cat <<EOF > templates/login.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CryptoMiner Login</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">
</head>
<body>
    <div class="login-container">
        <h2>CryptoMiner Dashboard</h2>
        
        {% if error %}
        <p class="error">{{ error }}</p>
        {% endif %}

        <form method="POST">
            <input type="text" name="username" placeholder="Username" required>
            <input type="password" name="password" placeholder="Password" required>
            <button type="submit">Login</button>
        </form>
    </div>
</body>
</html>
EOF

echo "[+] Creating Fake Dashboard..."
cat <<EOF > templates/dashboard.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CryptoMiner Dashboard</title>
</head>
<body>
    <h1>Welcome to CryptoMiner Dashboard</h1>
    <p>Loading mining statistics...</p>
</body>
</html>
EOF

echo "[+] Creating CSS Styles..."
cat <<EOF > static/style.css
body {
    font-family: Arial, sans-serif;
    background-color: #111;
    color: white;
    text-align: center;
    padding-top: 50px;
}

.login-container {
    width: 300px;
    margin: 0 auto;
    background: #222;
    padding: 20px;
    border-radius: 5px;
}

input {
    width: 90%;
    padding: 10px;
    margin: 10px 0;
    border: none;
}

button {
    width: 100%;
    padding: 10px;
    background: green;
    color: white;
    border: none;
    cursor: pointer;
}

.error {
    color: red;
    font-size: 14px;
    margin-top: 10px;
}
EOF

echo "[+] Setting Permissions..."
chmod -R 755 /opt/honeypot

echo "[+] Creating Systemd Service..."
cat <<EOF > /etc/systemd/system/honeypot.service
[Unit]
Description=Crypto Honeypot Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/honeypot/app.py
Restart=always
User=root
WorkingDirectory=/opt/honeypot

[Install]
WantedBy=multi-user.target
EOF

echo "[+] Starting Honeypot Service..."
sudo systemctl daemon-reload
sudo systemctl enable honeypot
sudo systemctl start honeypot

echo "[+] Honeypot successfully deployed!"

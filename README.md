# CryptoCanary – Cryptocurrency Miner Honeypot

CryptoCanary is a deceptive honeypot designed to attract and detect credential leaks from compromised password managers or other sources. It mimics a cryptocurrency miner management login, logging only successful logins with pre-configured honeypot credentials.

This project does not store or process real mining data – it is purely a canary system for detecting unauthorized access attempts.

## Features
- Looks like a real crypto miner panel with a simple login interface.
- Logs only canary logins to avoid disk bloat.
- Sends real-time alerts via Discord Webhooks when the honeypot credentials are used.
- Runs as a systemd service for continuous monitoring.
- Minimal setup required with a single script.

## Installation

### Clone the Repository
```bash
git clone https://github.com/bgens/CryptoCanary.git
cd CryptoCanary
```

### Run the Install Script
```bash
chmod +x install.sh
./install.sh
```

This installs dependencies, sets up the honeypot service, deploys a web-based login page, and configures systemd to auto-start the honeypot.

## Configuration

### Edit config.py Before Running
After installation, modify `/opt/honeypot/config.py` to configure:
```python
# Webhook for Discord alerts
DISCORD_WEBHOOK = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE"

# Honeypot Credentials (only these will be logged)
HONEYPOT_USERNAME = "admin"
HONEYPOT_PASSWORD = "CHANGE_ME_TO_CANARY_PASSWORD"
```
Replace `CHANGE_ME_TO_CANARY_PASSWORD` with the actual credentials you want to monitor for leaks.  
Replace `YOUR_WEBHOOK_URL_HERE` with your Discord Webhook URL to receive alerts.

Save the file and restart the honeypot:
```bash
sudo systemctl restart honeypot
```

### Firewall / Port usage
CryptoCanary by default runs on port 5000. You will need to allow TCP traffic in port 5000. If you're deploying to something like AWS or GCP you'll likely need to modify the network / firewall rules for the host to allow traffic on TCP 5000 for IPv4 and possibly IPv6. 

## How It Works
1. Users visit the login page: `http://your-server-ip:5000`
2. If the correct honeypot credentials are used:
   - Login is recorded.
   - IP and User-Agent are captured.
   - Discord alert is sent.
3. If incorrect credentials are used:
   - Login fails.
   - No logs are stored (to prevent disk bloat).

## Viewing Captured Logins
To view all successful honeypot logins, check the logs:
```bash
cat /opt/honeypot/honeypot.log
```

To see the structured JSON logs:
```bash
cat /opt/honeypot/honeypot_data.json | jq
```
If `jq` is not installed, run: `sudo apt install jq`

## How to Restart the Honeypot
To manually restart the service:
```bash
sudo systemctl restart honeypot
```

To check if it’s running:
```bash
sudo systemctl status honeypot
```

To stop the honeypot:
```bash
sudo systemctl stop honeypot
```

To enable auto-start on reboot:
```bash
sudo systemctl enable honeypot
```

## Security Considerations
- CryptoCanary does NOT process real user data – it only logs pre-configured canary credentials.
- Ensure your firewall only allows intended access to the honeypot system.
- If a honeypot login alert triggers, take immediate action (e.g., rotate credentials, investigate logs).

## Troubleshooting

### Webhook Alerts Are Not Working?
1. Manually test Discord webhook:
   ```bash
   curl -X POST -H "Content-Type: application/json" -d '{"content":"Test Webhook"}' "YOUR_WEBHOOK_URL_HERE"
   ```
   - If this works, the webhook is correct.
   - If it fails, check firewall settings or generate a new webhook.

2. Check honeypot logs for webhook errors:
   ```bash
   tail -f /opt/honeypot/honeypot.log
   ```
   If errors appear, ensure `config.py` is correctly configured.

3. Restart the honeypot after updates:
   ```bash
   sudo systemctl restart honeypot
   ```

### Nothing Is Logging?
- Ensure you are using the correct honeypot credentials.
- Check `/opt/honeypot/honeypot.log` for any errors.

## License
This project is released under the MIT License – free to use, modify, and distribute.


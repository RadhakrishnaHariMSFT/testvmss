#!/bin/bash

# Open firewall port (replace with your firewall rules as needed)
sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT

# Create Python HTTP server for responding with JSON
cat <<EOF > orionhealthextensionserver.py
import json
import os.path
from http.server import BaseHTTPRequestHandler, HTTPServer

def generate_phase_order_response_json():
    return json.dumps({
        "ApplicationHealthState": "Healthy",
        "CustomMetrics": json.dumps({
            "RollingUpgrade": {
                "PhaseOrderingNumber": 0,
                "SkipUpgrade": "false"
            }
        })
    })

# Function to generate the JSON response
def generate_skip_upgrade_response_json():
    return json.dumps({
        "ApplicationHealthState": "Healthy",
        "CustomMetrics": json.dumps({
            "RollingUpgrade": {
                "SkipUpgrade": "true"
            }
        })
    })

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Respond with HTTP 200 and JSON content
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        if os.path.isfile("/tmp/primary"):
            response = generate_skip_upgrade_response_json()
        else:
            response = generate_phase_order_response_json()
        self.wfile.write(response.encode('utf-8'))

# Set up the HTTP server
def run(server_class=HTTPServer, handler_class=RequestHandler):
    server_address = ('', 8000)
    httpd = server_class(server_address, handler_class)
    print('Starting server on port 8000...')
    httpd.serve_forever()

if __name__ == "__main__":
    run()
EOF

cat << EOF > /etc/systemd/system/orionhealthextension.service
[Unit]
Description=Orion Health Extension Service

[Service]
ExecStart=/usr/bin/python3 /var/lib/waagent/custom-script/download/0/orionhealthextensionserver.py
Restart=always

[Install]
WantedBy=default.target

EOF

systemctl daemon-reload
systemctl enable orionhealthextension.service
systemctl start orionhealthextension.service

# exit success code
exit 0

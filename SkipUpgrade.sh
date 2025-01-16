#!/bin/bash
sleep 3m

# Open firewall port (replace with your firewall rules as needed)
sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
ufw allow 8000

# Create Python HTTP server for responding with JSON
cat <<EOF > server.py
import json
import os.path
from http.server import BaseHTTPRequestHandler, HTTPServer

def generate_phaseorder_response_json():
    return json.dumps({
        "ApplicationHealthState": "Healthy",
        "CustomMetrics": {
            "RollingUpgrade": {
                "PhaseOrderingNumber": 0
            }
        }
    })

# Function to generate the JSON response
def generate_skipupgrade_response_json():
    return json.dumps({
        "ApplicationHealthState": "Healthy",
        "CustomMetrics": {
            "RollingUpgrade": {
                "SkipUpgrade": "true"
            }
        }
    })

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Respond with HTTP 200 and JSON content
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        if os.path.isfile("/tmp/primary"):
            response = generate_skipupgrade_response_json()
        else:
            response = generate_phaseorder_response_json()
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

# Run the server
python3 server.py

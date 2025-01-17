#!/bin/bash

# Open firewall port (replace with your firewall rules as needed)
sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT

# Create Python HTTP server for responding with JSON
cat <<EOF > server.py
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

# The nohup command in Linux is used to run processes in such a way that they continue running even after the 
# terminal session is closed. This is particularly useful for long-running processes or when working remotely over SSH, 
# where you don't want the process to terminate if the connection drops
# Run the server in the background using nohup as this bash script will exit and we want the server to keep running after that
nohup python3 server.py &

# exit success code
exit 0

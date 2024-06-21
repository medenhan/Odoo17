#!/bin/bash

# Update the system and install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y git python3-pip python3-dev python3-venv python3-wheel \
    libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools \
    node-less postgresql postgresql-client libpq-dev build-essential wkhtmltopdf

# Create the Odoo user
sudo adduser --system --group --home=/opt/odoo --shell=/bin/bash odoo

# Clone Odoo 17 from the official repository
sudo git clone --depth 1 --branch 17.0 https://www.github.com/odoo/odoo /opt/odoo/odoo

# Create a Python virtual environment for Odoo
sudo -u odoo python3 -m venv /opt/odoo/venv

# Install Python dependencies
sudo -u odoo /opt/odoo/venv/bin/pip install wheel  # Install wheel first
sudo -u odoo /opt/odoo/venv/bin/pip install -r /opt/odoo/odoo/requirements.txt
sudo -u odoo /opt/odoo/venv/bin/pip install psycopg2-binary  # Install binary version to avoid compilation issues

# Create directories for Odoo data and logs
sudo mkdir -p /var/lib/odoo /var/log/odoo
sudo chown odoo:odoo /var/lib/odoo /var/log/odoo

# Create PostgreSQL user for Odoo
sudo -u postgres createuser -s odoo

# Set a password for the PostgreSQL odoo user (change 'odoo_db_password' to your desired password)
sudo -u postgres psql -c "ALTER USER odoo WITH PASSWORD 'odoo_db_password';"

# Create Odoo configuration file
sudo tee /etc/odoo.conf > /dev/null <<EOF
[options]
admin_passwd = admin_master_password
db_host = False
db_port = False
db_user = odoo
db_password = odoo_db_password
addons_path = /opt/odoo/odoo/addons
logfile = /var/log/odoo/odoo.log
EOF

# Set proper permissions for the configuration file
sudo chown odoo:odoo /etc/odoo.conf
sudo chmod 640 /etc/odoo.conf

# Create systemd service file for Odoo
sudo tee /etc/systemd/system/odoo.service > /dev/null <<EOF
[Unit]
Description=Odoo
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/opt/odoo/venv/bin/python3 /opt/odoo/odoo/odoo-bin -c /etc/odoo.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start Odoo service
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo

# Install and configure Nginx as a reverse proxy
sudo apt install -y nginx
sudo tee /etc/nginx/sites-available/odoo > /dev/null <<EOF
upstream odoo {
    server 127.0.0.1:8069;
}

server {
    listen 80;
    server_name _;

    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    client_max_body_size 100m;

    location / {
        proxy_pass http://odoo;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
        proxy_redirect off;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo;
    }
}
EOF

# Enable the Nginx configuration and restart Nginx
sudo ln -s /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/odoo
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

# Print the public IP address for accessing Odoo
echo "Odoo installation complete. You can access it at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
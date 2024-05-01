#!/bin/bash
# Update and upgrade the system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install backend dependencies
sudo apt-get install -y python3-pip
sudo apt-get install -y python3-cffi python3-dev libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev build-essential libssl-dev libffi-dev libmysqlclient-dev libjpeg-dev libpq-dev libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev
sudo apt-get install -y openssh-server fail2ban

# Install frontend dependencies
sudo apt-get install -y npm
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less less-plugin-clean-css
sudo apt-get install -y node-less

# Install and configure PostgreSQL
sudo apt-get install -y postgresql

# Add system user for odoo17
sudo adduser --system --home=/opt/odoo17 --group odoo17

# Install git and Odoo17
sudo apt-get install -y git
sudo su - odoo17 -s /bin/bash
git clone https://www.github.com/odoo/odoo --depth 1 --branch 17.0 --single-branch .
exit

# Download Odoo dependencies and packages
sudo pip3 install -r /opt/odoo17/requirements.txt
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb
sudo wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb
sudo dpkg -i wkhtmltox_0.12.5-1.bionic_amd64.deb
sudo apt install -f -y

# Retrieve database credentials from Secrets Manager
SECRET_NAME="odoo17-db-credentials"
SECRET_STRING=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --query 'SecretString' --output text)
DB_USERNAME=$(echo "$SECRET_STRING" | jq -r '.username')
DB_PASSWORD=$(echo "$SECRET_STRING" | jq -r '.password')
RDS_ENDPOINT=$(echo "$SECRET_STRING" | jq -r '.host')

# Create Odoo conf file
sudo cp /opt/odoo17/debian/odoo.conf /etc/odoo17.conf
sudo sed -i "s/admin_passwd =.*/admin_passwd = admin/" /etc/odoo17.conf
sudo sed -i "s/db_host =.*/db_host = $RDS_ENDPOINT/" /etc/odoo17.conf
sudo sed -i "s/db_user =.*/db_user = $DB_USERNAME/" /etc/odoo17.conf
sudo sed -i "s/db_password =.*/db_password = $DB_PASSWORD/" /etc/odoo17.conf

# Set ownership and permissions for Odoo conf file
sudo chown odoo17: /etc/odoo17.conf
sudo chmod 640 /etc/odoo17.conf

# Create Odoo log directory
sudo mkdir /var/log/odoo
sudo chown odoo17:root /var/log/odoo

# Create Odoo Service file
sudo bash -c 'cat <<EOT > /etc/systemd/system/odoo17.service
[Unit]
Description=Odoo17
Documentation=http://www.odoo.com

[Service]
Type=simple
User=odoo17
ExecStart=/opt/odoo17/odoo-bin -c /etc/odoo17.conf

[Install]
WantedBy=default.target
EOT'

# Set permissions and ownership for Odoo Service file
sudo chmod 755 /etc/systemd/system/odoo17.service
sudo chown root: /etc/systemd/system/odoo17.service

# Start Odoo17 Service
sudo systemctl daemon-reload
sudo systemctl start odoo17.service
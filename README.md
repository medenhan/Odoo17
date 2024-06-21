# Automating Odoo 17 Deployment on AWS EC2 Using Userdata
        # step-by-step instructions and Guides

## 1. Project Overview

### 1.1 Purpose
This document outlines the process of deploying Odoo 17 on an AWS EC2 instance, providing a comprehensive guide for setup, configuration, and maintenance.

### 1.2 Scope
This guide covers the initial setup of an EC2 instance, Odoo 17 installation, basic configuration, and essential maintenance tasks. It is intended for system administrators and DevOps professionals managing Odoo deployments on AWS.

### 1.3 Technologies Used
- Amazon Web Services (AWS) EC2
- Ubuntu Server 22.04 LTS
- Odoo 17
- PostgreSQL
- Nginx
- Python 3

## 2. System Requirements

### 2.1 Hardware Requirements
- Minimum: t3.medium (2 vCPU, 4 GB RAM)
- Recommended: t3.large (2 vCPU, 8 GB RAM) or higher for production use

### 2.2 Software Requirements
- Ubuntu Server 22.04 LTS
- Python 3.8 or higher
- PostgreSQL 12 or higher

### 2.3 Network Requirements
- Inbound traffic allowed on ports 22 (SSH), 80 (HTTP), and 443 (HTTPS)
- Outbound internet access for package installation and updates

## 3. AWS EC2 Instance Setup

### 3.1 Instance Type Selection
1. Log in to the AWS Management Console
2. Navigate to EC2 Dashboard
3. Click "Launch Instance"
4. Choose "Ubuntu Server 22.04 LTS" as the Amazon Machine Image (AMI)
5. Choose an instance type with at least 2 vCPUs and 4GB of RAM (e.g., t3.medium or your chosen instance type).
5. Select t3.medium (or your chosen instance type)
6. Configure Instance Details as needed

### 3.2 Storage Configuration
1. In the "Add Storage" step, set the root volume size to at least 30 GB
2. Choose "General Purpose SSD (gp2)" for the volume type

### 3.3 Security Group Settings
1. Create a new security group or select an existing one
2. Add the following inbound rules:
   - SSH (22): Your IP
   - HTTP (80): Anywhere (0.0.0.0/0)
   - HTTPS (443): Anywhere (0.0.0.0/0)

## 4. Odoo 17 Installation

### 4.1 User Data 

 <br />
    <a href="https://raw.githubusercontent.com/medenhan/Odoo17/main/user-data.sh"><strong>You can access the user-data.sh bash script by clicking here! </strong></a>
    <br />
In the "Advanced details" section, paste the entire script into the "User data" text area.

#### Note that Before launching, make sure to replace "admin_master_password" and "odoo_db_password" in the script with secure passwords of your choice.

#### 4.1.1 Script Overview
The user data script automates the installation and configuration of Odoo 17 and its dependencies. It sets up the necessary environment, installs required packages, configures the database, and sets up Nginx as a reverse proxy.

#### 4.1.2 Detailed Script Explanation
    #!/bin/bash
1- This is called a shebang. It tells the system this is a bash script.

    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git python3-pip python3-dev python3-venv python3-wheel \
    libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools \
    node-less postgresql postgresql-client libpq-dev build-essential wkhtmltopdf
2- These lines update the system and install necessary packages. Each package has a specific purpose (e.g., git for version control, python3-pip for Python package management).

    sudo adduser --system --group --home=/opt/odoo --shell=/bin/bash odoo
3- This creates a system user named 'odoo' to run the Odoo service.

    sudo git clone --depth 1 --branch 17.0 https://www.github.com/odoo/odoo /opt/odoo/odoo
4- This clones the Odoo source code from GitHub.
    sudo -u odoo python3 -m venv /opt/odoo/venv
5- This creates a Python virtual environment for Odoo.
    sudo -u odoo /opt/odoo/venv/bin/pip install wheel
    sudo -u odoo /opt/odoo/venv/bin/pip install -r /opt/odoo/odoo/requirements.txt
    sudo -u odoo /opt/odoo/venv/bin/pip install psycopg2-binary
6- These commands install Python packages required by Odoo.

The rest of the script sets up configuration files, creates necessary directories, sets up the database, and configures the web server (Nginx).
### 4.2 Access Odoo:
   - Once the instance is running, find its public IP address in the EC2 console.
   - Open a web browser and navigate to http://<public-ip-address>.
   - You should see the Odoo database creation page.

### 4.3 Create your first Odoo database:

On the Odoo database creation page, fill in the required information:
   - Master Password: Use the admin_master_password you set in the script.
   - Database Name: Choose a name for your database.
   - Email: This will be your admin user email.
   - Password: Set a password for your admin user.
   - Phone Number: Optional.
   - Language: Choose your preferred language.
   - Country: Select your country.
Decide whether to load demonstration data (recommended for testing).
   - Click "Create database".

### 4.4 Logging in

After database creation, you'll be redirected to the login page.
Use the email and password you just set to log in.

### 4.5 Post-Installation Configuration
1. Change the default master password in /etc/odoo.conf for additional security.
2. Consider setting up regular database backups.
3. For production use, implement HTTPS using Let's Encrypt or AWS Certificate Manager.

## 5. Troubleshooting
If you encounter any issues:

SSH into your instance:
    ssh ubuntu@<your-instance-ip>

Check Odoo service status:
    sudo systemctl status odoo

View Odoo logs:
    sudo tail -f /var/log/odoo/odoo.log

Check Nginx status and logs:
    sudo systemctl status nginx
    sudo tail -f /var/log/nginx/error.log

## 6. Customization

   - To install additional Odoo modules, use the Odoo interface or add them to /opt/odoo/odoo/addons.
   - To change Odoo configuration, edit /etc/odoo.conf and restart the service:
    sudo nano /etc/odoo.conf
    sudo systemctl restart odoo

Remember, this setup is suitable for testing or small production environments. For larger deployments, consider separating the database, implementing load balancing, and adding more robust security measures.

By following these steps, you should have a functioning Odoo 17 installation on your EC2 instance, with most of the common issues preemptively addressed. Always monitor your instance and Odoo logs for any unexpected behavior or performance issues.

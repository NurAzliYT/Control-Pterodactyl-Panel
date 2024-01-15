#!/bin/bash

# Skrip Instalasi Otomatis dengan MariaDB, Nginx, SSL, dan Composer

# Meminta informasi dari pengguna
read -p "Masukkan nama pengguna: " username
read -p "Masukkan nama proyek: " project_name
read -p "Masukkan nama domain (contoh: example.com): " domain_name
read -p "Masukkan alamat email untuk sertifikat SSL: " email_address
read -p "Masukkan password MariaDB: " mariadb_password

# Instalasi MariaDB Server
sudo apt-get update
sudo apt-get install -y mariadb-server

# Konfigurasi MariaDB Server
sudo mysql_secure_installation <<EOF
Y
$mysql_password
$mysql_password
Y
Y
Y
Y
EOF

# Instalasi Firewall
sudo apt-get install -y ufw
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# Instalasi Nginx
sudo apt-get install -y nginx

# Instalasi Certbot (Let's Encrypt)
sudo apt-get install -y certbot python3-certbot-nginx

# Instalasi Composer
sudo apt-get install -y composer

# Konfigurasi Nginx dan SSL dengan Certbot
sudo tee "/etc/nginx/sites-available/$project_name" > /dev/null <<EOF
server {
    listen 80;
    server_name $domain_name www.$domain_name;
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $domain_name www.$domain_name;

    ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain_name/privkey.pem;

    location / {
        root /var/www/$project_name;
        index index.html index.htm;
    }

    # Konfigurasi tambahan sesuai kebutuhan
}
EOF

sudo ln -s /etc/nginx/sites-available/$project_name /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# Membuat direktori proyek
sudo mkdir -p /var/www/$project_name
sudo chown -R $username:$username /var/www/$project_name

# Meminta Certbot membuat sertifikat SSL
sudo certbot --nginx -d $domain_name -d www.$domain_name --email $email_address --agree-tos --non-interactive

php artisan key:generate

php artisan queue:restart

# Selesai
echo "Instalasi dan konfigurasi selesai. Silakan cek https://$domain_name di browser Anda."

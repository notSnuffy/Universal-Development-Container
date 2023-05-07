#!/usr/bin/env bash

set -eux

INSTALL_COMPOSER="${INSTALLCOMPOSER:-"true"}"

export DEBIAN_FRONTEND=noninteractive
apt-get update

# Install PHP and Apache
apt-get -y install php php-mysql apache2 libapache2-mod-php php-cli php-curl php-gd php-intl php-json php-mbstring php-xml php-zip php-xdebug

# Enable modules
a2enmod rewrite && phpenmod mysqli && phpenmod xdebug && phpenmod mbstring && phpenmod zip && phpenmod intl && phpenmod gd && phpenmod curl && phpenmod json && phpenmod xml

# Install PHP Composer
addcomposer() {
    PHP_SRC=$(which php)
    "${PHP_SRC}" -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
    "${PHP_SRC}" -r "if (hash_file('sha384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    "${PHP_SRC}" composer-setup.php --install-dir="/usr/local/bin" --filename=composer
    "${PHP_SRC}" -r "unlink('composer-setup.php');"
}

# Install PHP Composer if needed
if [[ "${INSTALL_COMPOSER}" = "true" ]]; then
    addcomposer
fi

# Configure Xdebug
XDEBUG_INI=$(find /etc/php -name xdebug.ini)
echo "xdebug.mode = debug" >> "${XDEBUG_INI}"
echo "xdebug.start_with_request = yes" >> "${XDEBUG_INI}"
echo "xdebug.client_port = 9003" >> "${XDEBUG_INI}"

# Configure Apache

echo "ServerName localhost" >> "/etc/apache2/apache2.conf"
echo "Listen 8081" >> "/etc/apache2/ports.conf"
cat server.conf > /etc/apache2/sites-available/000-default.conf
chown -R vscode:vscode /var/www/html

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"

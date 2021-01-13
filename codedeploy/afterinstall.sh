#!/bin/bash

if ! [ -f "/var/www/moodle/html/version.php" ]; then
    echo "Checkout code from Github..."
    git clone git@github.com:ucla/moodle.git /var/www/moodle/html
fi

cd /var/www/moodle/html || exit 1

if [ "$DEPLOYMENT_GROUP_NAME" == "Testing" ]; then
    echo "Checking out development branch..."
    git checkout development
else
    echo "Checking out master branch..."
    git checkout master
fi

if ! [ -f "/var/www/moodle/html/lib/aws.phar" ]; then
    echo "Downloading aws.phar..."
    wget -O /var/www/moodle/html/lib/aws.phar https://docs.aws.amazon.com/aws-sdk-php/v3/download/aws.phar
fi

echo "Updating moodle submodules..."
git submodule sync
git submodule update --init --recursive

composer -v > /dev/null 2>&1
COMPOSER=$?
if [[ $COMPOSER -ne 0 ]]; then
    echo "Installing composer..."
    curl -sS http://getcomposer.org/installer | php
fi
echo "Doing composer install..."
php composer.phar install

if [ -L "config.php" ]; then
    echo "Config symlink exists, no need to make a new one"
elif [ "$DEPLOYMENT_GROUP_NAME" == "Development" ]; then
    echo "Using DEV config file..."
    ln -s local/ucla/config/shared_dev_moodle-config.php config.php
elif [ "$DEPLOYMENT_GROUP_NAME" == "Testing" ]; then
    echo "Using TEST config file..."
    ln -s local/ucla/config/shared_test_moodle-config.php config.php
elif [ "$DEPLOYMENT_GROUP_NAME" == "Staging" ]; then
    echo "Using STAGE config file..."
    ln -s local/ucla/config/shared_stage_moodle-config.php config.php
elif [ "$DEPLOYMENT_GROUP_NAME" == "Production" ]; then
    echo "Using PROD config file..."
    ln -s local/ucla/config/shared_prod_moodle-config.php config.php
else
    # Fail here since we have an invalid deployment name.
    echo "No config found for $DEPLOYMENT_GROUP_NAME"
    exit 1
fi

if ! [ -f "config_private.php" ]; then
    if ! [ -f "/tmp/config_private.php" ]; then
        echo "File /tmp/config_private.php not found, try refreshing the instances"
        exit 1
    else
        echo "Copying config_private.php..."
        mv /tmp/config_private.php ./config_private.php
    fi
else
    echo "Config private exists, no need to make a new one"
fi

if ! [ -d /var/www/moodle/ccle_email_templates ]; then
    echo "Copying course creator email templates..."
    git clone https://github.com/ucla/ccle_email_templates.git /var/www/moodle/ccle_email_templates
else
    echo "Updating course creator email templates..."
    cd /var/www/moodle/ccle_email_templates || exit 1
    git pull
fi
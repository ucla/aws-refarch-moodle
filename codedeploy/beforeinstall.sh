#!/bin/bash

yum install -y git

# Remove placeholder if there are no other files
if ! [ -f "/var/www/moodle/html/version.php" ]; then
  echo "Removing placeholder file..."
  rm /var/www/moodle/html/README.txt
fi

echo "Adding Github to knownhost list..."
ssh-keyscan -H  github.com >>  ~/.ssh/known_hosts

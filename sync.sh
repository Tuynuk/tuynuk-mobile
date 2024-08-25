#!/bin/bash

read -p "Enter server ip address: " serverIp
# Define the .env file name
ENV_FILE="environment.env"

# Generate a key in base64 format
KEY=$(openssl rand -base64 12)

# Create the .env file if it doesn't exist and write the key to it
if [ ! -f "$ENV_FILE" ]; then
    touch $ENV_FILE
    echo "key='$KEY'" >> $ENV_FILE
    echo "serverIp='$serverIp'" >> $ENV_FILE
    echo ".env file created with a key."
else
    echo "env.env file already exists."
fi

dart run build_runner build
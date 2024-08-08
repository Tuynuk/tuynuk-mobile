#!/bin/bash

# Define the .env file name
ENV_FILE="env.env"

# Generate a key in base64 format
KEY=$(openssl rand -base64 12)

# Create the .env file if it doesn't exist and write the key to it
if [ ! -f "$ENV_FILE" ]; then
    touch $ENV_FILE
    echo "key='$KEY'" >> $ENV_FILE
    echo ".env file created with a 16-byte key."
else
    echo "env.env file already exists."
#    echo "KEY=$KEY" >> $ENV_FILE
#    echo "16-byte key added to the existing .env file."
fi

dart run build_runner build
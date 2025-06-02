#!/bin/bash

# Set the AWS Region
REGION="${AWS_REGION}"

# Set the AWS Secrets Manager Secret ID
SECRET_ID="arn:aws:secretsmanager:us-west-2:515275665481:secret:database_credentials-SxABtZ"

# Define the MySQL configuration file path
MYSQL_CONFIG=/docker-entrypoint-initdb.d/mysql-config.cnf

# Retrieve the secret from AWS Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id $SECRET_ID \
  --region $REGION \
  --output json | jq -r .SecretString > /run/secrets/mysql_secrets.json

# Read secrets from JSON
MYSQL_USER=$(cat /run/secrets/mysql_secrets.json | jq -r .username)
MYSQL_PASSWORD=$(cat /run/secrets/mysql_secrets.json | jq -r .password)

# Create the MySQL configuration file
echo "[client]" > $MYSQL_CONFIG
echo "user = $MYSQL_USER" >> $MYSQL_CONFIG
echo "password = $MYSQL_PASSWORD" >> $MYSQL_CONFIG
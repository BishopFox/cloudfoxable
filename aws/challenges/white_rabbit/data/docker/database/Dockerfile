FROM mysql:8.0

# Install AWS CLI
#RUN apt update && apt install -y awscli

# Create a directory to store the fetched secrets
RUN mkdir -p /run/secrets

# Copy the script to retrieve and apply the secrets
COPY ./get_secrets.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/get_secrets.sh

# Set the environment variable for AWS region
ENV AWS_REGION=us-west-2
ENV AWS_ACCESS_KEY_ID=AKIAXP6GSWBEXLLZFJI3
ENV AWS_SECRET_ACCESS_KEY=REMOVED
ENV VERSION=latest

# Copy the Docker entrypoint override script
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
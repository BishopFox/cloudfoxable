# Use a smaller base image (debian-slim)
FROM debian:bullseye-slim

# Set non-interactive mode to avoid prompting during apt-get install
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies, AWS CLI, Terraform in one RUN step and clean up cache
RUN apt-get update && apt-get install -y \
    curl \
    nano \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    jq \
    software-properties-common \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip && ./aws/install \
    && rm -rf awscliv2.zip ./aws \
    && curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
    && apt-add-repository "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && apt-get update && apt-get install -y terraform \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the application code
COPY . /cloudfoxable

# Set the working directory (optional)
WORKDIR /cloudfoxable/aws

# Default command (optional)
ENTRYPOINT ["/bin/bash"]

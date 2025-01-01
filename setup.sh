#!/bin/bash

# ANSI escape codes for colors
RESET='\033[0m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'

# Function to execute commands and handle errors
executeCommand() {
    command=$1
    result=$(eval "$command" 2>&1)
    status=$?
    if [ $status -ne 0 ]; then
        echo -e "${RED}Error executing command: $command${RESET}"
        echo "$result"
        exit 1
    fi
    echo "$result"
}

# Check if Node.js and npm are installed
if ! command -v node &>/dev/null; then
    echo -e "${RED}Ensure you have Node.js installed on your system.${RESET}"
    exit 1
fi

# Check if Wrangler is installed
if ! command -v wrangler &>/dev/null; then
    echo -e "${YELLOW}Wrangler is not installed. Installing Wrangler...${RESET}"
    executeCommand "npm install -g wrangler &>/dev/null"
fi

# Check if the repository is already cloned
REPO_DIR="gradle-mirror-cloudflare-worker"
REPO_URL="https://github.com/ehsannarmani/gradle-mirror-cloudflare-worker"
if [ -d "$REPO_DIR" ]; then
    echo -e "${CYAN}Repository already cloned.${RESET}"
else
    # Clone the repository (suppress output)
    echo -e "${CYAN}Cloning the repository...${RESET}"
    git clone REPO_URL &>/dev/null || {
        echo -e "${RED}Error: Failed to clone repository.${RESET}"
        exit 1
    }
fi

# Navigate to the repository directory
cd "$REPO_DIR" || exit

# Check if Wrangler is logged in by running `wrangler whoami`
echo -e "${CYAN}Checking if you are logged in to wrangler...${RESET}"

whoami_output=$(wrangler whoami 2>&1)

if [[ "$whoami_output" == *"You are not authenticated"* ]]; then
    echo -e "${CYAN}Logging into Wrangler...${RESET}"
    executeCommand "wrangler login"
    # Clear the console after login success
    clear
    echo -e "${GREEN}Logged in successfully!${RESET}"
    echo -e "${CYAN}Proceeding with deployment...${RESET}"
else
    echo -e "${CYAN}You are already logged in.${RESET}"
fi

# Modify compatibility_date in wrangler.toml to yesterday's date
DATE=$(date -d "yesterday" +%Y-%m-%d)

sed -i "s/^compatibility_date = .*/compatibility_date = \"$DATE\"/" wrangler.toml

# Deploy the Worker and capture the result
echo -e "${CYAN}Deploying the Mirror...${RESET}"
deployResult=$(executeCommand "wrangler deploy")

# Extract the worker URL from the deployment result using a more refined method
workerUrl=$(echo "$deployResult" | grep -oE 'https://[a-zA-Z0-9.-]+\.workers\.dev')

if [ -n "$workerUrl" ]; then
    echo -e "${GREEN}Your Mirror has been successfully deployed!${RESET}"
    echo -e "${GREEN}Mirror URL: $workerUrl${RESET}"
else
    echo -e "${RED}Error: Unable to extract the worker URL from the deployment output.${RESET}"
    exit 1
fi

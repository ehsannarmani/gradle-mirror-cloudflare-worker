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
        return 1
    fi
    echo "$result"
    return 0
}

# Check if Node.js is installed
if ! command -v node &>/dev/null; then
    echo -e "${RED}Node.js is not installed. Please install Node.js to proceed.${RESET}"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &>/dev/null; then
    echo -e "${RED}npm is not installed. Please install npm to proceed.${RESET}"
    exit 1
fi

# Check if Wrangler is installed
if ! command -v wrangler &>/dev/null; then
    echo -e "${YELLOW}Wrangler is not installed. Attempting to install Wrangler...${RESET}"
    executeCommand "npm install -g wrangler &>/dev/null"
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Retrying Wrangler installation with sudo...${RESET}"
        executeCommand "sudo npm install -g wrangler &>/dev/null"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to install Wrangler. Please install it manually.${RESET}"
            exit 1
        fi
    fi
    echo -e "${GREEN}Wrangler installed successfully.${RESET}"
fi

# Repository details
REPO_DIR="gradle-mirror-cloudflare-worker"
REPO_URL="https://github.com/ehsannarmani/gradle-mirror-cloudflare-worker"

# Check if the repository is already cloned
if [ -d "$REPO_DIR" ]; then
    echo -e "${CYAN}Repository already cloned.${RESET}"
else
    echo -e "${CYAN}Cloning the repository...${RESET}"
    git clone "$REPO_URL" &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to clone repository.${RESET}"
        exit 1
    fi
fi

# Navigate to the repository directory
cd "$REPO_DIR" || {
    echo -e "${RED}Error: Failed to navigate to repository directory.${RESET}"
    exit 1
}

# Check if Wrangler is logged in
echo -e "${CYAN}Checking if you are logged in to Wrangler...${RESET}"
whoami_output=$(wrangler whoami 2>&1)
if [[ "$whoami_output" == *"You are not authenticated"* ]]; then
    echo -e "${CYAN}Logging into Wrangler...${RESET}"
    executeCommand "wrangler login"
    clear
    echo -e "${GREEN}Logged in successfully!${RESET}"
else
    echo -e "${CYAN}You are already logged in.${RESET}"
fi

# Update compatibility_date in wrangler.toml to yesterday's date
DATE=$(date -d "yesterday" +%Y-%m-%d)
sed -i "s/^compatibility_date = .*/compatibility_date = \"$DATE\"/" wrangler.toml

# Deploy the Worker
echo -e "${CYAN}Deploying the Mirror...${RESET}"
deployResult=$(executeCommand "wrangler deploy")

# Extract the worker URL
workerUrl=$(echo "$deployResult" | grep -oE 'https://[a-zA-Z0-9.-]+\.workers\.dev')
if [ -n "$workerUrl" ]; then
    echo -e "${GREEN}Your Mirror has been successfully deployed!${RESET}"
    echo -e "${GREEN}Mirror URL: $workerUrl${RESET}"
else
    echo -e "${RED}Error: Unable to extract the worker URL from the deployment output.${RESET}"
    exit 1
fi

# Cleanup: Delete the repository folder if it was cloned
cd .. || exit
rm -rf "$REPO_DIR"

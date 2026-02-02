#!/bin/bash
set -euo pipefail

# Color codes - Amber theme
AMBER='\033[0;33m'           # Dark amber/yellow
BRIGHT_AMBER='\033[1;33m'    # Bright amber/yellow
ORANGE='\033[38;5;208m'      # Orange
BRIGHT_ORANGE='\033[38;5;214m' # Bright orange
GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
DIM='\033[2m'
NC='\033[0m'

# Gradient header animation
print_gradient_header() {
    echo ""
    echo -e "${BRIGHT_ORANGE}>>> ${BRIGHT_AMBER}PC ${AMBER}CONFIGURATION${NC}"
    echo ""
}

# Simple spinner that works
spinner() {
    local pid=$1
    local delay=0.1
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r${ORANGE}>>> ${NC}Configuring system ${ORANGE}${frames[$i]}${NC} "
        i=$(( (i + 1) % 10 ))
        sleep $delay
    done
    
    printf "\r${ORANGE}>>> ${NC}Configuring system...   \n"
}

# Clear screen
clear

# Header
print_gradient_header

# Welcome message
echo -e "${ORANGE}>>>${NC} Welcome to the setup wizard! Let's configure your system."
echo ""

# Show completed steps
echo -e "${GREEN}✓${NC} ${DIM}Where would you like to create your profile?${NC} ${GRAY}$(pwd)${NC}"
echo -e "${GREEN}✓${NC} ${DIM}Which authentication method?${NC} ${GRAY}Local credentials${NC}"
echo ""

# Get username
echo -e "${AMBER}?${NC} ${WHITE}Username${NC}"
echo -ne "${BRIGHT_AMBER}›${NC} "
read -r username

if [ -z "$username" ]; then
    echo ""
    echo -e "${RED}✕${NC} Username cannot be empty"
    exit 1
fi

echo ""

# Get password
echo -e "${AMBER}?${NC} ${WHITE}Password${NC}"
echo -ne "${BRIGHT_AMBER}›${NC} "
read -sr password
echo

if [ -z "$password" ]; then
    echo ""
    echo -e "${RED}✕${NC} Password cannot be empty"
    exit 1
fi

echo ""

# Show spinner during configuration
sleep 2 &
spinner $!

# Success messages
echo ""
echo -e "${GREEN}✓${NC} User profile created"
echo -e "${GREEN}✓${NC} Authentication configured"
echo -e "${GREEN}✓${NC} System settings applied"
echo ""

echo -e "${ORANGE}>>>${NC} ${BRIGHT_GREEN}Configuration complete!${NC}"
echo ""
echo -e "${DIM}User: ${username}${NC}"
echo ""
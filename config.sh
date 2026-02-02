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

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}✕${NC} This script must be run with sudo"
    echo -e "${DIM}Please run: sudo $0${NC}"
    exit 1
fi

# Gradient header animation
print_gradient_header() {
    echo ""
    echo -e "${BRIGHT_ORANGE}>>> ${BRIGHT_AMBER}RASPBERRY PI ${AMBER}CONFIGURATION${NC}"
    echo ""
}

# Simple spinner that works
spinner() {
    local pid=$1
    local delay=0.1
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r${ORANGE}>>> ${NC}Saving configuration ${ORANGE}${frames[$i]}${NC} "
        i=$(( (i + 1) % 10 ))
        sleep $delay
    done
    
    printf "\r${ORANGE}>>> ${NC}Saving configuration...   \n"
}

# Clear screen
clear

# Header
print_gradient_header

# Welcome message
echo -e "${ORANGE}>>>${NC} Welcome to the Raspberry Pi Network Setup! 🚀"
echo ""

# Explain what will happen
echo -e "${WHITE}This script will:${NC}"
echo -e "  ${ORANGE}•${NC} Save your Wi-Fi network credentials"
echo -e "  ${ORANGE}•${NC} Configure your Pi to connect automatically on boot"
echo ""

echo -e "${DIM}You'll need your home Wi-Fi network name (SSID) and password.${NC}"
echo -e "${DIM}After setup, your Pi will connect when you boot it at home.${NC}"
echo ""

echo -e "${AMBER}⚠${NC}  ${WHITE}Important:${NC} Make sure you have the correct Wi-Fi information!"
echo -e "${DIM}   If connection doesn't work, visit the Techlab and we'll assist you.${NC}"
echo ""

# Prompt to continue
echo -e "${WHITE}Press Enter to continue or Ctrl+C to cancel...${NC}"
read -r
echo ""

# Get SSID
echo -e "${AMBER}?${NC} ${WHITE}Wi-Fi Network Name (SSID)${NC}"
echo -e "${DIM}  Example: MyHomeWiFi or Apartment-5G${NC}"
echo -ne "${BRIGHT_AMBER}›${NC} "
read -r ssid

if [ -z "$ssid" ]; then
    echo ""
    echo -e "${RED}✕${NC} SSID cannot be empty"
    exit 1
fi

echo ""

# Get password
echo -e "${AMBER}?${NC} ${WHITE}Wi-Fi Password${NC}"
echo -e "${DIM}  Your password will be stored securely${NC}"
echo -ne "${BRIGHT_AMBER}›${NC} "
read -sr wifi_password
echo

if [ -z "$wifi_password" ]; then
    echo ""
    echo -e "${RED}✕${NC} Password cannot be empty"
    exit 1
fi

echo ""

# Confirm settings
echo -e "${ORANGE}>>>${NC} ${WHITE}Review your settings:${NC}"
echo ""
echo -e "  ${DIM}Network:${NC} ${ssid}"
echo ""

echo -e "${AMBER}?${NC} ${WHITE}Does this look correct?${NC} ${DIM}(y/n)${NC} ${BRIGHT_AMBER}›${NC} "
read -n 1 -r
echo
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${ORANGE}>>>${NC} Configuration cancelled. Run this script again when ready!"
    echo ""
    exit 0
fi

# Show spinner during configuration
(
    # ============================================================================
    # YOUR WI-FI CONFIGURATION LOGIC GOES HERE
    # ============================================================================
    
    # Placeholder: Validate inputs
    echo "$ssid" > /dev/null
    echo "$wifi_password" > /dev/null
    
    # Placeholder: Prepare configuration
    sleep 0.5
    
    # Adds Wi-Fi credentials with nmcli (NetworkManager CLI)
    sudo nmcli -p connection add type wifi con-name "TestNetwork" \
    ifname wlan0 ssid "$ssid" \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "$wifi_password"
        
    # Placeholder: Apply settings
    sleep 0.5
    
    # ============================================================================
    # END CONFIGURATION
    # ============================================================================
    
) &

spinner $!

# Success messages
echo ""
echo -e "${GREEN}✓${NC} Wi-Fi credentials saved securely"
echo -e "${GREEN}✓${NC} Network configuration complete"
echo -e "${GREEN}✓${NC} Auto-connect enabled"
echo ""

echo -e "${ORANGE}>>>${NC} ${BRIGHT_GREEN}Configuration complete!${NC}"
echo ""

# Next steps
echo -e "${WHITE}Next steps:${NC}"
echo -e "  ${ORANGE}1.${NC} Take your Pi home and plug it in"
echo -e "  ${ORANGE}2.${NC} Your Pi will automatically connect to ${BRIGHT_AMBER}${ssid}${NC}"
echo -e "  ${ORANGE}3.${NC} ${DIM}If it doesn't connect, visit the Techlab for assistance${NC}"
echo ""

echo -e "${BRIGHT_AMBER}💡 Troubleshooting tips:${NC}"
echo -e "  ${DIM}• Make sure you're within range of your network${NC}"
echo -e "  ${DIM}• Double-check that your password was entered correctly${NC}"
echo -e "  ${DIM}• Some networks require additional setup (guest networks, enterprise)${NC}"
echo -e "  ${DIM}• You can run this script again anytime to update settings${NC}"
echo ""

echo -e "${DIM}Configuration saved for:${NC} ${ssid}"
echo ""
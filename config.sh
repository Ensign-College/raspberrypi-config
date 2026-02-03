#!/bin/bash
set -euo pipefail

# Color codes - Amber theme
AMBER='\033[0;33m'
BRIGHT_AMBER='\033[1;33m'
ORANGE='\033[38;5;208m'
BRIGHT_ORANGE='\033[38;5;214m'
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

# Help/usage
show_help() {
    echo -e "${BRIGHT_ORANGE}>>> ${BRIGHT_AMBER}RASPBERRY PI ${AMBER}WI-FI MANAGER${NC}"
    echo ""
    echo -e "${WHITE}Usage:${NC}"
    echo -e "  ${ORANGE}sudo $0${NC}              Set up a new Wi-Fi network"
    echo -e "  ${ORANGE}sudo $0 --list${NC}       List saved Wi-Fi networks"
    echo -e "  ${ORANGE}sudo $0 --delete${NC}     Delete a saved network"
    echo -e "  ${ORANGE}sudo $0 --help${NC}       Show this help"
    echo ""
    exit 0
}

# List saved wifi connections
list_networks() {
    echo -e "${BRIGHT_ORANGE}>>> ${BRIGHT_AMBER}SAVED WI-FI NETWORKS${NC}"
    echo ""
    
    local networks
    networks=$(nmcli -t -f NAME,TYPE connection show | grep ':.*wireless' | cut -d: -f1)
    
    if [ -z "$networks" ]; then
        echo -e "  ${DIM}No Wi-Fi networks configured${NC}"
    else
        echo "$networks" | while read -r net; do
            echo -e "  ${ORANGE}•${NC} $net"
        done
    fi
    echo ""
    exit 0
}

# Delete a network
delete_network() {
    echo -e "${BRIGHT_ORANGE}>>> ${BRIGHT_AMBER}DELETE WI-FI NETWORK${NC}"
    echo ""
    
    local networks
    networks=$(nmcli -t -f NAME,TYPE connection show | grep ':.*wireless' | cut -d: -f1)
    
    if [ -z "$networks" ]; then
        echo -e "  ${DIM}No Wi-Fi networks to delete${NC}"
        echo ""
        exit 0
    fi
    
    echo -e "${WHITE}Saved networks:${NC}"
    local i=1
    local net_array=()
    while read -r net; do
        echo -e "  ${ORANGE}${i}.${NC} $net"
        net_array+=("$net")
        ((i++))
    done <<< "$networks"
    echo ""
    
    echo -e "${AMBER}?${NC} ${WHITE}Enter number to delete (or 'q' to cancel):${NC}"
    echo -ne "${BRIGHT_AMBER}›${NC} "
    read -r choice
    
    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo -e "${ORANGE}>>>${NC} Cancelled"
        exit 0
    fi
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#net_array[@]}" ]; then
        echo -e "${RED}✕${NC} Invalid selection"
        exit 1
    fi
    
    local to_delete="${net_array[$((choice-1))]}"
    
    echo ""
    echo -e "${AMBER}?${NC} ${WHITE}Delete '${to_delete}'?${NC} ${DIM}(y/n)${NC}"
    echo -ne "${BRIGHT_AMBER}›${NC} "
    read -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if nmcli connection delete "$to_delete" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Deleted '${to_delete}'"
        else
            echo -e "${RED}✕${NC} Failed to delete '${to_delete}'"
            exit 1
        fi
    else
        echo -e "${ORANGE}>>>${NC} Cancelled"
    fi
    echo ""
    exit 0
}

# Parse arguments
case "${1:-}" in
    --help|-h) show_help ;;
    --list|-l) list_networks ;;
    --delete|-d) delete_network ;;
    "") ;; 
    *)
        echo -e "${RED}✕${NC} Unknown option: $1"
        echo -e "${DIM}Run '$0 --help' for usage${NC}"
        exit 1
        ;;
esac

# Gradient header
print_gradient_header() {
    echo ""
    echo -e "${BRIGHT_ORANGE}>>> ${BRIGHT_AMBER}RASPBERRY PI ${AMBER}WI-FI SETUP${NC}"
    echo ""
}

# Spinner that suppresses background output
spinner() {
    local pid=$1
    local delay=0.1
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${ORANGE}>>> ${NC}Saving configuration ${ORANGE}${frames[$i]}${NC}  "
        i=$(( (i + 1) % 10 ))
        sleep $delay
    done
    printf "\r${ORANGE}>>> ${NC}Saving configuration...    \n"
}

# Sanitize input - remove dangerous characters
sanitize_input() {
    local input="$1"
    # Remove null bytes and control characters (except space)
    echo "$input" | tr -d '\000-\010\013\014\016-\037'
}

# Validate SSID
validate_ssid() {
    local ssid="$1"
    
    if [ -z "$ssid" ]; then
        echo -e "${RED}✕${NC} SSID cannot be empty"
        return 1
    fi
    
    if [ ${#ssid} -gt 32 ]; then
        echo -e "${RED}✕${NC} SSID too long (max 32 characters)"
        return 1
    fi
    
    return 0
}

# Validate password
validate_password() {
    local password="$1"
    
    if [ -z "$password" ]; then
        echo -e "${RED}✕${NC} Password cannot be empty"
        return 1
    fi
    
    if [ ${#password} -lt 8 ]; then
        echo -e "${RED}✕${NC} WPA2 passwords must be at least 8 characters"
        return 1
    fi
    
    if [ ${#password} -gt 63 ]; then
        echo -e "${RED}✕${NC} Password too long (max 63 characters)"
        return 1
    fi
    
    return 0
}

# Check for existing connection
check_existing_connection() {
    local ssid="$1"
    
    if nmcli connection show "$ssid" &>/dev/null; then
        echo ""
        echo -e "${AMBER}⚠${NC}  ${WHITE}Network '${ssid}' is already configured${NC}"
        echo ""
        echo -e "${AMBER}?${NC} ${WHITE}What would you like to do?${NC}"
        echo -e "  ${ORANGE}1.${NC} Update with new password"
        echo -e "  ${ORANGE}2.${NC} Keep existing and exit"
        echo ""
        echo -ne "${BRIGHT_AMBER}›${NC} "
        read -n 1 -r choice
        echo
        
        case "$choice" in
            1)
                echo ""
                echo -e "${ORANGE}>>>${NC} Removing old configuration..."
                nmcli connection delete "$ssid" > /dev/null 2>&1
                return 0
                ;;
            *)
                echo ""
                echo -e "${ORANGE}>>>${NC} Keeping existing configuration"
                exit 0
                ;;
        esac
    fi
    return 0
}

# Configure WiFi
configure_wifi() {
    local ssid="$1"
    local password="$2"
    local con_name="$ssid"
    
    # Create connection with password inline
    if ! nmcli connection add \
        type wifi \
        con-name "$con_name" \
        ifname wlan0 \
        ssid "$ssid" \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "$password" \
        > /dev/null 2>&1; then
        echo -e "${RED}✕${NC} Failed to create connection"
        return 1
    fi
    
    # Set auto-connect priority
    nmcli connection modify "$con_name" \
        connection.autoconnect yes \
        connection.autoconnect-priority 100 \
        > /dev/null 2>&1
    
    return 0
}



# ============================================================================
# MAIN SCRIPT
# ============================================================================

clear
print_gradient_header

# Welcome
echo -e "${ORANGE}>>>${NC} Welcome to the Raspberry Pi Network Setup! 🚀"
echo ""
echo -e "${WHITE}This script will:${NC}"
echo -e "  ${ORANGE}•${NC} Save your Wi-Fi network credentials securely"
echo -e "  ${ORANGE}•${NC} Configure your Pi to connect automatically on boot"
echo ""
echo -e "${DIM}You'll need your home Wi-Fi network name (SSID) and password.${NC}"
echo ""
echo -e "${AMBER}⚠${NC}  ${WHITE}Tip:${NC} Use ${DIM}--list${NC} to see saved networks, ${DIM}--delete${NC} to remove one"
echo ""
echo -e "${WHITE}Press Enter to continue or Ctrl+C to cancel...${NC}"
read -r
echo ""

# Get SSID
while true; do
    echo -e "${AMBER}?${NC} ${WHITE}Wi-Fi Network Name (SSID)${NC}"
    echo -e "${DIM}  Example: MyHomeWiFi or Apartment-5G${NC}"
    echo -ne "${BRIGHT_AMBER}›${NC} "
    read -r ssid_raw
    
    ssid=$(sanitize_input "$ssid_raw")
    
    if validate_ssid "$ssid"; then
        break
    fi
    echo ""
done

# Check for existing connection with same name
check_existing_connection "$ssid"

echo ""

# Get password
while true; do
    echo -e "${AMBER}?${NC} ${WHITE}Wi-Fi Password${NC}"
    echo -e "${DIM}  Must be 8-63 characters (WPA2 requirement)${NC}"
    echo -ne "${BRIGHT_AMBER}›${NC} "
    read -sr wifi_password_raw
    echo
    
    wifi_password=$(sanitize_input "$wifi_password_raw")
    
    if validate_password "$wifi_password"; then
        break
    fi
    echo ""
done

echo ""

# Confirm
echo -e "${ORANGE}>>>${NC} ${WHITE}Review your settings:${NC}"
echo ""
echo -e "  ${DIM}Network:${NC}  ${ssid}"
echo -e "  ${DIM}Password:${NC} $( printf '*%.0s' $(seq 1 ${#wifi_password}) )"
echo ""

echo -e "${AMBER}?${NC} ${WHITE}Save this configuration?${NC} ${DIM}(y/n)${NC}"
echo -ne "${BRIGHT_AMBER}›${NC} "
read -n 1 -r
echo
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${ORANGE}>>>${NC} Configuration cancelled. Run this script again when ready!"
    echo ""
    exit 0
fi

# Configure with spinner
(
    configure_wifi "$ssid" "$wifi_password"
) &

spinner $!
wait $! || {
    echo -e "${RED}✕${NC} Configuration failed"
    exit 1
}

# Success
echo ""
echo -e "${GREEN}✓${NC} Wi-Fi credentials saved"
echo -e "${GREEN}✓${NC} Auto-connect enabled for '${ssid}'"
echo ""
echo -e "${ORANGE}>>>${NC} ${BRIGHT_GREEN}Configuration complete!${NC}"
echo ""

# Clear next steps
echo -e "${WHITE}What happens now:${NC}"
echo -e "  ${ORANGE}•${NC} Your Pi is still connected to the TechLab network"
echo -e "  ${ORANGE}•${NC} The new network '${BRIGHT_AMBER}${ssid}${NC}' is saved but ${WHITE}not active yet${NC}"
echo -e "  ${ORANGE}•${NC} When you take your Pi home and power it on, it will connect automatically"
echo ""

echo -e "${WHITE}Next steps:${NC}"
echo -e "  ${ORANGE}1.${NC} Shut down your Pi safely: ${DIM}sudo shutdown now${NC}"
echo -e "  ${ORANGE}2.${NC} Take it home and plug it in"
echo -e "  ${ORANGE}3.${NC} It will connect to ${BRIGHT_AMBER}${ssid}${NC} automatically"
echo ""

echo -e "${BRIGHT_AMBER}💡 If it doesn't connect at home:${NC}"
echo -e "  ${DIM}• Most Pis only support ${NC}2.4GHz${DIM} Wi-Fi — make sure you're not using a 5GHz-only network${NC}"
echo -e "  ${DIM}• Double-check your Wi-Fi password was correct${NC}"
echo -e "  ${DIM}• Make sure your Pi is within range of your router${NC}"
echo -e "  ${DIM}• Bring it back to the TechLab and we'll help you out${NC}"
echo ""

echo -e "${DIM}Manage saved networks:${NC} sudo $0 --list ${DIM}or${NC} sudo $0 --delete"
echo ""
#!/bin/bash

# WiFi Toggle Script - Toggles between Intel and UGREEN WiFi adapters
# Usage: ./wifi-toggle.sh

# Interface names
INTEL_INTERFACE="wlp4s0"      # Intel WiFi interface
UGREEN_INTERFACE="wlx6c1ff779ca6c"  # UGREEN WiFi interface

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if interface exists
interface_exists() {
    ip link show "$1" &>/dev/null
}

# Function to check if interface is up
interface_is_up() {
    [[ $(cat "/sys/class/net/$1/operstate" 2>/dev/null) == "up" ]] || 
    [[ $(ip link show "$1" 2>/dev/null | grep -c "state UP") -gt 0 ]]
}

# Function to bring interface up
bring_up() {
    local interface="$1"
    local name="$2"
    echo -e "${GREEN}Bringing up $name ($interface)...${NC}"
    sudo ip link set "$interface" up
    if interface_is_up "$interface"; then
        echo -e "${GREEN}✓ $name is now active${NC}"
    else
        echo -e "${RED}✗ Failed to activate $name${NC}"
    fi
}

# Function to bring interface down
bring_down() {
    local interface="$1"
    local name="$2"
    echo -e "${RED}Bringing down $name ($interface)...${NC}"
    sudo ip link set "$interface" down
    if ! interface_is_up "$interface"; then
        echo -e "${RED}✓ $name is now inactive${NC}"
    else
        echo -e "${RED}✗ Failed to deactivate $name${NC}"
    fi
}

# Check if interfaces exist
if ! interface_exists "$INTEL_INTERFACE"; then
    echo -e "${RED}Error: Intel WiFi interface $INTEL_INTERFACE not found${NC}"
    exit 1
fi

if ! interface_exists "$UGREEN_INTERFACE"; then
    echo -e "${RED}Error: UGREEN WiFi interface $UGREEN_INTERFACE not found${NC}"
    exit 1
fi

# Check current states
intel_up=$(interface_is_up "$INTEL_INTERFACE" && echo "true" || echo "false")
ugreen_up=$(interface_is_up "$UGREEN_INTERFACE" && echo "true" || echo "false")

echo -e "${YELLOW}Current WiFi Status:${NC}"
echo -e "Intel WiFi ($INTEL_INTERFACE): $([ "$intel_up" = "true" ] && echo -e "${GREEN}UP${NC}" || echo -e "${RED}DOWN${NC}")"
echo -e "UGREEN WiFi ($UGREEN_INTERFACE): $([ "$ugreen_up" = "true" ] && echo -e "${GREEN}UP${NC}" || echo -e "${RED}DOWN${NC}")"
echo

# Toggle logic
if [ "$intel_up" = "true" ] && [ "$ugreen_up" = "true" ]; then
    # Both are up - turn off Intel, keep UGREEN
    echo -e "${YELLOW}Both adapters are active. Switching to UGREEN only...${NC}"
    bring_down "$INTEL_INTERFACE" "Intel WiFi"
    
elif [ "$intel_up" = "false" ] && [ "$ugreen_up" = "true" ]; then
    # Only UGREEN is up - switch to Intel only
    echo -e "${YELLOW}UGREEN is active. Switching to Intel only...${NC}"
    bring_down "$UGREEN_INTERFACE" "UGREEN WiFi"
    bring_up "$INTEL_INTERFACE" "Intel WiFi"
    
elif [ "$intel_up" = "true" ] && [ "$ugreen_up" = "false" ]; then
    # Only Intel is up - switch to UGREEN only
    echo -e "${YELLOW}Intel is active. Switching to UGREEN only...${NC}"
    bring_down "$INTEL_INTERFACE" "Intel WiFi"
    bring_up "$UGREEN_INTERFACE" "UGREEN WiFi"
    
else
    # Both are down - bring up UGREEN
    echo -e "${YELLOW}Both adapters are inactive. Activating UGREEN...${NC}"
    bring_up "$UGREEN_INTERFACE" "UGREEN WiFi"
fi

echo
echo -e "${YELLOW}Final WiFi Status:${NC}"
intel_up=$(interface_is_up "$INTEL_INTERFACE" && echo "true" || echo "false")
ugreen_up=$(interface_is_up "$UGREEN_INTERFACE" && echo "true" || echo "false")
echo -e "Intel WiFi ($INTEL_INTERFACE): $([ "$intel_up" = "true" ] && echo -e "${GREEN}UP${NC}" || echo -e "${RED}DOWN${NC}")"
echo -e "UGREEN WiFi ($UGREEN_INTERFACE): $([ "$ugreen_up" = "true" ] && echo -e "${GREEN}UP${NC}" || echo -e "${RED}DOWN${NC}")"
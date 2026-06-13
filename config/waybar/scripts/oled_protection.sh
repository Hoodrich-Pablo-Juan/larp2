#!/bin/bash

# OLED Protection script for Waybar
# Shifts the vertical position of Waybar every few minutes

while true; do
    # Shift down by 1px
    hyprctl keyword "layerrule" "margin-top 1, waybar"
    sleep 300 # 5 minutes
    
    # Shift back to 0px
    hyprctl keyword "layerrule" "margin-top 0, waybar"
    sleep 300
    
    # Shift down by 2px
    hyprctl keyword "layerrule" "margin-top 2, waybar"
    sleep 300
    
    # Shift back to 0px
    hyprctl keyword "layerrule" "margin-top 0, waybar"
    sleep 300
done

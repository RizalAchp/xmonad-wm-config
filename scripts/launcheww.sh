#!/usr/bin/env bash

function launchcenter() {
    $HOME/bin/eww open-many blur_full \
        weather profile quote \
        search_full incognito-icon \
        vpn-icon home_dir screenshot \
        power_full reboot_full lock_full \
        logout_full suspend_full
}

function launchsidebar() {
    $HOME/bin/eww open-many weather_side \
        time_side smol_calendar player_side \
        sys_side sliders_side
}

while :
do
    case "$1" in
        -c)
            launchcenter
            break;
            ;;
        -s)
            launchsidebar
            break;
            ;;
        *)
            break;
            ;;
    esac
done
